//
//  InMeetTipViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/6/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting

protocol InMeetTipViewModelObserver: AnyObject {
    func didUpdateTipInfo(_ tipInfo: TipInfo)
    func didCloseTipInfo(_ tipInfo: TipInfo)
}

final class InMeetTipViewModel: VideoChatNoticePushObserver, VideoChatNoticeUpdatePushObserver, VCManageNotifyPushObserver, MeetingSettingListener, BreakoutRoomManagerObserver, InMeetViewChangeListener {
    private(set) var tipInfos = [TipInfo]()
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    let breakoutRoom: BreakoutRoomManager?
    private var httpClient: HttpClient { meeting.httpClient }
    private var hasShowFakePstn: Bool = false

    private let queue = DispatchQueue(label: "lark.byteview.tips")
    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.resolver = resolver
        self.breakoutRoom = resolver.resolve(BreakoutRoomManager.self)
        self.breakoutRoom?.addObserver(self)
        meeting.push.notice.addObserver(self)
        meeting.push.noticeUpdate.addObserver(self)
        meeting.push.vcManageNotify.addObserver(self, handleCacheIfExists: false)
        meeting.rtc.network.addListener(self)
        meeting.audioModeManager.addListener(self)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
        resolver.viewContext.addListener(self, for: .hostControlDidAppear)
    }

    func initializeInfo() {
        if let msg = meeting.info.msg, msg.type == .tips, msg.isShow {
            handleMsgInfo(msg)
        }
        if let networkTipInfo = Self.createConnectionTipInfo(for: meeting.rtc.network.localNetworkStatus) {
            updateTipInfo(networkTipInfo)
        }

        if !hasShowFakePstn {
            handleFakePstnTips()
        }
    }

    private let observers = Listeners<InMeetTipViewModelObserver>()
    func addObserver(_ observer: InMeetTipViewModelObserver) {
        observers.addListener(observer)
    }

    func removeObserver(_ observer: InMeetTipViewModelObserver) {
        observers.removeListener(observer)
    }

    func gotoHostControl() {
        let vc = meeting.setting.ui.createInMeetSecurityViewController(context: InMeetSecurityContextImpl(meeting: meeting, fromSource: .tips))
        meeting.router.presentDynamicModal(vc,
                                          regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                          compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }

    func closeTip(_ tipInfo: TipInfo) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.tipInfos.firstIndex(where: { $0 == tipInfo }) {
                self.tipInfos.remove(at: idx)
                self.observers.forEach { $0.didCloseTipInfo(tipInfo) }
            }
        }
    }

    func closeTipFor(type: VideoChatNotice.NoticeType) {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.tipInfos.firstIndex(where: { $0.type == type }) {
                let info = self.tipInfos.remove(at: idx)
                self.observers.forEach { $0.didCloseTipInfo(info) }
            }
        }
    }

    enum TipKey: String {
        case largeMeeting = "tip_key:large_meeting"
    }

    func closeTip(_ key: TipKey) {
        self.closeTip(TipInfo(content: "", isFromNotice: false, key: key.rawValue))
    }

    func showTipInfo(_ info: TipInfo) {
        updateTipInfo(info)
    }

    func handleMsgInfo(_ msgInfo: MsgInfo) {
        i18n(defaultContent: msgInfo.message, msgI18NKey: msgInfo.msgI18NKey,
             isFromNotice: false) { [weak self] (info) in
            if let self = self, !info.content.isEmpty {
                self.updateTipInfo(info)
            }
        }
    }

    func didReceiveNotice(_ notice: VideoChatNotice) {
        if notice.type == .tips {
            // tips的meetingId校验，当不为空且不为零时需要进行校验
            if !notice.meetingID.isEmpty && notice.meetingID != "0" && notice.meetingID != meeting.meetingId {
                return
            }
            i18n(defaultContent: notice.message, msgI18NKey: notice.msgI18NKey, isFromNotice: true,
                 noticeInfo: notice) { [weak self] (info) in
                if !info.content.isEmpty {
                    self?.updateTipInfo(info)
                }
            }
        }
    }

    func didReceiveNoticeUpdate(_ update: VideoChatNoticeUpdate) {
        if update.type == .tips, !update.key.isEmpty, update.action == .dismiss {
            i18n(defaultContent: update.key, i18NKey: update.key, isFromNotice: true, updateInfo: update) { [weak self] info in
                if !info.content.isEmpty {
                    self?.updateTipInfo(info)
                }
            }
        }
    }

    func didReceiveManageNotify(_ notify: VCManageNotify) {
        /* - largeMeetingTriggered 推送包含两层逻辑：1、触发Tips提示；2、触发"大方会管提示人数"降阈
           - 分组会议期间不推送
           - 非主持人/联席不推送
         */
        guard notify.meetingID == meeting.meetingId, notify.notificationType == .largeMeetingTriggered else { return }
        guard meeting.setting.hasCohostAuthority, !meeting.setting.isOpenBreakoutRoom else {
            // 兜底
            Logger.meeting.info("largeMeetingTriggered tips be filtered")
            return
        }

        /// [建议项：建议开启/关闭]
        let suggestedSettings: [String: (Bool, Bool)] = [
            "muteOnEntry": (true, meeting.setting.isMuteOnEntry),
            "allowPartiUnmute": (false, meeting.setting.allowPartiUnmute),
            "onlyHostCanShare": (true, meeting.setting.onlyHostCanShare),
            "onlyPresenterCanAnnotate": (true, meeting.setting.onlyPresenterCanAnnotate)]

        let shouldShowTip = suggestedSettings.contains(where: { $1.0 != $1.1 })
        if shouldShowTip {
            handleFakeLargeMeetingTip()
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority, !isOn {
            closeTip(.largeMeeting)
        }
    }

    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        if info != nil {
            closeTip(.largeMeeting)
        }
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .hostControlDidAppear {
            closeTip(.largeMeeting)
        }
    }

    private func handleFakeLargeMeetingTip() {
        let tipInfo = TipInfo(content: I18n.View_G_ManyPeopleSecureSpeakPermitRec, iconType: .warning,
                              type: .largeMeeting, isFromNotice: false, canCover: true, canClosedManually: true,
                              alignment: Display.pad ? .center : .left, key: TipKey.largeMeeting.rawValue)
        updateTipInfo(tipInfo)
    }

    private func handleFakePstnTips() {
        if meeting.audioMode == .noConnect && meeting.joinMeetingParams?.audioMode == .pstn {
            let tipInfo = TipInfo(content: I18n.View_MV_CallingFloat + " " + (meeting.setting.callmePhoneNumber), iconType: .phone, type: .callmePhone, isFromNotice: false, canCover: false, canClosedManually: false)
            updateTipInfo(tipInfo)
            hasShowFakePstn = true
        }
    }

    private func i18n(defaultContent: String,
                      msgI18NKey: I18nKeyInfo? = nil,
                      i18NKey: String? = nil,
                      isFromNotice: Bool,
                      noticeInfo: VideoChatNotice? = nil,
                      updateInfo: VideoChatNoticeUpdate? = nil,
                      completion: @escaping (TipInfo) -> Void) {
        if let msgI18NKey = msgI18NKey {
            httpClient.i18n.get(by: msgI18NKey) { result in
                let key = msgI18NKey.newKey.isEmpty ? msgI18NKey.key : msgI18NKey.newKey
                if let (content, range) = result.value {
                    completion(TipInfo(content: content,
                                       iconType: noticeInfo?.tipsIconType ?? .info,
                                       type: noticeInfo?.noticeType ?? .other,
                                       isFromNotice: isFromNotice,
                                       highLightRange: range,
                                       scheme: msgI18NKey.jumpScheme,
                                       timeout: TimeInterval(noticeInfo?.timeout ?? 0) / 1000,
                                       noticeInfo: noticeInfo,
                                       updateInfo: updateInfo,
                                       key: key))
                } else {
                    completion(TipInfo(content: defaultContent, isFromNotice: isFromNotice, updateInfo: updateInfo, key: key))
                }
            }
        } else if let i18NKey = i18NKey {
            httpClient.i18n.get(i18NKey) { result in
                if let content = result.value {
                    completion(TipInfo(content: content, isFromNotice: isFromNotice, updateInfo: updateInfo, key: i18NKey))
                } else {
                    completion(TipInfo(content: defaultContent, isFromNotice: isFromNotice, updateInfo: updateInfo, key: i18NKey))
                }
            }
        } else {
            completion(TipInfo(content: defaultContent, isFromNotice: isFromNotice, updateInfo: updateInfo))
        }
    }

    private func updateTipInfo(_ tipInfo: TipInfo) {
        Logger.ui.info("updateTipInfo: isClosed = \(tipInfo.hasBeenClosedManually), isDismissInfo = \(tipInfo.isDismissInfo), autoDismissTime = \(tipInfo.autoDismissTime)")
        // 过滤已被手动关闭的info
        if tipInfo.hasBeenClosedManually {
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }
            self.tipInfos.removeAll { $0 == tipInfo }
            self.tipInfos.append(tipInfo)
            self.observers.forEach { $0.didUpdateTipInfo(tipInfo) }
        }
        let autoDismissTime = tipInfo.autoDismissTime
        if autoDismissTime > 0 {
            queue.asyncAfter(deadline: .now() + autoDismissTime) { [weak self] in
                Logger.ui.info("updateTipInfo: auto dismiss tip")
                self?.closeTip(tipInfo)
            }
        }
    }

    private func updateNetworkTip() {
        if let info = Self.createConnectionTipInfo(for: meeting.rtc.network.localNetworkStatus) {
            self.updateTipInfo(info)
        } else {
            self.closeTipFor(type: .connectionNotice)
        }
    }
}

