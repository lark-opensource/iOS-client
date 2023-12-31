//
//  RtcSdkModels.swift
//  ByteView
//
//  Created by kiri on 2022/8/15.
//

import Foundation

/// 屏幕采集媒体类型
/// - ByteRTCScreenMediaType
public enum RtcScreenMediaType {
    /// 只采集视频数据
    case videoOnly
    /// 只采集音频数据
    case audioOnly
    /// 音视频数据都采集
    case videoAndAudio
}

/// ByteRtcMeetingChannelProfileType
public enum RtcMeetingChannelProfileType {
    case vc
    case share1v1
}

/// ByteRtcVendorType
public enum RtcVendorType: Int, Hashable {
    case unknown
    case rtc
    case larkRtc
    case larkPreRtc
    case test
    case testPre
    case testGauss
}

/// 用户角色。房间模式为直播、游戏、云游戏模式时的可选用户角色。
///
/// - ByteRtcClientRole
///
/// 用户可通过设置用户角色控制：
/// 1. 发布/取消发布音视频流；
/// 2. 用户自身是否在房间中隐身。
///
/// 设置用户角色参考 setClientRole:方法。
public enum RtcClientRole {
    /// 主播角色。主播角色的用户既可以发布流到房间中，也可以从房间中订阅流，房间中的其他用户可以感知到该用户在房间中。
    case broadcaster
    /// 静默观众角色。静默观众角色的用户只能从房间中订阅流，不能向房间中发布流，房间中的其他用户无法感知到该用户在房间中。该用户加入退出房间等行为不会通知给房间中的其他用户。
    case audience
}

/// 视频参数
/// - ByteRTCVideoEncoderConfig
public struct RtcVideoEncoderConfig: CustomDebugStringConvertible {
    /// 视频宽度，单位：px
    public let width: Int
    /// 视频高度，单位：px
    public let height: Int
    /// 视频帧率，单位：fps
    public let frameRate: Int
    /// 最大编码码率，使用 SDK 内部采集时可选设置，自定义采集时必须设置，单位：kbps。
    /// - 内部采集模式下默认值为 -1，即适配码率模式，系统将根据输入的分辨率和帧率自动计算适用的码率。
    /// - 设为 0 则不对视频流进行编码发送。
    public let maxBitrate: Int

    public init(width: Int, height: Int, frameRate: Int, maxBitrate: Int) {
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.maxBitrate = maxBitrate
    }

    public var debugDescription: String {
        "\(width)x\(height)x\(frameRate)x\(maxBitrate)"
    }

    public static var screenEncoderConfig: RtcVideoEncoderConfig {
        RtcVideoEncoderConfig(width: 0, height: 0, frameRate: 15, maxBitrate: 1666)
    }

    public static var screenP2PEncoderConfig: RtcVideoEncoderConfig {
        RtcVideoEncoderConfig(width: 0, height: 0, frameRate: 24, maxBitrate: 2500)
    }
}

/// 视频流描述
/// - VideoStreamDescription
public struct RtcVideoStreamDescription: Equatable, CustomDebugStringConvertible {
    /// 视频分辨率
    public let videoSize: CGSize
    /// 视频预设帧率
    public let frameRate: Int
    /// 视频预设最大码率(Kbps)
    public let maxKbps: Int
    /// 视频编码质量偏好
    public let encoderPreference: RtcVideoEncoderPreference

    public var debugDescription: String {
        "\(videoSize.width)x\(videoSize.height)x\(frameRate)x\(maxKbps)"
    }
}

/// 编码质量偏好
/// - ByteVideoEncoderPreference
public enum RtcVideoEncoderPreference {
    /// 关闭
    case disabled
    /// 保持帧率
    case maintainFramerate
    /// 保持画质
    case maintainQuality
    /// 平衡模式
    case balance
}

/// ByteRtcPerfAdjustUnitType
public enum RtcPerfAdjustUnitType: Int {
    case videoPubCamera = 1
    case videoPubScreen
    case videoPubScreenCast
    case videoSubCamera
    case videoSubScreen
}

