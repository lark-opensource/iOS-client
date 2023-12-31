//
//  ScreenSharedData.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/24.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_InMeetingData.ScreenSharedData
public struct ScreenSharedData: Equatable {
    public init(isSharing: Bool,
                participantID: String,
                participantType: ParticipantType,
                participantDeviceID: String,
                width: Int32,
                height: Int32,
                shareScreenID: String,
                isSketch: Bool,
                canSketch: Bool,
                version: Int32,
                accessibility: Bool,
                isSmoothMode: Bool,
                isPortraitMode: Bool,
                sketchTransferMode: SketchTransferMode,
                sketchFitMode: SketchFitMode,
                sharerTenantWatermarkOpen: Bool,
                enableCursorShare: Bool,
                ccmInfo: CCMInfo?,
                isSharingPause: Bool) {
        self.isSharing = isSharing
        self.participant = ByteviewUser(id: participantID, type: participantType, deviceId: participantDeviceID)
        self.width = width
        self.height = height
        self.shareScreenID = shareScreenID
        self.isSketch = isSketch
        self.canSketch = canSketch
        self.version = version
        self.accessibility = accessibility
        self.isSmoothMode = isSmoothMode
        self.isPortraitMode = isPortraitMode
        self.sketchTransferMode = sketchTransferMode
        self.sketchFitMode = sketchFitMode
        self.sharerTenantWatermarkOpen = sharerTenantWatermarkOpen
        self.enableCursorShare = enableCursorShare
        self.ccmInfo = ccmInfo
        self.isSharingPause = isSharingPause
    }

    public init() {
        self.init(isSharing: false,
                  participantID: "",
                  participantType: .unknown,
                  participantDeviceID: "",
                  width: 0,
                  height: 0,
                  shareScreenID: "",
                  isSketch: false,
                  canSketch: false,
                  version: 0,
                  accessibility: false,
                  isSmoothMode: false,
                  isPortraitMode: false,
                  sketchTransferMode: .byData,
                  sketchFitMode: .sketchCubicFitting,
                  sharerTenantWatermarkOpen: false,
                  enableCursorShare: false,
                  ccmInfo: nil,
                  isSharingPause: false)
    }

    /// 有人正在共享屏幕
    public var isSharing: Bool

    /// 分享人
    public var participant: ByteviewUser

    public var width: Int32

    public var height: Int32

    /// 用于标识一个共享屏幕
    public var shareScreenID: String

    /// 标识是否在开启标注
    public var isSketch: Bool

    /// 主共享人版本旧或FG 没有宽高数据的时候是false
    public var canSketch: Bool

    /// 会议维度从0开始递增
    public var version: Int32

    /// 是否有辅助功能权限
    public var accessibility: Bool

    /// 代表是否为流畅模式
    public var isSmoothMode: Bool

    /// 共享屏幕时是否打开人像叠加
    public var isPortraitMode: Bool

    /// 标注传输模式, default = byData
    public var sketchTransferMode: SketchTransferMode

    public var sketchFitMode: SketchFitMode

    /// 标注的传输模式
    public enum SketchTransferMode: Int, Hashable {

        /// 通过数据包传输
        case byData // = 0

        /// 通过视频流传输
        case byVideo // = 1
    }

    public enum SketchFitMode: Int, Hashable {
        /// 三阶拟合，默认
        case sketchCubicFitting // = 0

        /// 二阶拟合，新方案走这个
        case sketchQuadraticFitting // = 1
    }

    /// 主共享人租户是否开启水印
    public var sharerTenantWatermarkOpen: Bool

    /// 是否开启鼠标单独传输
    public var enableCursorShare: Bool

    /// 投屏转妙享信息
    public var ccmInfo: CCMInfo?

    /// 是否暂停共享
    public var isSharingPause: Bool

    public func shouldShowWatermark(selfTenantID: String, sharerTenantID: String?) -> Bool {
        sharerTenantID != nil && selfTenantID != sharerTenantID && sharerTenantWatermarkOpen
    }
}

extension ScreenSharedData: CustomStringConvertible {

