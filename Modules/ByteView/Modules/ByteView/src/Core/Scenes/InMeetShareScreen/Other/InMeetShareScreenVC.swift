//
//  InMeetShareScreenVC.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/11/2.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//


import UIKit
import RxSwift
import SnapKit
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import Whiteboard
import ByteViewRtcBridge
import UniverseDesignIcon

protocol InMeetShareScreenVCDelegate: AnyObject {
    func shareScreenDidShowSketchMenu(_ sketchMenuView: UIView)
    func shareScreenDidHideSketchMenu()
    func isShareScreenSketchMenuEnabled() -> Bool
}

class InMeetShareScreenVC: VMViewController<InMeetShareScreenVM>, MeetingLayoutStyleListener {

    weak var fullScreenDetector: InMeetFullScreenDetector?
    var blockFullScreenToken: BlockFullScreenToken?

    let disposeBag = DisposeBag()

    weak var container: InMeetViewContainer?
    weak var layoutContainer: InMeetLayoutContainer?
    var isViewDidLoad: Bool = false

    private var attachedToLayoutContainer: Bool = false {
        didSet {
            guard self.attachedToLayoutContainer != oldValue else {
                return
            }
            self.updateFloatingTopOrBottomShareBarGuide()
            self.updateFloatingSketchMenuGuide()
        }
    }
    private var topOrBottomShareBarGuideToken: MeetingLayoutGuideToken?
    private var bottomSketchMenuGuideToken: MeetingLayoutGuideToken?
    private var invisibleBottomShareBarGuideToken: MeetingLayoutGuideToken?

    var watermarkView: UIView?
    private lazy var topBar = createTopBar()
    lazy var videoView = {
        let videoView = ShareScreenVideoView(meeting: viewModel.meeting)
        videoView.zoomDelegate = self
        return videoView
    }()
    lazy var bottomView = InMeetShareScreenBottomView(service: viewModel.meeting.service)

    // 共享标注 {
    var sketchViewModel: SketchViewModel?
    var sketchView: SketchView?
    var sketchMenuView: SketchMenuView?
    var sketchGest: WhiteboardGestRecognizer?
    var selfNeedAdjustAnnotate: Bool = true {
        didSet {
            guard oldValue != selfNeedAdjustAnnotate else { return }
            self.sketchViewModel?.selfNeedAdjustAnnotate = selfNeedAdjustAnnotate
        }
    }
    var sharerNeedAdjustAnnotate: Bool = true {
        didSet {
            guard oldValue != sharerNeedAdjustAnnotate else { return }
            self.sketchViewModel?.sharerNeedAdjustAnnotate = sharerNeedAdjustAnnotate
        }
    }
    var sketchDisposeBag = DisposeBag()
    var sketchMenuDisposeBag = DisposeBag()
    let isSketchLoadingRelay = BehaviorRelay<Bool>(value: false)
    // }

