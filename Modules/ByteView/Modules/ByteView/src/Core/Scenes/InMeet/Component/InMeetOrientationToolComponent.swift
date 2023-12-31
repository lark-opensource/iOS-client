//
//  InMeetOrientationToolComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

// nolint: magic_number
import Foundation
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import UIKit
import ByteViewTracker
import ByteViewSetting
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignColor

struct MobileOrientationButtonState {
    var isWebinarStage: Bool = false
    var endWebinarStageInLandscape: Bool = false
    var isSharing: Bool = false
    var endSharingInLandscape: Bool = false
    var isLandscape: Bool = false
    var meetingLayoutStyle: MeetingLayoutStyle = .tiled
    let canOrientationManually: Bool

    init(canOrientationManually: Bool = true) {
        self.canOrientationManually = canOrientationManually
    }

    mutating func handleLayoutStyleChange(layoutStyle: MeetingLayoutStyle) {
        self.meetingLayoutStyle = layoutStyle
    }

    mutating func handleIsWebinarStageChanged(isWebinarStage: Bool) {
        if self.isWebinarStage && !isWebinarStage && self.isLandscape {
            self.endWebinarStageInLandscape = true
        }
        self.isWebinarStage = isWebinarStage
    }

    mutating func orientationChange(isLandscape: Bool) {
        if !isLandscape {
            self.endWebinarStageInLandscape = false
            self.endSharingInLandscape = false
        }
        self.isLandscape = isLandscape
    }

    mutating func handleIsSharingChanged(isSharing: Bool) {
        if self.isSharing && !isSharing && self.isLandscape {
            self.endSharingInLandscape = true
        }
        self.isSharing = isSharing
    }

    var shouldDisplayOrientationButton: Bool {
        return canOrientationManually && meetingLayoutStyle != .fullscreen && (isWebinarStage || endWebinarStageInLandscape || isSharing || endSharingInLandscape)
    }
}

