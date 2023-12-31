//
//  InMeetSubtitleViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/6/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import RxSwift
import RxCocoa
import ByteViewUI
import ByteViewSetting

protocol InMeetSubtitleViewModelObserver: AnyObject {
    /// 将要发送请求更改字幕开关
    func willSwitchSubtitle(to newIsSubtitleOn: Bool)
    func didOpenSubtitleView()
    func didReceiveSubtitle(_ subtitle: Subtitle)
    func didReceiveSubtitleStatusConfirmedData(_ statusData: SubtitleStatusData)
    func didUpdateAsrSubtitleStatus(_ status: AsrSubtitleStatus)
    func didChangeTranslationOn(_ isTranslationOn: Bool)
    func didChangeSpokenLanguage(_ language: String, oldValue: String?)
    func didChangeSubtitleLanguage(_ language: String, oldValue: String?)
    /// ToolBar 点击字幕按钮
    func didShowSubtitleActionSheet(sourceView: UIView)
    /// 收到新字幕重置字幕面板隐藏Timer
    func willRestTimer()
    /// 显示字幕
    func didShowSubtitlePanel()
    func phraseStatusDidChanged()
    func willCloseSubtitle()
}

extension InMeetSubtitleViewModelObserver {
    func willSwitchSubtitle(to newIsSubtitleOn: Bool) {}
    func didOpenSubtitleView() {}
    func didReceiveSubtitle(_ subtitle: Subtitle) {}
    func didReceiveSubtitleStatusConfirmedData(_ statusData: SubtitleStatusData) {}
    func didUpdateAsrSubtitleStatus(_ status: AsrSubtitleStatus) {}
    func didChangeTranslationOn(_ isTranslationOn: Bool) {}
    func didChangeSpokenLanguage(_ language: String, oldValue: String?) {}
    func didChangeSubtitleLanguage(_ language: String, oldValue: String?) {}
    func didShowSubtitleActionSheet(sourceView: UIView) {}
    func willRestTimer() {}
    func didShowSubtitlePanel() {}
    func phraseStatusDidChanged() {}
    func willCloseSubtitle() {}
}

final class InMeetSubtitleViewModel {
    private static let logger = Logger.subtitle
    private let meeting: InMeetMeeting
    let breakoutRoom: BreakoutRoomManager
    private let context: InMeetViewContext
    var lastAsrSubtitleStatus: AsrSubtitleStatus = .unknown
    var httpClient: HttpClient { meeting.httpClient }
    var isSubtitleAlignRight: Bool = false

