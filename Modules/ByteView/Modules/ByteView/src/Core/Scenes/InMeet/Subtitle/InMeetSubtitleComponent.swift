//
//  InMeetSubtitleComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Action
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork
import ByteViewSetting

/// 字幕
/// - 提供LayoutGuide：subtitle
final class InMeetSubtitleComponent: InMeetViewComponent, InMeetMeetingProvider {
    //let view = UIView()
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let subtitle: InMeetSubtitleViewModel
    private let breakoutRoom: BreakoutRoomManager
    private let toolBarViewModel: ToolBarViewModel
    /// 会中字幕视图
    weak var container: InMeetViewContainer?
    var floatingSubtitleController: FloatingSubtitleViewController?

    weak var subtitleHistoryVC: SubtitleHistoryViewController?
    weak var filterVC: SubtitlesFilterViewController?
    weak var settingsVC: UIViewController?
    weak var actionSheetVC: ActionSheetController?
    private var isOpenHistoryForPad: Bool = false
    private var currentLayoutType: LayoutType
    private var enableSubtitleRecord: Bool = false

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.context = viewModel.viewContext
        self.subtitle = viewModel.resolver.resolve()!
        self.breakoutRoom = viewModel.resolver.resolve()!
        self.toolBarViewModel = viewModel.resolver.resolve()!
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        subtitle.addObserver(self)
        meeting.data.addListener(self)
        self.breakoutRoom.transition.addObserver(self)
        context.addListener(self, for: [.sketchMenu, .contentScene, .containerLayoutStyle, .whiteboardMenu])
    }

    var token: ToastAdditionalInsetsToken?

    deinit {
        NotificationCenter.default.removeObserver(self)
        selectSubtitleSpokenLanguageAlert?.dismiss()
        recordMeetingAudioAlert?.dismiss()
        detectedLanguageTipAlert?.dismiss()
        token?.cancel()
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .subtitle
    }

    func setupConstraints(container: InMeetViewContainer) {
        floatingSubtitleController?.updateFloatSubtitleLayoutGuide()
        floatingSubtitleController?.resetFloatingContainerPosition()
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        let isTranslationOn = subtitle.isTranslationOn
        if let isVisible = subtitle.isSubtitleVisible {
            didChangeTranslationOn(isTranslationOn && isVisible)
        } else {
            didChangeTranslationOn(isTranslationOn)
        }
        if !isTranslationOn {
            // 如果没开启过，就检查是不是要入会即开启
            checkTurnOnSubtitleWhenJoin()
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        currentLayoutType = newContext.layoutType
        if let actionSheet = actionSheetVC, Display.pad {
            actionSheet.dismiss(animated: false)
        }
        self.floatingSubtitleController?.containerDidTransition()
    }

    private func setupMeetingSubtitleLayout() {
        if floatingSubtitleController == nil {
            if let container = container {
                let subtitleVM = FloatingSubtitleViewModel(meeting: meeting, context: context, subtitle: subtitle)
                floatingSubtitleController = FloatingSubtitleViewController(viewModel: subtitleVM)
                floatingSubtitleController?.layoutStyle = context.meetingContent
                if let controller = floatingSubtitleController {
                    container.addContent(controller, level: .floatingSubtitle)
                    container.addMeetLayoutStyleListener(controller)
                    context.addListener(controller, for: [.contentScene, .flowPageControl])
                    controller.view.snp.makeConstraints { make in
                        make.edges.equalToSuperview()
                    }
                }
                floatingSubtitleController?.contentGuide = container.contentGuide
                floatingSubtitleController?.topBarGuide = container.topBarGuide
                floatingSubtitleController?.bottomBarGuide = container.bottomBarGuide
                floatingSubtitleController?.subtitleInitialGuide = container.subtitleInitialGuide
                floatingSubtitleController?.updateFloatSubtitleLayoutGuide()
                floatingSubtitleController?.resetFloatingContainerPosition()
            }
        }
        floatingSubtitleController?.setupMeetingSubtitleLayout(
            openHistorySubtitlePage: { [weak self] in
                MeetingTracksV2.trackClickSubtitleMiniWindow()
                SubtitleTracksV2.trackClickSubtitlePanel()
                self?.showHistoryPage()
            },
            closeSubtile: { [weak self] in
                guard let `self` = self else { return }
                self.closeSubtitle()
            }
        )

        updateContainerContext()
    }

    func closeSubtitle() {
        MeetingTracksV2.trackCloseSubtitleMiniWindow()
        if self.subtitle.isTranslationOn {
            self.subtitle.toggleSubtitleSwitch(fromSource: "realtime_subtitle")
        }
        self.removeMeetingSubtitleLayout()
    }

    class SubtitleToastAdditionalInsets: ToastAdditionalInsetsProvider {
        weak var context: InMeetViewContext?
        init(context: InMeetViewContext) {
            self.context = context
        }
        var additionalInsets: UIEdgeInsets {
            guard let context = context,
                  context.isSubtitleVisible else {
                return .zero
            }
            if Display.phone && !VCScene.isLandscape {
                return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 128.0, right: 0.0)
            } else if Display.pad {
                return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 128.0, right: 0.0)
            }
            return .zero
        }
    }

    func updateContainerContext() {
        if floatingSubtitleController != nil {
            context.isSubtitleVisible = true
            subtitle.isSubtitleVisible = true
            subtitle.didShowSubtitlePanel()
            self.token?.cancel()
            self.token = Toast.requestAdditionalInsets(SubtitleToastAdditionalInsets(context: context))
        } else {
            context.isSubtitleVisible = false
            subtitle.isSubtitleVisible = false
            self.token?.cancel()
            self.token = nil
        }
    }

    // 移除字幕相关view
    private func removeMeetingSubtitleLayout() {
        floatingSubtitleController?.vc.removeFromParent()
        floatingSubtitleController?.removeMeetingSubtitleLayout()
        floatingSubtitleController = nil
        updateContainerContext()
    }

    private func resetPadSubtitleHistoryGudide() {
        guard let bottomBarGuide = container?.bottomBarGuide,
              let historyLayoutGuide = container?.padSubtitleHistory else {
                  return
              }
        historyLayoutGuide.snp.remakeConstraints { make in
            make.left.right.equalTo(bottomBarGuide)
            make.bottom.equalTo(bottomBarGuide.snp.top)
            make.height.equalTo(0)
        }
    }

    private var isSubtitleOpenedInMeeting: Bool?
    private var pendingDetectedLanguageTip: LangDetectTip?
    weak var detectedLanguageTipAlert: ByteViewDialog?
    weak var selectSubtitleSpokenLanguageAlert: ByteViewDialog?
    weak var recordMeetingAudioAlert: ByteViewDialog?
}

