//
//  InMeetTopBarComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewUI
import ByteViewSetting
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewCommon

/// 顶部导航栏
/// - 提供LayoutGuide：topBar
final class InMeetTopBarComponent: InMeetViewComponent, InMeetViewChangeListener {
    let topBar: InMeetNavigationBar
    private let viewModel: InMeetViewModel
    private let gridViewModel: InMeetGridViewModel
    private let topBarViewModel: InMeetTopBarViewModel
    private let statusManager: InMeetStatusManager
    private let benefitViewModel: InMeetBenefitViewModel
    private let breakoutRoom: BreakoutRoomManager
    private let countDownManager: CountDownManager
    private weak var container: InMeetViewContainer?
    private let context: InMeetViewContext
    private let meeting: InMeetMeeting

    weak var sceneButton: UIButton?
    weak var sceneSelectionViewController: InMeetSceneSelectVC?
    weak var joinRoomViewController: JoinRoomTogetherViewController?
    weak var moreItemActionSheetVC: ActionSheetController?

    private var hangupType: InMeetTopBarHangupType = .hangup
    private var isLandscapeToolBarInitialized = false
    private var isPortraitToolbarInitialized = false
    private var isJoinRoomConnected: Bool = false
    private var durationTimer: Timer?
    private var duration = I18n.View_G_Connecting {
        didSet {
            if oldValue != duration {
                updateTopbarDurationText()
            }
        }
    }
    private var breakoutRemainingTime: TimeInterval = 0
    private var isRemainingTimeAvailable: Bool
    private static let navigationBarStatuses: [InMeetStatusType] = [.lock, .record, .transcribe, .interpreter, .live, .interviewRecord, .countDown]
    private lazy var statuses: [InMeetStatusThumbnailItem?] = Self.navigationBarStatuses.map { _ in nil }
    private var toolbarItems: [ToolBarItemType] = []