/// ByteRtcPerfAdjustDirection
public enum RtcPerfAdjustDirection: Int {
    case up = 0
    case down = 1
}

public enum RtcManualPerfAdjustResult: Int {
    case completed = 0
    case success
    case unStarted
    case disabled
    case lastUnitUncompleted
    case currentUnitToLimit
    case engineNotReady
}

/// ByteRtcManualPerfAdjustConfig
public struct RtcManualPerfAdjustConfig {
    public let targetTotalCpuRate: Double
}

/// 流属性
/// - ByteRTCStreamIndex
public enum RtcStreamIndex {
    /// 主流。
    ///
    /// 包括：
    /// 1. 由摄像头/麦克风通过内部采集机制，采集到的视频/音频;
    /// 2. 通过自定义采集，采集到的视频/音频。
    case main
    /// 屏幕流。屏幕共享时共享的视频流，或来自声卡的本地播放音频流。
    case screen
}

/// 用户信息
public struct RtcRemoteStreamKey {
    /// 用户 ID
    public let userId: RtcUID?
    /// 房间 ID
    public let roomId: String?
    /// 流属性，包括主流、屏幕流。
    public let streamIndex: RtcStreamIndex
}

/// 按媒体类型设置的蜂窝增强的配置
/// - ByteRTCCellularEnhancementConfig
public struct RtcCellularEnhancementConfig {
    /// 是否启用对音频类型的蜂窝增强功能，设置为true表示启用，否则不启用
    public let enhanceAudio: Bool
    /// 是否启用对视频类型的蜂窝增强功能，设置为true表示启用，否则不启用
    public let enhanceVideo: Bool
    /// 是否启用对屏幕音频类型的蜂窝增强功能，设置为true表示启用，否则不启用
    public let enhanceScreenAudio: Bool
    /// 是否启用对屏幕视频频类型的蜂窝增强功能，设置为true表示启用，否则不启用
    public let enhanceScreenVideo: Bool

    public init(enhanceAudio: Bool, enhanceVideo: Bool, enhanceScreenAudio: Bool, enhanceScreenVideo: Bool) {
        self.enhanceAudio = enhanceAudio
        self.enhanceVideo = enhanceVideo
        self.enhanceScreenAudio = enhanceScreenAudio
        self.enhanceScreenVideo = enhanceScreenVideo
    }
}

public struct RtcNetworkBandwidthEstimation {
    /// 该用户的上行网络估计可用带宽，单位kbps
    public let txEstimateBandwidth: Int
    /// 该用户的上行网络带宽状态
    public let txBandwidthStatus: Status
    /// 该用户的下行网络估计可用带宽，单位kbps
    public let rxEstimateBandwidth: Int
    /// 该用户的下行网络带宽状态
    public let rxBandwidthStatus: Status

    public init(txEstimateBandwidth: Int, txBandwidthStatus: Status, rxEstimateBandwidth: Int, rxBandwidthStatus: Status) {
        self.txEstimateBandwidth = txEstimateBandwidth
        self.txBandwidthStatus = txBandwidthStatus
        self.rxEstimateBandwidth = rxEstimateBandwidth
        self.rxBandwidthStatus = rxBandwidthStatus
    }

    public enum Status: Int, Hashable {
        /// 网络带宽状态未知
        case unknown
        /// 正常带宽状态
        case normal
        /// 低带宽状态
        case low
        /// 极低带宽状态
        case extremeLow
    }
}

public struct RtcSystemUsageInfo {
    public let cpuTotalUsage: Double
    public let cpuAppUsage: Double
    public let memoryTotalUsage: Int64
    public let memoryAppUsage: Int64

    public init(cpuTotalUsage: Double, cpuAppUsage: Double, memoryTotalUsage: Int64, memoryAppUsage: Int64) {
        self.cpuTotalUsage = cpuTotalUsage
        self.cpuAppUsage = cpuAppUsage
        self.memoryTotalUsage = memoryTotalUsage
        self.memoryAppUsage = memoryAppUsage
    }
}

