//
// Created by liujianlong on 2022/8/18.
//

import Foundation
import RxSwift
import ByteViewNetwork

protocol MeetingSceneModeListener: AnyObject {
    func containerDidChangeFocusing(container: InMeetViewContainer,
                                    isFocusing: Bool)
    func containerDidChangeSceneMode(container: InMeetViewContainer,
                                     sceneMode: InMeetSceneManager.SceneMode)
    func containerDidChangeContentMode(container: InMeetViewContainer,
                                       contentMode: InMeetSceneManager.ContentMode)
    func containerDidChangeWebinarStageInfo(container: InMeetViewContainer,
                                            webinarStageInfo: WebinarStageInfo?)
}

extension MeetingSceneModeListener {
    func containerDidChangeFocusing(container: InMeetViewContainer,
                                    isFocusing: Bool) {}
    func containerDidChangeSceneMode(container: InMeetViewContainer,
                                     sceneMode: InMeetSceneManager.SceneMode) {}
    func containerDidChangeWebinarStageInfo(container: InMeetViewContainer,
                                            webinarStageInfo: WebinarStageInfo?) {}
    func containerDidChangeContentMode(container: InMeetViewContainer,
                                       contentMode: InMeetSceneManager.ContentMode) {}
}

class InMeetSceneManager {
    enum SceneMode: String {
        // 宫格视图
        case gallery
        // 演讲者视图
        case speech
        // 缩略视图
        case thumbnailRow
        // Webinar 舞台模式
        case webinarStage
    }

    enum ContentMode: Equatable {
        case flow
        case shareScreen
        case follow
        case whiteboard
        case selfShareScreen
        case webSpace

        var isShareContent: Bool {
            switch self {
            case .flow:
                return false
            default:
                return true
            }
        }

        var isShareScreenOrWhiteboard: Bool {
            switch self {
            case .shareScreen, .whiteboard, .selfShareScreen:
                return true
            default:
                return false
            }
        }

        var isMobileLandscapeShareContent: Bool {
            switch self {
            case .shareScreen, .whiteboard:
                return true
            default:
                return false
            }
        }

        var enableSpeechSwitch: Bool {
            switch self {
            case .selfShareScreen, .webSpace:
                return false
            default:
                return true
            }
        }

        var enableShowSpeakOnMainView: Bool {
            switch self {
            case .selfShareScreen, .webSpace, .flow:
                return false
            default:
                return true
            }
        }
    }

    enum SettingEnableType {
        case none // 不展示入口
        case disable(String?) // 展示入口但不可点击，点击弹Toast
        case enable // 展示入口且可以点击

        var isHidden: Bool {
            switch self {
            case .none:
                return true
            default:
                return false
            }
        }

        var isEnabled: Bool {
            switch self {
            case .enable:
                return true
            default:
                return false
            }
        }
    }

    private let disposeBag = DisposeBag()

    private(set) var sceneMode: SceneMode {
        didSet {
            guard self.sceneMode != oldValue else {
                return
            }
            Logger.scene.info("sceneMode change \(oldValue) --> \(self.sceneMode)")
            self.updateSceneController()
            if let container = self.container {
                container.context.meetingScene = sceneMode
                if sceneMode != .speech {
                    container.context.floatingSpeechState = nil
                    container.context.isSpeechFlowSwitched = false
                }
                (container as? MeetingSceneModeListener)?.containerDidChangeSceneMode(container: container, sceneMode: self.sceneMode)
            }
        }
    }

