//
//  EmotionResouce.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/3.
//

import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure
import UIKit
import UniverseDesignColor
import CoreGraphics
import RustPB
import LarkLocalizations
import LarkSetting
import LarkFeatureGating

public extension NSNotification.Name {
    static let LKEmojiImageDownloadSucceedNotification = NSNotification.Name("LKEmojiImageDownloadSucceedNotification")
}

/// 资源模型
public final class Resouce {
    /// 国际化文案
    public var i18n: String
    /// 图片标识符
    public var imageKey: String
    /// 兜底本地图片名称，启动优化：启动时不同步读取图片，在第一次要使访问/修改image前进行读取
    public var imageName: String?
    /// 对应的图片，可能是：1、兜底本地图片，2、网络拉取。
    public var image: UIImage?
    /// 是否被禁用
    public var isDelete: Bool
    /// 所有皮肤key
    public var skinKeys: [String]
    /// emoji 原图的尺寸, 单位pt
    public var size: CGSize
    /// 表情的类型：默认、企业自定义等
    public var type: RustPB.Im_V1_EmojiPanel.TypeEnum

    /// init
    public init(i18n: String,
                imageKey: String,
                imageName: String? = nil,
                image: UIImage? = nil,
                isDelete: Bool,
                skinKeys: [String] = [],
                size: CGSize = .zero,
                type: RustPB.Im_V1_EmojiPanel.TypeEnum = .unknown) {
        self.i18n = i18n
        self.imageKey = imageKey
        self.imageName = imageName
        self.image = image
        self.isDelete = isDelete
        self.skinKeys = skinKeys
        self.size = size
        self.type = type
    }
}


/// 单例拆分，组件化改造一起处理，TODO：@qujieye
/// 替换EmotionHelper，封装文案&图片获取逻辑
/// 1、Emotion和Emoji是一个东西的不同说法，本类中同一用Emotion；
/// 2、Reaction面板在长按消息时出现，属于消息的附加信息；
/// 3、Emotion面板是Chat底部键盘中的一部分，属于消息体内的信息。
public final class EmotionResouce {
    /// 存放一些特定的表情ReactionKey
    public struct ReactionKeys {
        /// 👍
        public static var thumbsup = "THUMBSUP"
    }

    /// 单例对象
    public static let shared = EmotionResouce()

    /// 兜底，最近使用reaction_key
    public static let recentReactions = ["MUSCLE", "APPLAUSE", "OK", "THUMBSUP", "HEART", "JIAYI",
                                         "DONE", "BLUSH", "FACEPALM"]
    
    /// 兜底，最常使用reaction_key
    public static let mruReactions = ["OK", "FACEPALM", "LOL", "Get", "GLANCE", "CRY",
                                         "SOB", "FINGERHEART", "THUMBSUP"]
    
    /// 兜底，本地所有reaction_key
    public static let reactions = EmotionHelper.readPlistContent("reactions") as? [String] ?? []

    /// 加载失败的兜底图
    public static let colorImage = UIColor.ud.image(with: UIColor.ud.N900, size: CGSize(width: 32, height: 32), scale: 1)
    public static let circleImage = colorImage?.circleImage(cornerRadius: Const.circleImageCornerRadisu,
                                                            size: CGSize(width: 32, height: 32),
                                                            roundingCorners: .allCorners)
    public static let placeholder = circleImage?.ud.withTintColor(UIColor.ud.N900.withAlphaComponent(0.06)) ?? UIImage()

    /// 根据语言来判断是否是海外用户
    public static func isOversea() -> Bool {
        let language = BundleI18n.currentLanguage
        // 任何一种中文语言都属于国内（非海外）用户
        return !(language == .zh_CN || language == .zh_HK || language == .zh_TW)
    }

    /// 内部依赖
    public var dependency: EmotionResouceDependency?

    /// 所有资源，全量的数据（本地+服务端下发）
    private let allResouces: SafeDictionary<String, Resouce> = [:] + .readWriteLock
    /// 是否需要填充本地图片，启动优化：启动时不同步读取图片，在第一次要使用到数据前进行读取
    private let needReadLocalImage: SafeAtomic<Bool> = true + .semaphore
    /// 所有资源对应的version，用于打点使用
    private let resouceVersion: SafeAtomic<Int32> = 0 + .semaphore
    /// emotion_key -> reaction_key，全量的数据（本地+服务端下发）
    private let emotionToReaction: SafeDictionary<String, String> = [:] + .readWriteLock
    /// reaction_key -> emotion_key，全量的数据（本地+服务端下发）
    private let reactionToEmotion: SafeDictionary<String, String> = [:] + .readWriteLock
    /// i18n -> emotion_key，全量的数据（本地+服务端下发）
    private let i18nToEmotion: SafeDictionary<String, String> = [:] + .readWriteLock
    private let backupSize = CGSize(width: 32, height: 32)

