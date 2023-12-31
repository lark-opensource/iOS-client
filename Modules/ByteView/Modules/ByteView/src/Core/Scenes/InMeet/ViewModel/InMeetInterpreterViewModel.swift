//
//  InMeetInterpreterViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/5/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting
import UniverseDesignIcon

protocol InMeetInterpreterViewModelObserver: AnyObject {
    /// 收听的传译频道变更
    func interprationDidChangeSelectedChannel(_ channel: LanguageType, oldValue: LanguageType)
    /// 自己的传译设置变更
    func selfInterpreterSettingDidChange(_ setting: InterpreterSetting?)
    /// 白板状态变更（zooming，draging)，需要降低透明度
    func whiteboardOperateStatus(isOpaque: Bool)
}

extension InMeetInterpreterViewModelObserver {
    func interprationDidChangeSelectedChannel(_ channel: LanguageType, oldValue: LanguageType) {}

    func selfInterpreterSettingDidChange(_ setting: InterpreterSetting?) {}

    func whiteboardOperateStatus(isOpaque: Bool) {}
}

final class InMeetInterpreterViewModel: InMeetDataListener, InMeetRtcNetworkListener, MyselfListener, MeetingSettingListener, InMeetViewChangeListener, InMeetParticipantListener {
    static let logger = Logger.ui

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    var isPhoneLandscape: Bool = VCScene.isPhoneLandscape

    private let supportLanguagesRelay: BehaviorRelay<[LanguageType]>
    private(set) lazy var supportLanguagesObservable = supportLanguagesRelay.asObservable()

    /// 用户当前收听的传译频道
    private(set) var selectedChannel: LanguageType = .main

    // 用户当前收听的传译频道上是否有未静音的传译员
    @RwAtomic
    private var hasActiveInterpreterOnSelectedChannel: Bool = false

    private func updateActiveInterpreter(completion: (() -> Void)? = nil) {
        let hasActiveInterpreter = self.interpreters
            .filter { !$0.settings.isMicrophoneMuted }
            .filter { $0.settings.interpreterSetting?.interpretingLanguage == self.selectedChannel }
            .first != nil
        if self.hasActiveInterpreterOnSelectedChannel != hasActiveInterpreter {
            self.hasActiveInterpreterOnSelectedChannel = hasActiveInterpreter
            completion?()
        }
    }

    /// 是否静音传译主频道
    private(set) var isOriginChannelMuted = false