/// 可旋转时的横竖屏切换按钮，包含相邻的扬声器切换按钮
/// orientationToolbar只在手机中用，故pad禁用无需管理
final class InMeetOrientationToolComponent: InMeetViewComponent {
    let orientationToolbar: InMeetOrientationToolView
    private lazy var orientationButton: UIButton = makeOrientationButton()
    private var orientationButtonState: MobileOrientationButtonState

    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let view: UIView
    let disposeBag = DisposeBag()
    var layoutStyle: MeetingLayoutStyle
    var isKeyboardDisplaying: Bool = false
    var keyboardDisplayHeight: CGFloat = 0.0
    var currentLayoutType: LayoutType
    fileprivate var prevContainerViewSize: CGSize?
    private weak var container: InMeetViewContainer?
    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.meeting = viewModel.meeting
        self.context = viewModel.viewContext
        self.currentLayoutType = layoutContext.layoutType
        self.orientationButtonState = .init(canOrientationManually: viewModel.meeting.setting.canOrientationManually)
        Self.statusBarOrientationRelay.accept(container.view.orientation ?? (Display.pad ? .landscapeRight : .portrait))
        self.orientationToolbar = InMeetOrientationToolView(meeting: meeting)
        self.view = container.addContent(self.orientationToolbar, level: .orientation)
        self.layoutStyle = context.meetingLayoutStyle
        self.container = container
        orientationToolbar.isHidden = true
        orientationToolbar.delegate = self
    }

    func containerDidLoadComponent(container: InMeetViewContainer) {
        context.addListener(self, for: [.containerDidLayout, .subtitle, .sketchMenu, .contentScene, .singleVideo, .whiteboardMenu, .interpretation, .whiteboardEditAuthority, .whiteboardOperateStatus])
        /// 监听MagicShare文档的变化，如果文档有变化，调用一次代理方法，促使orientationToolView重新设置显隐等属性
        container.viewModel.resolver.resolve(InMeetFollowManager.self)?.addListener(self)
        context.fullScreenDetector?.registerInterruptWhiteListView(self.orientationToolbar)
        addKeyboardObserver()
        meeting.volumeManager.addListener(self)
        meeting.setting.addListener(self, for: .showsMicrophone)
        meeting.audioModeManager.addListener(self)
        meeting.webinarManager?.addListener(self)

        guard let rightContainerComponent = container.component(by: .mobileLandscapeRightContainer) as? InMeetMobileLandscapeRightComponent else {
            return
        }
        rightContainerComponent.addWidget(.microphone, nil)

        orientationButtonState.orientationChange(isLandscape: Self.isLandscapeOrientation)
        orientationButtonState.handleIsWebinarStageChanged(isWebinarStage: meeting.webinarManager?.stageInfo != nil)
        orientationButtonState.handleLayoutStyleChange(layoutStyle: container.meetingLayoutStyle)
        orientationButtonState.handleIsSharingChanged(isSharing: context.meetingContent.isShareScreenOrWhiteboard)
        updateOrientationButtonVisibility()
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        layoutStyle = context.meetingLayoutStyle
        self.orientationButtonState.handleLayoutStyleChange(layoutStyle: container.meetingLayoutStyle)
        Util.runInMainThread { [weak self] in
            self?.updateOrientationToolView()
        }
    }

    deinit {
        context.fullScreenDetector?.unregisterInterruptWhiteListView(self.orientationToolbar)
        NotificationCenter.default.removeObserver(self)
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .orientation
    }

    func setupConstraints(container: InMeetViewContainer) {
        let accessory = container.accessoryGuide
        view.snp.remakeConstraints { (maker) in
            maker.edges.equalTo(accessory)
        }
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
        Self.statusBarOrientationRelay.accept(self.container?.view.orientation ?? (Display.pad ? .landscapeRight : .portrait))
        self.updateOrientationToolView()
        self.orientationButtonState.orientationChange(isLandscape: self.container?.view.isLandscape ?? false)
        self.updateOrientationButtonVisibility()
        if newContext.layoutChangeReason.isOrientationChanged {
            MeetingTracksV2.trackChangeOrientation(toLandscape: container?.view.isLandscape ?? false, reason: .gravity)
        }
    }

    static let statusBarOrientationRelay: BehaviorRelay<UIInterfaceOrientation> = {
        let currentOrientation: UIInterfaceOrientation
        if #available(iOS 13, *) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { (scene) -> Bool in
                return scene.activationState == .foregroundActive && scene.session.role == .windowApplication
            }) as? UIWindowScene {
                currentOrientation = scene.interfaceOrientation
            } else {
                currentOrientation = Display.pad ? .landscapeRight : .portrait
            }
        } else {
            currentOrientation = UIApplication.shared.statusBarOrientation
        }
        let val: BehaviorRelay<UIInterfaceOrientation> = BehaviorRelay(value: currentOrientation)
        return val
    }()

    static var isLandscapeOrientation: Bool {
        statusBarOrientationRelay.value.isLandscape
    }

    static let isLandscapeOrientationRelay: Observable<Bool> = {
        statusBarOrientationRelay
            .asObservable()
            .map(\.isLandscape)
            .distinctUntilChanged()
    }()

    static var isPhoneLandscapeMode: Bool {
        Display.phone && self.isLandscapeOrientation
    }

    static let isLandscapeModeRelay: Observable<Bool> =
    {
        if !Display.phone {
            return .just(false)
        }
        return isLandscapeOrientationRelay
    }()

    private var magicShareDocType: FollowShareSubType? {
        guard context.meetingContent == .follow else { return nil }
        return meeting.shareData.shareContentScene.magicShareDocument?.shareSubType
    }

    private var isLandscapeFollow: Bool {
        if let docType = magicShareDocType {
            return [.ccmSheet, .ccmPpt, .ccmWikiSheet, .ccmBitable].contains(docType)
        }
        return false
    }

    private var mayUpdateOrientationToolView: Bool {
        let isPhone = Display.phone
        let isKeyboardValid = (isKeyboardDisplaying) && (keyboardDisplayHeight > 0) // 仅判断弹起的通知会不准确，增加键盘高度辅助判断
        return isPhone && (currentLayoutType.isPhoneLandscape || context.meetingContent.isShareScreenOrWhiteboard) && !isKeyboardValid // 弹起键盘时隐藏侧边栏
    }

    private var needResetOrientationToolBar = true

    private var draggableMargin: UIEdgeInsets {
        let margin: CGFloat = currentLayoutType.isPhoneLandscape ? 0 : 16
        return UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }

    private var forbiddenRegions: [CGRect] {
        if !currentLayoutType.isPhoneLandscape { return [] }
        let accessoryViews = container?.context.accessoryViews ?? []
        return accessoryViews
            .filter { !$0.isHidden }
            .map { $0.convert($0.bounds, to: self.view) }
    }

    private func updateOrientationToolView() {
        guard self.mayUpdateOrientationToolView else {
            orientationToolbar.isHidden = true
            updateOrientationButtonVisibility()
            return
        }

        let isMicHidden: Bool
        if !meeting.setting.showsMicrophone {
            isMicHidden = true
        } else if meeting.audioModeManager.bizMode.canShowMic {
            isMicHidden = !(context.isSketchMenuEnabled || context.isWhiteboardMenuEnabled || currentLayoutType.isPhoneLandscape) || (context.meetingLayoutStyle == .fullscreen && Display.phone && currentLayoutType.isCompact)
        } else {
            isMicHidden = true
        }
        // disable-lint: magic number
        var initialMargin: UIEdgeInsets = .zero
        if currentLayoutType.isPhoneLandscape, let docType = self.magicShareDocType {
            switch docType {
            case .ccmSheet, .ccmWikiSheet, .ccmBitable:
                initialMargin.bottom = 60
            case .ccmPpt:
                initialMargin.bottom = 54
            default:
                initialMargin.bottom = 0
            }
        }
        if Display.phone {
            if context.isInterpreter, currentLayoutType.isCompact, context.isWhiteboardMenuEnabled {
                initialMargin.bottom = 48
            } else if currentLayoutType.isPhoneLandscape, !context.isWhiteboardMenuEnabled, context.isWhiteboardEditEnable {
                initialMargin.bottom = 68
            }
        }
        // enable-lint: magic number
        var isResetPosition = false
        if needResetOrientationToolBar {
            isResetPosition = true
        }
        orientationToolbar.updateContext(dragbleMargin: self.draggableMargin,
                                         isMicHidden: isMicHidden,
                                         isFullScreen: context.meetingLayoutStyle == .fullscreen,
                                         isResetPosition: isResetPosition,
                                         initialMargin: initialMargin,
                                         forbiddenRegions: self.forbiddenRegions)
        orientationToolbar.isHidden = isMicHidden
        updateOrientationButtonVisibility()
    }
}

