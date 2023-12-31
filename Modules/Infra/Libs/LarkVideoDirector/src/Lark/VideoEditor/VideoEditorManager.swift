//
//  VideoEditorManager.swift
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/10/10.
//

import Foundation
import Heimdallr
import TTVideoEditor
import LKCommonsLogging
import LarkFoundation
import LKCommonsTracker
import LarkReleaseConfig
import LarkSetting
import LarkStorage

public final class VideoEditorManager {
    public static let shared = VideoEditorManager()

    private static let logger = Logger.log(VideoEditorManager.self)

    private let veLogger = VideoEditorLoggerDelegate()

    /// App 生命周期内，只初始化一次
    private var didSetup: Bool = false

    /// 初始化 VE，主要包括设置 VESDK 的日志、埋点回调，和配置设置
    public func setupVideoEditorIfNeeded() {
        guard !didSetup else { return }
        didSetup = true
        /// VE 不支持模拟器，所以
        /// 下面设置只在真机生效
        /// 模拟器调用下面方法会触发崩溃
        guard !Utils.isSimulator else { return }
        IESMMLogger.sharedInstance()?.loggerDelegate = self.veLogger
        IESMMTrackerManager.shareInstance().setAppLogCallback(ReleaseConfig.appIdForAligned, callback: {
            (_ event: String, _ params: [AnyHashable: Any]?, _ eventType: String) -> Void in
            Tracker.post(TeaEvent(event, params: params ?? [:]))
        })
        setupVEConfig()
    }

    public func getSmartCodecModel() -> URL? {
        if let path = ResourceManager.localCache(for: .aiCodec) {
            return URL(fileURLWithPath: path)
        } else {
            ResourceManager.fetchResource(for: .aiCodec)
            return nil
        }
    }

    public func fetchSmartCodecModel() {
        ResourceManager.fetchResource(for: .aiCodec)
    }
}

public final class VideoEditorLoggerDelegate: NSObject, IESEditorLoggerDelegate {

//    static let logger = Logger.log(VideoEditorLoggerDelegate.self)

    #if ALPHA
    private static let veStore = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("LarkVideoDirector").child("TTVideoEditor"))

    @KVConfig(key: "ve_nslog", default: false, store: veStore)
    private static var _veNSLog: Bool
    private static var _cachedVeNSLog: Bool?
    public static var useNSLog: Bool {
        get {
            if let _cachedVeNSLog {
                return _cachedVeNSLog
            } else {
                let rawValue = _veNSLog
                _cachedVeNSLog = rawValue
                return rawValue
            }
        }
        set {
            _veNSLog = newValue
            _cachedVeNSLog = newValue
        }
    }
    #endif

    public func iesEditorlog(toLocal logString: String?, andLevel level: IESMMlogLevel) {
        #if ALPHA
        // Debug 菜单将日志输入到 NSLog 便于在 Console 实时查看
        if Self.useNSLog {
            NSLog("\(level) " + (logString ?? ""))
            return
        }
        #endif
        // VESDK 日志量比较大 直接接入 BDAlog
        // TODO: 等待 molten-log 接入后，尝试切回 Logger
        // https://bytedance.feishu.cn/wiki/wikcn4bvB1irBZoNFdnuf39ddHf
        switch level {
        case .IESMMlogLevelError: BDAlogWrapper.error(logString ?? "")
        case .IESMMLogLevelWarn: BDAlogWrapper.warn(logString ?? "")
        case .IESMMLogLevelDebug: BDAlogWrapper.debug(logString ?? "")
        default: BDAlogWrapper.info(logString ?? "")
        }
    }
}

// MARK: - VE Config

extension VideoEditorManager {

    internal func setVEConfigNotSetHandler() {
        let start = CACurrentMediaTime()
        VEConfigCenter.setABSetNotifyHandle { [weak self] in
            guard !Utils.isSimulator, let self else { return }
            assertionFailure("must call `VideoEditorManager.shared.setupVideoEditorIfNeeded()` before call any VE API")
            Self.logger.warn("[VE][AB] AB not set before call VE API! setup VE now")
            // 将当前栈上报 Slardar 自定义异常
            let parameters = HMDUserExceptionParameter.initCurrentThreadParameter(
                withExceptionType: "Media-Use_VE_before_setup", customParams: nil, filters: nil
            )
            HMDUserExceptionTracker.shared().trackThreadLog(with: parameters)
            // 目前没有提供日志或者埋点的回调，通过 AB 的未设置回调把其他的回调也设置上
            self.setupVideoEditorIfNeeded()
        }
        Self.logger.info("[VE][AB] set handler cost: \(CACurrentMediaTime() - start) s")
    }

    // MARK: setupVEConfig