public enum RtcMediaDeviceWarnCode: Int, Hashable {
    /// 当前麦克风采集到声音啸叫
    ///
    /// 多个人在同一个地方，导致啸叫。
    ///
    /// 解决方案：提示用户关闭麦克风，扬声器以减少啸叫
    case howling = -6010
}

/// 音量信息
public struct RtcAudioVolumeInfo {
    /// 音量信息所属用户的用户ID
    public let uid: RtcUID
    /// 用户非线性音量大小信息
    public let nonlinearVolume: Int
    /// 用户线性音量大小信息
    public let linearVolume: Int
}

/// 房间通话统计数据，统计周期为 2s 。
///
/// 用户进房成功后，SDK 会周期性地通过 `onRoomStats` 回调通知用户当前房间内的汇总统计信息。此数据结构即为回调给用户的参数类型。
public struct RtcRoomStats {
    /// 蜂窝路径发送的码率 (kbps)，为获取该数据时的瞬时值
    public let txCellularKbitrate: Int
    /// 蜂窝路径接收码率 (kbps)，为获取该数据时的瞬时值
    public let rxCellularKbitrate: Int
}

/// 视频编码类型
public enum RtcVideoCodecType {
    /// 未知类型
    case unknown
    /// 标准 H264 编码格式
    case h264
    /// ByteVC1 编码器
    case byteVC1
}

/// 媒体流网络质量。
public enum RtcNetworkQuality: Int, Hashable, Comparable, CustomStringConvertible {
    /// 网络质量未知。
    case unknown = 0
    /// 包含两种
    /// - Excellent：网络质量极好。
    /// - Good：主观感觉和 kNetworkQualityExcellent 差不多，但码率可能略低。
    case good = 2
    /// Poor：主观感受有瑕疵但不影响沟通。
    case weak = 3
    /// 包含两种
    /// - Bad：勉强能沟通但不顺畅。
    /// - VeryBad：网络质量非常差，基本不能沟通。
    case bad = 4

    public static func < (lhs: RtcNetworkQuality, rhs: RtcNetworkQuality) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .good:
            return "good"
        case .weak:
            return "normal"
        case .bad:
            return "bad"
        }
    }
}

/// App 使用的 cpu 和 memory 信息
///
/// 信息由 SDK 周期性（2s）地通过 `reportSysStats` 回调事件通知给用户。
public struct RtcSysStats {
    /// 当前应用的 CPU 使用率，取值范围为 [0, 1]。
    public var cpuAppUsage: Double
    /// 当前系统的 CPU 使用率，取值范围为 [0, 1]。
    public var cpuTotalUsage: Double
    /// 当前设备的 CPU 核数量
    public var cpuCoreCount: Int32

    public init(cpuAppUsage: Double, cpuTotalUsage: Double, cpuCoreCount: Int32) {
        self.cpuAppUsage = cpuAppUsage
        self.cpuTotalUsage = cpuTotalUsage
        self.cpuCoreCount = cpuCoreCount
    }
}

/// 本地/远端网络质量
public struct RtcNetworkQualityInfo: CustomStringConvertible {
    /// 网络状况信息所属用户的用户 ID 。
    public let uid: RtcUID
    /// 该用户的上行网络状态。
    public let uplinkQuality: RtcNetworkQuality
    /// 该用户的下行网络状态
    public let downlinkQuality: RtcNetworkQuality
    /// 该用户的上行丢包网络状态
    public let uplinkLossQuality: RtcNetworkQuality?
    /// 该用户的下行丢包网络状态
    public let downlinkLossQuality: RtcNetworkQuality?
    /// 该用户的上行延时网络状态
    public let uplinkRttQuality: RtcNetworkQuality?
    /// 该用户的下行延时网络状态
    public let downlinkRttQuality: RtcNetworkQuality?
    /// 该用户的上行绝对带宽网络状态
    public let uplinkAbsBwQuality: RtcNetworkQuality?
    /// 该用户的下行绝对带宽网络状态
    public let downlinkAbsBwQuality: RtcNetworkQuality?
    /// 该用户的上行相对带宽网络状态
    public let uplinkRelBwQuality: RtcNetworkQuality?
    /// 该用户的下行相对带宽网络状态
    public let downlinkRelBwQuality: RtcNetworkQuality?

