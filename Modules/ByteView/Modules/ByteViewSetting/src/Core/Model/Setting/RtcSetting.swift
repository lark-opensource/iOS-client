//
//  RtcSetting.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/18.
//

import Foundation
import ByteViewNetwork

public struct RtcSetting {
    public let rtcAppId: String
    public let appGroupId: String
    public let isMediaOversea: Bool
    public let isDataOversea: Bool
    public let isHDModeEnabled: Bool
    public let isVirtualBgCoremlEnabled: Bool
    public let isVirtualBgCvpixelbufferEnabled: Bool

    public let hostConfig: RtcHostConfig
    public let dispatchConfig: RtcDispatchConfig
    public let multiResolutionConfig: MultiResolutionConfig
    public let renderConfig: RenderConfig
    public let activeSpeakerConfig: ActiveSpeakerConfig
    public let mutePromptConfig: MutePromptConfig
    public let perfSampleConfig: InMeetPerfSampleConfig
    // 初始化RTC时需要传入的一些其他参数
    // sharedEngineWithAppId:(NSString *)appId delegate:(id<ByteRtcMeetingEngineDelegate>)delegate parameters:(NSDictionary* _Nullable)parameters
    public let extra: [String: Any]
    public let bandwidth: GetAdminSettingsResponse.Bandwidth?
    public let fgConfig: String?
    /// 媒体服务器专有部署是否生效
    public let adminMediaServerSettings: Bool?
    public let clearRtcCacheVersion: String?
    //帧率联动配置
    public let encodeLinkageConfig: CameraEncodeLinkageConfig?
    //rtc日志路径
    public let logPath: String

    public struct RtcHostConfig {
        public let frontier: [String]
        public let decision: [String]
        public let defaultIps: [String]
        public let kaChannel: String
    }

    public struct RtcDispatchConfig {
        //!isMediaOversea && vendorType == VENDOR_TYPE_LARKRTC
        public let feishuRtc: [String]
        // !isMediaOversea && vendorType == VENDOR_TYPE_LARKPRERTC
        public let feishuPreRtc: [String]
        // !isMediaOversea && vendorType == VENDOR_TYPE_TEST
        public let feishuTestRtc: [String]
        // !isMediaOversea && vendorType == VENDOR_TYPE_TEST_PRE
        public let feishuTestPreRtc: [String]
        // !isMediaOversea && vendorType == VENDOR_TYPE_TEST_GAUSS
        public let feishuTestGaussRtc: [String]

        // isMediaOversea && vendorType == VENDOR_TYPE_LARKRTC
        public let larkRtc: [String]
        // isMediaOversea && vendorType == VENDOR_TYPE_LARKPRERTC
        public let larkPreRtc: [String]
        // isMediaOversea && vendorType == VENDOR_TYPE_TEST
        public let larkTestRtc: [String]
        // isMediaOversea && vendorType == VENDOR_TYPE_TEST_PRE
        public let larkTestPreRtc: [String]
        // isMediaOversea && vendorType == VENDOR_TYPE_TEST_GAUSS
        public let larkTestGaussRtc: [String]
    }

    public func getDomainConfigWith(vendorType: VideoChatInfo.VendorType) -> [String: Any] {
        var dispatch: [String] = []
        var defaultips: [String] = []
        if self.hostConfig.kaChannel != "saas" {
            dispatch = self.hostConfig.frontier
            defaultips = self.hostConfig.defaultIps
        }

        if dispatch.isEmpty {
            dispatch = getDispatchWith(vendorType: vendorType)
        }

        var domainConfig: [String: Any] = ["dispatch": dispatch]

        if !defaultips.isEmpty {
            domainConfig["default_ip"] = defaultips
        }

        var config: [String: Any] = ["rtc.domain_config": domainConfig]

        // 0: 线上环境, 2: 测试环境
        config["rtc.env"] = vendorType == .larkRtc ? 0 : 2

        return config
    }

    private func getDispatchWith(vendorType: VideoChatInfo.VendorType) -> [String] {
        var dispatch: [String] = []
        switch vendorType {
        case .larkRtc:
            dispatch = isMediaOversea ? dispatchConfig.larkRtc : dispatchConfig.feishuRtc
        case .larkPreRtc:
            dispatch = isMediaOversea ? dispatchConfig.larkPreRtc : dispatchConfig.feishuPreRtc
        case .larkRtcTest:
            dispatch = isMediaOversea ? dispatchConfig.larkTestRtc : dispatchConfig.feishuTestRtc
        case .larkRtcTestPre:
            dispatch = isMediaOversea ? dispatchConfig.larkTestPreRtc : dispatchConfig.feishuTestPreRtc
        case .larkRtcTestGauss:
            dispatch = isMediaOversea ? dispatchConfig.larkTestGaussRtc : dispatchConfig.feishuTestGaussRtc
        default:
            break
        }
        if dispatch.isEmpty {
            dispatch = isMediaOversea ? dispatchConfig.larkRtc : dispatchConfig.feishuRtc
        }
        return dispatch
    }
}
