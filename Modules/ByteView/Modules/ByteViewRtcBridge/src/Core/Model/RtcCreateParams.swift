//
//  RtcCreateParams.swift
//  ByteView
//
//  Created by kiri on 2022/8/8.
//

import Foundation
import AVFoundation
import CoreMotion
import ByteViewCommon

public struct RtcCreateParams {
    let uuid = UUID().uuidString
    let rtcAppId: String
    let sessionId: String
    let extensionGroupId: String
    let uid: String
    let vendorType: RtcVendorType
    let isVirtualBgCoremlEnabled: Bool
    let isVirtualBgCvpixelbufferEnabled: Bool
    let hostConfig: RtcHostConfig
    let audioConfig: AudioConfig
    let videoCaptureConfig: VideoCaptureConfig
    let mutePromptConfig: MutePromptConfig
    let effectFrameRateConfig: EffectFrameRateConfig
    let renderConfig: RtcRenderConfig
    let encodeLinkageConfig: CameraEncodeLinkageConfig?
    // 初始化RTC时需要传入的一些其他参数
    // sharedEngineWithAppId:(NSString *)appId delegate:(id<ByteRtcMeetingEngineDelegate>)delegate parameters:(NSDictionary* _Nullable)parameters
    let extra: [String: Any]
    // rtc域名配置
    let domainConfig: [String: Any]

    /// 毫秒
    let activeSpeakerReportInterval: Int
    let actionProxy: RtcActionProxy

    let fgConfig: String?
    /// 媒体服务器专有部署是否生效
    let adminMediaServerSettings: Bool?

    //rtc日志路径
    let logPath: String

    public var userToken: String?
    public var channelName: String?

    // RTC runtime参数，初始化时需要传入，joinChannel前也需要通过setRuntimeParameters传给RTC
    private(set) var runtimeParameters: [String: Any] = [:]

    // nolint-next-line: long parameters
    public init(rtcAppId: String, sessionId: String, extensionGroupId: String, uid: String, vendorType: RtcVendorType, isVirtualBgCoremlEnabled: Bool, isVirtualBgCvpixelbufferEnabled: Bool, hostConfig: RtcHostConfig, audioConfig: AudioConfig, videoCaptureConfig: VideoCaptureConfig, mutePromptConfig: MutePromptConfig, effectFrameRateConfig: EffectFrameRateConfig, renderConfig: RtcRenderConfig, encodeLinkageConfig: CameraEncodeLinkageConfig?, extra: [String: Any], domainConfig: [String: Any], activeSpeakerReportInterval: Int, actionProxy: RtcActionProxy, fgConfig: String?, adminMediaServerSettings: Bool?, logPath: String) {
        self.rtcAppId = rtcAppId
        self.sessionId = sessionId
        self.extensionGroupId = extensionGroupId
        self.uid = uid
        self.vendorType = vendorType
        self.isVirtualBgCoremlEnabled = isVirtualBgCoremlEnabled
        self.isVirtualBgCvpixelbufferEnabled = isVirtualBgCvpixelbufferEnabled
        self.hostConfig = hostConfig
        self.audioConfig = audioConfig
        self.videoCaptureConfig = videoCaptureConfig
        self.mutePromptConfig = mutePromptConfig
        self.effectFrameRateConfig = effectFrameRateConfig
        self.renderConfig = renderConfig
        self.encodeLinkageConfig = encodeLinkageConfig
        self.extra = extra
        self.domainConfig = domainConfig
        self.activeSpeakerReportInterval = activeSpeakerReportInterval
        self.actionProxy = actionProxy
        self.fgConfig = fgConfig
        self.adminMediaServerSettings = adminMediaServerSettings
        self.logPath = logPath
    }

    public mutating func mergeRuntimeParameters(_ parameters: [String: Any]?) {
        if let p = parameters, !p.isEmpty {
            self.runtimeParameters = runtimeParameters.merging(p, uniquingKeysWith: { $1 })
        }
    }