// MARK: - InMeetSubtitleViewModelObserver
extension InMeetSubtitleComponent: InMeetSubtitleViewModelObserver {
    func didOpenSubtitleView() {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            //  打开字幕
            self.setupMeetingSubtitleLayout()
            // 字幕视图曝光埋点
            SubtitleTracksV2.trackSubtitleViewAppear(type: .realtime_subtitle)
        }
    }

    func willCloseSubtitle() {
        MeetingTracksV2.trackCloseSubtitleMiniWindow()
        removeMeetingSubtitleLayout()
    }

    func didChangeTranslationOn(_ isTranslationOn: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if isTranslationOn {
                //  打开字幕
                self.setupMeetingSubtitleLayout()
                //  新会中字幕
                switch self.subtitle.lastAsrSubtitleStatus {
                case .unknown:
                    self.floatingSubtitleController?.updateSubtitleStatus(status: .opening)
                case .opening:
                    self.floatingSubtitleController?.updateSubtitleStatus(status: .opening)
                    self.againPushMessage()
                case .openSuccessed(let isRecover, let isAllMuted):
                    self.floatingSubtitleController?.updateSubtitleStatus(status: .openSuccessed(isRecover: isRecover,
                                                                                                 isAllMuted: isAllMuted))
                default:
                    self.floatingSubtitleController?.updateSubtitleStatus(status: self.subtitle.lastAsrSubtitleStatus)
                }

                self.subtitle.willRestTimer()

                if let tip = self.pendingDetectedLanguageTip {
                    self.handleDetectedLanguageTip(tip)
                }

                if !self.subtitle.asrSubtitleBuffer.isEmpty {
                    self.floatingSubtitleController?.restoreSubtitlesFrom(subtitles: self.subtitle.asrSubtitleBuffer)
                }
            } else {
                //  关闭字幕
                self.removeMeetingSubtitleLayout()
            }
        }
    }