    private var factory: ToolBarFactory { topBarViewModel.toolBarFactory }

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.viewModel = viewModel
        self.meeting = viewModel.meeting
        self.context = viewModel.viewContext
        let r = viewModel.resolver
        self.topBarViewModel = r.resolve()!
        self.gridViewModel = r.resolve()!
        self.breakoutRoom = r.resolve()!
        self.statusManager = r.resolve()!
        self.benefitViewModel = r.resolve()!
        self.countDownManager = r.resolve()!
        self.topBar = InMeetNavigationBar(viewModel: self.topBarViewModel, hasSwitchSceneEntrance: container.sceneManager.hasSwitchSceneEntrance)
        self.container = container
        let isBreakoutRoomTopicEmpty = self.meeting.data.breakoutRoomInfo?.topic.isEmpty ?? true
        self.isRemainingTimeAvailable = !isBreakoutRoomTopicEmpty && self.meeting.data.isBreakoutRoomAutoFinishEnabled
        container.addContent(topBar, level: .topBar)
        self.topBar.sceneMode = context.meetingScene
        self.topBar.gridVisibleRange = context.currentGridVisibleRange
        self.topBar.isShowSpeakerOnMainScreen = context.isShowSpeakerOnMainScreen
        context.addListener(self, for: [.contentScene, .currentGridVisibleRange, .showSpeakerOnMainScreen])
        self.bindViewModel()
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .topBar
    }

    func setupConstraints(container: InMeetViewContainer) {
        topBar.snp.makeConstraints { make in
            make.edges.equalTo(container.topBarGuide)
        }
        topBar.barContentGuide.snp.makeConstraints { make in
            make.edges.equalTo(container.topBarContentGuide)
        }
        topBar.updateCompressMode()
        updateBarHidden()
    }

    private func updateBarHidden() {
        let isHidden = context.isTopBarHidden
        topBar.isUserInteractionEnabled = !isHidden
        topBar.isSingleRow = context.meetingScene == .thumbnailRow
        topBar.isFlowShrunken = context.isFlowShrunken
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .whiteboardOperateStatus, let isOpaque = userInfo as? Bool {
            didChangeWhiteboardOperateStatus(isOpaque: isOpaque)
        } else {
            updateBarHidden()
        }
        if change == .contentScene {
            self.topBar.sceneMode = context.meetingScene
        } else if change == .currentGridVisibleRange {
            self.topBar.gridVisibleRange = context.currentGridVisibleRange
        } else if change == .showSpeakerOnMainScreen {
            self.topBar.isShowSpeakerOnMainScreen = context.isShowSpeakerOnMainScreen
        }
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.topBar.meetingLayoutStyle = container.meetingLayoutStyle
    }

    private func bindViewModel() {
        for (key, value) in statusManager.thumbnails {
            if let index = Self.navigationBarStatuses.firstIndex(where: { $0 == key }) {
                statuses[index] = value
            }
        }

        updateTitle()
        updateTopbarDurationText()
        startDurationTimer()
        updateStatuses()
        topBar.updateHangupType(hangupType)
        topBar.updateNetworkStatus(meeting.rtc.network.localNetworkStatus)
        topBar.updateSceneButtons()
        if topBarViewModel.isJoinRoomEnabled {
            topBar.setJoinRoomHidden(topBarViewModel.isJoinRoomHidden)
            topBar.joinRoomButton.isConnected = topBarViewModel.isRoomConnected
        }
        topBar.setE2EeViewHidden(!meeting.isE2EeMeeing)
        updateBreakoutRoomRemainingTime()
        resetNavigationToolbar()
        didChangeExternal(topBarViewModel.meetingTagType)
        didChangeWebinarRehearsingTagHidden(topBarViewModel.isWebinarRehearsingTagHidden)

        topBar.delegate = self
        context.addListener(self, for: [.topBarHidden, .contentScene, .flowShrunken, .whiteboardOperateStatus])
        meeting.data.addListener(self)
        meeting.rtc.network.addListener(self)
        meeting.setting.addListener(self, for: [.hasCohostAuthority, .isMyAIEnabled])
        meeting.shareData.addListener(self)
        breakoutRoom.addObserver(self)
        breakoutRoom.timer.addObserver(self)
        topBarViewModel.observer = self
        topBarViewModel.addToolbarListener(self)
        topBarViewModel.setToolbarBridge(self)
        if #available(iOS 13, *), VCScene.supportsMultipleScenes {
            NotificationCenter.default.addObserver(self, selector: #selector(handleSceneChange), name: VCScene.didChangeVcSceneNotification, object: nil)
        }
        if Display.pad {
            statusManager.addListener(self)
        }
        if container?.sceneManager.hasSwitchSceneEntrance ?? false {
            container?.addMeetSceneModeListener(self)
        }
    }

    private func updateTitle() {
        let title: String
        if meeting.subType == .webinar {
            title = I18n.View_G_WebinarInfo_Button
        } else if meeting.data.isInBreakoutRoom {
            title = meeting.data.breakoutRoomInfo?.topic ?? ""
        } else {
            title = I18n.View_G_MeetingInfo_Button
        }
        topBar.setTitle(title)
    }

    private func updateMeetingTag(_ tagType: MeetingTagType) {
        if let text = tagType.text {
            topBar.updateExternalView(text: text, isHidden: false)
        } else {
            topBar.updateExternalView(text: "", isHidden: true)
        }
    }

    private func startDurationTimer() {
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] (t) in
            if let self = self {
                self.updateDuration()
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        durationTimer = timer
    }

    private func updateDuration() {
        guard meeting.isCallConnected else { return }
        let time = Int(Date().timeIntervalSince(meeting.startTime))
        guard time >= 0 else {
            duration = ""
            return
        }
        // disable-lint: magic number
        let hour = time / 3600
        let minute = (time % 3600) / 60
        let second = time % 60
        // enable-lint: magic number
        let s = hour > 0 ? String(format: "%02d:%02d:%02d", hour, minute, second) : String(format: "%02d:%02d", minute, second)
        let billingSetting = meeting.setting.billingSetting
        if billingSetting.isInsufficientOfRemainingTime {
            duration = "\(s) (\(I18n.View_G_NumberMinutes(billingSetting.planTimeLimit)))"
        } else {
            duration = s
        }
    }

    private func updateTopbarDurationText() {
        topBar.durationLabel.text = duration
    }

    private func updateBreakoutRoomRemainingTime() {
        topBar.updateBreakoutRoomInfo(showRemainingTime: isRemainingTimeAvailable, remainingTime: breakoutRemainingTime)
    }

    private func updateHangup() {
        let hangupType: InMeetTopBarHangupType
        if meeting.data.isInBreakoutRoom, meeting.setting.canReturnToMainRoom {
            hangupType = .leave
        } else {
            hangupType = .hangup
        }
        if self.hangupType != hangupType {
            self.hangupType = hangupType
            Util.runInMainThread {
                self.topBar.updateHangupType(hangupType)
            }
        }
    }

    private func updateStatuses() {
        var items = statuses.compactMap { $0 }
        if !countDownManager.boardFolded || !VCScene.isRegular, let countDownIndex = items.firstIndex(where: { $0.type == .countDown }) {
            items.remove(at: countDownIndex)
        }
        topBar.updateStatus(items)
    }

    private func resetNavigationToolbar() {
        toolbarItems = topBarViewModel.toolbarItems
            .filter { factory.item(for: $0).phoneLocation == .navbar }
        let itemViews = toolbarItems.map { factory.navigationBarView(for: $0) }
        topBar.resetToolbarItemViews(itemViews)
    }

    private func updateBarItem(_ item: ToolBarItem) {
        let itemType = item.itemType
        let currentLocation = toolbarItems.firstIndex(of: item.itemType)
        let targetLocation = item.phoneLocation == .navbar ? topBarViewModel.toolbarItems.firstIndex(of: itemType) : nil
        if currentLocation == nil && targetLocation != nil {
            // 从无到有
            let position = ToolBarFactory.insertPosition(of: itemType,
                                                         target: toolbarItems,
                                                         order: topBarViewModel.toolbarItems)

            toolbarItems.insert(itemType, at: position)
            topBar.insertItemView(factory.navigationBarView(for: itemType), at: position)
        } else if let position = currentLocation, targetLocation == nil {
            // 从有到无
            toolbarItems.remove(at: position)
            topBar.removeItemView(at: position)
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.updateLayout(size: newContext.viewSize)
    }

    func updateLayout(size: CGSize) {
        self.topBar.toolBarStackView.isHiddenInStackView = false
        self.updateStatuses()
        self.resetNavigationToolbar()
        self.topBar.updateLayout()
        self.topBar.updateBackgroundColor()
        self.topBar.adaptShadowConfig()
    }

    @objc private func handleSceneChange() {
        topBar.updateSceneButtons()
    }

    private func resetGridOrder() {
        if gridViewModel.isGridOrderSyncing && meeting.myself.isHost {
            Toast.show(I18n.View_G_YouStoppedSyncingRevertToast)
        }
        gridViewModel.endUsingCustomOrder()
    }

    private var joinRoomTipSourceView: UIView {
        topBar.isMoreItemShowInCompact ? topBar.moreButton : topBar.joinRoomButton
    }
}