    public var description: String {
        var description = "RtcNetworkQualityInfo uid: \(uid), up: \(uplinkQuality), down: \(downlinkQuality)"
        if let uplinkLossQuality = uplinkLossQuality {
            description += ", upLoss: \(uplinkLossQuality)"
        }
        if let downlinkLossQuality = downlinkLossQuality {
            description += ", downLoss: \(downlinkLossQuality)"
        }
        if let uplinkRttQuality = uplinkRttQuality {
            description += ", upRtt: \(uplinkRttQuality)"
        }
        if let downlinkRttQuality = downlinkRttQuality {
            description += ", downRtt: \(downlinkRttQuality)"
        }
        if let uplinkAbsBwQuality = uplinkAbsBwQuality {
            description += ", upAbsBw: \(uplinkAbsBwQuality)"
        }
        if let downlinkAbsBwQuality = downlinkAbsBwQuality {
            description += ", downAbsBw: \(downlinkAbsBwQuality)"
        }
        if let uplinkRelBwQuality = uplinkRelBwQuality {
            description += ", upRelBw: \(uplinkRelBwQuality)"
        }
        if let downlinkRelBwQuality = downlinkRelBwQuality {
            description += ", downRelBw: \(downlinkRelBwQuality)"
        }
        return description
    }

    public var networkQuality: RtcNetworkQuality {
        return max(uplinkQuality, downlinkQuality)
    }

    init(uid: String,
         uplinkQuality: RtcNetworkQuality,
         downlinkQuality: RtcNetworkQuality,
         uplinkLossQuality: RtcNetworkQuality? = nil,
         downlinkLossQuality: RtcNetworkQuality? = nil,
         uplinkRttQuality: RtcNetworkQuality? = nil,
         downlinkRttQuality: RtcNetworkQuality? = nil,
         uplinkAbsBwQuality: RtcNetworkQuality? = nil,
         downlinkAbsBwQuality: RtcNetworkQuality? = nil,
         uplinkRelBwQuality: RtcNetworkQuality? = nil,
         downlinkRelBwQuality: RtcNetworkQuality? = nil) {
        self.uid = RtcUID(uid)
        self.uplinkQuality = uplinkQuality
        self.downlinkQuality = downlinkQuality
        self.uplinkLossQuality = uplinkLossQuality
        self.downlinkLossQuality = downlinkLossQuality
        self.uplinkRttQuality = uplinkRttQuality
        self.downlinkRttQuality = downlinkRttQuality
        self.uplinkAbsBwQuality = uplinkAbsBwQuality
        self.downlinkAbsBwQuality = downlinkAbsBwQuality
        self.uplinkRelBwQuality = uplinkRelBwQuality
        self.downlinkRelBwQuality = downlinkRelBwQuality
    }
}

/// SDK 与信令服务器连接状态。
public enum RtcConnectionState: String, CustomStringConvertible {
    /// value = 1。连接断开，且断开时长超过 12s，SDK 会自动重连。
    case disconnected
    /// value = 2。首次请求建立连接，正在连接中。
    case connecting
    /// value = 3。首次连接成功。
    case connected
    /// value = 4
    ///
    /// 涵盖了以下情况：
    /// - 首次连接时，10秒连接不成功
    /// - 连接成功后，断连 10 秒。自动重连中。
    case reconnecting
    /// value = 5。连接断开后，重连成功。
    case reconnected
    /// value = 6。处于 `disconnected` 状态超过 10 秒，且期间重连未成功。SDK 仍将继续尝试重连。
    case lost
    /// value = 7。连接失败，服务端状态异常。SDK 不会自动重连，请重新进房，或联系技术支持。
    case failed

    public var description: String { rawValue }
}