extension InMeetOrientationToolComponent: InMeetFollowListener {
    func didUpdateLocalDocuments(_ documents: [MagicShareDocument], oldValue: [MagicShareDocument]) {
        Util.runInMainThread { [weak self] in
            if let newDocument = documents.last,
               let oldDocument = oldValue.last,
               newDocument.hasEqualContentTo(oldDocument),
               !(Display.phone && self?.currentLayoutType.isCompact == true) {
                self?.needResetOrientationToolBar = false
            } else {
                self?.needResetOrientationToolBar = true
            }
            self?.updateOrientationToolView()
        }
    }
}

extension InMeetOrientationToolComponent: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .containerDidLayout {
            if prevContainerViewSize != self.view.bounds.size {
                prevContainerViewSize = self.view.bounds.size
                updateOrientationToolView()
            }
            return
        }
        if change == .contentScene {
            orientationButtonState.handleIsSharingChanged(isSharing: context.meetingContent.isShareScreenOrWhiteboard)
            needResetOrientationToolBar = true
        }
        if [.contentScene, .sketchMenu, .whiteboardMenu, .whiteboardEditAuthority].contains(change) {
            orientationToolbar.isPinPosition = true
        }
        if change == .whiteboardOperateStatus, let isOpaque = userInfo as? Bool {
            Util.runInMainThread {
                // disable-lint: magic number
                let alpha: CGFloat = isOpaque ? 1.0 : 0.3
                UIView.animate(withDuration: 0.25, animations: {
                    self.orientationToolbar.alpha = alpha
                })
                // enable-lint: magic number
            }
        }
        updateOrientationToolView()
        orientationToolbar.isPinPosition = false
    }
}

