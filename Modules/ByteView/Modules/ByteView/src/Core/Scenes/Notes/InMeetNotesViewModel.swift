//
//  InMeetNotesViewModel.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting
import ByteViewUI

/// 会议纪要变化，代理给NotesVC处理
protocol InMeetNotesChangeDelegate: AnyObject {
    /// 会议纪要变化
    func didChangeNotes(to runtime: NotesRuntime?)
    /// 点击了快捷共享按钮
    func didTapQuickShareButton()
}

extension InMeetNotesChangeDelegate {
    func didChangeNotes(to runtime: NotesRuntime?) {}
    func didTapQuickShareButton() {}
}

/// 会议纪要事件，代理给NotesContainerVC处理
protocol InMeetNotesEventDelegate: AnyObject {
    /// 点击纪要页面的关闭按钮
    func didTapCloseButtonNotesEvent()
}

extension InMeetNotesEventDelegate {
    func didTapCloseButtonNotesEvent() {}
}

final class InMeetNotesViewModel: InMeetNotesDataListener, MeetingSettingListener, NotesRuntimeDelegate, InMeetDataListener, InMeetShareDataListener {

    /// agendaReady后，如果文档存在评论，web会额外调用一次dismiss导致提示消失，临时加延迟解决
    static let durationAfterAgendaReady: CGFloat = 5.0

    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver

    var isHostOrCohost: Bool {
        didSet {
            if isHostOrCohost != oldValue {
                Logger.notes.info("update isHostOrCohost to: \(isHostOrCohost)")
                updateNotesMeetingInfo()
            }
        }
    }

    var canQuickShare: Bool = false {
        didSet {
            if canQuickShare != oldValue {
                Logger.notes.info("update canQuickShare to: \(canQuickShare)")
                currentNotesRuntime?.setQuickShareButtonHidden(false, isTapEnabled: canQuickShare)
            }
        }
    }

    /// 会议是否开启“在纪要文档中生成智能会议纪要”
    let inMeetGenerateMeetingSummaryInDocs: Bool

    var notesHttpClient: NotesNetworkAPI { meeting.httpClient.notes }

    weak var notesChangeDelegate: InMeetNotesChangeDelegate?

    lazy var notesDocumentFactory: NotesDocumentFactory = self.meeting.service.ccm.createNotesDocumentFactory()

    var currentNotesRuntime: NotesRuntime?

    weak var notesEventDelegate: InMeetNotesEventDelegate?

    init(meeting: InMeetMeeting, resolver: InMeetViewModelResolver) {
        self.isHostOrCohost = (meeting.myself.isHost || meeting.myself.isCoHost) || (meeting.type == .call)
        self.meeting = meeting
        self.resolver = resolver
        self.inMeetGenerateMeetingSummaryInDocs = meeting.setting.inMeetGenerateMeetingSummaryInDocs
    }

    deinit {
        Logger.notes.info("InMeetNotesVM.deinit")
    }

    func startDataObservation() {
        self.meeting.notesData.addListener(self)
        self.meeting.setting.addListener(self, for: [.hasCohostAuthority, .canShareContent, .canReplaceShareContent])
        self.meeting.data.addListener(self)
        self.meeting.shareData.addListener(self)
        updateCanQuickShare()
    }

    private func updateCanQuickShare() {
        self.canQuickShare = {
            if meeting.setting.onlyHostCanShare, !isHostOrCohost {
                return false
            } else if meeting.shareData.isSharingContent, meeting.setting.onlyHostCanReplaceShare, !isHostOrCohost {
                return false
            } else {
                return true
            }
        }()
        Logger.notes.info("update canQuickShare to: \(canQuickShare)")
        currentNotesRuntime?.setQuickShareButtonHidden(false, isTapEnabled: true)
    }

    // MARK: - InMeetNotesDataListener

    func didChangeNotesInfo(_ notes: NotesInfo?, oldValue: NotesInfo?) {
        Logger.notes.info("did change notes info to: \(notes), from: \(oldValue)")
        Util.runInMainThread { [weak self] in
            self?.updateNotesInfoOnMainThread(notes, oldValue: oldValue)
        }
    }

