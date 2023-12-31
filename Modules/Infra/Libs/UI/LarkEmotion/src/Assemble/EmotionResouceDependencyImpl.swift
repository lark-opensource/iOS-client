//
//  EmotionResouceDependencyImpl.swift
//  LarkEmotion
//
//  Created by 李勇 on 2021/3/3.
//

import Foundation
import UIKit
import LarkRustClient
import RustPB
import LarkContainer
import RxSwift
import ThreadSafeDataStructure
import ByteWebImage
import LarkFeatureGating

/// ResouceDependency在Lark中的实现
final class EmotionResouceDependencyImpl: EmotionResouceDependency, UserResolverWrapper {
    let userResolver: UserResolver
    /// 使用Provider每次都去重新获取，避免切换租户时rustService被释放导致请求被cancel
    @ScopedProvider private var rustService: RustService?
    private let disposeBag = DisposeBag()
    private let lock = NSLock()
    /// 正在拉取图片的imageKey，避免相同imageKey重复拉取
    private var inFetchImageKeys = SafeSet<String>() + .readWriteLock
    /// 正在拉取彩蛋的animationKey-AnimationItem，避免相同animationKey重复拉取
    private var animationKeyCache: SafeDictionary<String, AnimationItem> = [:] + .readWriteLock
    /// 正在拉取彩蛋的animationKey-emojiKeys，没有获取对应AnimationItem前避免相同animationKey重复拉取
    private var inFetchAnimationKeyToEmojiKeys: SafeDictionary<String, [String]> = [:] + .readWriteLock
    /// 当前是否正在拉取资源
    private var inFetchResouce: SafeAtomic<Bool> = false + .semaphore
    
    private lazy var emotionResouceConcurrentEnable = userResolver.fg.staticFeatureGatingValue(with: "messenger.emotion.resouce_concurrent")

    /// 拉取彩蛋动画资源的最大并发数
    private let fetchAnimationMaxNumInQueue = 1
    private let animationSemaphore: DispatchSemaphore
    private let animationQueue = DispatchQueue(label: "LarkEmotion.fetchAnimation.queue", qos: .background)

    init(resolver: UserResolver) {
        self.userResolver = resolver
        animationSemaphore = DispatchSemaphore(value: 0)
        // 在init时signal()，避免deinit时信号量值小于创建时的初始值
        for _ in 1 ... fetchAnimationMaxNumInQueue {
            animationSemaphore.signal()
        }
    }

    /// 通过imageKey拉取对应的图片，和EEImageService owner沟通，目前只能用这种方式
    func fetchImage(imageKey: String, emojiKey: String, callback: @escaping (UIImage) -> Void) {
        guard !self.inFetchImageKeys.value.contains(imageKey) else { return }
        self.inFetchImageKeys.value.insert(imageKey)

        EmotionUtils.logger.info("EmotionResouceImp: fetchImage start emojiKey = \(emojiKey), imageKey: \(imageKey)")

        let category: [String: Any] = [
            "image_key": imageKey
        ]
        let beginTime = CACurrentMediaTime()
        if emotionResouceConcurrentEnable {
            LarkImageService.shared.setImage(
                with: .reaction(key: imageKey, isEmojis: true),
                options: [.notDecodeForDisplay, .priority(.low)],
                category: "reaction",
                completion: { [weak self] result in
                    guard let self = self else { return }
                    // 转成ms
                    let time = (CACurrentMediaTime() - beginTime) * 1000
                    switch result {
                    case .success(let imageResult):
                        // 下载表情图片资源
                        EmotionTracker.trackerSlardar(event: "emoji_load_image", time: time, category: category, metric: [:], error: nil)
                        EmotionTracker.trackerTea(event: Const.loadImageEvent, time: time, extraParams: [Const.imageKey: imageKey], error: nil)
                        if let reactionIcon = imageResult.image {
                            callback(reactionIcon)
                        } else {
                            EmotionUtils.logger.warn("EmotionResouceImp: fetchImage reactionIcon is nil, emojiKey = \(emojiKey), imageKey = \(imageKey)")
                        }
                    case .failure(let error):
                        // 下载表情图片资源
                        EmotionTracker.trackerSlardar(event: "emoji_load_image", time: time, category: category, metric: [:], error: error)
                        EmotionTracker.trackerTea(event: Const.loadImageEvent, time: time, extraParams: [Const.imageKey: imageKey], error: error)
                        EmotionUtils.logger.error("EmotionResouceImp: fetchImage failed emojiKey = \(emojiKey), imageKey = \(imageKey), error = \(error)")
                    }
                    _ = self.inFetchImageKeys.value.remove(imageKey)
                }
            )
        } else {
            DispatchQueue.main.async {
                var imageView: UIImageView? = UIImageView()
                imageView?.bt.setLarkImage(with: .reaction(key: imageKey, isEmojis: true),
                                           trackStart: {
                    TrackInfo(biz: .Messenger, scene: .Chat, fromType: .reaction)
                },
                                           completion: { [weak self] result in
                    if let reactionIcon = try? result.get().image {
                        callback(reactionIcon)
                    } else {
                        EmotionUtils.logger.error("EmotionResouceImp: fetchImage failed emojiKey = \(emojiKey), imageKey: \(imageKey)")
                    }
                    imageView = nil
                    _ = self?.inFetchImageKeys.value.remove(imageKey)
                })
            }
        }
    }

