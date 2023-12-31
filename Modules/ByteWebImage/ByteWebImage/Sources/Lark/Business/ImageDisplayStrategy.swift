//
//  ImageDisplay.swift
//  LarkMessageCore
//
//  Created by kangsiwan on 2022/7/19.
//

import RustPB
import Foundation
import LarkSetting
import LKCommonsTracker
import LKCommonsLogging
import ThreadSafeDataStructure

public typealias DisplayPlaceholder = () -> UIImage?
// 图片展示时，业务方需要提供的key和placeholder
public protocol ImageDisplayDataProvider {
    /// 展示需要展示key
    func getImageKeyResource() -> LarkImageResource
    /// placeholder需要展示的UIImage
    func getImagePlaceholder() -> DisplayPlaceholder?
}

public extension ImageDisplayDataProvider {
    func getImagePlaceholder() -> DisplayPlaceholder? {
        return nil
    }
}

extension LarkImageResource: ImageDisplayDataProvider {
    public func getImageKeyResource() -> LarkImageResource {
        return self
    }
}

// 实现 ImageDisplayDataProvider 协议
public final class ImageDisplayDataProviderImpl: ImageDisplayDataProvider {
    public var imageKeyResource: LarkImageResource
    public var imagePlaceholder: DisplayPlaceholder?
    public init(imageKeyResource: LarkImageResource, imagePlaceholder: DisplayPlaceholder?) {
        self.imageKeyResource = imageKeyResource
        self.imagePlaceholder = imagePlaceholder
    }
    public func getImageKeyResource() -> LarkImageResource {
        return self.imageKeyResource
    }

    public func getImagePlaceholder() -> DisplayPlaceholder? {
        return imagePlaceholder
    }
}

// 上报埋点参数
public struct ImageDisplayTrackerParams {
    // 降级场景
    let scene: ImageDisplayScene
    // 是否有缓存
    let hasCache: Bool
    // 缓存级别
    let cacheLevel: String?
}

// 埋点上报的scene
public enum ImageDisplayScene: String {
    case imageMessage = "image_message"
    case messageReplay = "message_replay"
    case postMessage = "post_message"
    case mediaCover = "media_cover"
    case momentsImage = "moments_image"
    case lookLargeImage = "look_large_image"
}

public final class ImageDisplayStrategy {

    struct ImageDisplayItem {

        enum ImageDisplayKeyType: String {
            case origin
            case middle
            case thumb
        }

        let item: ImageItem
        let type: ImageDisplayKeyType
    }

    private static let logger = Logger.log(ImageDisplayStrategy.self, category: "ImageDisplayStrategy")
    private static var infoMap: SafeDictionary<String, Double> = [:] + .readWriteLock

    // Setting中有设置「"remote_default_target": "middle"」这样的值，此处转换一下
    static func transStringToItem(imageItemSet: ImageItemSet, str: String) -> ImageDisplayItem? {
        if str == "middle", let middleItem = imageItemSet.middle, middleItem.key != nil {
            return ImageDisplayItem(item: middleItem, type: .middle)
        } else if str == "thumb", let thumbItem = imageItemSet.thumbnail, thumbItem.key != nil {
            return ImageDisplayItem(item: thumbItem, type: .thumb)
        } else if str == "origin", let originItem = imageItemSet.origin, originItem.key != nil {
            return ImageDisplayItem(item: originItem, type: .origin)
        }
        return nil
    }

    /// 在chat内的加载策略：
    /// target：
    ///     1. middle/thumb（根据当前屏幕大小）
    ///     2. origin
    /// placeholder：
    ///     1. inline
    public static func messageImage(imageItem: ImageItemSet, scene: ImageDisplayScene, originSize: Int) -> ImageItem? {
        guard LarkImageService.shared.imageDisplaySetting.messageImageLoad.cache.cacheEnable else { return nil }
        let firstFindImageItem: ImageItem = imageItem.getThumbItem()
        let firstFindImageKeyType: ImageDisplayItem.ImageDisplayKeyType =
            (firstFindImageItem.key == imageItem.thumbnail?.key ?? "") ? .thumb : .middle
        let findItemArray: [ImageDisplayItem] = [
            ImageDisplayItem(item: firstFindImageItem, type: firstFindImageKeyType),
            ImageDisplayItem(item: imageItem.origin ?? ImageItem(), type: .origin)
        ]
        if let cacheItem = findItemArrayInCache(itemArray: findItemArray, scene: scene) {
            if originSize > 0, imageItem.isOrigin(item: cacheItem),
               originSize > LarkImageService.shared.imageDisplaySetting.messageImageLoad.cache.cacheLoadOriginMax {
                // 如果图片是originKey，并且originKey对应的文件大小，大于setting配置的值，那么不使用originKey
            } else {
                return cacheItem
            }
        }
        return nil
    }

