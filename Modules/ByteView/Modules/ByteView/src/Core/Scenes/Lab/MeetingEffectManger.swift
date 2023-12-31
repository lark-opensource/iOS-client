//
//  MeetingEffectManger.swift
//  ByteView
//
//  Created by ByteDance on 2023/7/12.
//

import Foundation
import ByteViewMeeting
import ByteViewSetting
import EffectPlatformSDK
import ByteViewNetwork

extension MeetingSession {
    var effectManger: MeetingEffectManger? { component(for: MeetingEffectManger.self) }
}

class MeetingEffectManger: MeetingComponent {
    private let session: MeetingSession
    private let logger = Logger.effect

    let virtualBgService: EffectVirtualBgService // 处理虚拟背景
    let pretendService: EffectPretendService // 处理animoji、美颜、滤镜

    let setting: MeetingSettingManager
    var isShowEffects: Bool { setting.showsEffects }
    var isVirtualBgEnabled: Bool { setting.isVirtualBgEnabled }

    // CPU打分与静态检测
    var isVirtualBgEffective: Bool = false
    var isAnimojiEffective: Bool = false
    var isFilterEffective: Bool = false
    var curFilterValue: Int?
    var isBeautyEffective: Bool = false

    @RwAtomic static var ignoreStaticPerfDegrade = false

    private var iesffectManager: IESEffectManager

    required init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let setting = session.setting, let service = session.service else { return nil }
        self.setting = setting
        self.session = session

        _ = LabImageCrop.initializeOnce
        MeetingEffectManger.initSDK(isFeishuBrand: setting.isFeishuBrand,
                                    labPlatformApplinkConfig: setting.labPlatformApplinkConfig,
                                    deviceId: session.service?.account.deviceId)
        self.iesffectManager = IESEffectManager()
        self.iesffectManager.config.downloadOnlineEnviromentModel = true // 设置模型环境是内测还是线上
        self.iesffectManager.setUp()

        self.virtualBgService = EffectVirtualBgService(service: service, setting: setting, userId: session.userId)
        self.pretendService = EffectPretendService(setting: setting)
    }

    deinit {
        logger.info("MeetingEffectManger deinit ")
    }

    static func initSDK(isFeishuBrand: Bool, labPlatformApplinkConfig: LabPlatformApplinkConfig, deviceId: String?) {
        Logger.effect.info("initSDK, domain: \(isFeishuBrand)")
        EffectPlatform.start(withAccessKey: EffectResource.effectAccessKey)
        EffectPlatform.setAppId(EffectResource.effectAppId)
        EffectPlatform.setOsVersion(UIDevice.current.systemVersion)
        EffectPlatform.setRegion(EffectResource.effectRegion)
        EffectPlatform.setChannel(EffectResource.effectChannel)
        EffectPlatform.setDeviceIdentifier(deviceId ?? "")
        #if canImport(VolcEngineRTC)
        let version = ByteRtcMeetingEngineKit.getEffectSDKVersion()
        EffectPlatform.setEffectSDKVersion(version)
        #endif
        EffectPlatform.setDomain(isFeishuBrand ? labPlatformApplinkConfig.feishuHost : labPlatformApplinkConfig.larkHost)
//        EffectPlatform.sharedInstance().enableNewEffectManager = true
    }

    func isEffectOn() -> Bool {
        let isVirtualBgOrBlurOn = (virtualBgService.currentVirtualBgsModel?.bgType ?? .setNone) != .setNone
        let isAnyEffectOn = pretendService.isAnyEffectOn
        return isVirtualBgOrBlurOn || isAnyEffectOn
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {}

    func getForCalendarSetting(meetingId: String?, uniqueId: String?, isWebinar: Bool?, isUnWebinarAttendee: Bool?) {
        logger.info("getForCalendarSetting, meetingId: \(meetingId), uniqueId: \(uniqueId), isWebinar: \(isWebinar), isUnWebinarAttendee: \(isUnWebinarAttendee)")

        virtualBgService.beginFetchCalendarBgsInfo(meetingId: meetingId, uniqueId: uniqueId, isWebinar: isWebinar, isUnWebinarAttendee: isUnWebinarAttendee)

        let request = GetExtraMeetingVirtualBackgroundRequest(uniqueID: uniqueId, meetingId: meetingId, isWebinar: isWebinar)
        session.httpClient.getResponse(request) { [weak self] res in
            guard let self = self else { return }
            self.virtualBgService.addJob(type: .calendar(res: res))
            switch res {
            case .success(let result):
                Logger.effectPretend.info("getCalendarInfo allowVirtualAvatar: \(result.allowVirtualAvatar)")
                self.pretendService.isAllowAnimoji = result.allowVirtualAvatar
            case .failure:
                self.logger.info("getCalendarInfo failed")
            }
        }
    }
}


extension MeetingEffectManger: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        logger.info("didChangeMeetingSetting \(isOn), key: \(key)")
    }
}

extension MeetingEffectManger: MeetingSessionListener {
    func willEnterState(_ state: ByteViewMeeting.MeetingState, from: ByteViewMeeting.MeetingState, event: ByteViewMeeting.MeetingEvent, session: ByteViewMeeting.MeetingSession) {}

    func didEnterState(_ state: ByteViewMeeting.MeetingState, from: ByteViewMeeting.MeetingState, event: ByteViewMeeting.MeetingEvent, session: ByteViewMeeting.MeetingSession) {}
}
