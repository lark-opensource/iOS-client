//
// Created by liujianlong on 2022/8/20.
//

import Foundation
import UniverseDesignColor
import RxSwift
import SnapKit

class GallerySceneController: BaseSceneController {
    override var content: InMeetSceneManager.ContentMode {
        didSet {
            guard self.content != oldValue else {
                return
            }
            updateFlowVCContent()
            updateShareBarDisplayInfo()
            if Display.pad,
               oldValue.isShareContent != self.content.isShareContent {
                self.updateFlowGuide()
            }
        }
    }

    private var flowVC: InMeetFlowViewControllerV2!
    private let flowGuide = UILayoutGuide()
    private let topBarExtendOverlayGuideHelper = UILayoutGuide()

    private let disposeBag = DisposeBag()

    private let shareContentBar = SceneTopStatusBar(regularAlignment: .center, compactAlignment: .center)
    private var shareContentBarBindBag = DisposeBag()

    var isMobileLandscapeMode: Bool = false {
        didSet {
            guard self.isMobileLandscapeMode != oldValue else {
                return
            }
            updateFlowGuide()
            updateFlowVCContent()
        }
    }

    var meetingLayoutStyle: MeetingLayoutStyle {
        didSet {
            guard self.meetingLayoutStyle != oldValue else {
                return
            }
            self.flowVC.meetingLayoutStyle = meetingLayoutStyle
            updateFlowGuide()
        }
    }

    private func attachFlowVC() {
        guard self.flowVC.parent !== self else {
            return
        }
        flowVC.goBackShareContentAction = { [weak self] location in
            self?.sceneControllerDelegate?.goBackToShareContent(from: .galleryLayout, location: location)
        }
        self.addChild(flowVC)
        view.addSubview(flowVC.view)
        flowVC.didMove(toParent: self)

        flowVC.setupExternalContainerGuides(topBarGuide: containerTopBarExtendGuide,
                                            bottomBarGuide: containerBottomBarGuide)
        if let layoutContainer = self.container?.layoutContainer {
            flowVC.didAttachToLayoutContainer(layoutContainer)
        }

        flowVC.view.snp.makeConstraints { make in
            make.edges.equalTo(flowGuide)
        }
    }

    private func detachFlowVC() {
        guard self.flowVC.parent === self else {
            return
        }
        if let layoutContainer = self.container?.layoutContainer {
            flowVC.didDetachFromLayoutContainer(layoutContainer)
        }
        self.flowVC.willMove(toParent: nil)
        self.flowVC.view.removeFromSuperview()
        self.flowVC.removeFromParent()
        self.flowVC.sceneContent = .flow
    }

    private func updateFlowVCContent() {
        guard let container = self.container else {
            return
        }
        if Display.pad {
            self.flowVC.displayMode = .gridVideo
            self.flowVC.sceneContent = self.content
        } else {
            if content.isMobileLandscapeShareContent && self.isMobileLandscapeMode {
                guard self.flowVC.sceneContent != self.content,
                      let shareComponent = container.shareComponent,
                      let vc = shareComponent.makeLandscapeVCWithContent(self.content) else {
//                assertionFailure()
                    return
                }
                detachFlowVC()

                self.flowVC = vc

                self.flowVC.loadViewIfNeeded()
                self.flowVC.meetingLayoutStyle = meetingLayoutStyle
                self.flowVC.displayMode = .gridVideo
                self.flowVC.sceneContent = self.content
                attachFlowVC()
            } else if self.flowVC is InMeetFlowAndShareContainerViewControllerV2 {
                detachFlowVC()

                self.flowVC = container.flowComponent!.getOrCreateFlowVC()
                self.flowVC.loadViewIfNeeded()
                self.flowVC.meetingLayoutStyle = meetingLayoutStyle
                self.flowVC.displayMode = .gridVideo
                self.flowVC.sceneContent = .flow
                attachFlowVC()
            } else {
                self.flowVC.displayMode = .gridVideo
                self.flowVC.sceneContent = .flow
            }
        }
    }