extension InMeetTopBarComponent: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .hasCohostAuthority {
            Util.runInMainThread {
                self.updateHangup()
            }
        }
        if key == .isMyAIEnabled {
            Util.runInMainThread {
                self.topBar.updateMyAIVisible()
            }
        }
    }
}

extension InMeetTopBarComponent: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        Util.runInMainThread {
            self.updateTitle()
            self.updateHangup()
            let isBreakoutRoomTopicEmpty = self.meeting.data.breakoutRoomInfo?.topic.isEmpty ?? true
            self.isRemainingTimeAvailable = !isBreakoutRoomTopicEmpty && self.meeting.data.isBreakoutRoomAutoFinishEnabled
            self.updateBreakoutRoomRemainingTime()
        }
    }
}

extension InMeetTopBarComponent: BreakoutRoomTimerObsesrver {
    func breakoutRoomRemainingTime(_ time: TimeInterval?) {
        self.breakoutRemainingTime = time ?? 0
        self.updateBreakoutRoomRemainingTime()
    }
}

extension InMeetTopBarComponent: InMeetTopBarViewModelObserver {

    func didChangeJoinRoomHidden(_ isHidden: Bool) {
        Util.runInMainThread {
            self.topBar.setJoinRoomHidden(isHidden)
        }
    }

    func didChangeRoomConnected(_ isConnected: Bool) {
        Util.runInMainThread {
            self.isJoinRoomConnected = isConnected
            self.topBar.joinRoomButton.isConnected = isConnected
        }
    }

    func didChangeExternal(_ meetingTagType: MeetingTagType) {
        Util.runInMainThread {
            self.updateMeetingTag(meetingTagType)
        }
    }

    func didChangeWebinarRehearsingTagHidden(_ isHidden: Bool) {
        Util.runInMainThread {
            self.topBar.setRehearsalHidden(isHidden)
        }
    }
}