//    字幕翻译链路打开时时push只在推送一次，在页面打开字幕加载动画后，再手动执行didReceivePushMessage更改状态
    func againPushMessage() {
//        1.2秒是为用户体验，避免快速展示聆听页
        self.subtitle.pushMessage()
    }

    func didChangeSubtitleLanguage(_ language: String, oldValue: String?) {
        if oldValue != nil {
            Util.runInMainThread { [weak self] in
                //  语言发生变化的时候清除掉会中字幕
                //  语言更换清除字幕，并且显示翻译服务切换中
                self?.floatingSubtitleController?.clearAllSubtitlesAndSwipeUpForPreviousSubtitles()
            }
        }
    }

    func didUpdateAsrSubtitleStatus(_ status: AsrSubtitleStatus) {
        if floatingSubtitleController == nil {
            return
        }
        Util.runInMainThread { [weak self] in
            switch status {
            case .exception:
                self?.removeMeetingSubtitleLayout()
                Toast.show(I18n.View_G_FailedToLoadSubtitles)
            default:
                break
            }
            //  新会中字幕
            self?.floatingSubtitleController?.updateSubtitleStatus(status: status)
        }
    }

    func didReceiveSubtitleStatusConfirmedData(_ statusData: SubtitleStatusData) {
        if self.meeting.data.isOpenBreakoutRoom == false || (self.meeting.data.isMainBreakoutRoom && BreakoutRoomUtil.isMainRoom(statusData.breakoutRoomId)) || self.meeting.data.breakoutRoomId == statusData.breakoutRoomId {
            let status = statusData.status
            Logger.meeting.info("subtitleStatusData: status = \(status), type = \(statusData.langDetectInfo.type)")
            if status == .firstOpen {
                handleFirstOpen(statusData)
            } else if status == .langDetected, statusData.langDetectInfo.type != .unknown,
                      !meeting.setting.subtitleDeleteSpokenLanguage {
                // 语种识别
                handleDetectedLanguageTip(statusData.langDetectInfo.tip)
            }
        }
    }

    func didShowSubtitleActionSheet(sourceView: UIView) {
        let appearance = ActionSheetAppearance(backgroundColor: Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody,
                                               titleColor: UIColor.ud.textPlaceholder)
        let actionSheet = ActionSheetController(appearance: appearance)
        actionSheet.modalPresentation = .popover
        let showHistoryAction = SheetAction(title: I18n.View_MV_ViewFullSubtitle,
                                            titleFontConfig: .h4,
                                            handler: { [weak self] _ in
            self?.showHistoryPage()
            SubtitleTracksV2.trackSubtitleActionSheetClickCompleteSubtitle()
        })
        let closeSubtitleAction = SheetAction(title: I18n.View_G_TurnSubtitlesOff,
                                              titleColor: UIColor.ud.functionDangerContentDefault,
                                              titleFontConfig: .h4,
                                              handler: { [weak self] _ in
            self?.subtitle.toggleSubtitleSwitch(fromSource: "toolbar")
            SubtitleTracksV2.trackSubtitleActionSheetClickClose()
        })
        let cancelAction = SheetAction(title: I18n.View_MV_CancelButtonTwo,
                                       titleFontConfig: .h4,
                                       sheetStyle: .cancel,
                                       handler: { _ in
            SubtitleTracksV2.trackSubtitleActionSheetClickCancel()
        })
        actionSheet.addAction(cancelAction)
        actionSheet.addAction(showHistoryAction)
        actionSheet.addAction(closeSubtitleAction)

        let originBounds = sourceView.bounds
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: CGRect(x: originBounds.minX,
                                                                         y: originBounds.minY - 1,
                                                                         width: originBounds.width,
                                                                         height: originBounds.height),
                                                      backgroundColor: UIColor.ud.bgBody,
                                                      popoverSize: actionSheet.padContentSize,
                                                      permittedArrowDirections: .down)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        meeting.router.presentDynamicModal(actionSheet, regularConfig: regularConfig, compactConfig: compactConfig)
        actionSheetVC = actionSheet
        // TODO: @huangtao.ht CR切换，tableView展示也有问题
    }

    func willRestTimer() {
        floatingSubtitleController?.resetTimer()
    }
}