    init(resolver: InMeetViewModelResolver) {
        self.context = resolver.viewContext
        self.meeting = resolver.meeting
        self.breakoutRoom = resolver.resolve()!
        self.phraseStatus = meeting.setting.subtitlePhraseStatus

        self.lastParticipantSettings = meeting.myself.settings

        if let info = meeting.data.inMeetingInfo, let isSubtitleOn = info.isSubtitleOn {
            self.isSubtitleOpenedInMeeting = isSubtitleOn
        }
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.addMyselfListener(self)
        meeting.push.extraInfo.addObserver(self)
        meeting.push.inMeetingChange.addObserver(self)
        meeting.setting.addComplexListener(self, for: .subtitlePhraseStatus)
        if #available(iOS 13.0, *) {
            VCSideBarSceneService.addProvider(self, for: sceneInfo)
        }
    }

    deinit {
        if #available(iOS 13.0, *) {
            VCSideBarSceneService.removeProvider(for: sceneInfo)
        }
    }

    private let observers = Listeners<InMeetSubtitleViewModelObserver>()
    func addObserver(_ observer: InMeetSubtitleViewModelObserver) {
        observers.addListener(observer)
    }

    func removeObserver(_ observer: InMeetSubtitleViewModelObserver) {
        observers.removeListener(observer)
    }

    // MARK: - subtitle settings
    /// 首次开启字幕时选择为全体参会人设置的默认语言
    private var isSpokenLanguageSelected = false
    private(set) var selectedSpokenLanguage: Subtitle.Language = .defaultLanguage
    private(set) var isTranslationOn: Bool = false
    private(set) var spokenLanguage: String?
    private(set) var subtitleLanguage: String?
    private var lastParticipantSettings: ParticipantSettings
    private var participantsCount: Int = 0
    private var isReuseAsrTask: Int = 0
    var isAllMuted: Bool {
        if participantsCount > 30 { return false }
        for participant in meeting.participant.activePanel.all {
            if !participant.settings.isMicrophoneMutedOrUnavailable {
                return false
            }
        }
        return true
    }

    private let disposeBag = DisposeBag()

    // 2022.3.18 增注：原注释如下，但从代码里赋值来看感觉不像
    /// 本场会议中是否开启过字幕，用于判断是否需要进行口说语言选择
    private var isSubtitleOpenedInMeeting = false
    ///   实时字幕是否可见
    var isSubtitleVisible: Bool?

    lazy var sceneInfo: SceneInfo = {
        var info = SceneInfo(key: SceneKey.vcSideBar, id: "subtitle_history_\(meeting.meetingId)")
        info.title = I18n.View_M_Subtitles
        return info
    }()
    private weak var sceneNaviVC: UINavigationController?

    @RwAtomic
    var phraseStatus: GetSubtitleSettingResponse.PhraseTranslationStatus = .on {
        willSet {
            if newValue != phraseStatus {
                DispatchQueue.main.async {
                    self.observers.forEach { $0.phraseStatusDidChanged() }
                }
            }
        }
    }

    private func updateEnterOrLeaveBreakoutRoom() {
        didChangeTranslationOn(false)
        self.isSubtitleVisible = false
        self.lastAsrSubtitleStatus = .unknown
    }

    private func update(_ settings: ParticipantSettings) {
        self.lastParticipantSettings = settings
        let selectableSpokenLanguages = self.meeting.setting.selectableSpokenLanguages
        if !isSpokenLanguageSelected && !settings.appliedSpokenLanguage.isEmpty {
            if let language = selectableSpokenLanguages.first(where: { $0.language == settings.appliedSpokenLanguage }) {
                selectedSpokenLanguage = language
            } else {
                // 兜底策略，默认设置为中文
                selectedSpokenLanguage = Subtitle.Language(language: "zh_cn", desc: I18n.View_G_Chinese)
            }
            isSpokenLanguageSelected = true
        }
        if let isOn = settings.isTranslationOn, isOn != isTranslationOn {
            didChangeTranslationOn(isOn)
        }
        if !settings.spokenLanguage.isEmpty, settings.spokenLanguage != self.spokenLanguage {
            didChangeSpokenLanguage(settings.spokenLanguage)
        }
        if !settings.subtitleLanguage.isEmpty, settings.subtitleLanguage != self.subtitleLanguage {
            didChangeSubtitleLanguage(settings.subtitleLanguage)
        }
    }

    func willSwitchSubtitle() {
        meeting.setting.refreshSubtitleSetting()
        observers.forEach { $0.willSwitchSubtitle(to: !isTranslationOn) }
    }

    func didOpenSubtitleView() {
        observers.forEach { $0.didOpenSubtitleView() }
    }

    func didShowSubtitleActionSheet(sourceView: UIView) {
        observers.forEach { $0.didShowSubtitleActionSheet(sourceView: sourceView) }
    }

    func willRestTimer() {
        observers.forEach { $0.willRestTimer() }
    }

    func didShowSubtitlePanel() {
        observers.forEach { $0.didShowSubtitlePanel() }
    }

    @available(iOS 13, *)
    func showSubtitleHistoryScene() {
        self.meeting.router.openByteViewScene(sceneInfo: sceneInfo,
                                              keepOpenForActivated: true,
                                              completion: nil)
    }

    @available(iOS 13, *)
    func closeHistroySceneIfNeeded() {
        let info = SceneInfo(key: SceneKey.vcSideBar, id: "subtitle_history")
        if VCScene.isConnected(scene: info) {
            VCScene.closeScene(info)
        }
    }

    private func didChangeTranslationOn(_ isTranslationOn: Bool) {
        self.isTranslationOn = isTranslationOn
        Logger.subtitle.info("Subtitle status changed: \(isTranslationOn)")
        if !isTranslationOn {
            hasReceivedSubtitle = false
            clearAsrBuffer()
            if #available(iOS 13, *), VCScene.supportsMultipleScenes {
                DispatchQueue.main.async {
                    self.closeHistroySceneIfNeeded()
                }
            }
        }
        observers.forEach { $0.didChangeTranslationOn(isTranslationOn) }
    }

    private func didChangeSpokenLanguage(_ language: String) {
        let oldValue = self.spokenLanguage
        self.spokenLanguage = language
        observers.forEach { $0.didChangeSpokenLanguage(language, oldValue: oldValue) }
    }

    private func didChangeSubtitleLanguage(_ language: String) {
        isSubtitleAlignRight = language == "ar"
        let oldValue = self.subtitleLanguage
        self.subtitleLanguage = language
        observers.forEach { $0.didChangeSubtitleLanguage(language, oldValue: oldValue) }
    }

    private func didUpdateAsrSubtitleStatus(_ status: AsrSubtitleStatus) {
        lastAsrSubtitleStatus = status

        switch status {
        case .openSuccessed(_, let isAllMuted):
            if isAllMuted {
                // 字幕耗时埋点：开启到当前无人发言计时上报：成功
                SubtitleTracksV2.endTrackSubtitleStartDuration(status: .success, type: .start_to_silence, exists: isReuseAsrTask)
                // 字幕耗时埋点：无人发言到首句字幕计时开始
                SubtitleTracksV2.startTrackSilenceToSubtitle()
            } else {
                // 字幕耗时埋点：开启到正在聆听计时上报：成功
                SubtitleTracksV2.endTrackSubtitleStartDuration(status: .success, type: .start_to_listen, exists: isReuseAsrTask)
                // 字幕耗时埋点：正在聆听到首句字幕计时开始
                SubtitleTracksV2.startTrackListenToSubtitle()
            }
        case .openFailed:
            // 字幕耗时埋点：开启到下一状态上报：失败
            SubtitleTracksV2.endTrackSubtitleStartDuration(status: .fail, type: .start_to_listen, exists: isReuseAsrTask)
            SubtitleTracksV2.endTrackSubtitleStartDuration(status: .fail, type: .start_to_silence, exists: isReuseAsrTask)
        case .translation:
            // 字幕耗时埋点：正在聆听/无人发言到首句字幕上报：成功
            SubtitleTracksV2.endTrackListenToSubtitleDuration(status: .success, type: .listen_to_subtitle)
            SubtitleTracksV2.endTrackSilenceToSubtitleDuration(status: .success, type: .silence_to_subtitle)
        default:
            break
        }
        observers.forEach { $0.didUpdateAsrSubtitleStatus(status) }
    }

    // MARK: - handleSubtitle
    private(set) var asrSubtitleBuffer: [Subtitle] = []
    private var hasReceivedSubtitle = false
    private var lastSubtitleData: MeetingSubtitleData?
    private func update(_ data: MeetingSubtitleData) {
        lastSubtitleData = data
        if data != lastSubtitleData, data.trackReceived {
            SubtitleTracks.trackReceiveSubtitle(segId: data.segID)
        }

        let participantService = httpClient.participantService
        participantService.participantInfo(pid: data.participantId, meetingId: meeting.meetingId) { [weak self] (ap) in
            guard let self = self else { return }
            self.appendSubtitleIfNeeded(Subtitle(data: data, meeting: self.meeting, name: ap.name, avatarInfo: ap.avatarInfo))
        }
    }

    // nolint-next-line: magic number
    private let sliceIDCache = MemoryCache(countLimit: 50 * 5, removeAllOnMemoryWarning: false)
    // 根据设备 ID 和 segID 分组。
    // 由于时序问题，服务端无法保证单个设备、不同的 segID 的情况下 sliceID 严格递增，因此需要针对 segID 维度进行过滤。
    private func appendSubtitleIfNeeded(_ subtitle: Subtitle) {
        if subtitle.data.subtitleType != .translation {
            didAppendSubtitle(subtitle)
            return
        }

        let key = subtitle.groupID
        let currentSliceId = subtitle.sliceID
        let lastSliceId = sliceIDCache.value(forKey: key, defaultValue: Int.min)
        if currentSliceId > lastSliceId {
            sliceIDCache.setValue(currentSliceId, forKey: key)
            didAppendSubtitle(subtitle)

            // 上报字幕上屏决策埋点
            if subtitle.trackArrival {
                SubtitleTracksV3.trackShouldShowSubtitle(seg_id: String(subtitle.segID),
                                                         slice_id: String(subtitle.sliceID),
                                                         display_time: Date().timeStamp,
                                                         decision: 0)
            }
        } else {
            Self.logger.info("Received outdated subtitle, speakerIdentifier = \(subtitle.speakerIdentifier), sliceID = \(subtitle.sliceID), segID = \(subtitle.segID)")

            // 上报字幕上屏决策埋点
            if subtitle.trackArrival {
                SubtitleTracksV3.trackShouldShowSubtitle(seg_id: String(subtitle.segID),
                                                         slice_id: String(subtitle.sliceID),
                                                         display_time: Date().timeStamp,
                                                         decision: 1)
            }
        }
    }

    private func didAppendSubtitle(_ subtitle: Subtitle) {
        if subtitle.data.event == nil {
            didAppendNoEventSubtitle(subtitle)
        }
        observers.forEach { $0.didReceiveSubtitle(subtitle) }
    }

    private func didAppendNoEventSubtitle(_ subtitle: Subtitle) {
        hasReceivedSubtitle = true

        let foundIndex = asrSubtitleBuffer.firstIndex { [subtitle] (item) -> Bool in
            return item.groupID == subtitle.groupID
        }
        if let index = foundIndex {
            asrSubtitleBuffer[index] = subtitle
        } else if !subtitle.isNoise {
            //  加一条新的字幕
            asrSubtitleBuffer.append(subtitle)
        }

        if self.asrSubtitleBuffer.count > 2 {
            self.asrSubtitleBuffer.removeFirst()
        }
        didUpdateAsrSubtitleStatus(.translation(subtitle))
        // 收到新字幕，重置字幕面板隐藏Timer
        willRestTimer()
    }

    private func clearAsrBuffer() {
        asrSubtitleBuffer.removeAll()
    }

    // MARK: - Subtitle Switch

    func toggleSubtitleSwitch(fromSource: String) {
        let switchSubtitleBlock = { [weak self] in
            self?.willSwitchSubtitle()
            self?.switchSubtitle()
        }

        if isTranslationOn {
            self.lastAsrSubtitleStatus = .unknown
            switchSubtitleBlock()
            SubtitleTracksV2.trackClickSubtitleClose(fromSource: fromSource)
            // 字幕耗时埋点 上报：关闭
            SubtitleTracksV2.endTrackSubtitleStartDuration(status: .close, type: .start_to_listen, exists: isReuseAsrTask)
            SubtitleTracksV2.endTrackSubtitleStartDuration(status: .close, type: .start_to_silence, exists: isReuseAsrTask)
            SubtitleTracksV2.endTrackListenToSubtitleDuration(status: .close, type: .listen_to_subtitle)
            SubtitleTracksV2.endTrackSilenceToSubtitleDuration(status: .close, type: .silence_to_subtitle)
            return
        }

        SubtitleTracksV2.trackOpenSubtitles(isAutoOpen: false)
        // 仅在字幕未开启时作套餐判断
        if self.meeting.setting.hasSubtitleQuota {
            Util.runInMainThread(switchSubtitleBlock)
        }
    }

    private func switchSubtitle() {
        /// 用户点击“开启字幕”，如果是首位开启字幕的用户，选择语言，点击取消则不开启，点击确定后同步语言给其他用户，弹出是否同意录制本次会议
        if isTranslationOn {
            // 关闭 subtitle，直接发请求
            doSwitchSubtitle(enableRecord: nil)
            return
        }

        let enableSpokenLanguage = meeting.setting.isSpokenLanguageSettingsEnabled
        let enableAudioRecordForSubtitle = meeting.setting.isAudioRecordEnabledForSubtitle

        if enableSpokenLanguage, !isSubtitleOpenedInMeeting {
            showSubtitleSpokenLanguageSettingsAlert { [weak self] isOn in
                guard let self = self else { return }

                if enableAudioRecordForSubtitle {
                    if isOn {
                        self.showRecordAudioConfirmedAlert { enableRecord in
                            SubtitleTracks.trackEnableAudioRecord(enableRecord)
                            self.doSwitchSubtitle(enableRecord: enableRecord)
                        }
                    } else {
                        self.doSwitchSubtitle(enableRecord: nil)
                    }
                } else {
                    self.doSwitchSubtitle(enableRecord: isOn)
                }

            }
        } else if enableAudioRecordForSubtitle {
            self.showRecordAudioConfirmedAlert { enableRecord in
                SubtitleTracks.trackEnableAudioRecord(enableRecord)
                self.doSwitchSubtitle(enableRecord: enableRecord)
            }
        } else {
            doSwitchSubtitle(enableRecord: nil)
        }
    }

    private func doSwitchSubtitle(enableRecord: Bool?) {
        let newValue = !isTranslationOn
        if newValue {
            didOpenSubtitleView()
        }
        /// 发送开启/关闭字幕请求
        var request = ParticipantChangeSettingsRequest(meeting: meeting)
        request.participantSettings.isTranslationOn = newValue
        request.participantSettings.enableSubtitleRecord = enableRecord
        httpClient.send(request)
        if !isTranslationOn {
            SubtitleTracksV2.startTrackSubtitleStartDuration()
        }
    }

    // MARK: - Alert

    private func showSubtitleSpokenLanguageSettingsAlert(callback: @escaping ((Bool) -> Void)) {
        SubtitleAlertUtil.showSelectLanguageAlert(router: meeting.router, context: context, selectedLanguage: selectedSpokenLanguage,
                                                  selectableSpokenLanguages: meeting.setting.selectableSpokenLanguages,
                                                  completion: { [weak self] lang in
            if let self = self, let language = lang?.language {
                var request = HostManageRequest(action: .applyGlobalSpokenLanguage, meetingId: self.meeting.meetingId)
                request.globalSpokenLanguage = language
                self.httpClient.send(request)
                callback(true)
            } else {
                callback(false)
            }
        }, alertGenerationCallback: nil)
    }

    private func showRecordAudioConfirmedAlert(callback: @escaping ((Bool) -> Void)) {
        ByteViewDialog.Builder()
            .id(.recordMeetingAudio)
            .title(I18n.View_VM_AllowUsToUseAudio)
            .message(I18n.View_VM_AllowUsToUseAudioDescriptionNew)
            .leftTitle(I18n.View_VM_NoButton)
            .leftHandler({ _ in callback(false) })
            .rightTitle(I18n.View_G_OkButton)
            .rightHandler({ _ in callback(true) })
            .needAutoDismiss(true)
            .show()
    }
}