extension InMeetTopBarComponent: MeetingSceneModeListener {
    func containerDidChangeSceneMode(container: InMeetViewContainer,
                                     sceneMode: InMeetSceneManager.SceneMode) {
        self.sceneSelectionViewController?.dismiss(animated: true)
        if container.sceneManager.isFocusing {
            self.topBar.padSwitchSceneButton.sceneType = .focus
            self.topBar.adaptShadowConfig()
            return
        }
        switch container.sceneMode {
        case .gallery:
            self.topBar.padSwitchSceneButton.sceneType = .gallery
        case .thumbnailRow:
            self.topBar.padSwitchSceneButton.sceneType = .thumbnailRow
        case .speech:
            self.topBar.padSwitchSceneButton.sceneType = .speech
        case .webinarStage:
            self.topBar.padSwitchSceneButton.sceneType = .webinarStage
        }
        self.topBar.adaptShadowConfig()
    }

    func containerDidChangeFocusing(container: InMeetViewContainer, isFocusing: Bool) {
        self.topBar.sceneMode = container.sceneMode
        if container.sceneManager.isFocusing {
            self.topBar.padSwitchSceneButton.sceneType = .focus
            return
        }
        switch container.sceneMode {
        case .gallery:
            self.topBar.padSwitchSceneButton.sceneType = .gallery
        case .thumbnailRow:
            self.topBar.padSwitchSceneButton.sceneType = .thumbnailRow
        case .speech:
            self.topBar.padSwitchSceneButton.sceneType = .speech
        case .webinarStage:
            self.topBar.padSwitchSceneButton.sceneType = .webinarStage
        }
    }
}

extension InMeetTopBarComponent: InMeetRtcNetworkListener {
    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {
        Util.runInMainThread {
            self.topBar.updateNetworkStatus(status)
        }
    }
}

extension InMeetTopBarComponent: InMeetNavigationBarDelegate {
    func navigationBarDidChangeCompactMode(currentMoreItemShow: Bool) {
        Logger.ui.info("navigationBarDidChangeCompactMode currentMode is: \(currentMoreItemShow)")
        if joinRoomViewController != nil {
            joinRoomViewController?.popoverPresentationController?.sourceView = joinRoomTipSourceView
            topBar.moreButton.isSelected = currentMoreItemShow
        }
        if sceneSelectionViewController != nil {
            sceneSelectionViewController?.popoverPresentationController?.sourceView = currentMoreItemShow ? topBar.moreButton : topBar.padSwitchSceneButton
            topBar.moreButton.isSelected = currentMoreItemShow
        }
        if moreItemActionSheetVC != nil {
            moreItemActionSheetVC?.dismiss(animated: false)
        }
    }