public enum RtcNetworkType: Int, Hashable, CustomStringConvertible {
    case begin = -3
    case disconnect_leave = -2
    case unknown = -1
    case disconnected
    case lan
    case wifi
    case modile2G
    case modile3G
    case modile4G
    case modile5G

    public var description: String {
        switch self {
        case .begin:
            return "begin"
        case .disconnect_leave:
            return "disconnect_leave"
        case .disconnected:
            return "disconnected"
        case .unknown:
            return "unknown"
        case .lan:
            return "lan"
        case .wifi:
            return "wifi"
        case .modile2G:
            return "2g"
        case .modile3G:
            return "3g"
        case .modile4G:
            return "4g"
        case .modile5G:
            return "5g"
        }
    }
}

public enum RtcError: Equatable, CustomStringConvertible {
    case unknown(Int)

    /// 加入房间错误。
    /// - 调用 joinChannelByKey:channelName:info:uid:{@link #ByteRtcEngineKit#joinChannelByKey:channelName:info:uid:} 方法时发生未知错误导致加入房间失败。需要用户重新加入房间。
    case joinRoomFailed
    /// RTC内部卡死,不调用离会逻辑/
    case overDeadlockNotify
    // disable-lint: magic number
    public var rawValue: Int {
        switch self {
        case .joinRoomFailed:
            return -1001
        case .overDeadlockNotify:
            return -1111
        case .unknown(let code):
            return code
        }
    }
    // enable-lint: magic number
    public var description: String {
        switch self {
        case .unknown(let code):
            return "RtcError(\(code))"
        case .joinRoomFailed:
            return "joinRoomFailed"
        case .overDeadlockNotify:
            return "overDeadlockNotify"
        }
    }
}

public struct VideoSubscribeConfig: Equatable {
    public var res: Int
    public var fps: Int
    public var videoSubBaseLine: RtcSubscribeVideoBaseline?
    public let extraInfo = ExtraInfo()

    public init(res: Int, fps: Int, videoSubBaseLine: RtcSubscribeVideoBaseline? = nil) {
        self.res = res
        self.fps = fps
        self.videoSubBaseLine = videoSubBaseLine
    }

    public final class ExtraInfo: Equatable {
        public static func == (lhs: VideoSubscribeConfig.ExtraInfo, rhs: VideoSubscribeConfig.ExtraInfo) -> Bool {
            true
        }

        // 用于埋点, gallery, share_screen, full_screen, floating_window
        public var layoutType: String?
        // 用于埋点, 对应宫格流样式一屏的宫格数量
        public var viewCount: Int?
        // 用于埋点, 是否为宫格流样式中的小视图
        public var isMini: Bool?
    }
}

/// 订阅流的参数配置。用户手动订阅一路音视频流所使用的订阅配置参数。
/// - 用户关闭自动订阅功能，使用手动订阅模式时，通过调用 subscribeStream:subscribeConfig:{@link #ByteRtcEngineKit#subscribeStream:subscribeConfig:} 方法订阅音视频流，调用时传入的参数即为此数据类型。
public struct RtcSubscribeConfig: Equatable {
    /// 订阅的视频流分辨率下标。
    /// - 用户可以通过调用 setVideoProfiles{@link #ByteRtcEngineKit#setVideoProfiles:} 方法在一路流中发布多个不同分辨率的视频。因此订阅流时，需要指定订阅的具体分辨率。此参数即用于指定需订阅的分辨率的下标，默认值为 0 。
    public var videoIndex: Int = 0
    /// 订阅的视频流帧率。
    public var framerate: Int = 0
    /// 订阅的宽度信息， 默认值为0。
    public var width: Int = 0
    /// 订阅的高度信息， 默认值为0。
    public var height: Int = 0

    public let videoBaseline: RtcSubscribeVideoBaseline?
    public let preferredConfig: VideoSubscribeConfig
    public let streamDescription: RtcVideoStreamDescription?