@available(iOS 13, *)
extension InMeetSubtitleViewModel: VCSideBarSceneProvider {
    func createViewController(scene: UIScene,
                              session: UISceneSession,
                              options: UIScene.ConnectionOptions,
                              sceneInfo: SceneInfo,
                              localContext: AnyObject?) -> UIViewController?
    {
        if sceneInfo != self.sceneInfo {
            return nil
        }
        let naviVC: UINavigationController
        if let vc = sceneNaviVC {
            naviVC = vc
        } else {
            let vm = SubtitlesViewModel(meeting: meeting, subtitle: self)
            let viewController = SubtitleHistoryViewController(viewModel: vm)
            viewController.subtitle = self
            viewController.isSubtitleScene = true

            viewController.closeHistoryBlock = { [weak self] in
                guard let self = self, VCScene.isConnected(scene: self.sceneInfo) else { return }
                VCScene.closeScene(self.sceneInfo)
                self.sceneNaviVC = nil
                self.isSubtitleVisible = true
                self.observers.forEach { $0.didChangeTranslationOn(self.isTranslationOn) }
            }
            viewController.closeSubtitleBlock = { [weak self] in
                guard let self = self, VCScene.isConnected(scene: self.sceneInfo) else { return }
                VCScene.closeScene(self.sceneInfo)
                self.sceneNaviVC = nil
                if self.isTranslationOn {
                    self.toggleSubtitleSwitch(fromSource: "realtime_subtitle")
                }
                self.observers.forEach { $0.willCloseSubtitle() }
            }
            naviVC = NavigationController(rootViewController: viewController)
            sceneNaviVC = naviVC
        }
        return naviVC
    }
}

