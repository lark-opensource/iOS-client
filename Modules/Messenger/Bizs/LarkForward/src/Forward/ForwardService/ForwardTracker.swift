//
//  ForwardTracker.swift
//  LarkForward
//
//  Created by xiongmin on 2021/8/10.
//

import UIKit
import Foundation
import LarkSDKInterface
import AppReciableSDK
import ThreadSafeDataStructure
import ByteWebImage

public struct TrackImageInfo {
    var imageType: ImageSourceResult.SourceType = .unknown
    var colorSpaceName: String?
    var isOrigin: Bool = false
    var fallToFile: Bool = false
    var contentLength: Int = 0
    var resourceWidth: CGFloat = 0
    var resourceHeight: CGFloat = 0
    var uploadLength: Int = 0
    var uploadWidth: CGFloat = 0
    var uploadHeight: CGFloat = 0

    public init() { }
}

public final class ForwardTracker {

    static var infoMap: SafeDictionary<String, DisposedKey> = [:] + .readWriteLock

    static func startTrack(_ key: String, scene: Scene) {
        guard !key.isEmpty else { return }
        let disposeKey = AppReciableSDK.shared.start(biz: .Messenger, scene: scene, event: .messageSend, page: nil)
        infoMap[key] = disposeKey
    }

    static func end(_ key: String, info: TrackImageInfo) {
        guard !key.isEmpty, let disposeKey = infoMap[key] else { return }
        let category: [String: Any] = [
            "image_type": info.imageType.description,
            "chat_type": 0,
            "color_space": info.colorSpaceName ?? "unkown",
            "is_image_fallback_to_file": info.fallToFile,
            "is_image_origin": info.isOrigin
        ]
        let metric: [String: Any] = [
            "resource_content_length": info.contentLength,
            "resource_width": info.resourceWidth,
            "resource_height": info.resourceHeight,
            "upload_content_length": info.uploadLength,
            "upload_width": info.uploadWidth,
            "upload_height": info.uploadHeight
        ]
        let extra = Extra(isNeedNet: true,
                          latencyDetail: nil,
                          metric: metric,
                          category: category,
                          extra: nil)
        AppReciableSDK.shared.end(key: disposeKey, extra: extra)
        infoMap[key] = nil
    }

    static func failed(_ key: String, error: Error?) {
        guard !key.isEmpty else { return }
        let errorParams = ErrorParams(biz: .Messenger,
                                      scene: .Forward,
                                      errorType: .Other,
                                      errorLevel: .Exception,
                                      userAction: nil,
                                      page: nil,
                                      errorMessage: error?.localizedDescription)
        AppReciableSDK.shared.error(params: errorParams)
        infoMap[key] = nil
    }

}