    init(res: VideoSubscribeConfig, index: Int, streamDescription: RtcVideoStreamDescription?) {
        self.preferredConfig = res
        self.videoBaseline = res.videoSubBaseLine
        self.streamDescription = streamDescription
        if let videoSize = streamDescription?.videoSize, videoSize.width > 0 && videoSize.height > 0 {
            self.width = Int(CGFloat(res.res) * videoSize.width / min(videoSize.width, videoSize.height))
            self.height = Int(CGFloat(res.res) * videoSize.height / min(videoSize.width, videoSize.height))
            if res.fps > 0 { self.framerate = res.fps }
        } else {
            self.videoIndex = index
        }
    }
}

/// 5.18版本后，飞书会议弱网提示专用，设置订阅视频基线数据用于计算网络等级
public struct RtcSubscribeVideoBaseline: Equatable, CustomStringConvertible {
    /// 网络等级判定为优秀的视频分辨率基线，-1表示业务不设置计算时忽略此参数
    public let goodVideoPixelBaseline: Int
    /// 网络等级判定为优秀的视频帧率基线，-1表示业务不设置计算时忽略此参数
    public let goodVideoFpsBaseline: Int
    /// 网络等级判定为差的视频分辨率基线，-1表示业务不设置计算时忽略此参数
    public let badVideoPixelBaseline: Int
    /// 网络等级判定为差的视频帧率基线，-1表示业务不设置计算时忽略此参数
    public let badVideoFpsBaseline: Int

    public var description: String {
        "goodRes: \(goodVideoPixelBaseline), goodFps: \(goodVideoFpsBaseline), badRes: \(badVideoPixelBaseline), badFps: \(badVideoFpsBaseline)"
    }
}

/// ByteRtcFetchEffectInfo
public struct RtcFetchEffectInfo {
    public let resId: String
    public var resPath: String
    public var category: String
    public var panel: String
    public var tagNum: Int
    public var tags: [String]
    public var params: [NSNumber]

    public init(resId: String, resPath: String, category: String, panel: String, tagNum: Int, tags: [String], params: [NSNumber]) {
        self.resId = resId
        self.resPath = resPath
        self.category = category
        self.panel = panel
        self.tagNum = tagNum
        self.tags = tags
        self.params = params
    }
}

/// ByteRtcEffectType
public enum RtcEffectType: String, CustomStringConvertible {
    case buildIn
    case exclusive

    public var description: String { rawValue }
}

/// ByteRtcAUProperty
enum RtcAUProperty {
    /// 控制vpio所有算法处理
    case bypassVoiceProcessing
    /// 麦克风硬件静音，ios14后会使麦克风占用标志消失
    case muteOutput
    /// 控制vpio AGC处理
    case voiceProcessingEnableAGC
}

/// 远端用户优先级。在性能不足需要回退时，会先回退优先级低的用户的音视频流
/// - ByteRtcRemoteUserPriority
enum RtcRemoteUserPriority {
    /// 用户优先级为低，默认值
    case low
    /// 用户优先级为正常
    case medium
    /// 用户优先级为高
    case high
}

/// 视频输入源类型
/// - ByteRTCVideoSourceType
enum RtcVideoSourceType {
    /// 内部采集视频源
    case `internal`
}

/// 用户订阅的远端音/视频流统计信息以及网络状况，统计周期为 2s 。
///
/// 订阅远端用户发布音/视频流成功后，SDK 会周期性地通过 `onRemoteStreamStats`
/// 通知本地用户订阅的远端音/视频流在此次统计周期内的接收状况。此数据结构即为回调给本地用户的参数类型。
struct RtcRemoteStreamStats {
    /// 用户 ID 。音频来源的用户 ID
    let uid: RtcUID
    /// 远端音频流的统计信息
    let audioStats: RtcRemoteAudioStats
    /// 远端视频流的统计信息
    let videoStats: RtcRemoteVideoStats
    /// 所属用户的媒体流是否为屏幕流。你可以知道当前统计数据来自主流还是屏幕流。
    let isScreen: Bool
}