    private var isOpenInterpretation: Bool
    private var setting: InterpreterSetting?
    private var interpreters: [Participant]
    private var supportLanguages: [LanguageType]
    private weak var confirmAlert: ByteViewDialog?
    private var isRtcReady = false
    private var publishingChannelId: String?
    private var isInterpreterChecked = false
    private var httpClient: HttpClient { meeting.httpClient }

    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
        self.interpreters = meeting.participant.currentRoom.nonRingingDict.map(\.value).onTheCallInterpreter
        self.isOpenInterpretation = meeting.setting.isMeetingOpenInterpretation
        self.supportLanguages = meeting.setting.meetingSupportLanguages
        self.supportLanguagesRelay = .init(value: supportLanguages)
        self.updateActiveInterpreter()
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.addMyselfListener(self)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
        if meeting.rtc.network.reachableState == .connected {
            isRtcReady = true
        } else {
            meeting.rtc.network.addListener(self)
        }
        context.addListener(self, for: .whiteboardOperateStatus)
    }

    deinit {
        confirmAlert?.dismiss()
        GuideManager.shared.dismissGuide(with: .interpretation)
    }

    private let observers = Listeners<InMeetInterpreterViewModelObserver>()

    func addObserver(_ observer: InMeetInterpreterViewModelObserver, fireImmediately: Bool = false) {
        observers.addListener(observer)
        if fireImmediately {
            observer.selfInterpreterSettingDidChange(setting)
        }
    }

    func removeObserver(_ observer: InMeetInterpreterViewModelObserver) {
        observers.removeListener(observer)
    }

    func checkInterpreterIfNeeded() {
        if isInterpreterChecked { return }
        isInterpreterChecked = true
        if let setting = meeting.myself.settings.interpreterSetting, setting.confirmStatus == .waitConfirm {
            showConfirmAlert(setting)
        }
    }

    // 传译员正在翻译的传译频道
    func selectInterpretingChannel(_ channel: LanguageType) {
        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.earlyPush = false
        request.participantSettings.interpreterSetting = UpdatingInterpreterSetting(interpretingLanguage: channel)
        httpClient.send(request)
        publishChannel(channel.channelId)
    }

    func selectSubscribeChannel(_ channel: LanguageType) {
        Self.logger.debug("interpretation selectedChannel: \(channel.channelId)")
        if !isSupportedChannel(channel) {
            handleUnsupportedChannel()
            return
        }
        if channel != selectedChannel {
            let oldValue = selectedChannel
            selectedChannel = channel
            updateActiveInterpreter()
            updateSubscribeChannelIfNeeded()
            observers.forEach { $0.interprationDidChangeSelectedChannel(channel, oldValue: oldValue) }
        }
    }

    func muteOriginChannel(_ isMuted: Bool) {
        Self.logger.debug("interpretation mute: \(isMuted)")
        if isMuted != isOriginChannelMuted {
            isOriginChannelMuted = isMuted
            updateSubscribeChannelIfNeeded()
        }
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let setting = myself.settings.interpreterSetting
        if setting != self.setting {
            let oldValue = self.setting
            self.setting = setting
            observers.forEach { $0.selfInterpreterSettingDidChange(setting) }
            guard let setting = setting else {
                let channel: LanguageType = .main
                Self.logger.debug("interpretation defaultInterpretingChannel: \(channel.channelId)")
                publishChannel(channel.channelId)
                return
            }
            if setting.confirmStatus == .waitConfirm {
                showConfirmAlert(setting)
            }
            let lastUserConfirm = oldValue?.isUserConfirm ?? false
            if setting.isUserConfirm != lastUserConfirm {
                let channel = setting.isUserConfirm ? setting.interpretingLanguage : .main
                Self.logger.debug("interpretation defaultInterpretingChannel: \(channel.channelId)")
                publishChannel(channel.channelId)
            }
        }
        if let setting = setting, setting.isUserConfirm {
            // 当前参会人如果是译员，不显示传译tip
            GuideManager.shared.dismissGuide(with: .interpretation)
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        let value = output.newData.nonRingingDict.filter { $0.value.settings.interpreterSetting?.userIsOnTheCall ?? false }.map(\.value)
        if value != interpreters {
            let oldInterpreters = interpreters
            interpreters = value
            updateActiveInterpreter { [weak self] in
                self?.updateSubscribeChannelIfNeeded(isActiveInterpreterChange: true)
            }
            let oldOnTheCall = output.oldData.nonRingingDict.map(\.value)
            showOnlineOfflineToast(value, oldValue: oldInterpreters, lastOnTheCallParticipants: oldOnTheCall)
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        let isOpenInterpretation = inMeetingInfo.meetingSettings.isMeetingOpenInterpretation
        if isOpenInterpretation != self.isOpenInterpretation {
            self.isOpenInterpretation = isOpenInterpretation
            if !isOpenInterpretation {
                dismissConfirmAlert()
            }
            if isOpenInterpretation {
                self.meeting.isInterprationGuideShowed = false
            }
            // 传译状态变更
            Self.logger.info("Interpretation status changed: \(isOpenInterpretation)")
        }
        let supportLanguages = inMeetingInfo.meetingSettings.meetingSupportLanguages
        if supportLanguages != self.supportLanguages {
            self.supportLanguages = supportLanguages
            supportLanguagesRelay.accept(supportLanguages)
            if !isSupportedChannel(selectedChannel) {
                handleUnsupportedChannel()
            }
        }
        // Check Guide
        let hasSupportLanguages = !inMeetingInfo.meetingSettings.meetingSupportLanguages.isEmpty
        if hasSupportLanguages {
            Util.runInMainThread { [weak self] in
                guard let self = self else { return }
                self.showInterpretationGuide()
            }
        } else {
            GuideManager.shared.dismissGuide(with: .interpretation)
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority, isOn {
            // 当管理权限变更时（被转移为联席or主持人），同步VideoChatInMeetingInfo中的会前传译员信息
            meeting.data.triggerInMeetingInfo()
        }
    }

    func didChangeRtcReachableState(_ state: InMeetRtcReachableState) {
        guard !meeting.data.isInBreakoutRoom else { return } // 讨论组无同传
        if state == .connected, !isRtcReady {
            isRtcReady = true
            if let channelId = publishingChannelId {
                publishChannel(channelId)
            }
            updateSubscribeChannelIfNeeded()
            meeting.rtc.network.removeListener(self)
        }
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .whiteboardOperateStatus, let isOpaque = userInfo as? Bool {
            observers.forEach { $0.whiteboardOperateStatus(isOpaque: isOpaque) }
        }
    }

    private func isSupportedChannel(_ channel: LanguageType) -> Bool {
        return channel == .main || supportLanguages.contains(channel)
    }

    private func handleUnsupportedChannel() {
        selectSubscribeChannel(.main)
        if !self.meeting.setting.hasHostAuthority {
            Toast.show(I18n.View_G_ChannelClosedOriginalAudio)
        }
    }

    // 传译员上线/离线提醒
    private func showOnlineOfflineToast(_ interpreters: [Participant], oldValue: [Participant], lastOnTheCallParticipants: [Participant]) {
        guard let w = meeting.router.window, !w.isFloating else {
            return
        }
        let interpreterIds = Set(interpreters.map { $0.identifier })
        let onTheCallIds = Set(meeting.participant.global.nonRingingDict.keys)
        let idledInterpreters = oldValue.compactMap { (p) -> ParticipantId? in
            if p.settings.interpreterSetting?.confirmStatus != .confirmed {
                return nil
            }
            let id = p.identifier
            if interpreterIds.contains(id) || onTheCallIds.contains(p.user) {
                return nil
            }
            return p.participantId
        }
        let lastOnTheCallIds = Set(lastOnTheCallParticipants.map { $0.user.id })
        let newInterpreters = interpreters.compactMap { p -> ParticipantId? in
            if lastOnTheCallIds.contains(p.user.id) {
                return nil
            }
            return p.participantId
        }
        let participantService = meeting.httpClient.participantService
        if !idledInterpreters.isEmpty, meeting.setting.canEditInterpreter {
            // 离线
            participantService.participantInfo(pids: idledInterpreters, meetingId: meeting.meetingId, completion: { [weak self] aps in
                if let self = self, let w = self.meeting.router.window, !w.isFloating {
                    let nameText = aps.map { $0.name }.joined(separator: I18n.View_G_EnumerationComma)
                    Toast.show(I18n.View_G_NameInterpreterLeft(nameText))
                }
            })
        }
        if !newInterpreters.isEmpty, meeting.setting.canEditInterpreter {
            // 上线
            participantService.participantInfo(pids: newInterpreters, meetingId: meeting.meetingId, completion: { [weak self] aps in
                if let self = self, let w = self.meeting.router.window, !w.isFloating {
                    let nameText = aps.map { $0.name }.joined(separator: I18n.View_G_EnumerationComma)
                    Toast.show(I18n.View_G_NameInterpreterJoined(nameText))
                }
            })
        }
    }

    private func showConfirmAlert(_ setting: InterpreterSetting) {
        let keys = [setting.firstLanguage.despI18NKey, setting.secondLanguage.despI18NKey]
        httpClient.i18n.get(keys) { [weak self] (result) in
            if let i18n = result.value {
                Util.runInMainThread {
                    self?.popConfirmInterpreterPopup(setting, i18n: i18n)
                }
            }
        }
    }

    private func dismissConfirmAlert() {
        confirmAlert?.dismiss()
        confirmAlert = nil
    }

    private func popConfirmInterpreterPopup(_ setting: InterpreterSetting, i18n: [String: String]) {
        Self.logger.debug("Popup interpreter confirm popver.")
        dismissConfirmAlert()
        let textTop: CGFloat = 2
        let textMarginInterpreter: CGFloat = 12
        let interpreterBottom: CGFloat = 6
        let interpreterHeight: CGFloat = 44
        let left: CGFloat = 20
        let contentView = UIView()
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: I18n.View_G_AssignedAsInterpreter, config: .body, alignment: .center)
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(left)
            make.top.equalTo(textTop)
            make.centerX.equalToSuperview()
        }
        let labelHeight: CGFloat = label.attributedText?.boundingRect(with: CGSize(width: ByteViewDialog.calculatedContentWidth() - left * 2, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil).height ?? 0
        let defaultDescription = I18n.View_G_SelectLanguage
        let adaptsLandscapeLayout = false
        let popupWidth = ByteViewDialog.calculatedContentWidth(adaptsLandscapeLayout: adaptsLandscapeLayout)
        let switchIconWidth = 11.0
        let switchOffsetLanguage = 14.0
        let infomationWidth = (popupWidth - 2 * switchOffsetLanguage - switchIconWidth) / 2.0
        let firstWidth = InterpreterInformationView.maxWidthWithLanguageIcon(i18n[setting.firstLanguage.despI18NKey] ?? defaultDescription)
        let secondWidth = InterpreterInformationView.maxWidthWithLanguageIcon(i18n[setting.secondLanguage.despI18NKey] ?? defaultDescription)
        let showIcon = firstWidth < infomationWidth && secondWidth < infomationWidth
        let firstInterpreterView = InterpreterInformationView()
        firstInterpreterView.isUserInteractionEnabled = false
        firstInterpreterView.descriptionLabel.text = i18n[setting.firstLanguage.despI18NKey, default: defaultDescription]
        firstInterpreterView.config(with: InterpreterInformation(languageType: setting.firstLanguage), showIcon: showIcon, httpClient: httpClient)
        contentView.addSubview(firstInterpreterView)
        firstInterpreterView.snp.makeConstraints { (make) in
            make.top.equalTo(label.snp.bottom).offset(textMarginInterpreter)
            make.left.equalToSuperview()
            make.right.equalTo(contentView.snp.centerX).offset(-switchOffsetLanguage)
            make.height.equalTo(interpreterHeight)
            make.bottom.equalTo(-interpreterBottom)
        }
        let secondInterpreterView = InterpreterInformationView()
        secondInterpreterView.isUserInteractionEnabled = false
        secondInterpreterView.descriptionLabel.text = i18n[setting.secondLanguage.despI18NKey, default: defaultDescription]
        secondInterpreterView.config(with: InterpreterInformation(languageType: setting.secondLanguage), showIcon: showIcon, httpClient: httpClient)
        contentView.addSubview(secondInterpreterView)
        secondInterpreterView.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(firstInterpreterView)
            make.left.equalTo(contentView.snp.centerX).offset(switchOffsetLanguage)
            make.right.equalToSuperview()
        }

        let switchIcon = UIImageView(image: UDIcon.getIconByKey(.switchOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12)))
        contentView.addSubview(switchIcon)
        switchIcon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(firstInterpreterView.snp.centerY)
            make.width.equalTo(switchIconWidth)
        }
        ByteViewDialog.Builder()
            .id(.interpreterConfirm)
            .title(I18n.View_G_Welcome)
            .contentView(contentView)
            .contentHeight(textTop + ceil(labelHeight) + textMarginInterpreter + interpreterHeight + interpreterBottom)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self] (_) in
                guard let self = self else { return }
                var request = ParticipantChangeSettingsRequest(meeting: self.meeting)
                request.participantSettings.interpreterSetting = UpdatingInterpreterSetting(confirmStatus: .confirmed)
                self.httpClient.send(request)
                InterpreterTrack.setInterpreter(uid: self.meeting.userId, deviceId: self.meeting.account.deviceId)
            })
            .needAutoDismiss(true)
            .adaptsLandscapeLayout(adaptsLandscapeLayout)
            .show { [weak self] alert in
                if let self = self {
                    self.confirmAlert = alert
                } else {
                    alert.dismiss()
                }
            }
    }

    private func publishChannel(_ channelId: String) {
        if isRtcReady {
            meeting.rtc.engine.setPublishChannel(channelId: channelId)
            publishingChannelId = nil
        } else {
            publishingChannelId = channelId
        }
    }

    private func updateSubscribeChannelIfNeeded(isActiveInterpreterChange: Bool = false) {
        guard isRtcReady else {
            return
        }

        meeting.rtc.engine.toggleRescaleAudioVolume(enable: hasActiveInterpreterOnSelectedChannel)

        // 7.8 新需求 - 由译员说话触发时，只有静音下才更新频道订阅
        guard !isActiveInterpreterChange || isOriginChannelMuted else {
            return
        }

        let channelId = selectedChannel.channelId
        Self.logger.info("Interpretation channel changed: \(channelId), isMuteOrigin: \(isOriginChannelMuted), hasActiveInterpreterOnSelectedChannel: \(hasActiveInterpreterOnSelectedChannel)")
        let mainChannelId = LanguageType.main.channelId
        var channelIds = [mainChannelId]
        if channelId != mainChannelId {
            // 收听传译频道需要同时订阅主频道
            // 3.43 新需求 - 如果是其他频道并且静音就不需要主频道
            // 7.8 新需求 - 如果静音下译员未说话或者没有译员也开启主频道
            if isOriginChannelMuted, hasActiveInterpreterOnSelectedChannel {
                channelIds = [channelId]
            } else {
                channelIds = [mainChannelId, channelId]
            }
        }
        meeting.rtc.engine.setSubChannels(channelIds)
    }

    private var needsToShowInterpreterGuide: Bool {
        let isOpenInterpretation = meeting.setting.isMeetingOpenInterpretation
        let isInterperter = meeting.myself.settings.interpreterSetting?.confirmStatus == .confirmed || meeting.myself.settings.interpreterSetting?.confirmStatus == .waitConfirm
        // iPhone共享横屏时不显示
        let canShow = Display.pad || (!isPhoneLandscape && !meeting.shareData.isSharingContent)
        Self.logger.info("Current participant isUserConfirm = \(isInterperter), canShow = \(canShow) when needs to show guide")
        return isOpenInterpretation && !isInterperter && !meeting.isInterprationGuideShowed && canShow
    }

    private func showInterpretationGuide() {
        guard needsToShowInterpreterGuide else { return }
        let guide = GuideDescriptor(type: .interpretation, title: nil, desc: I18n.View_G_InterpretingSelectChannel)
        guide.style = .darkPlain
        guide.duration = 6
        GuideManager.shared.request(guide: guide)
        meeting.isInterprationGuideShowed = true
    }
}

extension LanguageType {
    var channelId: String {
        return languageType
    }

    static var main: LanguageType {
        LanguageType.init(languageType: mainType, despI18NKey: mainI18nKey, iconStr: mainIconStr)
    }

    private static var mainType: String {
        return "main"
    }

    private static var mainI18nKey: String {
        return "View_VM_PermissionsOffNew"
    }

    private static var mainIconStr: String {
        return ""
    }

    static var mainTitle: NSAttributedString {
        return NSAttributedString(string: I18n.View_VM_PermissionsOffNew, config: .body)
    }

    var isMain: Bool {
        return channelId == Self.main.channelId
    }
}