    func navigationBarDidClickBack() {
        MeetingTracksV2.trackClickMobileBack()
        if !viewModel.meeting.isEnd {
            VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: "minimize"])
        }
        viewModel.meeting.router.setWindowFloating(true)
    }

    func navigationBarDidClickHangup(sender: UIButton) {
        InMeetLeaveAction.hangUp(sourceView: sender,
                                 meeting: meeting,
                                 context: viewModel.viewContext,
                                 breakoutRoom: breakoutRoom)
    }

    func navigationBarDidClickMoreButton(sender: UIButton) {
        // disable-lint: magic number
        let appearance = ActionSheetAppearance(backgroundColor: UIColor.ud.bgFloat,
                                               contentViewColor: UIColor.ud.bgFloat,
                                               separatorColor: UIColor.clear,
                                               modalBackgroundColor: UIColor.ud.bgMask,
                                               customTextHeight: 50.0,
                                               tableViewCornerRadius: 0.0)
        // enable-lint: magic number

        let actionSheetVC = ActionSheetController(appearance: appearance)
        actionSheetVC.modalPresentation = .alwaysPopover
        actionSheetVC.delegate = self
        if Display.phone {
            for itemView in topBar.toolbarItemViews {
                var iconKey: UDIconType?
                if case .icon(key: let key) = itemView.item.outlinedIcon {
                    iconKey = key
                }
                if case .customColoredIcon(key: let key, color: _) = itemView.item.outlinedIcon {
                    iconKey = key
                }
                guard let iconKey = iconKey else { continue }
                actionSheetVC.addAction(SheetAction(title: itemView.item.title,
                                         titleFontConfig: VCFontConfig.bodyAssist,
                                                    icon: UDIcon.getIconByKey(iconKey, iconColor: UIColor.ud.iconN1.withAlphaComponent(0.8), size: CGSize(width: 20, height: 20)),
                                         showBottomSeparator: false,
                                                    sheetStyle: itemView.item.badgeType != .none ? .iconLabelAndBadge : .iconAndLabel,
                                         handler: { [weak itemView] _ in
                    itemView?.item.clickAction()
                }))
            }
        } else {
            if topBarViewModel.isMyAIEnabled {
                actionSheetVC.addAction(SheetAction(title: meeting.setting.aiBrandName,
                                         titleFontConfig: VCFontConfig.bodyAssist,
                                         icon: UDIcon.getIconByKey(.myaiColorful, size: CGSize(width: 20, height: 20)),
                                         showBottomSeparator: false,
                                         sheetStyle: .iconAndLabel,
                                         handler: { _ in
                }))
            }
            if topBarViewModel.isJoinRoomEnabled {
                actionSheetVC.addAction(SheetAction(title: I18n.View_G_ConnectToRoom_Button,
                                         titleFontConfig: VCFontConfig.bodyAssist,
                                         icon: UDIcon.getIconByKey(.videoSystemOutlined, iconColor: UIColor.ud.iconN1.withAlphaComponent(0.8), size: CGSize(width: 20, height: 20)),
                                         showBottomSeparator: false,
                                         sheetStyle: .iconAndLabel,
                                         handler: { [weak self, sender] _ in
                    self?.navigationBarDidClickJoinRoom(sender)
                }))
            }
            if container?.sceneManager.hasSwitchSceneEntrance == true {
                actionSheetVC.addAction(SheetAction(title: I18n.View_G_Layout,
                                         titleFontConfig: VCFontConfig.bodyAssist,
                                         icon: UDIcon.getIconByKey(.gridViewOutlined, iconColor: UIColor.ud.iconN1.withAlphaComponent(0.8), size: CGSize(width: 20, height: 20)),
                                         showBottomSeparator: false,
                                         sheetStyle: .iconAndLabel,
                                         handler: { [weak self, sender] _ in
                    self?.navigationBarDidClickSwitchMeetingScene(sender: sender)
                }))
            }
        }
        let width = actionSheetVC.maxIntrinsicWidth
        let height = actionSheetVC.intrinsicHeight
        let anchor = AlignPopoverAnchor(sourceView: sender,
                                        alignmentType: .right,
                                        contentWidth: .fixed(width),
                                        contentHeight: height,
                                        contentInsets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0),
                                        positionOffset: CGPoint(x: 0, y: 3),
                                        cornerRadius: 8.0,
                                        borderColor: UIColor.ud.lineBorderCard,
                                        dimmingColor: UIColor.clear,
                                        containerColor: UIColor.ud.bgFloat)
        moreItemActionSheetVC = actionSheetVC
        AlignPopoverManager.shared.present(viewController: actionSheetVC, anchor: anchor)
    }

    func navigationBarDidClickSwitchCamera() {
        meeting.camera.switchCamera()
    }

    func navigationBarDidClickMeetingTitle(sender: UIButton) {
        topBar.expandDetail(true)
        let vm = DailyDetailViewModel(meeting: meeting, context: context, benefit: benefitViewModel)
        let viewController = DailyDetailViewController(viewModel: vm)
        viewController.dismissDelegate = self

        var bounds = sender.bounds
        bounds.origin.y += 4
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sender,
                                                      sourceRect: bounds,
                                                      backgroundColor: UIColor.ud.bgFloat,
                                                      permittedArrowDirections: .up)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        meeting.router.presentDynamicModal(viewController, regularConfig: regularConfig, compactConfig: compactConfig)

        MeetingTracks.trackDailyDetail()
        MeetingTracksV2.trackClickMeetingDetail(isSharingContent: meeting.shareData.isSharingContent,
                                                isMinimized: false,
                                                isMore: false)
        MeetingTracksV2.trackEnterMeetingDetail()
    }

    func navigationBarDidClickSwitchMeetingScene(sender: UIButton) {
        Logger.ui.info("TopBar didClickSwitchScene")
        guard let container = self.container,
              !sender.isSelected else {
            return
        }

        sender.isSelected = true
        sceneButton = sender

        if !container.sceneManager.checkAllowUserSwitchScene(nil, showToast: true) {
            sender.isSelected = false
            return
        }

        let sourceView = sender
        var sourceRect = sourceView.bounds
        if sender.window?.traitCollection.horizontalSizeClass == .compact {
            sourceRect.size.height += 2.0
        } else {
            sourceRect.size.height += 4.0
        }

        let vc = InMeetSceneSelectVC(meeting: viewModel.meeting,
                                     viewModel: viewModel,
                                     hasWebinarStage: container.sceneManager.webinarStageInfo != nil,
                                     context: container.context)
        sceneSelectionViewController = vc
        vc.delegate = self
        container.addMeetSceneModeListener(vc)

        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: sourceRect,
                                                      backgroundColor: UIColor.ud.bgFloat,
                                                      popoverSize: vc.calculatedContentSize,
                                                      popoverLayoutMargins: UIEdgeInsets(edges: 8.0),
                                                      permittedArrowDirections: .up)
        let dmConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        meeting.router.presentDynamicModal(vc, config: dmConfig)
    }

    func navigationBarDidClickJoinRoom(_ sender: UIButton) {
        let meeting = self.viewModel.meeting
        if meeting.myself.settings.targetToJoinTogether?.id == nil,
           !meeting.setting.isUltrawaveEnabled {
            Toast.show(I18n.View_UltraOnToUseThis_Note)
            return
        }
        sender.isSelected = true
        showJoinRoomPopover()
    }

    private func showJoinRoomPopover() {
        let vm = JoinRoomTogetherViewModel(service: viewModel.meeting.service, provider: InMeetJoinRoomProvider(meeting: viewModel.meeting), source: .navibar)
        let vc = JoinRoomTogetherViewController(viewModel: vm)
        joinRoomViewController = vc
        vc.delegate = self
        let sourceView = joinRoomTipSourceView
        let popoverConfig = DynamicModalPopoverConfig(sourceView: sourceView,
                                                      sourceRect: sourceView.bounds.offsetBy(dx: 0, dy: 4),
                                                      backgroundColor: .ud.bgFloat,
                                                      popoverLayoutMargins: UIEdgeInsets(top: 0, left: 10, bottom: -4, right: 10),
                                                      permittedArrowDirections: .up)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover,
                                               popoverConfig: popoverConfig,
                                               backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        meeting.router.presentDynamicModal(vc, regularConfig: regularConfig, compactConfig: compactConfig)
    }

    func navigationBarDidClickOpenScene() {
        VCScene.openAuxScene(id: "meeting_\(meeting.sessionId)", title: meeting.topic) { (_, _) in
            if VCScene.isAuxSceneOpen {
                MeetingTracks.trackCreateAuxWindow(createWay: "button")
            }
        }
    }

    func navigationBarDidClickCloseScene() {
        MeetingTracks.trackCloseAuxWindow()
        VCScene.closeAuxScene()
    }

    func navigationBarDidClickCountDown() {
        countDownManager.foldBoard(false)
    }

    func navigationBarDidClickStatusView(_ statusView: UIView) {
        if statusManager.statuses.isEmpty { return }
        var bounds = statusView.bounds
        bounds.origin.y += 20
        let popoverConfig = DynamicModalPopoverConfig(sourceView: statusView,
                                                      sourceRect: bounds,
                                                      backgroundColor: UIColor.ud.bgFloat,
                                                      permittedArrowDirections: .up)
        let vm = InMeetStatusDetailViewModel(resolver: viewModel.resolver)
        let viewController = InMeetStatusDetailViewController(viewModel: vm)
        let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
        let compactConfig = DynamicModalConfig(presentationStyle: .pan)
        meeting.router.presentDynamicModal(viewController, regularConfig: regularConfig, compactConfig: compactConfig)
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "mobile_status_bar"])
    }
}