    /// 从服务端同步资源：指定单个或者全部
    // nolint: duplicated_code -- 待重构
    func fetchResouce(key: String?, version: Int32, callback: @escaping ([String: Resouce], Int32) -> Void) {
        guard !self.inFetchResouce.value else { return }
        self.inFetchResouce.value = true
        EmotionUtils.logger.info("EmotionResouceImp: fetchResouce start: \(key)")
        var request = Im_V1_GetEmojisRequest()
        if version != 0 {
            request.version = version
        }
        var count = 0
        var full = true
        if let key = key {
            request.triggerKeys = [key]
            count = 1
            full = false
        }
        // Slardar表情监控埋点
        let metric: [String: Any] = [
            "count": count
        ]
        let category: [String: Any] = [
            "full_request": full
        ]
        let beginTime = CACurrentMediaTime()
        self.rustService?.sendAsyncRequest(request).subscribe(onNext: { [weak self] (response: Im_V1_GetEmojisResponse) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取 Emoji 信息
            EmotionTracker.trackerSlardar(event: "emoji_get_emojis", time: time, category: category, metric: metric, error: nil)
            EmotionTracker.trackerTea(event: Const.getEmojisEvent, time: time, extraParams: [Const.count: count, Const.fullRequest: full], error: nil)
            var resouces: [String: Resouce] = [:]
            response.emojis.forEach { (key, imV1Emoji) in
                if !imV1Emoji.skinKeys.isEmpty {
                    EmotionUtils.logger.error("EmotionResouceImp: \(key) skinKeys = \(imV1Emoji.skinKeys)")
                }
                let resouce = Resouce(i18n: imV1Emoji.text,
                                      imageKey: imV1Emoji.imageKey,
                                      isDelete: imV1Emoji.isDeleted,
                                      skinKeys: imV1Emoji.skinKeys,
                                      size: CGSize(width: CGFloat (imV1Emoji.width),
                                                   height: CGFloat(imV1Emoji.height)))
                resouces[key] = resouce
            }
            EmotionUtils.logger.info("EmotionResouceImp: fetchResouce succeed response.emojis count: \(response.emojis.count)")
            callback(resouces, response.version)
            self?.inFetchResouce.value = false
        }, onError: { [weak self] (error) in
            self?.fetchOnError(beginTime: beginTime, category: category, metric: metric, error: error)
        }).disposed(by: self.disposeBag)
    }

    /// 从服务端同步资源：批量指定
    func fetchResouce(keys: [String], version: Int32, callback: @escaping ([String: Resouce], Int32) -> Void) {
        guard !self.inFetchResouce.value else { return }
        self.inFetchResouce.value = true
        EmotionUtils.logger.info("EmotionResouceImp: batch fetchResouce start: \(keys)")
        var request = Im_V1_GetEmojisRequest()
        if version != 0 {
            request.version = version
        }
        request.triggerKeys = keys
        var count = keys.count
        var full = keys.isEmpty
        // Slardar表情监控埋点
        let metric: [String: Any] = [
            "count": count
        ]
        let category: [String: Any] = [
            "full_request": full
        ]
        let beginTime = CACurrentMediaTime()
        self.rustService?.sendAsyncRequest(request).subscribe(onNext: { [weak self] (response: Im_V1_GetEmojisResponse) in
            // 转成ms
            let time = (CACurrentMediaTime() - beginTime) * 1000
            // 获取 Emoji 信息
            EmotionTracker.trackerSlardar(event: "emoji_get_emojis", time: time, category: category, metric: metric, error: nil)
            EmotionTracker.trackerTea(event: Const.getEmojisEvent, time: time, extraParams: [Const.count: count, Const.fullRequest: full], error: nil)
            var resouces: [String: Resouce] = [:]
            response.emojis.forEach { (key, imV1Emoji) in
                if !imV1Emoji.skinKeys.isEmpty {
                    EmotionUtils.logger.error("EmotionResouceImp: \(key) skinKeys = \(imV1Emoji.skinKeys)")
                }
                let resouce = Resouce(i18n: imV1Emoji.text,
                                      imageKey: imV1Emoji.imageKey,
                                      isDelete: imV1Emoji.isDeleted,
                                      skinKeys: imV1Emoji.skinKeys,
                                      size: CGSize(width: CGFloat (imV1Emoji.width),
                                                   height: CGFloat(imV1Emoji.height)))
                resouces[key] = resouce
            }
            let emojiKeys = response.emojis.map { (key, _) in
                return key
            }
            EmotionUtils.logger.info("EmotionResouceImp: fetchResouce succeed response.emojis.keys: \(emojiKeys)")
            callback(resouces, response.version)
            self?.inFetchResouce.value = false
        }, onError: { [weak self] (error) in
            self?.fetchOnError(beginTime: beginTime, category: category, metric: metric, error: error)
        }).disposed(by: self.disposeBag)
    }
    
    private func fetchOnError(beginTime: CFTimeInterval,
                              category: [String: Any],
                              metric: [String: Any], error: Error) {
        // 转成ms
        let time = (CACurrentMediaTime() - beginTime) * 1000
        // 获取 Emoji 信息
        EmotionTracker.trackerSlardar(event: "emoji_get_emojis", time: time, category: category, metric: metric, error: error)
        var extraParams: [AnyHashable: Any] = [:]
        extraParams[Const.count] = metric[Const.count]
        extraParams[Const.fullRequest] = category[Const.fullRequest]
        EmotionTracker.trackerTea(event: Const.getEmojisEvent, time: time, extraParams: extraParams, error: error)
        EmotionUtils.logger.error("EmotionResouceImp: fetchResouce failed error = \(error)")
        self.inFetchResouce.value = false
    }
}

extension EmotionResouceDependencyImpl {
    enum Const {
        static let getEmojisEvent: String = "emoji_get_emojis"
        static let loadImageEvent: String = "emoji_load_image"
        static let count: String = "count"
        static let fullRequest: String = "full_request"
        static let imageKey: String = "image_key"
    }
}