    private(set) var contentMode: ContentMode = .flow {
        didSet {
            guard self.contentMode != oldValue else {
                return
            }
            Logger.scene.info("content change \(oldValue) --> \(self.contentMode)")
            self.container?.context.sceneControllerState.content = self.contentMode

            // 共享内容切换，取消单流放大
            // https://meego.feishu.cn/larksuite/issue/detail/6223460
            hideSingleVideo()

            container?.context.meetingContent = contentMode
            if let context = container?.context, context.isSketchMenuEnabled, context.meetingContent != .shareScreen {
                context.isSketchMenuEnabled = false
            }
            sceneStrategy.contentMode = self.contentMode
            self.sceneMode = sceneStrategy.sceneMode

            self.updateHideSelf()
            // sceneController 放在最后更新，避免无效操作，因为 `updateSceneMode` 可能会替换 sceneController
            self.sceneController?.content = contentMode
            if let container = self.container {
                (container as? MeetingSceneModeListener)?.containerDidChangeContentMode(container: container, contentMode: self.contentMode)
            }
        }
    }

    var webinarStageInfo: WebinarStageInfo? {
        get {
            sceneStrategy.webinarStageInfo
        }
        set {
            guard self.sceneStrategy.webinarStageInfo != newValue else {
                return
            }
            sceneStrategy.webinarStageInfo = newValue
            self.sceneMode = sceneStrategy.sceneMode
            if let container = self.container {
                (container as? MeetingSceneModeListener)?.containerDidChangeWebinarStageInfo(container: container,
                                                                                             webinarStageInfo: webinarStageInfo)
            }
        }
    }

    var isFocusing: Bool {
        get {
            self.sceneStrategy.isFocusing
        }
        set {
            guard self.sceneStrategy.isFocusing != newValue else {
                return
            }
            self.sceneStrategy.isFocusing = newValue
            self.sceneMode = self.sceneStrategy.sceneMode
            if let container = self.container {
                (container as? MeetingSceneModeListener)?.containerDidChangeFocusing(container: container,
                                                                                     isFocusing: isFocusing)
            }
        }
    }

    var is1V1: Bool {
        get {
            sceneStrategy.is1V1
        }
        set {
            sceneStrategy.is1V1 = newValue
            self.sceneMode = self.sceneStrategy.sceneMode
        }
    }

    var hasHostCohostAuthority: Bool {
        get {
            sceneStrategy.hasHostCohostAuthority
        }

        set {
            sceneStrategy.hasHostCohostAuthority = newValue
            self.sceneMode = self.sceneStrategy.sceneMode
        }
    }

    var hideSelfEnabled: Bool {
        if contentMode.isShareContent {
            return true
        } else {
            return meeting.participant.currentRoom.nonRingingCount > 1
        }
    }

    var isWebinar: Bool {
        meeting.subType == .webinar
    }

    let isWebinarAttendee: Bool

    var hasSwitchSceneEntrance: Bool {
        self.sceneStrategy.hasSwitchSceneEntrance
    }

    var hideNonVideoParticipantsEnabled: SettingEnableType {
        if meeting.participant.currentRoom.nonRingingCount <= 1 {
            return .none
        } else if gridVM.isSyncingOthers {
            return .disable(isWebinar ? I18n.View_G_SyncedOrderNoHideWeb : I18n.View_G_SyncedOrderNoHide)
        }
        return .enable
    }

    let meeting: InMeetMeeting
    weak var container: InMeetViewContainer?
    weak var context: InMeetViewContext?
    private let sceneStrategy: SceneSwitchStrategy
    private let gridVM: InMeetGridViewModel

    init(meeting: InMeetMeeting,
         sceneControllerState: SceneSwitchStrategy.SceneControllerState,
         gridVM: InMeetGridViewModel) {
        self.contentMode = sceneControllerState.content
        self.isWebinarAttendee = meeting.webinarManager?.isWebinarAttendee ?? false

        self.sceneStrategy = SceneSwitchStrategy(state: sceneControllerState, hasSwitchSceneEntrance: Display.pad && !self.isWebinarAttendee, storage: meeting.storage)

        self.meeting = meeting
        self.gridVM = gridVM

        self.sceneMode = sceneStrategy.sceneMode
        Logger.scene.info("initialScene: \(sceneControllerState)")
    }

    deinit {
        Logger.scene.info("InMeetSceneManager deinit")
        if let context = self.context {
            self.sceneStrategy.saveSceneState(&context.sceneControllerState)
        }
    }