extension InMeetTopBarComponent: DailyDetailViewControllerDismissDelegate {
    func dailyDetailViewControllerDidDismiss() {
        topBar.expandDetail(false)
    }
}

extension InMeetTopBarComponent: InMeetSceneSelectViewControllerDelegate {
    func sceneSelectionViewWillDisappear() {
        sceneButton?.isSelected = false
        topBar.moreButton.isSelected = false
    }

    func sceneSelectionViewDidSelectSceneMode(_ mode: InMeetSceneManager.SceneMode) {
        guard let container = container else {
            return
        }
        InMeetSceneTracks.trackClickLayout(newScene: mode,
                                           beforeScene: container.sceneMode,
                                           isSharing: container.contentMode.isShareContent,
                                           isSharer: viewModel.meeting.shareData.isSelfSharingContent)
        sceneSelectionViewController?.dismiss(animated: true)
        if container.sceneManager.checkAllowUserSwitchScene(mode, showToast: true) {
            container.sceneManager.switchSceneMode(mode)
        }
    }

    func sceneSelectionViewDidToggleHideSelf(_ enabled: Bool) {
        guard let container = container else {
            return
        }
        sceneSelectionViewController?.dismiss(animated: true)
        container.context.isSettingHideSelf = enabled
        InMeetSceneTracks.trackClickHideSelf(isHideSelf: enabled,
                                             location: "layout_panel",
                                             scene: container.sceneMode)
    }