extension InMeetSubtitleComponent: InMeetDataListener {
    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if let isSubtitleOn = inMeetingInfo.isSubtitleOn {
            isSubtitleOpenedInMeeting = isSubtitleOn
            checkTurnOnSubtitleWhenJoin()
        }
    }

    /// 初始化会议中第一次有人打开字幕提示功能
    private func handleFirstOpen(_ statusData: SubtitleStatusData) {
        let participantService = httpClient.participantService
        participantService.participantInfo(pid: statusData.firstOneOpenSubtitle, meetingId: meeting.meetingId) { [weak self] (p) in
            if self != nil, !p.name.isEmpty {
                Toast.show(I18n.View_G_TurnedOnSubtitlesNameBraces(p.name))
            }
        }
    }
}

// MARK: - layout状态监听
extension InMeetSubtitleComponent: InMeetViewChangeListener {
   func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
       guard change == .containerLayoutStyle || change == .contentScene else { return }
   }
}

extension InMeetSubtitleComponent: TransitionManagerObserver {
    func transitionStatusChange(isTransition: Bool, info: BreakoutRoomInfo?, isFirst: Bool?) {
        if isTransition == false {
            checkTurnOnSubtitleWhenJoinBreakoutRoom()
        }
    }
}

// MARK: - history
extension InMeetSubtitleComponent {
    func showHistoryPage() {
        SubtitleTracks.trackClickAllSubtitles()
        SubtitleTracksV2.trackClickShowHistory()
        SubtitleTracksV2.trackSubtitleViewAppear(type: .complete_subtitle)

        floatingSubtitleController?.view.removeFromSuperview()
        floatingSubtitleController?.removeFromParent()
        floatingSubtitleController = nil

        if #available(iOS 13, *), VCScene.supportsMultipleScenes {
            subtitle.showSubtitleHistoryScene()
        } else {
            let vm = SubtitlesViewModel(meeting: meeting, subtitle: subtitle)
            showHistoryVC(viewModel: vm)
        }
        updateContainerContext()
    }

    func showHistoryVC(viewModel: SubtitlesViewModel) {
        let controller = SubtitleHistoryViewController(viewModel: viewModel)
        controller.subtitle = self.subtitle
        subtitleHistoryVC = controller
        controller.filterBlock = { [weak self] filterVC in
            self?.filterVC = filterVC
        }

        meeting.router.setWindowFloating(true)
        let vc = NavigationController(rootViewController: controller)
        vc.modalPresentationStyle = .fullScreen
        meeting.larkRouter.present(vc, animated: true)

    }

    // 切换之前如果打开了筛选或者设置页面，必须先关闭，
    func closeFilterAndSettingsPageIfNeeded() {
        settingsVC?.presentingViewController?.dismiss(animated: false, completion: nil)
        filterVC?.presentingViewController?.dismiss(animated: false, completion: nil)
    }
}

// MARK: - alerts
extension InMeetSubtitleComponent {
    private func checkTurnOnSubtitleWhenJoinBreakoutRoom() {
        guard meeting.setting.canOpenSubtitle, meeting.setting.turnOnSubtitleWhenJoin else {
            return
        }

        let isQuotaEnabled = meeting.setting.hasSubtitleQuota
        Util.runInMainThread {
            // 判断付费套餐是否允许开启字幕
            guard isQuotaEnabled else {
                return
            }

            SubtitleTracksV2.trackOpenSubtitles(isAutoOpen: self.enableSubtitleRecord)
            SubtitleTracksV2.startTrackSubtitleStartDuration()
            var request = ParticipantChangeSettingsRequest(meeting: self.meeting)
            request.participantSettings.isTranslationOn = true
            request.participantSettings.enableSubtitleRecord = self.enableSubtitleRecord
            self.httpClient.send(request)
        }
    }

    private func checkTurnOnSubtitleWhenJoin() {
        guard !meeting.router.isFloating, meeting.setting.canOpenSubtitle,
              let isSubtitleOpenedInMeeting = isSubtitleOpenedInMeeting,
              meeting.setting.turnOnSubtitleWhenJoin else {
            return
        }
        if context.isTurnOnSubtitleWhenJoinChecked {
            return
        }
        context.isTurnOnSubtitleWhenJoinChecked = true

        let isQuotaEnabled = meeting.setting.hasSubtitleQuota
        Util.runInMainThread {
            // 判断付费套餐是否允许开启字幕
            guard isQuotaEnabled else {
                return
            }

            if !isSubtitleOpenedInMeeting && self.meeting.setting.isSpokenLanguageSettingsEnabled {
                self.showSubtitleSpokenLanguageSettingsAlert { [weak self] (isSelected) in
                    if isSelected, let self = self {
                        self.showRecordAudioAlert()
                    }
                }
            } else {
                self.showRecordAudioAlert()
            }
        }
    }

