//
//  ToolBarTranscribeItem.swift
//  ByteView
//
//  Created by yangyao on 2023/6/17.
//

import Foundation
import RxSwift
import ByteViewUI
import ByteViewSetting
import ByteViewNetwork
import ByteViewTracker
import UniverseDesignIcon

final class ToolBarTranscribeItem: ToolBarItem {
    override var itemType: ToolBarItemType { .transcribe }

    override var title: String {
        I18n.View_G_Transcribe_Button
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .transcribeFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .transcribeOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsTranscribe ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        // 转录开启，展示在center，关闭，收缩在app中
        if !meeting.setting.showsTranscribe {
            return .none
        }
        return isTranscribing ? .right : .more
    }

    private let transcribeViewModel: InMeetTranscribeViewModel

    var httpClient: HttpClient { meeting.httpClient }

    var isLaunching: Bool {
        // 云端启动中
        transcribeViewModel.isLaunching && meeting.data.isTranscribeInitializing
    }

    var isTranscribing: Bool {
        meeting.data.isTranscribing
    }

    var hasTranscribed: Bool {
        meeting.data.inMeetingInfo?.transcriptInfo?.transcriptStatus == .pause
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.transcribeViewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.data.addListener(self, fireImmediately: false)
        meeting.addMyselfListener(self, fireImmediately: false)
        meeting.setting.addListener(self, for: .showsTranscribe)
        transcribeViewModel.addListener(self)
    }

    /// 点击了转录/停止转录按钮
    override func clickAction() {
        // 启动中，则无效点击
        guard provider != nil || !isLaunching else { return }
        // 目前服务端 FeatureConfig.recoreEnable 同时代表 "admin 后端是否开启转录功能"以及"面试会议是否允许开启转录"
        // 该值为 false 时，如果是因为 admin 关闭，则依然显示转录按钮，点击弹 toast
        // 如果是因为面试会议或其他原因，则在 showldShow 中过滤，直接隐藏该按钮
        if !meeting.setting.isTranscribeEnabled {
            if meeting.setting.recordCloseReason == .admin {
                Toast.show(I18n.View_MV_FeatureNotOnYet_Hover)
            }
            return
        }

        if transcribeViewModel.isTranscriptViewOpened {
            // ipad上转录页面已经打开，再次点击则关闭
            closeTranscribeContent()
            MeetSettingTracks.trackHideTranscriptPanel(location: "toolbar")
            return
        } else {
            // 已经转录过或者正在转录
            if hasTranscribed || isTranscribing {
                showTranscribeContent()
                return
            }
        }

        switch meeting.type {
        case .meet:
            handleMeetClick()
        case .call:
            handleCallClick()
        case .unknown:
            break
        }
    }

    private func handleMeetClick() {
        if meeting.webinarManager?.isRehearsing ?? false {
            // 彩排过程中不支持发起转录
            Toast.show(I18n.View_G_NoTranscribeRehearsal, type: .warning)
            return
        }
        let isMyselfOnlyParticipant: Bool = meeting.participant.global.count == 1
        let isMyAudioMuted: Bool = meeting.microphone.isMuted
        let requestedButBeforeTranscribing = transcribeViewModel.requestedButBeforeTranscribing.value

        if selfCanStartTranscribing {
            if isTranscribing {
                stopTranscribing()
            } else {
                if isMyselfOnlyParticipant {
                    startTranscribing({ [weak self] result in
                        // 单人会议转录
                        switch result {
                        case .success:
                            if isMyAudioMuted {
                                self?.showTurnOnMicAlert()
                            } else {
                                self?.showTranscribeContent()
                            }
                        case .failure:
                            self?.shrinkToolBar {
                                Toast.show(I18n.View_G_Transcribe_FailToast)
                            }
                        }
                    })
                } else {
                    showStartTranscribeAlert()
                }
            }
        } else if !isTranscribing, !meeting.setting.allowRequestTranscribe {
            shrinkToolBar {
                Toast.show(I18n.View_G_CantTranscribeDueToHost_Toast)
            }
        } else if !isTranscribing, !requestedButBeforeTranscribing {
            showRequestConfirmAlert(for: .meet)
        } else if isTranscribing {
            shrinkToolBar {
                Toast.show(I18n.View_G_Transcribe_Ing)
            }
        } else {
            // 发出的请求转录消息尚未被主持人处理时
            shrinkToolBar {
                Toast.show(I18n.View_G_RequestSentShort)
            }
        }
    }