    func setup(container: InMeetViewContainer) {
        if Display.phone {
            InMeetOrientationToolComponent.isLandscapeModeRelay.asObservable()
                    .subscribe(onNext: { [weak self] b in
                        guard let self = self else {
                            return
                        }
                        self.sceneStrategy.isMobileLandscapeMode = b
                        self.sceneMode = self.sceneStrategy.sceneMode
                    })
                    .disposed(by: self.disposeBag)
        }
        container.context.meetingScene = sceneMode
        container.context.meetingContent = contentMode
        if sceneMode != .speech {
            container.context.floatingSpeechState = nil
            container.context.isSpeechFlowSwitched = false
        }
        sceneStrategy.saveSceneState(&container.context.sceneControllerState)

        (container as? MeetingSceneModeListener)?.containerDidChangeSceneMode(container: container,
                                                                              sceneMode: self.sceneMode)

        (container as? MeetingSceneModeListener)?.containerDidChangeFocusing(container: container,
                                                                             isFocusing: self.isFocusing)

        (container as? MeetingSceneModeListener)?.containerDidChangeWebinarStageInfo(container: container,
                                                                                     webinarStageInfo: self.webinarStageInfo)

        (container as? MeetingSceneModeListener)?.containerDidChangeContentMode(container: container,
                                                                                contentMode: self.contentMode)


        self.container = container
        self.context = container.context
        self.updateSceneController()

        self.showGuideIfNeeded()
    }

    func beginShareContent(_ content: ContentMode) {
        Util.runInMainThread {
            self.contentMode = content
        }
    }

    func endShareContent(_ content: ContentMode) {
        Util.runInMainThread {
            guard self.contentMode == content else {
                return
            }
            self.contentMode = .flow
        }
    }

    func checkAllowUserSwitchScene(_ sceneMode: InMeetSceneManager.SceneMode?, showToast: Bool) -> Bool {
        if self.isFocusing {
            if showToast {
                Toast.show(I18n.View_G_HostSetFocusNoChange_Toast)
            }
            return false
        }
        if let stageInfo = self.webinarStageInfo,
           self.contentMode != .selfShareScreen,
           !stageInfo.allowGuestsChangeView,
           !self.hasHostCohostAuthority {
            if let syncUser = stageInfo.syncUser,
               showToast {
                self.meeting.httpClient.participantService.participantInfo(pid: syncUser,
                                                                           meetingId: self.meeting.meetingId,
                                                                           completion: { pInfo in
                    Util.runInMainThread {
                        Toast.show(I18n.View_G_NameSyncingNoSwitch(name: pInfo.name))
                    }
                })
            }
            return false
        }
        if sceneMode == .webinarStage && self.contentMode == .selfShareScreen {
            if showToast {
                Toast.show(I18n.View_MV_CantSwitchToStageWhenSharing_Toast)
            }
            return false
        }
        return true
    }

    func switchSceneMode(_ sceneMode: SceneMode) {
        assert(hasSwitchSceneEntrance)

        self.sceneStrategy.onUserSwitchScene(sceneMode: sceneMode)
        self.sceneMode = self.sceneStrategy.sceneMode
    }

    var shareComponent: InMeetShareComponent? {
        guard let container = self.container,
              let shareComponent = container.component(by: .share) as? InMeetShareComponent else {
            return nil
        }
        return shareComponent
    }