    /// 切租户/冷启动/重新登陆会重新加载一次兜底数据
    public func reloadResouces(key: String? = nil) {
        EmotionUtils.logger.info("EmotionResouce: reloadResouces start")

        // 不支持发送的key黑名单，兜底isDelete设置为true，业务方不用再理解黑名单，只理解isDelete
        let blackKeys: Set<String> = [
            "Lark_Emoji_Attention_0", "Lark_Emoji_WellDone_0", "Lark_Emoji_GoodJob_0",
            "Lark_Emoji_Detergent_0", "Lark_Emoji_Awesome_0", "Lark_Emoji_FollowMe_0",
            "ATTENTION", "WELLDONE", "GOODJOB", "DETERGENT", "AWESOME", "FOLLOWME"
        ]

        var allResouces: [String: Resouce] = [:]
        var emotionToReaction: [String: String] = [:]
        var reactionToEmotion: [String: String] = [:]
        var i18nToEmotion: [String: String] = [:]

        EmotionHelper.emotionInfos.forEach { (value: [String]) in
            // 如果是5个，配置为：(国内ImageKey, 国际化文案key, EmotionKey, 国内ImageName, ReactionKey)
            // 如果是7个，配置为：(国内ImageKey, 国际化文案key, EmotionKey, 国内ImageName, ReactionKey, 海外/英文 ImageName, 海外/英文 ImageKey)
            guard value.count == 5 || value.count == 7 else { return }

            var isOversea = EmotionResouce.isOversea()
            // -----------------------------------------------------------------------
            // 服务端目前LarkValues在繁体中文下还是英文样式，为了和安卓的表现一致，先加入如下判断
            // 等服务端修改后整段特化处理代码需要删除
            let name = Int(value[3]) ?? 0
            let isLarkValues = (name >= Const.larkValueStartIndex && name <= Const.larkValueEndIndex)
            if isLarkValues && BundleI18n.currentLanguage != .zh_CN {
                isOversea = true
            }
            // -----------------------------------------------------------------------

            let imageKey = (isOversea && value.count == 7) ? value[6] : value[0]
            let i18n = value[1]
            let emotionKey = value[2]
            let imageName = (isOversea && value.count == 7) ? value[5] : value[3]
            let reactionKey = value[4]
            let skinKeys = EmotionHelper.keyToSkinKeysMap[emotionKey] ?? []

            allResouces[emotionKey] = Resouce(
                i18n: i18n,
                imageKey: imageKey,
                imageName: imageName,
                isDelete: blackKeys.contains(emotionKey),
                skinKeys: skinKeys,
                type: .default
            )
            allResouces[reactionKey] = Resouce(
                i18n: i18n,
                imageKey: imageKey,
                imageName: imageName,
                isDelete: blackKeys.contains(reactionKey),
                skinKeys: skinKeys,
                type: .default
            )
            // 填充emotion_key与reaction_key转换关系
            emotionToReaction[emotionKey] = reactionKey
            reactionToEmotion[reactionKey] = emotionKey
            // 填充emotion_key与文案对应关系
            i18nToEmotion[i18n] = emotionKey
        }
        // 重新初始化为本地新值
        self.allResouces.replaceInnerData(by: allResouces)
        self.resouceVersion.value = 0
        self.needReadLocalImage.value = true
        self.emotionToReaction.replaceInnerData(by: emotionToReaction)
        self.reactionToEmotion.replaceInnerData(by: reactionToEmotion)
        self.i18nToEmotion.replaceInnerData(by: i18nToEmotion)
        self.fetchResouce(key: key)
    }

    /// 填充本地兜底图片
    private func readLocalImageIfNeeded() {
        guard self.needReadLocalImage.value else { return }
        self.needReadLocalImage.value = false

        self.allResouces.values.forEach { (resouce) in
            guard let name = resouce.imageName else { return }
            let image = EmotionHelper.image(named: name)
            resouce.image = image
            resouce.size = image?.size ?? self.backupSize
        }
    }