    func didHintNotesPermission(_ content: String) {
        Logger.notes.info("NotesVM.didHintNotesPermission, content: \(content)")
        currentNotesRuntime?.showNotesPermissionHint(content)
    }

    // MARK: - MeetingSettingListener

    func didChangeMeetingSetting(_ settings: ByteViewSetting.MeetingSettingManager, key: ByteViewSetting.MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority {
            isHostOrCohost = isOn || (meeting.type == .call)
            updateCanQuickShare()
        }
        if key == .canShareContent {
            updateCanQuickShare()
        }
        if key == .canReplaceShareContent {
            updateCanQuickShare()
        }
    }

    // MARK: - NotesRuntimeDelegate

    func notesRuntime(_ notesRuntime: NotesRuntime, onInvoke data: [String: Any]?, callback: NotesInvokeCallBack?) {
        Logger.notes.info("notes runtime onInvoke")
        if let validData = data, let command = validData[InMeetNotesKeyDefines.Params.command] as? String {
            Logger.notes.info("notes runtime onInvoke, command: \(command), validData: \(validData)")
            updateCanQuickShare()
            switch command {
            case InMeetNotesKeyDefines.Event.agendaReady:
                updateNotesMeetingInfo()
                if let notesInfo = meeting.notesData.notesInfo {
                    updateNotesAgendaInfo(with: notesInfo)
                }
                if meeting.shouldShowPermissionHint,
                   let content = meeting.permissionHintContent,
                   !content.isEmpty {
                    // agendaReady后，如果文档存在评论，web会额外调用一次dismiss导致提示消失。临时加延迟解决，CCM在计划修复了，后续会删掉#tbd:liurundong.henry
                    DispatchQueue.main.asyncAfter(deadline: .now() + Self.durationAfterAgendaReady) { [weak self] in
                        guard let self = self, self.meeting.shouldShowPermissionHint else { return }
                        self.currentNotesRuntime?.showNotesPermissionHint(content)
                    }
                }
            case InMeetNotesKeyDefines.Event.track:
                if let payload = validData[InMeetNotesKeyDefines.Params.payload] as? [String: Any],
                   let eventName = payload[InMeetNotesKeyDefines.Params.eventName] as? String,
                   let params = payload[InMeetNotesKeyDefines.Params.params] as? [String: Any] {
                    NotesTracks.trackPassThroughEvents(eventName, params: params)
                }
            case InMeetNotesKeyDefines.Event.closePermissionTips:
                if let payload = validData["payload"] as? [String: Any], let action = payload["action"] as? String, action == "openPermissionSetting" {
                    notesRuntime.openPermissionSettings()
                    return
                }
                meeting.shouldShowPermissionHint = false
            case InMeetNotesKeyDefines.Event.startRecording:
                clickRecord()
            case InMeetNotesKeyDefines.Event.notesReady:
                updateNotesMeetingInfo()
            case InMeetNotesKeyDefines.Event.getAIInfo:
                callback?(generateAIInfoCallback(), nil)
            case InMeetNotesKeyDefines.Event.startMagicShare:
                notesChangeDelegate?.didTapQuickShareButton()
                if let payload = validData["payload"] as? [String: Any], let fileUrl = payload["url"] as? String {
                    NotesTracks.trackClickNotesQuickMagicShareWithUrl(fileUrl.vc.removeParams())
                }
            default:
                break
            }
        }
    }

    func notesRuntime(_ notesRuntime: NotesRuntime, onEvent event: NotesDocumentEvent) {
        Logger.notes.info("notes runtime onEvent: \(event)")
        if case .onNavigationItemClick(let item) = event {
            switch item {
            case InMeetNotesKeyDefines.NavigationBarItem.close:
                NotesTracks.trackClickNotesNavigationBar(on: .close)
                notesEventDelegate?.didTapCloseButtonNotesEvent()
            case InMeetNotesKeyDefines.NavigationBarItem.more:
                NotesTracks.trackClickNotesNavigationBar(on: .more)
            case InMeetNotesKeyDefines.NavigationBarItem.notification:
                NotesTracks.trackClickNotesNavigationBar(on: .notification)
            case InMeetNotesKeyDefines.NavigationBarItem.share:
                NotesTracks.trackClickNotesNavigationBar(on: .share)
            default:
                break
            }
        }
    }