    private(set) var sceneController: InMeetSceneController?
    private func updateSceneController() {
        guard let container = self.container else {
            return
        }
        Logger.scene.info("updateSceneController \(self.sceneMode)")
        UIView.performWithoutAnimation {
            if let oldLayoutGuideHelper = self.sceneController {
                container.removeContent(oldLayoutGuideHelper, level: .sceneLayoutController)
            }
            self.sceneController = container.makeSceneController(content: self.contentMode, scene: self.sceneMode)
            self.sceneController?.sceneControllerDelegate = self
            if let sceneController = self.sceneController {
                container.addContent(sceneController, level: .sceneLayoutController)
                sceneController.view.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            container.view.layoutIfNeeded()
            if Display.phone, #available(iOS 16.0, *) {
                self.gridVM.router.topMost?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }

    private func hideSingleVideo() {
        if let component = container?.component(by: .singleVideo) as? InMeetSingleVideoComponent {
            // 离开或进入共享场景时需要隐藏 PIN 视图
            // https://meego.feishu.cn/larksuite/issue/detail/6223460
            component.hideSingleVideo(animated: false)
        }
    }

    func updateHideSelf() {
        guard let container = self.container else { return }
        let isHideSelf: Bool
        let isSettingHideSelf = container.context.isSettingHideSelf
        // 仅设置打开 && 可以隐藏自己，才真正隐藏自己
        if isSettingHideSelf && self.hideSelfEnabled {
            isHideSelf = true
        } else {
            isHideSelf = false
        }
        container.context.isHideSelf = isHideSelf
    }

    func updateHideNonVideo() {
        guard let container = self.container else { return }
        if case .enable = hideNonVideoParticipantsEnabled, container.context.isSettingHideNonVideoParticipants {
            container.context.isHideNonVideoParticipants = true
        } else {
            container.context.isHideNonVideoParticipants = false
        }
    }
}

// guide
extension InMeetSceneManager {
    func showGuideIfNeeded() {
        guard hasSwitchSceneEntrance,
              meeting.service.shouldShowGuide(.padChangeSceneMode) else {
            return
        }

        let guide = GuideDescriptor(type: .padChangeSceneMode, title: nil, desc: I18n.View_G_MultipleViewOnline)
        guide.style = .plain
        guide.sureAction = { [weak self] in
            self?.meeting.service.didShowGuide(.padChangeSceneMode)
        }
        GuideManager.shared.request(guide: guide)
    }
}

protocol SceneControllerDelegate: AnyObject {
    func goBackToShareContent(from: BackToShareFrom, location: BackToShareLocation)
}

protocol InMeetSceneController: UIViewController {
    var sceneControllerDelegate: SceneControllerDelegate? { get set }
    var content: InMeetSceneManager.ContentMode { get set }
    var childVCForStatusBarStyle: InMeetOrderedViewController? { get }
    var childVCForOrientation: InMeetOrderedViewController? { get }
}


enum BackToShareFrom {
    case galleryLayout
    case pinActiveSpeaker
}

enum BackToShareLocation {
    case userMenu
    case topBar
    case singleClickSpeaker
    case doubleClickSharing
}

extension InMeetSceneManager: SceneControllerDelegate {
    func goBackToShareContent(from: BackToShareFrom, location: BackToShareLocation) {
        InMeetSceneTracks.trackBackToShare(from: from,
                                           location: location,
                                           scene: self.sceneMode,
                                           isSharing: self.contentMode.isShareContent,
                                           isSharer: self.meeting.shareData.isSelfSharingContent)
        self.container?.context.isShowSpeakerOnMainScreen = false
        if sceneMode == .gallery {
            let scene = sceneStrategy.lastShareSceneMode ?? self.shareScene
            self.switchSceneMode(scene)
        }
    }
}

extension InMeetSceneManager {
    var shareScene: SceneMode {
        get {
            meeting.storage.string(forKey: .shareScene).flatMap({ SceneMode(rawValue: $0) }) ?? .thumbnailRow
        }
        set {
            guard self.shareScene != newValue, newValue != .gallery else { return }
            Logger.scene.info("set shareScene \(newValue)")
            meeting.storage.set(newValue.rawValue, forKey: .shareScene)
        }
    }
}


extension  InMeetSceneManager {
    var childViewControllerForStatusBarStyle: InMeetOrderedViewController? {
        self.sceneController?.childVCForStatusBarStyle
    }

    var childViewControllerForOrientation: InMeetOrderedViewController? {
        self.sceneController?.childVCForOrientation
    }
}