    /// mergeResouces
    /// canFetchImage: 拉图片依赖图片服务, 需要外面决定是否能拉取图片而避免撞Assert
    public func mergeResouces(resouces: [String: Resouce], version: Int32) {
        EmotionUtils.logger.info("EmotionResouce: mergeResouces start, version = \(version) self.resouceVersion = \(resouceVersion.value)")
        // 解决SDK可能的时序问题，SDK给端上的是SDK侧merge后全量的数据，端上只需要处理最新的就好
        guard version > self.resouceVersion.value else { return }
        self.resouceVersion.value = version
        // 必须先读取本地图片，避免imageKey变更image清空后，又读取了本地图片
        self.readLocalImageIfNeeded()
        EmotionUtils.logger.info("EmotionResouce: mergeResouces resouces count = \(resouces.count)")

        resouces.forEach { (key, resouce) in
            if resouce.isDelete {
                EmotionUtils.logger.error("EmotionResouce: mergeResouces key length\(key.count) isDeleted = \(resouce.isDelete)")
            }
            if !resouce.skinKeys.isEmpty {
                EmotionUtils.logger.error("EmotionResouce: mergeResouces key length\(key.count) skinKeys = \(resouce.skinKeys)")
            }
            // 如果有值，则按需进行替换
            if let temp = self.allResouces[key] {
                if temp.i18n != resouce.i18n {
                    // 如果服务端下发的文案和本地的不一致会替换本地的文案
                    EmotionUtils.logger.error("EmotionResouce: mergeResouces i8n Key lose, Emotinkey length = \(key.count)")
                    // 如果该key是emotion_key，需要替换对应关系
                    if self.emotionToReaction.keys.contains(key) {
                        self.i18nToEmotion[resouce.i18n] = key
                    }
                    temp.i18n = resouce.i18n
                }
                // imageKey不同，则需要清除本地图片
                if temp.imageKey != resouce.imageKey {
                    EmotionUtils.logger.error("EmotionResouce: mergeResouces imageKeyChanged emojiKey length = \(key.count), localImageKey = \(temp.imageKey), serverImageKey = \(resouce.imageKey)")
                    temp.image = nil
                    temp.imageKey = resouce.imageKey
                    // 如果有图片，则需要进行拉取
                    self.dependency?.fetchImage(imageKey: resouce.imageKey, emojiKey: key, callback: { [weak self] (image) in
                        guard let `self` = self else { return }
                        self.allResouces[key]?.image = image
                        // 老的表情reactionKey和emotionKey不同, 需要同时更新, 避免不同的使用方对同一资源获取两次
                        if let reactionkey = self.reactionKeyBy(emotionKey: key), reactionkey != key {
                            self.allResouces[reactionkey]?.image = image
                        }
                        if let emotionKey = self.emotionKeyBy(reactionKey: key), emotionKey != key {
                            self.allResouces[emotionKey]?.image = image
                        }
                    })
                    if resouce.size != .zero, resouce.size != temp.size {
                        temp.size = resouce.size
                        EmotionUtils.logger.error("EmotionResouce: mergeResouces resouce.size is changed emojiKey length = \(key.count), size = \(resouce.size)")
                    }
                }
                temp.skinKeys = resouce.skinKeys
                temp.isDelete = resouce.isDelete
            } else {
                EmotionUtils.logger.error("EmotionResouce: mergeResouces server add newEmojiKey length = \(key.count), imageKey = \(resouce.imageKey), skinKeys = \(resouce.skinKeys)")
                // 如果没值，则需要进行添加：企业自定义表情的增加以及新增默认表情会走这边逻辑
                self.allResouces[key] = resouce
                // 此版本之后新增的reaction_key和emoji_key使用相同的key
                self.emotionToReaction[key] = key
                self.reactionToEmotion[key] = key
                // 填充emotion_key与文案对应关系
                self.i18nToEmotion[resouce.i18n] = key
                // 如果有图片，则需要进行拉取
                self.dependency?.fetchImage(imageKey: resouce.imageKey, emojiKey: key, callback: { [weak self] (image) in
                    guard let `self` = self else { return }
                    self.allResouces[key]?.image = image
                    self.allResouces[key]?.size = image.size
                    // 新增的表情（包括服务端新加的和企业自定义的）图片下载成功需要通知给上层页面
                    NotificationCenter.default.post(name: .LKEmojiImageDownloadSucceedNotification, object: ["key": key], userInfo: nil)
                })
            }
        }
    }

