//
//  Monitor.swift
//  LarkAssetsBrowser
//
//  Created by xiongmin on 2021/4/27.
//

import Foundation
import AppReciableSDK
import ByteWebImage
import ThreadSafeDataStructure

enum FromType: Int {
    case unkown = 0
    case message = 1
    case avatar = 2
}

/// 临时兼容 setImageBlock 需要传递埋点信息的结构体
/// 祝愿早日干掉 setImageBlock 🙏
public struct CompletionInfo {
    public var imageKey: String
    public var loadType: ImageResultFrom
    public init(imageKey: String, loadType: ImageResultFrom) {
        self.imageKey = imageKey
        self.loadType = loadType
    }
}

struct Metric {
    var imageKey: String
    var contentLength: Int //  资源占用字节
    var resourceWidth: Float
    var resourceHeight: Float
    var resourceFrames: Int
    var sdkCost: [String: UInt64]
}

struct Category {
    var isOrigin: Bool
    var imageType: String
    var fromType: Int
    var colorSpace: String
    var loadType: Int
    var isTiled: Bool
}

final class MoniterInfoItem {
    var extra: Extra
    var key: String
    var startTime: TimeInterval = 0
    var thumbStartTime: TimeInterval = 0
    var downloadStartTime: TimeInterval = 0
    var decodeStartTime: TimeInterval = 0
    init(with key: String, extra: Extra) {
        self.key = key
        self.extra = extra
    }
}

final class Monitor: NSObject {

    static let shared = Monitor()

    var infoMap = [String: MoniterInfoItem]() + .readWriteLock

    var keyMap = [String: DisposedKey]() + .readWriteLock

    private var queue = DispatchQueue(label: "com.lark.asset.monitor")

    override init() {
        super.init()
    }

    /// 记录起始时间数据
    /// - Parameters:
    ///   - key: 图片资源的Key
    ///   - biz: 来源业务
    ///   - scene: 来源场景
    func start(with key: String, biz: Biz? = nil, scene: Scene? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let extra = Extra()
            let info = MoniterInfoItem(with: key, extra: extra)
            let stamp = Date().timeIntervalSince1970
            info.startTime = stamp
            info.extra = extra
            self.infoMap[key] = info
            let disposeKey = AppReciableSDK.shared.start(
                biz: biz ?? .Core,
                scene: scene ?? .ImageViewer,
                event: .openImageViewer,
                page: nil,
                extra: extra
            )
            self.keyMap[key] = disposeKey
        }
    }

    func thumStart(with key: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            info.thumbStartTime = Date().timeIntervalSince1970
        }
    }

    func thumbEnd(with key: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            if info.extra.latencyDetail == nil {
                info.extra.latencyDetail = [:]
            }
            info.extra.latencyDetail?["view_thumb_cost"] =
                Int((Date().timeIntervalSince1970 - info.thumbStartTime) * 1_000)
        }
    }

    func downloadStart(with key: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            info.downloadStartTime = Date().timeIntervalSince1970
        }
    }

    func downloadEnd(with key: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            if info.extra.latencyDetail == nil {
                info.extra.latencyDetail = [:]
            }
            info.extra.latencyDetail?["loader_origin_cost"] =
                Int((Date().timeIntervalSince1970 - info.downloadStartTime) * 1_000)
        }
    }

    func decodeStart(with key: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            info.decodeStartTime = Date().timeIntervalSince1970
        }
    }

    func decodeEnd(with key: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            if info.extra.latencyDetail == nil {
                info.extra.latencyDetail = [:]
            }
            info.extra.latencyDetail?["decode_cost"] =
                Int((Date().timeIntervalSince1970 - info.decodeStartTime) * 1_000)
        }
    }

    func finish(with key: String, metric: Metric, category: Category) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            info.extra.metric = [
                "image_key": metric.imageKey,
                "resource_content_length": metric.contentLength,
                "resource_width": metric.resourceWidth,
                "resource_height": metric.resourceHeight,
                "resource_frames": metric.resourceFrames
            ]
            info.extra.category = [
                "from_type": category.fromType,
                "load_type": category.loadType,
                "image_type": category.imageType,
                "color_space": category.colorSpace,
                "media_is_origin_type": category.isOrigin.stringValue,
                "is_tiled": category.isTiled.stringValue
            ]
            if info.extra.latencyDetail == nil, !metric.sdkCost.isEmpty {
                info.extra.latencyDetail = [:]
            }
            metric.sdkCost.forEach { key, value in
                info.extra.latencyDetail?[key] = value
            }
            if let disposeKey = self.keyMap[key] {
                AppReciableSDK.shared.end(key: disposeKey, extra: info.extra)
                self.keyMap.removeValue(forKey: key)
            }
            self.infoMap.removeValue(forKey: key)
        }
    }

    func error(with key: String, code: ByteWebImageErrorCode, status: Int, message: String) {
        queue.async { [weak self] in
            guard let self = self, let info = self.infoMap[key] else {
                return
            }
            if let _ = self.keyMap[key] {
                let params = ErrorParams(biz: .Core,
                                         scene: .ImageViewer,
                                         event: .openImageViewer,
                                         errorType: .Unknown,
                                         errorLevel: .Exception,
                                         errorCode: code,
                                         errorStatus: status,
                                         userAction: nil,
                                         page: nil,
                                         errorMessage: message,
                                         extra: info.extra)
                AppReciableSDK.shared.error(params: params)
                self.keyMap.removeValue(forKey: key)
            }
            self.infoMap.removeValue(forKey: key)
        }
    }
}