    func sceneSelectionViewDidToggleHideNonVideo(_ enabled: Bool) {
        guard let container = container else {
            return
        }
        sceneSelectionViewController?.dismiss(animated: true)

        if gridViewModel.isSyncingOthers {
            Toast.show(isWebinar ? I18n.View_G_SyncedOrderNoHideWeb : I18n.View_G_SyncedOrderNoHide)
            return
        }
        container.context.isSettingHideNonVideoParticipants = enabled
        InMeetSceneTracks.trackSwitchHideNoVideoUser(isHide: enabled)
    }

    func sceneSelectionViewDidToggleSyncOrder(_ enabled: Bool) {
        guard let container = container else {
            return
        }
        InMeetSceneTracks.trackClickSyncOrder(isSharing: container.contentMode.isShareContent,
                                              isSharer: viewModel.meeting.shareData.isSelfSharingContent,
                                              scene: container.sceneMode)
        sceneSelectionViewController?.dismiss(animated: true)

        // 展示开关但是不可点击，点击弹Toast提示
        var error: String?
        if !viewModel.meeting.myself.isHost {
            error = I18n.View_G_CancelHostPermit
        } else if viewModel.meeting.data.inMeetingInfo?.focusingUser != nil {
            error = isWebinar ? I18n.View_G_FocusVideoSetNoSyncingVideoOrderWeb : I18n.View_G_FocusVideoSetNoSyncingVideoOrder
        } else if viewModel.meeting.data.isOpenBreakoutRoom {
            error = isWebinar ? I18n.View_G_BreakRoomNoSyncOrderWeb : I18n.View_G_BreakRoomNoSyncOrder
        }
        if let error = error {
            Toast.show(error)
            return
        }

        let block: ((Bool) -> Void) = { [weak self] enabled in
            guard let self = self else { return }
            if !self.viewModel.meeting.myself.isHost {
                Toast.show(I18n.View_G_CancelHostPermit)
                return
            }
            if enabled {
                self.gridViewModel.beginSyncingGridOrder(syncToServer: true, resetFirstPage: true, becomeHost: false)
            } else {
                Toast.show(I18n.View_G_StoppedSyncingToast)
                self.gridViewModel.endSyncingGridOrder()
            }
        }
        if enabled {
            let title: String
            if self.viewModel.meeting.webinarManager?.stageInfo != nil {
                title = I18n.View_G_OrderNoSyncStagePop
            } else if isWebinar {
                title = I18n.View_G_SyncVideoOrderAttendeePop
            } else {
                title = I18n.View_G_SyncVideoOrderAllPop
            }
            ByteViewDialog.Builder()
                .title(title)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    InMeetSceneTracks.trackToggleCustomOrderPopup(name: "confirm_host_sync_video_order", confirm: false)
                })
                .rightTitle(I18n.View_G_SyncVideoButton)
                .rightHandler({ _ in
                    block(true)
                    InMeetSceneTracks.trackToggleCustomOrderPopup(name: "confirm_host_sync_video_order", confirm: true)
                })
                .show()
        } else {
            ByteViewDialog.Builder()
                .colorTheme(.redLight)
                .title(I18n.View_G_ConfirmStopSyncVideoOrderPop)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    InMeetSceneTracks.trackToggleCustomOrderPopup(name: "stop_host_sync_video_order", confirm: false)
                })
                .rightTitle(I18n.View_G_Window_Confirm_Button)
                .rightHandler({ _ in
                    block(false)
                    InMeetSceneTracks.trackToggleCustomOrderPopup(name: "stop_host_sync_video_order", confirm: true)
                })
                .show()
        }
    }

    func sceneSelectionViewDidResetOrder() {
        guard let container = container else {
            return
        }
        sceneSelectionViewController?.dismiss(animated: true)
        InMeetSceneTracks.trackClickResetOrder(isSharing: container.contentMode.isShareContent,
                                               isSharer: viewModel.meeting.shareData.isSelfSharingContent,
                                               scene: container.sceneMode)
        // 如果当前正在主动同步，则需要手动取消同步
        if gridViewModel.isGridOrderSyncing {
            let title = isWebinar ? I18n.View_G_ResetOrderAttendeePop : I18n.View_G_ResetWillStopSyncingPop
            ByteViewDialog.Builder()
                .colorTheme(.redLight)
                .title(title)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    InMeetSceneTracks.trackToggleCustomOrderPopup(name: "confirm_reset_video_order", confirm: false)
                })
                .rightTitle(I18n.View_G_Reset_Button)
                .rightHandler({ [weak self] _ in
                    guard let self = self else { return }
                    InMeetSceneTracks.trackToggleCustomOrderPopup(name: "confirm_reset_video_order", confirm: true)
                    if !self.viewModel.meeting.myself.isHost {
                        return
                    }
                    self.resetGridOrder()
                })
                .show()
        } else {
            resetGridOrder()
        }
    }

    func sceneSelectionViewDidToggleShowSpeakerOnMainView(_ enabled: Bool) {
        guard let container = container else {
            return
        }
        InMeetSceneTracks.trackClickShowSpeaker(onMain: enabled)
        sceneSelectionViewController?.dismiss(animated: true)
        container.context.isShowSpeakerOnMainScreen = enabled
    }
}