    /// 拉取服务端资源列表：指定某一个key或者全部
    /// canFetchImage: 是否能拉取图片(拉图片依赖图片服务, 需要外面决定是否能拉取图片而避免撞Assert)
    public func fetchResouce(key: String?) {
        self.dependency?.fetchResouce(key: key, version: self.resouceVersion.value, callback: { [weak self] (resouces, version) in
            self?.mergeResouces(resouces: resouces, version: version)
        })
    }

    /// 批量拉取服务端资源列表：指定某一些keys
    /// canFetchImage: 是否能拉取图片(拉图片依赖图片服务, 需要外面决定是否能拉取图片而避免撞Assert)
    public func fetchResouce(keys: [String]) {
        guard !keys.isEmpty else { return }
        self.dependency?.fetchResouce(keys: keys, version: self.resouceVersion.value, callback: { [weak self] (resouces, version) in
            self?.mergeResouces(resouces: resouces, version: version)
        })
    }

    /// 通过key获取Resouce资源对象
    public func resourceBy(key: String) -> Resouce? {
        return self.allResouces[key]
    }

    /// 获取表情违规状态下显示的文案
    public func getIllegaDisplayText() -> String {
        return BundleI18n.LarkEmotion.Lark_IM_ImageIllegalUnableToDisplay_Text
    }

    /// 通过key获取本地图片
    public func imageBy(key: String) -> UIImage? {
        guard key.isEmpty == false else { return nil }
        // 必须先读取本地图片，此时需要用到本地图片
        self.readLocalImageIfNeeded()
        // key对应的资源在本地缓存里面存在 并且 没有被禁用
        if let resouce = self.allResouces[key], resouce.isDelete == false {
            if let image = resouce.image {
                return image
            } else {
                EmotionUtils.logger.error("EmotionResouce: allResouces contains this emojiKey length: \(key.count) but it's imageKey: \(resouce.imageKey) hasn't cached image!!! begin to fetch...")
                // 如果没有图片，则需要进行拉取
                self.dependency?.fetchImage(imageKey: resouce.imageKey, emojiKey: key, callback: { [weak self] (image) in
                    guard let `self` = self else { return }
                    self.allResouces[key]?.image = image
                    // 老的表情reactionKey和emotionKey不同, 需要同时更新, 避免不同的使用方对同一资源获取两次
                    if let reactionkey = self.reactionKeyBy(emotionKey: key), reactionkey != key {
                        self.allResouces[reactionkey]?.image = image
                    }
                    if let emotionKey = self.emotionKeyBy(reactionKey: key), emotionKey != key {
                        self.allResouces[emotionKey]?.image = image
                    }
                })
                return nil
            }
        }
        // key对应的资源在本地缓存里面存在 但是 由于安全或其他原因被禁用了（牢记安全生产第一条）
        if let resouce = self.allResouces[key], resouce.isDelete == true {
            EmotionUtils.logger.error("EmotionResouce: allResouces contains this emojiKey length: \(key.count) but it's isDelete == true")
            // 切记要返回给调用者nil，防止色情、反动等图片透出
            return nil
        }
        // 到这边的话说明key对应的资源在本地缓存里面不存在
        EmotionUtils.logger.error("EmotionResouce: allResouces not contains this emojiKey length: \(key.count) begin to fetchResouce")
        // allResouces没有该key，则需要从服务端进行拉取
        self.fetchResouce(key: key)
        // 打点上报，此时触发了fallback逻辑
        EmotionTracker.trackFallback(key: key, version: self.resouceVersion.value)
        return nil
    }

    /// 通过key获取imageKey，key：reaction_key/emotion_key
    public func imageKeyBy(key: String) -> String? {
        return self.allResouces[key]?.imageKey
    }

    /// 通过key获取国际化文案，key：reaction_key/emotion_key
    public func i18nBy(key: String) -> String? {
        guard self.isDeletedBy(key: key) == false else {
            // 如果该表情违规的话返回给业务违规提示
            return self.getIllegaDisplayText()
        }
        return self.allResouces[key]?.i18n
    }

    /// 通过国际化文案得到emotion_key
    public func emotionKeyBy(i18n: String) -> String? {
        let emojiKey = self.i18nToEmotion[i18n] ?? "NotFound"
        EmotionUtils.logger.error("EmotionResouce: emotionKeyBy(i18n:) has deprecated, emojiKey length: \(emojiKey.count)")
        return self.i18nToEmotion[i18n]
    }