/// 远端音频流统计信息，统计周期为 2s 。
///
/// 本地用户订阅远端音频流成功后，SDK 会周期性地通过 `onRemoteStreamStats`
/// 通知本地用户订阅的音频流在此次统计周期内的接收状况。此数据结构即为回调给本地用户的参数类型。
struct RtcRemoteAudioStats {
}

/// 远端视频流统计信息，统计周期为 2s 。
///
/// 本地用户订阅远端视频流成功后，SDK 会周期性地通过 `onRemoteStreamStats`
/// 通知本地用户订阅的远端视频流在此次统计周期内的接收状况。此数据结构即为回调给本地用户的参数类型。
struct RtcRemoteVideoStats {
    /// 远端视频宽度。
    let width: Int
    /// 远端视频高度。
    let height: Int
    /// 远端视频流是否是屏幕共享流。你可以知道当前数据来自主流还是屏幕流。
    let isScreen: Bool
    /// 编码类型。
    let codecType: RtcVideoCodecType
}

/// 本地音/视频流统计信息以及网络状况，统计周期为 2s 。
///
/// 本地用户发布音/视频流成功后，SDK 会周期性地通过 `onLocalStreamStats`
/// 通知本地用户发布的音/视频流在此次统计周期内的发送状况。此数据结构即为回调给用户的参数类型。
struct RtcLocalStreamStats {
    /// 本地设备发送音频流的统计信息
    let audioStats: RtcLocalAudioStats
    /// 本地设备发送视频流的统计信息
    let videoStats: RtcLocalVideoStats
    /// 所属用户的媒体流是否为屏幕流。你可以知道当前统计数据来自主流还是屏幕流。
    let isScreen: Bool
}

/// 本地音频流统计信息，统计周期为 2s 。
///
/// 本地用户发布音频流成功后，SDK 会周期性地通过 `onLocalStreamStats`
/// 通知本地用户发布的音频流在此次统计周期内的发送状况。此数据结构即为回调给本地用户的参数类型。
struct RtcLocalAudioStats {
}

/// 本地视频流统计信息，统计周期为 2s 。
///
/// 本地用户发布视频流成功后，SDK 会周期性地通过 `onLocalStreamStats`
/// 通知本地用户发布的视频流在此次统计周期内的发送状况。此数据结构即为回调给本地用户的参数类型。
struct RtcLocalVideoStats {
    /// 所属用户的媒体流是否为屏幕流。你可以知道当前统计数据来自主流还是屏幕流。
    let isScreen: Bool
    /// 编码类型。
    let codecType: RtcVideoCodecType
}

/// 当前媒体设备类型
enum RtcMediaDeviceType {
    /// 视频采集设备类型
    case videoCaptureDevice
}

/// 媒体设备状态
enum RtcMediaDeviceState {
    /// 设备已开启
    case started
    /// 设备已停止
    case stopped
    /// 系统通话，锁屏或第三方应用打断了音视频通话。将在通话结束或第三方应用结束占用后自动恢复。
    case interruptionBegan
    /// 音视频通话已从系统电话或第三方应用打断中恢复
    case interruptionEnded
    /// 设备运行时错误
    ///
    /// 例如，当媒体设备的预期行为是正常采集，但没有收到采集数据时，将回调该状态。
    case runtimeError
}

/// 媒体设备错误类型
enum RtcMediaDeviceError: Equatable {
    case unknown(Int)
    /// 媒体设备正常
    case ok
    case notAvailableInBackground
    case videoInUseByAnotherClient
    case notAvailableWithMultipleForegroundApps
    case notAvailableDueToSystemPressure
}

enum RtcNsOption: String, CustomStringConvertible {
    /// close noise suppression
    case disabled
    /// mild level
    case mild
    /// medium level
    case medium
    /// aggressive level
    case aggressive
    /// very aggressive level
    case veryAggressive

    var description: String { rawValue }
}

/// ByteStream
struct RtcStreamInfo {
    /// 此流是否包括视频流
    let hasVideo: Bool
    /// 视频流的分辨率信息
    let videoStreamDescriptions: [RtcVideoStreamDescription]
}
