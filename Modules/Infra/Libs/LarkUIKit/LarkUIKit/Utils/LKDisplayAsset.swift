//
//  LKDisplayAsset.swift
//  LarkUIKit
//
//  Created by Yuguo on 2017/4/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    var imageFormat: ImageFormat {
        var headerData = [UInt8](repeating: 0, count: 3)
        self.copyBytes(to: &headerData, from: (0..<3))
        let hexString = headerData.reduce("") { $0 + String(($1 & 0xFF), radix: 16) }.uppercased()
        var imageFormat = ImageFormat.unknown
        switch hexString {
        case "FFD8FF":
            imageFormat = .jpg
        case "89504E":
            imageFormat = .png
        case "474946":
            imageFormat = .gif
        default: break
        }
        return imageFormat
    }

    enum ImageFormat {
        case jpg, png, gif, unknown
    }
}

/// 与DisplayAsset一一绑定的翻译属性
/// origin: 原asset
/// translated: 是别的原asset的翻译态asset
public enum DisplayAssetTranslationProperty: String {
    case origin
    case translated
}

// 权限管控下，资源类消息展示状态
public enum PermissionDisplayState {
    case allow // 权限都允许
    case previewDeny // 预览权限不允许
    case receiveDeny // 接收权限不允许
    case receiveLoading // 接收权限结果未返回（接收权限是异步的）

    // 接收权限拒绝或者结果没有返回。这些都属于不能接收
    public var canNotReceive: Bool {
        return self == .receiveLoading || self == .receiveDeny
    }

    // 预览拒绝
    public var canNotPreview: Bool {
        return self == .previewDeny
    }

    // 允许
    public var isAllow: Bool {
        return self == .allow
    }
}

public final class LKDisplayAsset {

    public var visibleThumbnail: UIImageView?
    public var originalData: Data?
    public var originalUrl: String = ""
    public var translateProperty: DisplayAssetTranslationProperty = .origin
    public var extraInfo: [String: Any] = [:]
    // 当图片被展示的时候，此字段会被透传到image_load埋点的extra参数上
    public var trackExtraInfo: [String: Any] = [:]
    /// 是否检测可翻译
    public var detectCanTranslate: Bool = true
    /// 是否有预览权限 permissionState
    public var permissionState: PermissionDisplayState = .allow

    /// 原始图片key
    public var originalImageKey: String?
    /// 原始数据intact的Key
    public var intactImageKey: String?
    /// 原始图片的大小，当以原图发送的时候会有此值
    public var originalImageSize: UInt64 = 0
    /// 是否自动加载原图
    public var isAutoLoadOriginalImage: Bool = false
    public var forceLoadOrigin: Bool = false
    public var fsUnit: String = ""
    public var duration: Int32 = 0

    private var _key: String = ""
    public var key: String {
        set {
            _key = newValue
        }
        get {
            if !_key.isEmpty {
                return _key
            }

            if !originalUrl.isEmpty {
                if let key = originalUrl.components(separatedBy: "/").last {
                    return key
                }
            }

            if !videoCoverUrl.isEmpty {
                return videoCoverUrl
            }

            return ""
        }
    }

    /// 兜底展示图片
    public var placeHolder: UIImage?

    public init() {}

    // Video related stuffs
    public private(set) var videoUrl: String = ""
    public private(set) var videoCoverUrl: String = ""
    public private(set) var videoSize: Float = 0 // 以 MB 为单位
    public private(set) var isVideo = false
    public var isLocalVideoUrl = false
    public var isVideoMuted = false
    public var isVideoValid = true

    public class func initWith(videoUrl: String,
                               videoCoverUrl: String,
                               videoSize: Float) -> LKDisplayAsset {
        let asset = LKDisplayAsset()
        asset.videoUrl = videoUrl
        asset.videoCoverUrl = videoCoverUrl
        asset.videoSize = videoSize
        asset.isVideo = true
        return asset
    }

    // SVG related stuffs
    public var isSVG = false
    public var svgData: String?

    public func isGIf() -> Bool {
        if self.originalData?.imageFormat == .gif {
            return true
        }
        return false
    }
    /// 图片裁剪范围 
    public var crop: [CGFloat]?
    public var isGif: Bool?
}