    public struct AudioConfig: Equatable, CustomStringConvertible {
        let isCallKit: Bool
        let category: AVAudioSession.Category
        let options: AVAudioSession.CategoryOptions
        let mode: AVAudioSession.Mode
        public init(isCallKit: Bool, category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions, mode: AVAudioSession.Mode) {
            self.isCallKit = isCallKit
            self.category = category
            self.options = options
            self.mode = mode
        }

        public var description: String {
            "AudioConfig(isCallKit: \(isCallKit), category: \(category), options: \(options), mode: \(mode))"
        }
    }

    public struct VideoCaptureConfig: CustomStringConvertible {
        public var videoSize: CGSize
        public var frameRate: Int
        public init(videoSize: CGSize, frameRate: Int) {
            self.videoSize = videoSize
            self.frameRate = frameRate
        }

        public var description: String {
            "VideoCaptureConfig(\(Int(videoSize.width))x\(Int(videoSize.height))@\(frameRate))"
        }
    }

    public struct MutePromptConfig {
        public let interval: Int // SDK回调声音的时间间隔 ms
        public let level: Int // SDK检测音量的阈值

        public init(interval: Int, level: Int) {
            self.interval = interval
            self.level = level
        }
    }

    public struct EffectFrameRateConfig {
        let virtualBackgroundFps: Int
        let animojiFps: Int
        let filterFps: Int
        let beautyFps: Int
        let mixFilterBeautyFps: Int
        let mixOtherFps: Int

        // nolint-next-line: long parameters
        public init(virtualBackgroundFps: Int, animojiFps: Int, filterFps: Int, beautyFps: Int, mixFilterBeautyFps: Int, mixOtherFps: Int) {
            self.virtualBackgroundFps = virtualBackgroundFps
            self.animojiFps = animojiFps
            self.filterFps = filterFps
            self.beautyFps = beautyFps
            self.mixFilterBeautyFps = mixFilterBeautyFps
            self.mixOtherFps = mixOtherFps
        }
    }

    public struct RtcHostConfig: Encodable {
        let frontier: [String]
        let decision: [String]
        let defaultIps: [String]
        let kaChannel: String

        public init(frontier: [String], decision: [String], defaultIps: [String], kaChannel: String) {
            self.frontier = frontier
            self.decision = decision
            self.defaultIps = defaultIps
            self.kaChannel = kaChannel
        }

        enum CodingKeys: String, CodingKey {
            case frontier = "rtc_frontier"
            case decision = "rtc_decision"
            case defaultIps = "rtc_defaultips"
            case kaChannel = "kaChannel"
        }

        func toJSONString() -> String? {
            let json = JSONEncoder()
            if let data = try? json.encode(self), let str = String(data: data, encoding: .utf8) {
                return str
            }
            return nil
        }
    }

    public struct CameraEncodeLinkageConfig {
        // 总计档位数量
        let levelsCount: Int
        // 小视图基准档位
        let smallViewBaseIndex: Int
        // // 大视图 pixel
        let bigViewPixels: Int
        // 大视图基准档位
        let bigViewBaseIndex: Int
        // 单个特效降级档位
        let singleEffectLevel: Int
        // 组合特效降级档位
        let groupEffectLevel: Int
        // 节能模式降级档位
        let ecoModeLevel: Int

        // nolint-next-line: long parameters
        public init(levelsCount: Int, smallViewBaseIndex: Int, bigViewPixels: Int, bigViewBaseIndex: Int, singleEffectLevel: Int, groupEffectLevel: Int, ecoModeLevel: Int) {
            self.levelsCount = levelsCount
            self.smallViewBaseIndex = smallViewBaseIndex
            self.bigViewPixels = bigViewPixels
            self.bigViewBaseIndex = bigViewBaseIndex
            self.singleEffectLevel = singleEffectLevel
            self.groupEffectLevel = groupEffectLevel
            self.ecoModeLevel = ecoModeLevel
        }
    }

}