    let contentLayoutGuide = UILayoutGuide()
    let parentContainerGuide = UILayoutGuide()
    let bottomBarLayoutGuide = UILayoutGuide()
    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard meetingLayoutStyle != oldValue else {
                return
            }
            self.bottomView.meetingLayoutStyle = meetingLayoutStyle
            self.updateBottomViewConstraint()
            self.updateContentConstraint()
            self.showOrDismissViewOnYourOwnGuide()
        }
    }

    var isSketchEnabled: Bool = false {
        didSet {
            guard self.isSketchEnabled != oldValue else {
                return
            }
            self.updateFloatingSketchMenuGuide()
        }
    }

    @RwAtomic
    var isSketchSaving: Bool = false

    // 是否暂停共享恢复后需要展示编辑菜单
    var needShowMenuView: Bool = false

    var blockSelfDoubleTapAction: (() -> Bool)?

    // MARK: - Onboarding

    /// “妙享模式已开启，点击即可进入自由浏览”提示
    var viewOnYourOwnGuideView: GuideView?
    var viewOnYourOwnGuideAnchorView: UIView?

    /// “共享人已允许自由浏览文档”提示
    var presenterAllowFreeToBrowseHintView: GuideView?

    var freeToBrowseButtonDisplayStyle: ShareScreenFreeToBrowseViewDisplayStyle? {
        didSet {
            // 显示Onboarding提示
            let newValue = freeToBrowseButtonDisplayStyle
            if oldValue != .operable,
               freeToBrowseButtonDisplayStyle == .operable {
                requestShowViewOnYourOwnGuide()
            } else {
                removeViewOnYourOwnGuideOnMainThread()
            }
            // 显示Guide提示
            if !viewModel.meeting.service.storage.bool(forKey: .presenterAllowFree),
               oldValue != .operable,
               newValue == .operable,
               viewModel.shouldShowPresenterAllowFreeToBrowseHint() {
                self.viewModel.storeLastShowPresenterAllowFreeToBrowseHintShareID()
                self.showPresenterAllowFreeToBrowseHintOnMainThread()
            }
            if newValue == .operable {
                ShareScreenToFollowTracks.trackViewFreeToBrowseButton(with: viewModel.meeting.shareData.shareContentScene.shareScreenData?.ccmInfo?.memberID)
            } else {
                viewModel.clearLastShowPresenterAllowFreeToBrowseHintShareID()
            }
        }
    }

    /// 横屏下，点击portraitOnlyHintView之外的部分触发隐藏
    let dismissPortraitOnlyHintView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = true
        return view
    }()

    /// 横屏下，对仅支持竖屏的文档点击“自由浏览”时弹出的提示
    let portraitOnlyHintView: PopConfirmView = {
        let view = PopConfirmView()
        view.isHidden = true
        return view
    }()

    // }

    weak var delegate: InMeetShareScreenVCDelegate?

    convenience init(viewModel: InMeetShareScreenVM, delegate: InMeetShareScreenVCDelegate?) {
        self.init(viewModel: viewModel)
        self.delegate = delegate
        self.viewModel.addListener(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isViewDidLoad = true
        if let anchorView = viewOnYourOwnGuideAnchorView {
            anchorView.snp.remakeConstraints { make in
                make.edges.equalTo(self.bottomView.freeToBrowseButton)
            }
        }
    }

    deinit {
        if let viewOnYourOwnGuide = viewOnYourOwnGuideView {
            Util.runInMainThread {
                viewOnYourOwnGuide.removeFromSuperview()
            }
        }
        if let viewOnYourOwnGuideAnchor = viewOnYourOwnGuideAnchorView {
            Util.runInMainThread {
                viewOnYourOwnGuideAnchor.removeFromSuperview()
            }
        }
    }

    // MARK: - auto rotate
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private static func controlStateImage(icon: UDIconType, dimension: CGFloat, color: UIColor) -> (UIImage, UIImage) {
        let normalImage = UDIcon.getIconByKey(icon, iconColor: color, size: CGSize(width: dimension, height: dimension))
        let highlightImage = UDIcon.getIconByKey(icon, iconColor: color.withAlphaComponent(0.5), size: CGSize(width: dimension, height: dimension))
        return (normalImage, highlightImage)
    }

    private func createTopBar() -> UIView {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = UIColor.ud.bgBody
        let imageDimension: CGFloat = 20
        let (img, hlImg) = Self.controlStateImage(icon: .vcToolbarUpFilled,
                                                  dimension: imageDimension,
                                                  color: UIColor.ud.iconN3)
        let (slImg, slHlImg) = Self.controlStateImage(icon: .vcToolbarDownFilled,
                                                      dimension: imageDimension,
                                                      color: UIColor.ud.iconN3)
        btn.setImage(img, for: .normal)
        btn.setImage(hlImg, for: .highlighted)
        btn.setImage(slImg, for: .selected)
        btn.setImage(slHlImg, for: [.selected, .highlighted])
        btn.rx.tap
            .subscribe(onNext: { [weak self] in
                btn.isSelected = !btn.isSelected
                self?.toggleTopBar()
            })
            .disposed(by: self.disposeBag)
        return btn
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }

    private func toggleTopBar() {
        guard let navVC = self.navigationController else {
            return
        }
        if navVC.isNavigationBarHidden {
            navVC.setNavigationBarHidden(false, animated: true)
        } else {
            navVC.setNavigationBarHidden(true, animated: true)
        }
    }

    // MARK: - Life Cycle Funcs

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewOnYourOwnGuideView?.removeFromSuperview()
        viewOnYourOwnGuideView = nil
        presenterAllowFreeToBrowseHintView?.removeFromSuperview()
        presenterAllowFreeToBrowseHintView = nil
        endBlockFullScreen()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestShowViewOnYourOwnGuide()
    }

    override func setupViews() {
        self.view.clipsToBounds = false
        self.view.backgroundColor = UIColor.ud.vcTokenMeetingBgVideoOff
        self.view.addSubview(videoView)
        self.view.addLayoutGuide(contentLayoutGuide)
        self.view.addLayoutGuide(parentContainerGuide)
        self.view.addLayoutGuide(bottomBarLayoutGuide)
        self.view.addSubview(bottomView)
        self.view.addSubview(dismissPortraitOnlyHintView)
        self.view.addSubview(portraitOnlyHintView)

        updateContentConstraint()
        updateBottomViewConstraint()
        updatePortraitOnlyHintViewConstraint()
        configZoomViewDoubleTap()
        configPortraitOnlyHintViewTap()
        configShowToast()
        self.bottomView.freeToBrowseButtonDisplayStyle = viewModel.meeting.shareData.shareContentScene.shareScreenData?.ccmInfo?.freeToBrowseButtonDisplayStyle ?? .hidden
    }

    private func configShowToast() {
        viewModel.triggerToast = { (text: String) in
            Toast.showOnVCScene(text)
        }
    }

    override func bindViewModel() {
        let sessionId = viewModel.meeting.sessionId
        viewModel.shareScreenGridInfo
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] gridInfo in
                guard let self = self else {
                    return
                }
                let isSipOrRoom = gridInfo?.user.isSipOrRoom ?? false
                self.videoView.setStreamKey(gridInfo?.rtcUid.map({ .screen(uid: $0, sessionId: sessionId) }), isSipOrRoom: isSipOrRoom)

                if let name = gridInfo?.name,
                   !name.isEmpty {
                    let infoText = gridInfo?.isSharingPause == true ? I18n.View_G_NameSharingPaused(name) : I18n.View_VM_SharingNameBraces(name)
                    self.bottomView.infoLabel.text = infoText
                } else {
                    self.bottomView.infoLabel.text = ""
                }
                self.bottomView.annotateButton.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
                self.bottomView.annotateButton.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg.withAlphaComponent(0.5), for: .highlighted)
                self.bottomView.freeToBrowseAction = { [weak self] (reason: ClickFreeToBrowseButtonSwitchReason) in
                    guard let self = self else { return }
                    Logger.shareScreenToFollow.info("triggered entering shareScreenToFollow with reason: \(reason.rawValue)")
                    ShareScreenToFollowTracks.trackClickFreeToBrowseButton(with: reason)
                    self.viewModel.meeting.shareData.setShareScreenToFollowShow(true)
                }
            })
            .disposed(by: self.disposeBag)

        bindSketch()
        // 设置共享桌面水印
        Observable.combineLatest(viewModel.meeting.service.larkUtil.getVCShareZoneWatermarkView(),
                                 viewModel.shareWatermark.showWatermarkRelay.asObservable().distinctUntilChanged())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, show) in
                self?.configWatermarkView(showWatermark: show, view: view)
            }).disposed(by: self.disposeBag)

        fullScreenDetector = viewModel.context.fullScreenDetector
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.updateBottomViewConstraint()
        self.updateContentConstraint()
        if Display.phone {
            bottomView.isPortrait = bottomView.isPhonePortrait
        } else {
            bottomView.isPadCompact = traitCollection.isCompact
        }
    }

    func configWatermarkView(showWatermark: Bool, view: UIView?) {
        watermarkView?.removeFromSuperview()
        guard showWatermark, let view = view else {
            watermarkView = nil
            return
        }
        view.frame = self.videoView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.videoView.addSubview(view)
        view.layer.zPosition = .greatestFiniteMagnitude
        self.watermarkView = view
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.parent is InMeetFlowAndShareContainerViewControllerV2,
           self.view.window != nil {
            // 加进 collectionView cell 时，需要刷新约束
            self.topOrBottomShareBarGuideToken?.layoutGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.bottomView)
            }
            if Display.phone {
                self.invisibleBottomShareBarGuideToken?.layoutGuide.snp.remakeConstraints { make in
                    make.edges.equalTo(self.bottomView)
                }
            }
            if let sketchMenuView = self.sketchMenuView,
               sketchMenuView.superview != nil {
                self.bottomSketchMenuGuideToken?.layoutGuide.snp.remakeConstraints { make in
                    make.edges.equalTo(sketchMenuView)
                }
            }
        }
    }

    var isBottomViewHidden: Bool {
        self.isSketchEnabled || meetingLayoutStyle == .fullscreen
    }

    func updateBottomViewConstraint() {
        guard self.isViewLoaded else {
            return
        }
        bottomView.backgroundView.snp.remakeConstraints({ make in
            if Display.phone && !isBottomViewHidden {
                make.top.left.right.equalToSuperview()
                if currentLayoutContext.layoutType.isPhoneLandscape {
                    make.bottom.equalTo(parentContainerGuide.snp.bottom)
                } else {
                    make.bottom.equalToSuperview()
                }
            } else {
                make.edges.equalToSuperview()
            }
        })
        bottomView.snp.remakeConstraints { make in
            let height: CGFloat
            if Display.phone {
                height = currentLayoutContext.layoutType.isPhoneLandscape ? 36 : 40
            } else {
                height = 32
            }

            make.left.right.equalToSuperview()
            make.height.equalTo(height)
            if Display.phone {
                if isBottomViewHidden {
                    make.top.equalTo(self.view.snp.bottom)
                } else if currentLayoutContext.layoutType.isPhoneLandscape {
                    make.bottom.equalTo(parentContainerGuide).inset(17)
                } else {
                    make.bottom.equalTo(contentLayoutGuide)
                }
            } else {
                if isBottomViewHidden {
                    make.bottom.equalTo(self.view.snp.top)
                } else {
                    make.top.equalTo(self.contentLayoutGuide)
                }
            }
        }
        bottomView.alpha = isBottomViewHidden ? 0.0 : 1.0
        self.updateFloatingTopOrBottomShareBarGuide()
        if !self.isBottomViewHidden && self.meetingLayoutStyle == .overlay {
            self.bottomView.backgroundView.vc.addOverlayShadow(isTop: !Display.phone)
        } else {
            self.bottomView.backgroundView.vc.removeOverlayShadow()
        }
    }

    func updateContentConstraint() {
        guard self.isViewLoaded else {
            return
        }
        self.videoView.snp.remakeConstraints { make in
            if Display.phone || meetingLayoutStyle != .tiled {
                make.top.equalToSuperview()
            } else {
                make.top.equalTo(self.bottomView.snp.bottom)
            }
            make.left.right.equalToSuperview()
            if Display.phone && meetingLayoutStyle == .tiled {
                make.bottom.equalTo(self.bottomView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
    }

    private func configZoomViewDoubleTap() {
        let blockZoomViewDoubleTapAction: (() -> Bool) = { [weak self] in
            guard let self = self else {
                return false
            }
            if self.freeToBrowseButtonDisplayStyle == .operable {
                self.viewModel.storage.set(true, forKey: .doubleTapToFree)
                if self.currentLayoutContext.layoutType.isPhoneLandscape && !self.isDocumentLandscapeValid {
                    self.showPortraitOnlyHint()
                } else {
                    self.bottomView.freeToBrowse(with: .doubleClick)
                }
            }
            return true
        }
        videoView.blockSelfDoubleTapAction = blockZoomViewDoubleTapAction
    }

    func updatePortraitOnlyHintViewConstraint() {
        dismissPortraitOnlyHintView.snp.remakeConstraints {
            $0.edges.equalTo(videoView)
        }
        portraitOnlyHintView.snp.remakeConstraints {
            if Display.phone {
                $0.bottom.equalTo(bottomView.snp.top)
            } else {
                $0.top.equalTo(bottomView.snp.bottom)
            }
            $0.centerX.equalTo(bottomView.freeToBrowseButton)
        }
    }

    func configPortraitOnlyHintViewTap() {
        let tapGr = UITapGestureRecognizer(target: self, action: #selector(dismissPortraitOnlyHint))
        dismissPortraitOnlyHintView.addGestureRecognizer(tapGr)

        portraitOnlyHintView.leftBtnTapAction = { [weak self] in
            self?.dismissPortraitOnlyHint()
        }
        portraitOnlyHintView.rightBtnTapAction = { [weak self] in
            self?.dismissPortraitOnlyHint()
            self?.bottomView.freeToBrowse(with: .barIcon)
        }
        bottomView.blockTapFreeToBrowseButtonAction = { [weak self] in
            guard let self = self else {
                return false
            }
            if self.currentLayoutContext.layoutType.isPhoneLandscape && !self.isDocumentLandscapeValid && self.freeToBrowseButtonDisplayStyle == .operable {
                self.showPortraitOnlyHint()
                return true
            } else {
                return false
            }
        }
    }

    private func showPortraitOnlyHint() {
        dismissPortraitOnlyHintView.isHidden = false
        portraitOnlyHintView.isHidden = false
    }

    @objc
    /// 隐藏“投屏转妙享仅支持竖屏”提示视图
    private func dismissPortraitOnlyHint() {
        dismissPortraitOnlyHintView.isHidden = true
        portraitOnlyHintView.isHidden = true
    }

    var isDocumentLandscapeValid: Bool {
        guard let shareSubType = viewModel.screenSharedData?.ccmInfo?.type else {
            return true
        }
        return shareSubType.isLandscapeEnabled(setting: viewModel.setting)
    }

    /// 当沉浸态有变化时，判断是否显示或隐藏Guide
    private func showOrDismissViewOnYourOwnGuide() {
        if meetingLayoutStyle != .fullscreen {
            requestShowViewOnYourOwnGuide()
        } else {
            removeViewOnYourOwnGuideOnMainThread()
        }
    }

}

extension InMeetShareScreenVC: InMeetFlowAndShareProtocol {
    var shareVideoView: UIView? {
        self.videoView
    }

    var shareBottomView: UIView? {
        self.bottomView
    }

    var shareBottomBackgroundView: UIView? {
        self.bottomView.backgroundView
    }

    var singleTapGestureRecognizer: UITapGestureRecognizer? {
        get {
            videoView.singleTapGestureRecognizer
        }
        set {
            videoView.singleTapGestureRecognizer = newValue
        }
    }
}

extension InMeetShareScreenVC: ZoomViewZoomscaleObserver {
    func zoomScaleChangeEvent(_ scale: CGFloat, oldValue: CGFloat, type: ZoomView.ZoomScaleChangeType) {
        Logger.ui.info("zoomScaleChangeEvent: \(scale) old: \(oldValue): type: \(type)")
        guard let shareScreenID = viewModel.meeting.data.inMeetingInfo?.shareScreen?.shareScreenID else {
            return
        }
        let isZoomIn = scale > oldValue
        MeetingTracksV2.trackShareScreenZoom(shareID: shareScreenID, isZoomIn: isZoomIn, isClick: type == .doubleTap)
    }
}

extension InMeetShareScreenVC: InMeetLayoutContainerAware {
    func didAttachToLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        self.layoutContainer = layoutContainer
        self.attachedToLayoutContainer = true
    }
    func didDetachFromLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        self.attachedToLayoutContainer = false
        self.layoutContainer = nil
    }

    private func updateFloatingTopOrBottomShareBarGuide() {
        if self.isBottomViewHidden || !self.attachedToLayoutContainer {
            self.topOrBottomShareBarGuideToken?.invalidate()
            self.topOrBottomShareBarGuideToken = nil
        } else {
            if self.topOrBottomShareBarGuideToken == nil {
                self.topOrBottomShareBarGuideToken = self.layoutContainer?.registerAnchor(anchor: Display.phone ? .bottomShareBar : .topShareBar)
                self.topOrBottomShareBarGuideToken?.layoutGuide.snp.remakeConstraints({ make in
                    make.edges.equalTo(self.bottomView)
                })
            }
        }

        if Display.phone {
            if !self.attachedToLayoutContainer {
                self.invisibleBottomShareBarGuideToken?.invalidate()
                self.invisibleBottomShareBarGuideToken = nil
            } else {
                if self.invisibleBottomShareBarGuideToken == nil {
                    self.invisibleBottomShareBarGuideToken = self.layoutContainer?.registerAnchor(anchor: .invisibleBottomShareBar)
                    self.invisibleBottomShareBarGuideToken?.layoutGuide.snp.remakeConstraints({ make in
                        make.edges.equalTo(self.bottomView)
                    })
                }
            }
        }

    }

    private func updateFloatingSketchMenuGuide() {
        if !self.attachedToLayoutContainer || !self.isSketchEnabled {
            self.bottomSketchMenuGuideToken?.invalidate()
            self.bottomSketchMenuGuideToken = nil
        } else {
            if self.bottomSketchMenuGuideToken == nil,
               let sketchMenuView = self.sketchMenuView,
               sketchMenuView.superview != nil {
                self.bottomSketchMenuGuideToken = self.layoutContainer?.registerAnchor(anchor: .bottomSketchBar)
                self.bottomSketchMenuGuideToken?.layoutGuide.snp.remakeConstraints { make in
                    make.edges.equalTo(sketchMenuView)
                }
            }
        }
    }
}

extension CCMInfo {
    var freeToBrowseButtonDisplayStyle: ShareScreenFreeToBrowseViewDisplayStyle {
        switch (!url.isEmpty, isAllowFollowerOpenCcm) {
        case (false, _):
            return .hidden
        case (true, false):
            return .disabled
        case (true, true):
            return .operable
        }
    }
}