    // 获取emoji 原图的尺寸, 单位pt
    public func sizeBy(key: String) -> CGSize? {
        let size = self.allResouces[key]?.size
        if let size = size, size != .zero {
            return size
        } else {
            let image = self.allResouces[key]?.image
            return image?.size ?? backupSize
        }
    }

    /// 通过key获取skinKeys，key：reaction_key/emotion_key
    public func skinKeysBy(key: String) -> [String] {
        let resouces = self.allResouces[key]
        if resouces == nil {
            EmotionUtils.logger.error("EmotionResouce: resouces is nil, key length = \(key.count)")
        }
        if resouces?.skinKeys.isEmpty == true {
            // 多肤色本地兜底
            if let skinKeys = EmotionHelper.keyToSkinKeysMap[key] {
                EmotionUtils.logger.error("EmotionResouce: key length = \(key.count) skinKeys is empty, use local instead")
                return skinKeys
            }
        }
        return self.allResouces[key]?.skinKeys ?? []
    }

    /// 通过key获取资源是否被禁用，key：reaction_key/emotion_key
    public func isDeletedBy(key: String) -> Bool {
        // 之前map中不存在的key认为是禁用的，但是有了企业自定义表情后就不能这么认为了
        // 只有服务端明确的告诉我这个表情违规才设置成true，在任何地方都不再显示，不单是表情面板
        let isDeleted = self.allResouces[key]?.isDelete ?? false
        if isDeleted {
            EmotionUtils.logger.error("EmotionResouce: isDeletedBy has been called, but key isDeleted = \(isDeleted), key length = \(key.count)")
        }
        return isDeleted
    }

    /// 通过emoji_key获取对应的reaction_key
    public func reactionKeyBy(emotionKey: String) -> String? {
        return self.emotionToReaction[emotionKey]
    }

    /// 通过reaction_key获取对应的emotion_key
    public func emotionKeyBy(reactionKey: String) -> String? {
        return self.reactionToEmotion[reactionKey]
    }

    /// map缓存里面是否存在对应的key，key：reaction_key/emotion_key
    public func isInAllResoucesMapBy(key: String) -> Bool {
        // 判断map中是否存在对应的key，默认不在map缓存中
        var result = false
        if let resouce = self.allResouces[key] {
            result = true
        }
        return result
    }

    /// 查询是否是企业自定义表情，key：reaction_key/emotion_key
    public func isCustomEmotionBy(key: String) -> Bool {
        // 有些key可能压根不在缓存里面
        // 这说明：要么服务端GetEmojis的时候漏发了（那就是server的锅）要么是其他企业的表情（外部租户流入）
        guard let resouce = self.allResouces[key] else {
            return true
        }
        var result = false
        // 只要不是.default我们都认为是企业自定义表情，因为其他企业的表情第一次拉取后也会进缓存，这样type默认是.unknown
        if resouce.type != .default {
            result = true
        }
        return result
    }
}

extension UIImage {
    func circleImage(cornerRadius: CGFloat, size: CGSize, roundingCorners: UIRectCorner) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        // 开启上下文
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        if let context = UIGraphicsGetCurrentContext() {
            var path: UIBezierPath
            // 判断剪切的图片是否是矩形
            if size.height == size.width {
                // 剪切为圆形
                if cornerRadius == size.width/2 {
                    path = UIBezierPath(arcCenter: CGPoint(x: size.width/2, y: size.height/2), radius: cornerRadius, startAngle: 0, endAngle: 2.0*CGFloat(Double.pi), clockwise: true)
                } else {
                    // 按圆角剪切
                    path = UIBezierPath(roundedRect: rect, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
                }
            } else {
                // 按圆角剪切
                path = UIBezierPath(roundedRect: rect, byRoundingCorners: roundingCorners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            }
            context.addPath(path.cgPath)
            context.clip()
            self.draw(in: rect)
            // 从上下文上获取剪裁后的照片
            guard let uncompressedImage = UIGraphicsGetImageFromCurrentImageContext() else {
                UIGraphicsEndImageContext()
                return nil
            }
            // 关闭上下文
            UIGraphicsEndImageContext()
            return uncompressedImage
        } else {
            return nil
        }
    }
}

extension EmotionResouce {
    enum Const {
        static let circleImageCornerRadisu: CGFloat = 16
        static let larkValueStartIndex: Int = 234
        static let larkValueEndIndex: Int = 241
    }
}