extension InMeetSubtitleViewModel: MeetingComplexSettingListener {
    func didChangeComplexSetting(_ settings: MeetingSettingManager, key: MeetingComplexSettingKey, value: Any, oldValue: Any?) {
        if key == .subtitlePhraseStatus {
            self.phraseStatus = settings.subtitlePhraseStatus
        }
    }
}

extension InMeetSubtitleViewModel: InMeetDataListener, VideoChatExtraInfoPushObserver, InMeetingChangedInfoPushObserver, MyselfListener, InMeetParticipantListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        if let oldValue = oldValue, myself.breakoutRoomId != oldValue.breakoutRoomId {
            updateEnterOrLeaveBreakoutRoom()
        }
        if myself.settings != lastParticipantSettings {
            update(myself.settings)
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if let isSubtitleOn = inMeetingInfo.isSubtitleOn {
            isSubtitleOpenedInMeeting = isSubtitleOn
        }
    }

    func didReceiveExtraInfo(_ message: VideoChatExtraInfo) {
        if message.type == .subtitle, let subtitle = message.subtitle, subtitle.meetingID == self.meeting.meetingId {
            update(subtitle)
        }
    }

    func didReceiveInMeetingChangedInfo(_ data: InMeetingData) {
        if data.meetingID == meeting.meetingId, data.type == .subtitleStatusConfirmed, let statusData = data.subtitleStatusData {
            let status = statusData.status
            // udate isReuseAsrTask
            if let reuseAsrTask = statusData.monitor.reuseAsrTask {
                self.isReuseAsrTask = reuseAsrTask ? 1 : 0
            }
            // update asr
            if status != .openSuccess && status != .unknown {
                didUpdateAsrSubtitleStatus(status.asrSubtitleStatus)
            }
            if status == .openSuccess {
                pushMessage()
            }
            observers.forEach { $0.didReceiveSubtitleStatusConfirmedData(statusData) }
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        participantsCount = output.sumCount
    }

    func pushMessage() {
        didUpdateAsrSubtitleStatus(.openSuccessed(isRecover: hasReceivedSubtitle, isAllMuted: self.isAllMuted))
    }
}

private struct ParticipantProfileInfo {
    let name: String
    let avatarInfo: AvatarInfo
}

extension Date {
    var timeStamp: String {
        String(CLongLong(round(self.timeIntervalSince1970 * 1000)))
    }
}
