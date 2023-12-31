//
//  WhiteboardInfo.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/3/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBWhiteboardSettings = Videoconference_V1_WhiteboardSettings
typealias PBWhiteboardCanvasSize = Videoconference_V1_WhiteboardCanvasSize

public struct WhiteboardInfo: Equatable {

    /// 白板唯一id，一个会议生命周期内只存在一个白板。
    public let whiteboardID: Int64

    /// 白板共享发起人
    public let sharer: ByteviewUser

    /// 白板相关的设置
    public let whiteboardSettings: WhiteboardSettings

    /// 白板页
    public let pages: [WhiteboardPage]

    /// 会议是否正在共享白板
    public let whiteboardIsSharing: Bool

    /// 用来给客户端解决新旧数据冲突
    public var version: Int32

    /// 后续一些与主业务逻辑无关的参数统一放在这里
    public var extraInfo: ExtraInfo

    public struct ExtraInfo: Equatable {
        /// 共享人是否开启水印（从水印服务直接获取，来自用户配置或继承租户配置）
        public var sharerWatermarkOpen: Bool
    }

    public func shouldShowWatermark(selfTenantID: String, sharerTenantID: String?) -> Bool {
        sharerTenantID != nil && selfTenantID != sharerTenantID && extraInfo.sharerWatermarkOpen
    }
}

public struct WhiteboardSettings: Equatable {

    public enum ShareMode: Int, Hashable {
      case presentation
      case collaboration
    }

    public let shareMode: ShareMode

    public let canvasSize: CGSize

    public init(shareMode: ShareMode, canvasSize: CGSize) {
        self.shareMode = shareMode
        self.canvasSize = canvasSize
    }
}

extension WhiteboardSettings {
    var pbType: PBWhiteboardSettings {
        var setting = PBWhiteboardSettings()
        var pbCanvasSize = PBWhiteboardCanvasSize()
        pbCanvasSize.height = Int32(canvasSize.height)
        pbCanvasSize.width = Int32(canvasSize.width)
        setting.canvasSize = pbCanvasSize
        setting.shareMode = PBWhiteboardSettings.ShareMode(rawValue: shareMode.rawValue) ?? .collaborationMode
        return setting
    }
}

extension WhiteboardSettings.ShareMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .presentation:
            return "presentation"
        case .collaboration:
            return "collaboration"
        }
    }
}

extension WhiteboardSettings: CustomStringConvertible {
    public var description: String {
        "WhiteboardSettings(shareMode: \(shareMode), canvasSize: \(canvasSize.width)x\(canvasSize.height))"
    }
}

extension WhiteboardInfo: CustomStringConvertible {

    public var description: String {
        String(indent: "WhiteboardInfo",
               "whiteboardID: \(whiteboardID)",
               "sharer: \(sharer)",
               "pages: \(pages)",
               "whiteboardIsSharing: \(whiteboardIsSharing)",
               "version: \(version)",
               "whiteboardSettings: \(whiteboardSettings)",
               "sharerWatermarkOpen: \(extraInfo.sharerWatermarkOpen)"
        )
    }
}