extension InMeetOrientationToolComponent: InMeetOrientationToolViewDelegate {
    func orientationToolbarDidClickMic() {
        guard !meeting.audioModeManager.shouldHandleMicClickEvent() else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        meeting.microphone.muteMyself(!meeting.microphone.isMuted, source: .floating_button, completion: nil)
    }

    static func switchOrientation(for view: UIView) {
        let targetOrientation: UIInterfaceOrientation = view.orientation?.isPortrait == true ? .landscapeRight : .portrait
        UIDevice.updateDeviceOrientationForViewScene(view, to: targetOrientation, animated: true)
    }

    func orientationToolbarPositionChanged() {
        needResetOrientationToolBar = false
    }

    func orientationToolbarPanGestureWillEnd() {
        MeetingTracksV2.trackHaulMic(isSharing: meeting.shareData.isSharingContent)
    }
}

extension InMeetOrientationToolComponent: VolumeManagerDelegate {
    func volumeDidChange(to volume: Int, rtcUid: RtcUID) {
        if rtcUid == meeting.myself.bindRtcUid {
            orientationToolbar.micIconView.micOnView.updateVolume(volume)
        }
    }
}

extension InMeetOrientationToolComponent: InMeetAudioModeListener {
    func didChangeMicState(_ state: MicViewState) {
        updateOrientationToolView()
        orientationToolbar.setMicState(by: state)
    }
}

extension InMeetOrientationToolComponent: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .showsMicrophone {
            DispatchQueue.main.async {
                self.updateOrientationToolView()
            }
        }
    }
}

// MARK: - 监听键盘显隐变化

extension InMeetOrientationToolComponent {
    /// 监听键盘显隐变化，弹起键盘时隐藏侧边栏，键盘隐藏时视情况显示侧边栏
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShowNotification),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHideNotification),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidChangeFrameNotification(noti:)),
                                               name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }

    @objc
    private func keyboardDidChangeFrameNotification(noti: Notification) {
        if let endFrame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            Util.runInMainThread { [weak self] in
                Logger.util.debug("keyboard frame did change")
                self?.keyboardDisplayHeight = endFrame.size.height
                self?.updateOrientationToolView()
            }
        }
    }

    @objc
    private func keyboardDidShowNotification() {
        Logger.util.debug("keyboard did show, hide orientation tool")
        Util.runInMainThread { [weak self] in
            self?.isKeyboardDisplaying = true
            self?.updateOrientationToolView()
        }
    }

    @objc
    private func keyboardDidHideNotification() {
        Logger.util.debug("keyboard did hide, show orientation tool")
        Util.runInMainThread { [weak self] in
            self?.isKeyboardDisplaying = false
            self?.updateOrientationToolView()
        }
    }
}

extension InMeetOrientationToolComponent: WebinarRoleListener {
    func webinarDidChangeStageInfo(stageInfo: WebinarStageInfo?, oldValue: WebinarStageInfo?) {
        Util.runInMainThread {
            self.orientationButtonState.handleIsWebinarStageChanged(isWebinarStage: stageInfo != nil)
            self.updateOrientationButtonVisibility()
        }
    }
}

extension InMeetOrientationToolComponent {
    // MARK: - Phone change orientation -
    static let landscapeImage = UDIcon.getIconByKey(.landscapeModeColorful, iconColor: UDColor.iconN1, size: CGSize(width: 24.0, height: 24.0))