    private func handleCallClick() {
        let requestedButBeforeTranscribing = transcribeViewModel.requestedButBeforeTranscribing.value

        if isTranscribing {
            stopTranscribing()
        } else if hasTranscribed {
            startTranscribing()
        } else if !requestedButBeforeTranscribing {
            requestTranscribing(for: .call)
        }
    }

    private func updateTranscribeInfos() {
        notifyListeners()
    }

    private var selfCanStartTranscribing: Bool {
        meeting.setting.canStartTranscribe
    }

    // MARK: - Alert
    private func stopTranscribing() {
        transcribeViewModel.requestStopTranscribing(onConfirm: { [weak self] in
            self?.shrinkToolBar(completion: nil)
        })
    }

    /// 单人会中且静音时开启转录的提示
    private func showTurnOnMicAlert() {
        let curMeeting = meeting
        ByteViewDialog.Builder()
            .id(.confirmBeforeTranscribe)
            .colorTheme(.firstButtonBlue)
            .title(I18n.View_G_NoAudioWillBeRecorded)
            .message(I18n.View_G_Muted)
            .buttonsAxis(.vertical)
            .leftTitle(I18n.View_G_UnmuteMyself)
            .leftHandler({ [weak self] _ in
                // 解除静音，并开始转录
                curMeeting.microphone.muteMyself(false, source: .transcribe, completion: nil)
                self?.showTranscribeContent()
            })
            .rightTitle(I18n.View_G_RecordWithoutAudio)
            .rightHandler({ [weak self] _ in
                // 保持静音，并开始转录
                self?.showTranscribeContent()
            })
            .needAutoDismiss(true)
            .show()
    }