    override init(container: InMeetViewContainer, content: InMeetSceneManager.ContentMode) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
        super.init(container: container, content: content)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.flowVC = container!.flowComponent!.getOrCreateFlowVC()
        self.flowVC.loadViewIfNeeded()
        self.view.addLayoutGuide(flowGuide)
        // 勿删，修复grid拖动时概率消失问题 @huangtao.ht
        self.view.insertSubview(UIView(), at: 0)
        self.view.addLayoutGuide(topBarExtendOverlayGuideHelper)
        updateShareBarStyle()
        updateShareBarDisplayInfo()
        shareContentBar.buttonAction = { [weak self] _ in
            self?.sceneControllerDelegate?.goBackToShareContent(from: .galleryLayout, location: .topBar)
        }
    }

    override func onMount(container: InMeetViewContainer) {
        super.onMount(container: container)
        self.flowVC.meetingLayoutStyle = meetingLayoutStyle
        self.flowVC.displayMode = .gridVideo
        self.updateFlowVCContent()
        // iOS 12 attachFlowVC() -> updateFlowVCContent() 调用顺序下，会出现约束布局崩溃
        attachFlowVC()
        self.updateFlowGuide()

        container.addMeetLayoutStyleListener(self)
        container.context.addListener(self, for: [.containerDidLayout])
        if Display.phone {
            InMeetOrientationToolComponent.isLandscapeModeRelay
                .subscribe(onNext: { [weak self] val in
                    self?.isMobileLandscapeMode = val
                })
                .disposed(by: self.disposeBag)
        }
    }

    override func onUnmount() {
        super.onUnmount()
        self.container?.topExtendContainerComponent?.removeChild(for: .shareContent)
        detachFlowVC()
    }

    private func updateShareBarDisplayInfo() {
        guard Display.pad else {
            return
        }
        let shouldDisplayShareBar = Display.pad && self.content.isShareContent
        if let topBarExtendComponent = self.container?.topExtendContainerComponent {
            if shouldDisplayShareBar {
                topBarExtendComponent.addChild(self.shareContentBar, for: .shareContent)
            } else {
                topBarExtendComponent.removeChild(for: .shareContent)
            }
        }
        self.shareContentBarBindBag = DisposeBag()
        if self.content == .selfShareScreen {
            self.shareContentBar.setButtonText(regular: I18n.View_G_Return, compact: I18n.View_G_Return)
        } else {
            self.shareContentBar.setButtonText(regular: I18n.View_M_BackToSharedContent, compact: I18n.View_G_Return)
        }
        switch self.content {
        case .selfShareScreen, .webSpace:
            self.shareContentBar.setLabelText(regular: I18n.View_M_NowSharingToast, compact: I18n.View_M_NowSharingToast)
        case .shareScreen:
            let vm = self.container?.shareComponent?.shareScreenVM
            vm?.shareScreenGridInfo
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] (v: InMeetShareScreenVM.ShareScreenInfo?) in
                        guard let info = v, let self = self else {
                            return
                        }
                        // 捕获 VM 避免 VM 析构
                        let displayText = info.isSharingPause ? I18n.View_G_NameSharingPaused(info.name) : I18n.View_VM_SharingNameBraces(info.name)
                        _ = vm
                        self.shareContentBar.setLabelText(regular: displayText,
                                                          compact: displayText)
                    })
                    .disposed(by: self.shareContentBarBindBag)
        case .follow:
            let vm = self.container?.shareComponent?.followViewModel
            if let vm = vm {
                Observable.combineLatest(vm.shareUserName, vm.magicShareDocumentRelay.asObservable())
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] (name: String, v: MagicShareDocument?) in
                            guard let self = self else {
                                return
                            }
                            // 捕获 VM 避免 VM 析构
                            _ = vm
                            if vm.meeting.shareData.isSelfSharingContent {
                                self.shareContentBar.setLabelText(regular: I18n.View_VM_YouAreSharingFileName(v?.nonEmptyDocTitle ?? ""),
                                                                  compact: I18n.View_VM_NowSharing)
                            } else {
                                self.shareContentBar.setLabelText(regular: I18n.View_VM_NameIsSharingFileName(name, v?.nonEmptyDocTitle ?? ""),
                                                                  compact: I18n.View_VM_SharingDocNameBraces(name))
                            }
                        })
                        .disposed(by: self.shareContentBarBindBag)
            }
        case .whiteboard:
            let vm = self.container?.shareComponent?.whiteBoardViewModel
            vm?.userNameObservable
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] s in
                        // 捕获 VM 避免 VM 析构
                        _ = vm
                        let displayName = I18n.View_G_NameSharingBoard_Status(s)
                        self?.shareContentBar.setLabelText(regular: displayName, compact: displayName)
                    })
                    .disposed(by: self.shareContentBarBindBag)
        case .flow:
            self.shareContentBar.setLabelText(regular: "", compact: "")
        }
    }

    private func updateShareBarStyle() {
        shareContentBar.minSpacing = 12.0
        self.shareContentBar.updateStatusBarStyle()
    }

    private func updateFlowGuide() {
        guard self.isMounted else {
            return
        }
        self.topBarExtendOverlayGuideHelper.snp.remakeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.height.equalTo(self.containerTopBarExtendGuide)
        }
        flowGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            if meetingLayoutStyle.isOverlayFullScreen {
                if content.isShareContent && Display.pad {
                    make.top.equalTo(self.topBarExtendOverlayGuideHelper.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
                make.bottom.equalToSuperview()
            } else if isMobileLandscapeMode {
                make.top.bottom.equalToSuperview()
            } else {
                make.top.equalTo(containerTopBarExtendGuide.snp.bottom)
                make.bottom.equalTo(containerBottomBarGuide.snp.top)
            }
        }
    }

    override var childVCForOrientation: InMeetOrderedViewController? {
        if let vc = self.flowVC {
            return InMeetOrderedViewController(orientation: .flow, vc)
        }
        return nil
    }

    override var childVCForStatusBarStyle: InMeetOrderedViewController? {
        if let vc = self.flowVC {
            return InMeetOrderedViewController(orientation: .flow, vc)
        }
        return nil
    }

}

extension GallerySceneController: MeetingLayoutStyleListener {
    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        guard self.isMounted else {
            return
        }
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }
}

extension GallerySceneController: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard self.isMounted else {
            return
        }
        switch change {
        case .containerDidLayout:
            self.flowVC.handleTopBottomGuideChanged()
        default:
            break
        }
    }
}