    private func makeOrientationButton() -> UIButton {
        var config = UDButtonUIConifg.defaultConfig
        config.type = .custom(from: .small,
                              size: CGSize(width: 48.0, height: 48.0),
                              inset: 0,
                              iconSize: CGSize(width: 24.0, height: 24.0))
        config.radiusStyle = .circle
        config.normalColor = .init(borderColor: UDColor.lineBorderCard,
                                   backgroundColor: UDColor.bgFloat,
                                   textColor: UDColor.iconN1)
        config.pressedColor = .init(borderColor: UDColor.lineBorderCard,
                                    backgroundColor: UDColor.bgFloat,
                                    textColor: UDColor.iconN1)
        let button = UDButton(config)
        button.setImage(Self.landscapeImage, for: .normal)
        button.imageEdgeInsets = .zero
        button.layer.ud.setShadow(type: .s4Down)

        button.addTarget(self, action: #selector(handleOrientationButtonTapped), for: .touchUpInside)

        return button
    }

    private func updateOrientationButtonVisibility() {
        guard Display.phone && self.meeting.setting.canOrientationManually,
              let container = self.container,
              let rightContainerComponent = container.component(by: .mobileLandscapeRightContainer) as? InMeetMobileLandscapeRightComponent else {
            return
        }
        let shouldDisplay = orientationButtonState.shouldDisplayOrientationButton
        if shouldDisplay && Self.isLandscapeOrientation {
            rightContainerComponent.addWidget(.orientation, self.orientationButton)
            var bottomInset = 0.0
            if self.magicShareDocType != nil {
                // 仅文档需要避让内部一些按钮，其他情况暂时不需要
                bottomInset = orientationToolbar.extraMargin.bottom
            }
            rightContainerComponent.updateBottomInset(bottomInset)
        } else if shouldDisplay {
            rightContainerComponent.removeWidget(.orientation)
            self.view.addSubview(self.orientationButton)
            var rightMargin = -12.0
            var bottomMargin = -12.0
            if !self.orientationToolbar.isHidden {
                // 竖屏 mic 显示
                bottomMargin = -72.0 - (context.isInterpreter ? 48 : 0)
                rightMargin = -16.0
            } else if container.context.isWhiteboardEditEnable {
                // 竖屏 白板编辑按钮 显示
                bottomMargin = -68.0
                rightMargin = -8.0
            }

            self.orientationButton.snp.remakeConstraints { make in
                make.size.equalTo(CGSize(width: 48.0, height: 48.0))
                make.bottom.equalTo(container.accessoryGuide).offset(bottomMargin)
                make.right.equalTo(container.accessoryGuide).offset(rightMargin)
            }
        } else {
            rightContainerComponent.removeWidget(.orientation)
            self.orientationButton.removeFromSuperview()
        }
    }

    @objc
    func handleOrientationButtonTapped() {
        let option: String
        if Self.isLandscapeOrientation {
            UIDevice.updateDeviceOrientationForViewScene(to: .portrait)
            option = "landscape_to_portrait"
        } else {
            UIDevice.updateDeviceOrientationForViewScene(to: .landscapeRight)
            option = "portrait_to_landscape"
        }
        var params: TrackParams = [.click: "click_to_change_screen_direction", .option: option]
        let shareData = meeting.shareData
        if shareData.isSharingContent || shareData.isSelfSharingContent {
            let shareType: String
            if shareData.isSharingScreen {
                shareType = "share_screen"
            } else if shareData.isSharingDocument {
                shareType = "magic_share"
            } else if shareData.isSharingWhiteboard {
                shareType = "whiteboard"
            } else {
                shareType = ""
            }
            params["share_type"] = shareType
            params["is_sharer"] = shareData.isSelfSharingContent ? "true" : "false"
        }
        VCTracker.post(name: .vc_meeting_onthecall_click,
                       params: params)
    }

}