extension InMeetTipViewModel {
    static private func createConnectionTipInfo(for status: RtcNetworkStatus?) -> TipInfo? {
        guard let status = status else {
            return nil
        }

        var title: String = ""
        var iconType: TipInfo.IconType = .info
        switch status.networkShowStatus {
        case .connected, .weak:
            return nil
        case .disconnected:
            iconType = .error
            title = I18n.View_G_InternetDisconnectRetry_Note
        case .iceDisconnected:
            iconType = .warning
            title = I18n.View_G_InternetUnstableReconnect_Note
        default:
            return nil
        }

        return TipInfo(content: title, iconType: iconType, type: .connectionNotice, isFromNotice: false, canCover: false, canClosedManually: false)
    }

}

extension InMeetTipViewModel: InMeetRtcNetworkListener {
    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        if status.networkType != .disconnected, status.networkShowStatus == .disconnected {
            return
        }
        self.updateNetworkTip()
    }
}

extension InMeetTipViewModel: InMeetAudioModeListener {
    func beginPstnCalling() {
        let tips = TipInfo(content: "\(I18n.View_MV_CallingFloat) \(meeting.setting.callmePhoneNumber)",
                           iconType: .phone, type: .callmePhone, isFromNotice: false, canCover: false, canClosedManually: false)
        self.showTipInfo(tips)
    }