    private func showSubtitleSpokenLanguageSettingsAlert(completion: ((Bool) -> Void)? = nil) {
        SubtitleAlertUtil
            .showSelectLanguageAlert(router: meeting.router, context: context, selectedLanguage: subtitle.selectedSpokenLanguage,
                                     selectableSpokenLanguages: meeting.setting.selectableSpokenLanguages,
                                     completion: { [weak self] selectedLanguage in
                guard let self = self else { return }
                if let language = selectedLanguage?.language {
                    var request = HostManageRequest(action: .applyGlobalSpokenLanguage, meetingId: self.meeting.meetingId)
                    request.globalSpokenLanguage = language
                    self.httpClient.send(request)
                    completion?(true)
                } else {
                    completion?(false)
                }
            }, alertGenerationCallback: { [weak self] (alertController) in
                SubtitleTracks.trackSpokenLanguagePrompt()
                if let self = self {
                    self.selectSubtitleSpokenLanguageAlert = alertController
                } else {
                    alertController.dismiss()
                }
            })
    }

    private func showRecordAudioAlert() {
        SubtitleAlertUtil.showRecordAudioConfirmedAlert(meeting: meeting, completion: { [weak self] isRecordEnabled in
            guard let self = self else { return }
            SubtitleTracksV2.trackOpenSubtitles(isAutoOpen: true)
            SubtitleTracksV2.startTrackSubtitleStartDuration()
            var request = ParticipantChangeSettingsRequest(meeting: self.meeting)
            request.participantSettings.isTranslationOn = true
            request.participantSettings.enableSubtitleRecord = isRecordEnabled
            self.enableSubtitleRecord = isRecordEnabled
            self.httpClient.send(request)
        }, alertGenerationCallback: { [weak self] (alert) in
            if let self = self {
                self.recordMeetingAudioAlert = alert
            } else {
                alert.dismiss()
            }
        })
    }

    private func handleDetectedLanguageTip(_ tip: LangDetectTip) {
        if !subtitle.isTranslationOn {
            pendingDetectedLanguageTip = tip
            return
        }
        pendingDetectedLanguageTip = nil
        SubtitleAlertUtil.constructDetectedLanguageTipInfo(tip, httpClient: httpClient) { [weak self] alertInfo in
            guard let self = self, let info = alertInfo.value else { return }
            self.detectedLanguageTipAlert?.dismiss()
            SubtitleAlertUtil.showDetectedLanguageTipAlert(tip: tip, info: info, completion: { [weak self] isConfirmed in
                if let self = self, !isConfirmed {
                    self.presentSubtitleSettings()
                }
            }, alertGenerationCallback: { [weak self] alert in
                if let self = self {
                    self.detectedLanguageTipAlert = alert
                } else {
                    alert.dismiss()
                }
            })
        }
    }

    func presentSubtitleSettings() {
        let viewController = meeting.setting.ui.createSubtitleSettingViewController(context: SubtitleSettingContext(fromSource: .handleDetectedLanguageTip))
        let vc = NavigationController(rootViewController: viewController)
        vc.modalPresentationStyle = .fullScreen
        meeting.router.present(vc)
    }
}

extension InMeetSubtitleComponent: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        checkTurnOnSubtitleWhenJoin()
    }
}

enum LangDetectTip: Equatable {
    case unknown
    case mismatching(detectedKey: String, currentKey: String)
    case nonsupport(detectedKey: String)
}

extension LangDetectTip {
    struct Alert {
        let title: String
        let description: String
        let button1: String
        let button2: String
        let id: ByteViewDialogIdentifier
    }
}

extension SubtitleStatusData.LangDetectInfo {
    var tip: LangDetectTip {
        if self.type == .mismatch, !detectedLanguageKey.isEmpty, !languageKey.isEmpty {
            return .mismatching(detectedKey: detectedLanguageKey, currentKey: languageKey)
        }
        if self.type == .unsupported, !detectedLanguageKey.isEmpty {
            return .nonsupport(detectedKey: detectedLanguageKey)
        }
        return .unknown
    }
}