extension RtcCreateParams: CustomStringConvertible {
    public var description: String {
        "RtcCreateParams(uid: \(uid), vendorType: \(vendorType), audioConfig: \(audioConfig), videoCaptureConfig: \(videoCaptureConfig))"
    }
}

public enum RtcActionType {
    /// 操作rtc sdk
    case rtc
    /// 响应rtc delegate
    case rtcDelegate
    /// 回调给调用方
    case callback
    /// 渲染
    case render
}

public protocol RtcActionProxy {
    func performAction<T>(_ type: RtcActionType, action: () -> T) -> T
    func requestAudioCapturePermission(scene: RtcAudioScene) throws
    func requestVideoCapturePermission(scene: RtcCameraScene) throws
    func startDeviceMotionUpdatesForCamera(manager: CMMotionManager, to queue: OperationQueue, withHandler handler: @escaping CMDeviceMotionHandler)
    func clearSafeModeCache(_ action: (Bool) -> Void)
    /// 将要创建RTC（sdk）实例
    func willCreateInstance()
    func setInputMuted(_ muted: Bool)
}

public struct RtcRenderConfig {
    let viewSizeDebounce: TimeInterval
    let sharedDisplayLink: SharedDisplayLinkConfig?
    let unsubscribeDelay: UnsubscribeDelayConfig
    let proxy: RtcActionProxy

    public init(viewSizeDebounce: TimeInterval, sharedDisplayLink: SharedDisplayLinkConfig?, unsubscribeDelay: UnsubscribeDelayConfig?, proxy: RtcActionProxy?) {
        self.viewSizeDebounce = viewSizeDebounce
        self.sharedDisplayLink = sharedDisplayLink
        self.unsubscribeDelay = unsubscribeDelay ?? .default
        self.proxy = proxy ?? DefaultRtcActionProxy()
    }

    public struct SharedDisplayLinkConfig {
        let enabled: Bool
        let fpsList: [Int]
        let maxFps: Int

        public init(enabled: Bool, fpsList: [Int], maxFps: Int) {
            self.enabled = enabled
            self.fpsList = fpsList
            self.maxFps = maxFps
        }
    }

    public struct UnsubscribeDelayConfig {
        let maxStreamCount: Int
        let video: Float
        let screen: Float

        public init(maxStreamCount: Int, video: Float, screen: Float) {
            self.maxStreamCount = maxStreamCount
            self.video = video
            self.screen = screen
        }

        // nolint-next-line: magic number
        fileprivate static let `default` = UnsubscribeDelayConfig(maxStreamCount: 10, video: 0.5, screen: 2.5)
    }

    static let `default` = RtcRenderConfig(viewSizeDebounce: 1.0, sharedDisplayLink: nil, unsubscribeDelay: .default, proxy: nil)
}

struct DefaultRtcActionProxy: RtcActionProxy {

    func performAction<T>(_ type: RtcActionType, action: () -> T) -> T {
        action()
    }

    func requestAudioCapturePermission(scene: RtcAudioScene) throws {
    }

    func requestVideoCapturePermission(scene: RtcCameraScene) throws {
    }

    func startAudioCapture(scene: RtcAudioScene, _ action: @escaping (Result<Void, Error>) -> Void) {
        action(.success(Void()))
    }

    func startVideoCapture(scene: RtcCameraScene, _ action: @escaping (Result<Void, Error>) -> Void) {
        action(.success(Void()))
    }

    func startDeviceMotionUpdatesForCamera(manager: CMMotionManager, to queue: OperationQueue, withHandler handler: @escaping CMDeviceMotionHandler) {
        manager.startDeviceMotionUpdates(to: queue, withHandler: handler)
    }

    func clearSafeModeCache(_ action: (Bool) -> Void) {
        action(false)
    }

    func willCreateInstance() {}

    func setInputMuted(_ muted: Bool) {}
}