    /// - Note: VE 的配置第一次被读取之后便不可更新，所以只在 App 生命周期内初始化一次。
    /// VESDK 的配置必须在调用所有实例之前设置，否则会无效，详见
    /// [文档](https://bytedance.feishu.cn/wiki/CCEMwwQVNiH8G6kd1rYc1QttnBf)
    private func setupVEConfig() {
        let start = CACurrentMediaTime()
        // MARK: 默认开启的配置

        // config
        // 开启音视频交织优化
        Self.logger.info("[VE][AB] crossplatEnable")
        let veConfigCenter = VEConfigCenter.sharedInstance()
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "vesdk_crossplat_input", type: .bool)
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "vesdk_crossplat_compile", type: .bool)
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_crossplatAudioMux", type: .bool)
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_enableResumeCompileFromBreakPoint", type: .bool)
        // 开启跨平台开关 才能触发内部音视频交织优化
        IESMMParamModule.sharedInstance().useCrossPlatformProcessUnit = true
        IESMMParamModule.sharedInstance().useNewAudioEditor = true
        // 添加 ve 画质优化参数
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "vesdk_enable_fullrange_opt", type: .bool) // 1100 可删
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "vesdk_enable_write_colorproperties", type: .bool) // 1100 可删
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_extend_colorspace_support", type: .bool) // 1100 可删

        // 支持后台转码
        Self.logger.info("[VE][AB] backgroundSendEnable")
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_enableBackGroundTranscode", type: .bool)
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_enableResumeCompileFromBreakPoint", type: .bool)

        // 支持慢速视频发送
        // 设置高清发布开关
        IESMMParamModule.sharedInstance().enableHDModeUpload = true
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_use_bitrate_json_Opt", type: .bool)
        // 设置是否使用参数下发
        IESMMParamModule.sharedInstance().useServerPar = true

        // 视频剪辑支持 HDR 视频显示
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "vesdk_enable_apple_hdr_support", type: .bool) // 1100 可删

        // MARK: FG 配置

        // 更新编码器配置
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "vesdk_ffmpeg_enable_video_timestamp_monotonic", type: .bool)

        // 添加 hdr 后台转码开关
        veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_ios_enable_background_hdrtosdr", type: .bool)

        // MARK: 依赖 Setting & AB 的配置

        do {
            let setting = try SettingManager.shared.setting(with: VideoSynthesisSetting.key)
            let abSetting = Tracker.experimentValue(
                key: "ve_synthesis_settings_ab_config", shouldExposure: true
            ) as? [String: Any]
            let videoSynthesisSetting = VideoSynthesisSetting(setting: setting, abConfig: abSetting)
            let veSetting = videoSynthesisSetting.veSetting
            Self.logger.info("[VE][AB] get veSetting: \(veSetting)")

            // 支持后台转码带有旋转信息的视频
            if veSetting.enableMuxRotation == 1 {
                veConfigCenter?.configVESDKABValue(NSNumber(true), key: "veabtest_ios_enable_mux_rotation", type: .bool)
            }

            // 支持 AB 动态下发
            veSetting.internalSetting.forEach { (key: String, value: Any) in
                if let boolValue = value as? Bool {
                    veConfigCenter?.configVESDKABValue(NSNumber(value: boolValue), key: key, type: .bool)
                } else if let intValue = value as? Int {
                    if intValue == 0 {
                        veConfigCenter?.configVESDKABValue(NSNumber(false), key: key, type: .bool)
                    } else if intValue == 1 {
                        veConfigCenter?.configVESDKABValue(NSNumber(true), key: key, type: .bool)
                    } else {
                        veConfigCenter?.configVESDKABValue(NSNumber(value: intValue), key: key, type: .int)
                    }
                } else if let floatValue = value as? Float {
                    veConfigCenter?.configVESDKABValue(NSNumber(value: floatValue), key: key, type: .float)
                } else if let strValue = value as? String {
                    veConfigCenter?.configVESDKABValue(strValue, key: key, type: .string)
                }
            }
        } catch {
            Self.logger.error("[VE][AB] failed to get ve setting: \(error)")
            return
        }
        VEConfigCenter.setABSetComplete()
        Self.logger.info("[VE][AB] setupVEConfig, cost: \(CACurrentMediaTime() - start) s")
    }
}

// MARK: Bridge to ObjC

public final class VideoEditorManagerBridge: NSObject {

    @objc
    public static func setupVideoEditorIfNeeded() {
        VideoEditorManager.shared.setupVideoEditorIfNeeded()
    }
}

// MARK: Model

// TODO: VE 的配置之后会独立一个 Setting

/// 视频发送综合配置
fileprivate struct VideoSynthesisSetting {

    static let logger = Logger.log(VideoSynthesisSetting.self, category: "VideoSynthesisSetting")

    static let key = UserSettingKey.make(userKeyLiteral: "ve_synthesis_settings")

    private(set) var veSetting: VideoEditorSetting = VideoEditorSetting()

    init() {}

    init(setting: [String: Any], abConfig: [String: Any]?) {
        var jsonDict = setting

        func mergeDictionary(dic1: [String: Any], dic2: [String: Any]) -> [String: Any] {
            return dic1.merging(dic2) { value1, value2 in
                var result = value1
                if let oldDic = value1 as? [String: Any],
                   let newDic = value2 as? [String: Any] {
                    result = mergeDictionary(dic1: oldDic, dic2: newDic)
                } else {
                    result = value2
                }
                return result
            }
        }
        // 合并 ab 与 setting
        if let abConfig = abConfig {
            let newSetting = mergeDictionary(dic1: jsonDict, dic2: abConfig)
            Self.logger.info("get new abConfig \(abConfig) result \(newSetting)")
            jsonDict = newSetting
        }

        self.veSetting = VideoEditorSetting(config: jsonDict[VideoEditorSetting.key] as? [String: Any])
    }
}



/// 视频 ve 透传配置
fileprivate struct VideoEditorSetting {
    static let key: String = "ve"
    /// "internal\_setting" ve码率相关透传配置（支持慢速视频发送）
    private(set) var internalSetting: [String: Any] = [:]
    /// "enable\_mux\_rotation" 是否支持带有旋转信息的视频后台转码
    private(set) var enableMuxRotation: Int32 = 0

    init(config: [String: Any]? = nil) {
        if let internalSetting = config?["internal_setting"] as? [String: Any] {
            self.internalSetting = internalSetting
        }

        if let enableMuxRotation = config?["enable_mux_rotation"] as? Int32 {
            self.enableMuxRotation = enableMuxRotation
        }
    }
}