    func closePstnCalling() {
        self.closeTipFor(type: .callmePhone)
    }
}

extension InMeetTipViewModel {
    func showCCMExternalPermChangedTip(operationBlock: (() -> Void)?, closeBlock: (() -> Void)?) {
        let tipInfo = TipInfo(content: I18n.View_G_TurnOffExternalSharing, iconType: .warning, type: .ccmExternalPermChange, isFromNotice: false, canCover: true, canClosedManually: true)
        tipInfo.operationButtonAction = operationBlock
        tipInfo.closeButtonAction = closeBlock
        self.showTipInfo(tipInfo)
    }

    func dismissCCMExternalPermChangedTip() {
        self.closeTipFor(type: .ccmExternalPermChange)
    }
}

extension VideoChatNotice {
    enum NoticeType {
        case maxParticipantLimit
        case maxDurationLimit
        case subtitleSettingJump
        case connectionNotice
        case autoRecordSettingJump
        case interviewerTipsAddDisappear
        case callmePhone
        case largeMeeting
        case ccmExternalPermChange // CCM 外部权限变更
        case other
    }

    var tipsIconType: TipInfo.IconType {
        if let iconType = extra["icon_type"] {
            if iconType == "info" {
                return .info
            } else if iconType == "warning" {
                return .warning
            } else if iconType == "error" {
                return .error
            }
        }
        return .info
    }

    var noticeType: NoticeType {
        if msgI18NKey?.type == .subtitleSettingJump {
            return .subtitleSettingJump
        }

        if msgI18NKey?.type == .autoRecordSettingJump {
            return .autoRecordSettingJump
        }
        if msgI18NKey?.type == .interviewerTipsAddDisappear {
            return .interviewerTipsAddDisappear
        }

        switch cmd {
        case 1:
            return .maxParticipantLimit
        default:
            return .other
        }
    }
}