    func notesRuntime(_ notesRuntime: NotesRuntime, onOperation operation: NotesDocumentOperation) -> Bool {
        Logger.notes.info("notes runtime onOperation: \(operation)")
        return false
    }

    // MARK: - InMeetDataListener

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        let isRecording = inMeetingInfo.isRecording
        let isTranscribing = inMeetingInfo.isTranscribing
        if isRecording != oldValue?.isRecording || isTranscribing != oldValue?.isTranscribing {
            // 录制/转录状态变更
            Logger.meeting.info("Record status changed to: \(isRecording), transcribing status changed to: \(isTranscribing)")
            currentNotesRuntime?.updateMeetingInfo(isRecordTipEnabled: checkIsRecordTipEnabled(),
                                                   isRecording: checkIsRecordingOrTranscribing(),
                                                   isHostOrCohost: isHostOrCohost,
                                                   deviceId: meeting.myself.deviceId,
                                                   meetingId: meeting.meetingId,
                                                   apiVersion: meeting.notesData.currentNotesInfoVersion)
        }
    }

    // MARK: - InMeetShareDataListener

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        updateCanQuickShare()
    }

    // MARK: - Priveta Vars

    // 纪要Scene不可见
    // 如果支持分屏，进入下面判断；如果不支持分屏，直接显示（老版本iPad走iPhone逻辑）
    // 如果有纪要Scene，判断是否是前台活跃，不是则提示
    // 如果没有纪要Scene，一定没有展开纪要，则直接提示
    // 需要确保在主线程调用!!!
    private var isNotesSceneInactive: Bool {
        if #available(iOS 13.0, *) {
            if let validNotesScene = VCScene.connectedScene(scene: InMeetNotesKeyDefines.generateNotesSceneInfo(with: meeting.meetingId)),
               validNotesScene.activationState == .foregroundActive {
                if let ws = meeting.router.window?.windowScene, ws.session == validNotesScene.session, !meeting.router.isFloating { // 独占Scene，且会议全屏
                    return true
                }
                return false
            } else {
                return true
            }
        } else {
            return true
        }
    }

    private lazy var notesProviderVM: InMeetNotesProviderViewModel? = {
        return resolver.resolve(InMeetNotesProviderViewModel.self)
    }()

    // MARK: - Private Funcs

    private func updateShowNewAgendaHintOnMainThread(_ notesInfo: NotesInfo) {
        assert(Thread.isMainThread, "invalid call, update shouldShowNewAgendaHint on non-main thread")
        if Display.phone {
            meeting.shouldShowNewAgendaHint = false
        } else {
            if isNotesSceneInactive {
                // 不可见不更新
            } else {
                meeting.shouldShowNewAgendaHint = false
            }
        }
    }

    private func updateNotesAgendaInfo(with notesInfo: NotesInfo) {
        Logger.notes.info("will update notesAgendaInfo")
        currentNotesRuntime?.updateActiveAgenda(notesInfo.activatingAgenda,
                                                pausedAgenda: notesInfo.pausedAgenda,
                                                meetingPassedTime: Int64(Date().timeIntervalSince(meeting.startTime)))
        Util.runInMainThread { [weak self] in
            self?.updateShowNewAgendaHintOnMainThread(notesInfo)
        }
    }

    func updateNotesMeetingInfo() {
        Logger.notes.info("will update notesMeetingInfo")
        currentNotesRuntime?.updateMeetingInfo(isRecordTipEnabled: checkIsRecordTipEnabled(),
                                               isRecording: checkIsRecordingOrTranscribing(),
                                               isHostOrCohost: isHostOrCohost,
                                               deviceId: meeting.myself.deviceId,
                                               meetingId: meeting.meetingId,
                                               apiVersion: meeting.notesData.currentNotesInfoVersion)
    }


    private func updateNotesInfoOnMainThread(_ notes: NotesInfo?, oldValue: NotesInfo?) {
        assert(Thread.isMainThread, "invalid call, update notesInfo on non-main thread")
        if let newNotes = notes, !newNotes.notesURL.isEmpty {
            // 新NotesInfo有效，更新或打开Notes
            if newNotes.notesURL.vc.removeParams() == currentNotesRuntime?.notesUrl.vc.removeParams() {
                // 新旧Notes的url相同，更新议程数据
                Logger.notes.info("will update notes")
                updateNotesAgendaInfo(with: newNotes)
            } else if currentNotesRuntime == nil {
                // 新旧Notes的url不同，创建并更换到新Notes
                Logger.notes.info("will start notes")
                currentNotesRuntime = notesDocumentFactory.createRuntime(with: newNotes.notesURL)
                currentNotesRuntime?.setDelegate(self)
                notesChangeDelegate?.didChangeNotes(to: currentNotesRuntime)
            } else {
                Logger.notes.info("will replace notes")
            }
        }
    }

    // https://bytedance.feishu.cn/wiki/B4Wvw6FiqisAFok0Mfhcq7iRnud
    private func generateAIInfoCallback() -> [String: Any] {
        let vcPromptId = meeting.setting.notesAIConfig.vcPromptId
        let participantNumber = meeting.participant.global.count
        let meetingId = meeting.meetingId
        let isCalendarMeeting = meeting.isCalendarMeeting
        var duration: Int64 = 0
        if let calendarInfo = meeting.notesData.calendarInfo {
            duration = (calendarInfo.theEventEndTime - calendarInfo.theEventStartTime) / (1000 * 60)
        }

        func buildParamsValues(content: String, promptId: String) -> [String: Any] {
            return [
                InMeetNotesKeyDefines.Params.content: content,
                InMeetNotesKeyDefines.Params.promptId: promptId
            ]
        }
        func buildBizExtraDataValues(isCalendarMeeting: Bool, attendeeNum: Int, meetingId: String, duration: Int64? = 0) -> [String: Any] {
            var bizExtraDataValues = [
                InMeetNotesKeyDefines.Params.attendeeNum: "\(participantNumber)", // 为当前参会人数
                InMeetNotesKeyDefines.Params.meetingId: meetingId, // 会议ID
                InMeetNotesKeyDefines.Params.source: InMeetNotesKeyDefines.Params.meeting // 会中场景，会中传"meeting"
            ]
            if isCalendarMeeting {
                bizExtraDataValues[InMeetNotesKeyDefines.Params.eventDuration] = "\(duration)" // 即时会议不传，日程会议传入日程时长，时长（单位：分钟）
            }
            return bizExtraDataValues
        }
        return [
            InMeetNotesKeyDefines.Params.params:
                buildParamsValues(content: generateAITopic(),
                                  promptId: vcPromptId),
            InMeetNotesKeyDefines.Params.bizExtraData:
                buildBizExtraDataValues(isCalendarMeeting: isCalendarMeeting,
                                        attendeeNum: participantNumber,
                                        meetingId: meetingId,
                                        duration: duration)
        ]
    }

    private func generateAITopic() -> String {
        if meeting.isCalendarMeeting {
            return meeting.notesData.calendarInfo?.topic ?? ""
        } else {
            if let i18nTopic = meeting.data.inMeetingInfo?.meetingSettings.i18nDefaultTopic?.i18NKey, !i18nTopic.isEmpty {
                return ""
            } else {
                return meeting.data.inMeetingInfo?.meetingSettings.topic ?? ""
            }
        }
    }

    private func clickRecord() {
        guard let recordVM = resolver.resolve(InMeetRecordViewModel.self) else {
            Logger.notes.warn("resolve InMeetRecordViewModel failed, record action is skipped")
            return
        }
        recordVM.notesStartRecord()
    }

    private func checkIsRecordTipEnabled() -> Bool {
        return meeting.setting.isMyAIAllEnabled
        && meeting.setting.isNotesMyAIGuideEnabled
        && !meeting.service.shouldShowGuide(.myAIOnboarding)
        && meeting.setting.isRecordEnabled
        && inMeetGenerateMeetingSummaryInDocs
    }

    private func checkIsRecordingOrTranscribing() -> Bool {
        return meeting.data.isRecording || meeting.data.isTranscribing
    }
}
