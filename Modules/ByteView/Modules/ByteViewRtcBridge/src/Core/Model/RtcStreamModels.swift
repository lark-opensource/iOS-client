//
//  RtcStreamModels.swift
//  ByteView
//
//  Created by kiri on 2022/9/21.
//

import Foundation

public struct RtcUID: Hashable {
    public private(set) var id: String
    public init(_ id: String) {
        self.id = id
    }
}

public struct RtcStreamKey: Hashable, CustomStringConvertible {
    public let uid: RtcUID
    public let isScreen: Bool
    public let isLocal: Bool
    public let sessionId: String
    public var description: String {
        if isLocal {
            return "local"
        } else if isScreen {
            return "screen: \(uid), session: \(sessionId)"
        } else {
            return "stream: \(uid), session: \(sessionId)"
        }
    }

    private init(uid: RtcUID, isScreen: Bool, isLocal: Bool, sessionId: String) {
        self.uid = uid
        self.isScreen = isScreen
        self.isLocal = isLocal
        self.sessionId = sessionId
    }

    public static let local = RtcStreamKey(uid: RtcUID(""), isScreen: false, isLocal: true, sessionId: "")

    public static func stream(uid: RtcUID, sessionId: String) -> RtcStreamKey {
        RtcStreamKey(uid: uid, isScreen: false, isLocal: false, sessionId: sessionId)
    }

    public static func screen(uid: RtcUID, sessionId: String) -> RtcStreamKey {
        RtcStreamKey(uid: uid, isScreen: true, isLocal: false, sessionId: sessionId)
    }
}

public struct StreamStatus: CustomStringConvertible {
    public var streamKey: RtcStreamKey
    public var streamID: String?
    public var hasRenderer: Bool
    public var streamAdded: Bool
    public var muted: Bool
    public var lastSDKCall: String?

    public var isOK: Bool {
        hasRenderer && streamAdded && !muted
    }

    public var description: String {
        "StreamStatus(\(self.streamKey), id:\(streamID ?? "<nil>"), hasRenderer:\(hasRenderer), streamAdded:\(streamAdded), muted:\(muted), lastSDKCall:\(lastSDKCall ?? "<nil>"))"
    }
}

public struct RtcVideoStreamInfo {
    public let hasScreenShare: Bool
    public let hasSubscribeCameraStream: Bool
}

public enum ByteViewRenderMode {
    case renderModeFit
    case renderModeHidden
    case renderModeAuto

    // - 1:1 视频流使用 aspectFit
    // - 其它视频流 aspectFill
    case renderModeFit1x1

    // - 16:9 视频流使用 aspectFill
    // - 其它视频流 aspectFit
    case renderModeFill16x9

    // Pad 宫格视图远端视频流裁剪规则
    // https://bytedance.feishu.cn/docx/doxcnkL5Kt6OP0UNL26fyi5nvoc
    case renderModePadGallery

    // Pad 悬浮窗视图视频流裁剪规则
    // - 本地视频流 aspectFit
    // - 远端视频流 竖屏 强制裁剪 1:1
    // - 远端视频流 横屏 auto
    case renderModePadPortraitFloating
}

public struct MultiResSubscribeConfig: Equatable {
    public enum Priority: Equatable {
        case high
        case medium
        case low
    }
    public var normal: MultiResSubscribeResolution
    public var priority: Priority
    public var sipOrRoom: MultiResSubscribeResolution?
    public var sipOrRoomPriority: Priority?
    public var respectViewSize: Bool
    public var viewSizeScale: Float
    #if DEBUG
    public var isValid = true
    #else
    public var isValid: Bool { true }
    #endif
    public static let invalidDefault: MultiResSubscribeConfig = {
        // nolint-next-line: magic number
        let res = MultiResSubscribeResolution(res: 480, fps: 15, goodRes: 480, goodFps: 15, badRes: 480, badFps: 15)
        var ret = MultiResSubscribeConfig(normal: res, priority: .low, viewSizeScale: 1.0)
        #if DEBUG
        // 宫格 Layout 需要明确定义订阅配置
        ret.isValid = false
        #endif
        return ret
    }()

    // nolint-next-line: long parameters
    public init(normal: MultiResSubscribeResolution, priority: Priority, sipOrRoom: MultiResSubscribeResolution? = nil, sipOrRoomPriority: Priority? = nil, viewSizeScale: Float = 0) {
        self.normal = normal
        self.priority = priority
        self.viewSizeScale = viewSizeScale
        self.respectViewSize = viewSizeScale > 0
        self.sipOrRoom = sipOrRoom
        self.sipOrRoomPriority = sipOrRoomPriority
    }
}

public struct MultiResSubscribeResolution: Equatable {
    public var res: Int
    public var fps: Int
    public var goodRes: Int
    public var goodFps: Int
    public var badRes: Int
    public var badFps: Int

    // nolint-next-line: long parameters
    public init(res: Int, fps: Int, goodRes: Int, goodFps: Int, badRes: Int, badFps: Int) {
        self.res = res
        self.fps = fps
        self.goodRes = goodRes
        self.goodFps = goodFps
        self.badRes = badRes
        self.badFps = badFps
    }
}

extension MultiResSubscribeResolution: CustomStringConvertible {
    public var description: String {
        "\(self.res)@\(self.fps), good: \(self.goodRes)@\(self.goodFps), bad: \(self.badRes)@\(self.badFps)"
    }
}

enum VideoStreamForceCrop1x1Mode {
    /// 不执行 1x1 裁剪
    case none
    /// 对高度大于宽度的视频流，执行 1x1 裁剪
    case cropHeight
    /// 始终执行 1x1 裁剪
    case alwaysCrop
}