    // disable-lint: duplicated code
    /// 多人会议 主持人开始转录弹窗
    private func showStartTranscribeAlert() {
        // 确定要开始会议转录？
        let title = I18n.View_G_Transcribe_StartPop
        ByteViewDialog.Builder()
            .id(.confirmBeforeTranscribe)
            .title(title)
            .message(nil)
            .leftTitle(I18n.View_G_CancelTurnOff)
            .leftHandler({ _ in
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .transcribeStart, action: "cancel")
            })
            .rightTitle(I18n.View_G_Start)
            .rightHandler({ [weak self] _ in
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .transcribeStart, action: "start")

                if let self = self {
                    self.startTranscribing({ result in
                        switch result {
                        case .success:
                            self.showTranscribeContent()
                        case .failure:
                            break
                        }
                    })
                }
            })
            .needAutoDismiss(true)
            .show()
    }

    // enable-lint: duplicated code
    /// 多人会议 参会人请求转录弹窗
    private func showRequestConfirmAlert(for meetType: MeetingType) {
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: meeting.info.host, meetingId: meeting.meetingId) { [weak self] (ap) in
            guard let self = self else { return }
            Util.runInMainThread {
                let title = I18n.View_G_Transcribe_AskHostPop

                var message: String
                if self.meeting.setting.isSupportNoHost {
                    message = I18n.View_G_Transcribe_HostRights(ap.name)
                } else {
                    message = I18n.View_G_OnlyHostCanTranscribe
                }

                ByteViewDialog.Builder()
                    .id(.conformRequestTranscribing)
                    .title(title)
                    .message(message)
                    .leftTitle(I18n.View_G_CancelButton)
                    .leftHandler({ _ in
                    })
                    .rightTitle(I18n.View_M_SendRequest)
                    .rightHandler({ [weak self] _ in
                        guard let self = self else { return }
                        if self.selfCanStartTranscribing {
                            Toast.show(I18n.View_G_CouldNotSendRequest)
                        } else {
                            self.requestTranscribing(for: meetType)
                        }
                    })
                    .needAutoDismiss(true)
                    .show()
            }
        }
    }

    // MARK: - Transcribing
    /// 主持人开始转录请求
    private func startTranscribing(contextIdCallback: ((String) -> Void)? = nil, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            self.transcribeViewModel.startTranscribing( { [weak self] res in
                self?.transcribeViewModel.isLaunching = true
                completion?(res)
            })
        }
    }
    /// 参会人/单人请求转录请求
    private func requestTranscribing(for meetType: MeetingType, _ completion: ((Result<Void, Error>) -> Void)? = nil) {
        transcribeViewModel.requestTranscribing({ [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.transcribeViewModel.isLaunching = meetType == .call
                let toast: String
                if meetType == .meet {
                    toast = I18n.View_G_RequestSent
                } else {
                    let name = self.meeting.participant.another?.userInfo?.name ?? ""
                    toast = I18n.View_G_Transcribe_AfterApprove(name)
                }
                Toast.showOnVCScene(toast)
            case .failure:
                if self.transcribeViewModel.requestedButBeforeTranscribing.value {
                    self.transcribeViewModel.enableRequestTranscribing()
                }
            }
            completion?(result)
        })
        disableRequestTranscribing()
        shrinkToolBar(completion: nil)
    }

    private func disableRequestTranscribing() {
        transcribeViewModel.requestedButBeforeTranscribing.accept(true)
        // 30秒后恢复可点击
        let recoveryTimeConstant: Int = 30
        let autoEnableTranscribeRequest = transcribeViewModel.requestedButBeforeTranscribing
        let cancelDelayEnableRequestTranscribeSubject = transcribeViewModel.cancelDelayEnableRequestTranscribeSubject
        _ = Observable<Void>.just(Void())
            .delay(.seconds(recoveryTimeConstant), scheduler: MainScheduler.instance)
            .map { _ in false }
            .catchError { _ in .empty() }
            .takeUntil(cancelDelayEnableRequestTranscribeSubject)
            .bind(to: autoEnableTranscribeRequest)
        //这里不能加DisposeBag
    }

    private func showTranscribeContent() {
        if !transcribeViewModel.isTranscriptViewOpened {
            transcribeViewModel.showTranscribeContent()
        }
    }

    private func closeTranscribeContent() {
        transcribeViewModel.closeTranscribeContent()
    }
}

extension ToolBarTranscribeItem: InMeetDataListener, MyselfListener, InMeetingChangedInfoPushObserver {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        Util.runInMainThread {
            self.updateTranscribeInfos()
        }
    }

    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        Util.runInMainThread {
            self.updateTranscribeInfos()
        }
    }

    func didReceiveInMeetingChangedInfo(_ message: InMeetingData) {
        Util.runInMainThread {
            self.updateTranscribeInfos()
        }
    }
}

extension ToolBarTranscribeItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}

extension ToolBarTranscribeItem: InMeetTranscribeViewModelListener {
    func launchingStatusDidChanged() {
        Util.runInMainThread {
            self.updateTranscribeInfos()
        }
    }

    func clickTranscribeButton() {
        // 启动中，则无效点击
        guard provider != nil || !isLaunching else { return }
        // 目前服务端 FeatureConfig.recoreEnable 同时代表 "admin 后端是否开启转录功能"以及"面试会议是否允许开启转录"
        // 该值为 false 时，如果是因为 admin 关闭，则依然显示转录按钮，点击弹 toast
        // 如果是因为面试会议或其他原因，则在 showldShow 中过滤，直接隐藏该按钮
        if !meeting.setting.isTranscribeEnabled {
            if meeting.setting.recordCloseReason == .admin {
                Toast.show(I18n.View_MV_FeatureNotOnYet_Hover)
            }
            return
        }

        switch meeting.type {
        case .meet:
            handleMeetClick()
        case .call:
            handleCallClick()
        case .unknown:
            break
        }
    }
}