extension InMeetTopBarComponent: InMeetDataListener {
    func didChangeWhiteboardOperateStatus(isOpaque: Bool) {
        topBar.updateWhiteboardOpaque(isOpaque)
    }
}

extension InMeetTopBarComponent: InMeetStatusManagerListener {
    func statusDidChange(type: InMeetStatusType) {
        Util.runInMainThread {
            guard let index = Self.navigationBarStatuses.firstIndex(where: { $0 == type }) else { return }
            self.statuses[index] = self.statusManager.thumbnails[type]
            if type == .interpreter, let icon = self.statusManager.statuses[type]?.icon {
                self.statuses[index]?.icon = icon
            }
            self.updateStatuses()
        }
    }
}

extension InMeetTopBarComponent {
    // 是否为Webinar会议
    var isWebinar: Bool {
        viewModel.meeting.subType == .webinar
    }
}

extension InMeetTopBarComponent: JoinRoomTogetherViewControllerDelegate {
    func didConnectRoom(_ controller: UIViewController, room: ByteviewUser) {
    }

    func didDisconnectRoom(_ controller: UIViewController?, room: ByteviewUser) {
    }

    func joinRoomViewControllerDidAppear(_ controller: JoinRoomTogetherViewController) {
        topBar.joinRoomButton.isSelected = controller.style == .popover
    }

    func joinRoomViewControllerWillDisappear(_ controller: JoinRoomTogetherViewController) {
        topBar.moreButton.isSelected = false
        topBar.joinRoomButton.isSelected = false
    }

    func joinRoomViewControllerDidChangeStyle(_ controller: JoinRoomTogetherViewController, style: JoinRoomViewStyle) {
        topBar.joinRoomButton.isSelected = controller.style == .popover
    }
}

extension InMeetViewContainer {
    var topBar: InMeetNavigationBar? {
        if let component = component(by: .topBar) as? InMeetTopBarComponent {
            return component.topBar
        }
        return nil
    }
}

extension InMeetTopBarComponent: ActionSheetControllerDelegate {
    func viewWillDisappear() {
        topBar.moreButton.isSelected = false
    }
    func viewWillAppear() {
        topBar.moreButton.isSelected = true
    }
}

extension InMeetTopBarComponent: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        topBar.shareScene = newScene
    }
}

extension InMeetTopBarComponent: ToolBarViewModelDelegate {
    func toolbarItemDidChange(_ item: ToolBarItem) {
        Util.runInMainThread {
            self.updateBarItem(item)
        }
    }
}

extension InMeetTopBarComponent: ToolBarViewModelBridge {
    func toggleToolBarStatus(expanded: Bool, completion: (() -> Void)?) {
        guard let landscapeTools = container?.component(by: .landscapeTools) as? InMeetLandscapeToolsComponent else { return }
        if expanded {
            Logger.ui.info("TopBar didClickMore")
            landscapeTools.showLandscapeMoreView()
            completion?()
        } else {
            landscapeTools.hideLandscapeMoreView(completion: completion)
        }
    }

    func itemView(with type: ToolBarItemType) -> UIView? {
        topBar.toolbarItemViews.first(where: { $0.itemType == type })
    }
}