    public var description: String {
        String(indent: "ScreenSharedData",
               "shareScreenID:\(shareScreenID)",
               "width:\(width)",
               "height:\(height)",
               "isSketch:\(isSketch)",
               "canSketch:\(canSketch)",
               "isSharing:\(isSharing)",
               "isSmoothMode:\(isSmoothMode)",
               "sketchFitMode:\(sketchFitMode)",
               "accessibility:\(accessibility)",
               "isPortraitMode:\(isPortraitMode)",
               "sketchTransferMode:\(sketchTransferMode)",
               "sharerTenantWatermarkOpen:\(sharerTenantWatermarkOpen)",
               "enableCursorShare:\(enableCursorShare)",
               "ccmInfo: \(ccmInfo)",
               "isSharingPause: \(isSharingPause)"
        )
    }
}

/// Videoconference_V1_InMeetingData.ScreenSharedData.CCMInfo
public struct CCMInfo: Equatable, CustomStringConvertible {
    public init(status: CCMInfoStatus,
                url: String,
                token: String,
                type: FollowShareSubType,
                title: String,
                memberID: String,
                isAllowFollowerOpenCcm: Bool,
                extraInfo: FollowInfo.ExtraInfo,
                rawURL: String,
                strategies: [FollowStrategy],
                hasSharePermission_p: Bool,
                thumbnail: FollowInfo.ThumbnailDetail) {
        self.status = status
        self.url = url
        self.token = token
        self.type = type
        self.title = title
        self.memberID = memberID
        self.isAllowFollowerOpenCcm = isAllowFollowerOpenCcm
        self.extraInfo = extraInfo
        self.rawURL = rawURL
        self.strategies = strategies
        self.hasSharePermission_p = hasSharePermission_p
        self.thumbnail = thumbnail
    }

    public init() {
        self.init(status: .invalid,
                  url: "",
                  token: "",
                  type: .ccmDoc,
                  title: "",
                  memberID: "",
                  isAllowFollowerOpenCcm: false,
                  extraInfo: FollowInfo.ExtraInfo(sharerTenantWatermarkOpen: false,
                                                  docTenantWatermarkOpen: false,
                                                  actionUniqueID: "",
                                                  docTenantID: ""),
                  rawURL: "",
                  strategies: [],
                  hasSharePermission_p: false,
                  thumbnail: FollowInfo.ThumbnailDetail(thumbnailURL: "",
                                                        decryptKey: "",
                                                        cipherType: .aes256Gcm,
                                                        nonce: ""))
    }

    /// 暗水印校验状态
    public var status: CCMInfoStatus

    /// ccm url链接
    public var url: String

    /// ccm 文档token
    public var token: String

    /// ccm 文件类型
    public var type: FollowShareSubType

    /// ccm 文件标题
    public var title: String

    /// 需要回传给前端的ccm member id
    public var memberID: String

    /// 文档是否允许自由浏览
    public var isAllowFollowerOpenCcm: Bool

    /// 8/9/10为客户端兼容magicshare需要的字段
    public var extraInfo: FollowInfo.ExtraInfo

    public var rawURL: String

    public var strategies: [FollowStrategy] = []

    /// presenter是否有该CCMInfo的share权限
    public var hasSharePermission_p: Bool

    public var thumbnail: FollowInfo.ThumbnailDetail

    public var description: String {
        return """
        status: \(status.rawValue),
        url: \(url.hashValue),
        token: \(token.hashValue),
        type: \(type),
        title: \(title.hashValue),
        memberID: \(memberID),
        isAllowFollowerOpenCcm: \(isAllowFollowerOpenCcm),
        extraInfo: \(extraInfo),
        rawURL: \(rawURL.hashValue),
        strategies: \(strategies.count),
        hasSharePermission_p: \(hasSharePermission_p),
        thumbnail: \(thumbnail)
        """
    }
}

/// 文档水印识别状态标识
public enum CCMInfoStatus: Int, Hashable {
  /// 暗水印校验中
  case validating // = 0
  /// 已经过校验
  case validated // = 1
  /// 校验失败
  case invalid // = 2
}