    /// 在大图查看器内的加载策略：
    /// 如果目标是展示原图
    /// target：
    ///     1. origin
    /// placeholder：
    ///     1. middle
    ///     2. thumb
    /// 如果目标是展示非原图
    /// target:
    ///     1. origin
    ///     2. middle
    /// placeholder
    ///     1. thumb
    ///
    /// 如果target命中缓存，则不用网络，不用再找placeholder。
    /// 如果placeholder命中缓存，则需要网络请求
    public static func largeImage(imageItem: ImageItemSet, scene: ImageDisplayScene, forceOrigin: Bool) -> ImageDisplayDataProvider? {
        guard LarkImageService.shared.imageDisplaySetting.largeImageLoad.cache.cacheEnable else {
            return nil
        }
        // 找缓存的降级Item
        var imageDisplayItemArray: [ImageDisplayItem]
        var placeholderItemArray: [ImageDisplayItem]
        // 最终要展示的Item
        var finalDisplayItem: ImageItem
        // 目标是展示原图
        if forceOrigin {
            imageDisplayItemArray = [ImageDisplayItem(item: imageItem.origin ?? ImageItem(), type: .origin)]
            placeholderItemArray = [ImageDisplayItem(item: imageItem.middle ?? ImageItem(), type: .middle),
                                    ImageDisplayItem(item: imageItem.thumbnail ?? ImageItem(), type: .thumb)]
            finalDisplayItem = imageItem.origin ?? ImageItem()
        } else {
            // 目标是展示非原图，从setting取兜底图的key
            imageDisplayItemArray = [ImageDisplayItem(item: imageItem.origin ?? ImageItem(), type: .origin),
                                     ImageDisplayItem(item: imageItem.middle ?? ImageItem(), type: .middle)]
            if let settingItem = transStringToItem(
                imageItemSet: imageItem, str: LarkImageService.shared.imageDisplaySetting.largeImageLoad.remote.remoteDefaultTarget) {
                imageDisplayItemArray.append(settingItem)
            }
            placeholderItemArray = [ImageDisplayItem(item: imageItem.thumbnail ?? ImageItem(), type: .thumb)]
            finalDisplayItem = imageItem.middle ?? ImageItem()
        }
        // 如果从缓存中取到key，placeholder清空，最终展示的key为缓存key
        if let targetItem = ImageDisplayStrategy.findItemArrayInCache(itemArray: imageDisplayItemArray, scene: .lookLargeImage) {
            finalDisplayItem = targetItem
            placeholderItemArray = []
        }
        let placeholder: () -> UIImage? = {
            if let item = findItemArrayInCache(itemArray: placeholderItemArray, scene: .lookLargeImage),
               let key = item.key {
                return LarkImageService.shared.image(with: .default(key: key), cacheOptions: .all)
            }
            return nil
        }
        return ImageDisplayDataProviderImpl(imageKeyResource: finalDisplayItem.imageResource(),
                                            imagePlaceholder: placeholder)
    }

    /// - Parameters:
    /// - keyArray: 查找缓存的降级数组
    /// - scene: 降级查找缓存的场景，用来埋点
    /// - Note: 外部降级查找缓存，统一使用接口。会帮助上报埋点
    static func findItemArrayInCache(itemArray: [ImageDisplayItem], scene: ImageDisplayScene) -> ImageItem? {
        let trackerKey = startTracker()
        var newItemArray: [ImageDisplayItem] = []
        // 去重,keyArray最多就三个key，origin、middle、thumb，所以此处简单去重就行
        for item in itemArray {
            if let key = item.item.key, !key.isEmpty, !newItemArray.contains(where: { $0.item.key == key }) {
                newItemArray.append(item)
            }
        }
        for item in newItemArray {
            if let key = item.item.key, findKeyInCache(key: key) {
                let params = ImageDisplayTrackerParams(scene: scene, hasCache: true, cacheLevel: item.type.rawValue)
                endTracker(key: trackerKey, params: params)
                return item.item
            }
        }
        let params = ImageDisplayTrackerParams(scene: scene, hasCache: false, cacheLevel: nil)
        endTracker(key: trackerKey, params: params)
        return nil
    }

    private static func findKeyInCache(key: String) -> Bool {
        if key.isEmpty { return false }
        // 在内存缓存中找key
        if LarkImageService.shared.isCached(resource: .default(key: key), options: .memory) {
            ImageDisplayStrategy.logger.info("found key from memory \(key)")
            return true
        }

        // 在磁盘缓存中找key
        if LarkImageService.shared.isCached(resource: .default(key: key), options: .disk) {
            ImageDisplayStrategy.logger.info("found key from disk \(key)")
            return true
        }
        return false
    }

    private static func startTracker() -> String {
        let uuid = UUID().uuidString
        ImageDisplayStrategy.infoMap[uuid] = CACurrentMediaTime()
        return uuid
    }

    private static func endTracker(key: String, params: ImageDisplayTrackerParams) {
        guard let start = ImageDisplayStrategy.infoMap[key] else {
            return
        }
        let cost = CACurrentMediaTime() - start
        let extra: [String: Any] = [
            "scene": params.scene.rawValue,
            "has_cache": params.hasCache == true ? 1 : 0,
            "cache_level": params.cacheLevel ?? "",
            "find_cache_cost_time": cost * 1000
        ]
        let event = TeaEvent("load_image_cache_dev", params: extra, md5AllowList: [], bizSceneModels: [])
        Tracker.post(event)
        ImageDisplayStrategy.infoMap[key] = nil
    }
}
