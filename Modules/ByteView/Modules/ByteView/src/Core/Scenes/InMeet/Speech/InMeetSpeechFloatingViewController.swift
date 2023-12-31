//
//  InMeetSpeechFloatingViewController.swift
//  ByteView
//
//  Created by ZhangJi on 2022/8/23.
//

import UIKit
import SnapKit
import RxSwift
import RxRelay
import ByteViewCommon
import ByteViewNetwork
import ByteViewTracker
import Whiteboard
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewRtcBridge
import ByteViewUI

enum SpeechFloatingContent {
    case local
    case activeSpeakerWithoutLocal
    case activeSpeaker
    case shareScreen
    case follow
    case whiteBoard
    case selfShareScreen
    case webSpace

    var isParticipant: Bool {
        switch self {
        case .local, .activeSpeaker, .activeSpeakerWithoutLocal:
            return true
        default:
            return false
        }
    }

    var isShare: Bool {
        switch self {
        case .shareScreen, .follow, .whiteBoard, .selfShareScreen, .webSpace:
            return true
        default:
            return false
        }
    }
}

protocol InMeetSpeechFloatingVCDelegate: AnyObject {
    func speechFloatingDidShrunk(isShrunken: Bool)
    func speechFloatingEndDrag(isShrunken: Bool)
}

final class InMeetSpeechFloatingViewController: VMViewController<InMeetSpeechViewModel> {

    weak var delegate: InMeetSpeechFloatingVCDelegate? {
        didSet {
           self.speechFloatingView.delegate = self.delegate
        }
    }

    private lazy var shouldSetInitialPosition: Bool = true
    private lazy var lastFrame: CGRect = speechFloatingView.frame
    var didTapUserName: ((Participant) -> Void)?
    var didTapSwitch: (() -> Void)?

    var disposeBag = DisposeBag()

    private(set) var content: SpeechFloatingContent = .local {
        didSet {
            guard content != oldValue else {
                return
            }
            bindViewModel(with: content)
        }
    }

    private var window: UIWindow? {
        if #available(iOS 13, *) {
            return VCScene.windowScene?.windows.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }

    lazy var speechFloatingView: InMeetSpeechFloatingView = {
        let view = InMeetSpeechFloatingView()
        view.layer.borderWidth = 0.5
        view.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        view.applyFloatingShadow()
        return view
    }()

    private lazy var sharingDefaultThumbnail = createFloatingShareLoadingHintView()

    private var whiteboardViewController: UIViewController?
    private var shareScreenVC: InMeetShareScreenVideoVC?
    private var msThumbnailVC: InMeetFollowThumbnailVC?

    private var watermarkView: UIView?

    lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
    lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustSpeechFrame()
    }

    override func loadView() {
        view = IrregularHittableView()
    }

    override func setupViews() {
        view.backgroundColor = .clear

        view.addSubview(speechFloatingView)
        speechFloatingView.snp.makeConstraints { make in
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.width.equalTo(240)
            make.height.equalTo(135)
        }
        speechFloatingView.addGestureRecognizer(panGesture)
        speechFloatingView.addGestureRecognizer(tapGesture)

        speechFloatingView.insertShareContent(sharingDefaultThumbnail)

        sharingDefaultThumbnail.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(28)
        }

        speechFloatingView.participantView.didTapUserName = { [weak self] participant in
            self?.didTapUserName?(participant)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateInitialPosition()
    }

    deinit {
        if viewModel.context.meetingScene == .speech {
            viewModel.context.floatingSpeechState = (speechFloatingView.viewType == .up, speechFloatingView.transform)
        }
    }

    func updateInitialPosition() {
        guard let storage = viewModel.context.floatingSpeechState,
              shouldSetInitialPosition else { return }
        shouldSetInitialPosition = false
        self.speechFloatingView.transform = storage.1
        self.speechFloatingView.setViewType(storage.0 ? .up : .down)
        if let transform = shouldChangeTransform(with: view.bounds.size) {
            self.speechFloatingView.transform = transform
            self.updateSpeechAbsoluteFrame()
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if let transform = self.shouldChangeTransform(with: newContext.viewSize) {
            self.speechFloatingView.transform = transform
        }
        if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh {
            self.speechFloatingView.snp.remakeConstraints { make in
                make.right.lessThanOrEqualToSuperview().offset(-16)
                make.width.equalTo(view.isLandscape ? 240 : 180)
                if self.speechFloatingView.speechViewIsUp.value {
                    make.height.equalTo(40)
                } else {
                    make.height.equalTo(view.isLandscape ? 135 : 180)
                }
            }
        }
        self.adjustSpeechFrame()
    }

    override func bindViewModel() {
        self.bindViewModel(with: self.content)

        speechFloatingView.speechViewIsUp.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isUp in
                guard let self = self else { return }
                self.speechFloatingView.snp.remakeConstraints { make in
                    make.right.lessThanOrEqualToSuperview().offset(-16)
                    make.width.equalTo(VCScene.isLandscape ? 240 : 180)
                    if isUp {
                        make.height.equalTo(40)
                    } else {
                        make.height.equalTo(VCScene.isLandscape ? 135 : 180)
                    }
                }
                if isUp {
                    self.speechFloatingView.hiddenShareContent(true)
                    self.speechFloatingView.hiddenVideoView(true)
                } else {
                    self.speechFloatingView.hiddenShareContent(!self.content.isShare, isScreen: self.content == .shareScreen)
                    self.speechFloatingView.hiddenVideoView(self.content.isShare)
                }
            })
            .disposed(by: rx.disposeBag)

        if let gridVM = viewModel.gridVM {
            gridVM.shrinkViewSpeakingUser
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [view = speechFloatingView] name, showFocusPrefix in
                    let nameOrEmpty = name ?? ""
                    if showFocusPrefix {
                        view.setFocusingUserName(nameOrEmpty)
                    } else {
                        view.setSpeakerUserName(nameOrEmpty)
                    }
                }).disposed(by: rx.disposeBag)
        }

        viewModel.forceHiddenFloatingViewRelay.asObservable()
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] forceHidden in
                self?.speechFloatingView.setForcedHidden(forceHidden)
            })
            .disposed(by: rx.disposeBag)
    }

    func updateSpeechContent(_ content: SpeechFloatingContent) {
        self.content = content
    }

    private func bindViewModel(with content: SpeechFloatingContent) {
        guard let gridVM = self.viewModel.gridVM else { return }
        self.disposeBag = DisposeBag()
        self.speechFloatingView.isHidden = false
        self.sharingDefaultThumbnail.isHidden = true
        if speechFloatingView.speechViewIsUp.value {
            self.speechFloatingView.hiddenVideoView(true)
            self.speechFloatingView.hiddenShareContent(true)
        } else {
            self.speechFloatingView.hiddenShareContent(!content.isShare, isScreen: content == .shareScreen)
            self.speechFloatingView.hiddenVideoView(content.isShare)
        }
        if content != .shareScreen {
            cleanShareScreen()
        }

        if content != .follow {
            cleanMSThumbnail()
        }

        clearWhiteboardViews()
        if content.isShare {
            setupWatermark()
            if content == .shareScreen {
                guard let shareScreenVM = viewModel.shareScreenVM else { return }
                shareScreenVM.shareScreenGridInfo
                    .asObservable()
                    .distinctUntilChanged()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] gridInfo in
                        self?.setupScreenShareWith(gridInfo)
                    })
                    .disposed(by: self.disposeBag)
            } else if content == .follow {
                if let document = viewModel.floatingMagicDocumentRelay.value, document.isSSToMS {
                    guard let shareScreenVM = viewModel.shareScreenVM else { return }
                    Observable.combineLatest(shareScreenVM.shareScreenGridInfo,
                                             viewModel.floatingMagicDocumentRelay.asObservable()) { ($0, $1) }
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] value in
                            self?.setupMagicShareWith(value.1, userName: value.0?.name ?? "", isShareScreenPaused: value.0?.isSharingPause)
                        })
                        .disposed(by: self.disposeBag)
                } else {
                    viewModel.floatingMagicDocumentRelay
                        .asObservable()
                        .distinctUntilChanged()
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] document in
                            self?.setupMagicShareWith(document, userName: "", isShareScreenPaused: nil)
                        })
                        .disposed(by: self.disposeBag)
                }
            } else if content == .whiteBoard {
                viewModel.floatingWhiteBoardInfoRelay
                    .asObservable()
                    .distinctUntilChanged()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] whiteBoardInfo in
                        self?.setupWhiteBoardInfoWith(whiteBoardInfo)
                    })
                    .disposed(by: self.disposeBag)
            }
        } else {
            let vm: Observable<InMeetGridCellViewModel>
            switch content {
            case .local:
                let localVM = gridVM.localGridCellViewModel
                Observable.combineLatest(gridVM.focusingPidRelay.asObservable(), viewModel.selfIsHost.asObservable())
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] focusID, isHost in
                        guard let self = self, let localVM = localVM else { return }
                        if focusID != nil && !isHost {
                            self.speechFloatingView.isHidden = true
                            self.speechFloatingView.transform = .identity
                            self.speechFloatingView.participantView.streamRenderView.setStreamKey(nil)
                            self.updateSpeechAbsoluteFrame()
                        } else {
                            self.speechFloatingView.isHidden = false
                            self.speechFloatingView.bind(viewModel: localVM)
                        }
                    })
                    .disposed(by: self.disposeBag)
                return
            case .activeSpeakerWithoutLocal:
                vm = gridVM.singleGridViewModel(asIncludeLocal: false)
            case .activeSpeaker:
                vm = gridVM.singleGridViewModel(asIncludeLocal: true)
            default:
                return
            }
            vm.asObservable()
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] cellVM in
                    self?.speechFloatingView.bind(viewModel: cellVM)
                })
                .disposed(by: self.disposeBag)
        }
    }

    private func setupScreenShareWith(_ gridInfo: InMeetShareScreenVM.ShareScreenInfo?) {
        guard let gridInfo = gridInfo else {
            self.speechFloatingView.shareDisplayText = ""
            return
        }

        if gridInfo.user == viewModel.meeting.account {
            self.speechFloatingView.shareDisplayText = I18n.View_M_NowSharingToast
        } else {
            self.speechFloatingView.shareDisplayText = gridInfo.isSharingPause ? I18n.View_G_NameSharingPaused(gridInfo.name) : I18n.View_VM_SharingNameBraces(gridInfo.name)
        }
        self.setupShareScreen()
        if let renderView = self.shareScreenVC?.streamRenderView {
            renderView.addListener(self)
            sharingDefaultThumbnail.isHidden = renderView.isRendering
        }
    }

    private func setupMagicShareWith(_ document: MagicShareDocument?, userName: String, isShareScreenPaused: Bool?) {
        guard let document = document else {
            self.speechFloatingView.shareDisplayText = ""
            return
        }

        if document.isSSToMS {
            if let validPausedStatus = isShareScreenPaused, validPausedStatus {
                self.speechFloatingView.shareDisplayText = I18n.View_G_NameSharingPaused(userName)
            } else {
                self.speechFloatingView.shareDisplayText = I18n.View_VM_SharingNameBraces(userName)
            }
        } else {
            if document.user == viewModel.meeting.account {
                self.speechFloatingView.shareDisplayText = I18n.View_VM_NowSharing
            } else {
                self.speechFloatingView.shareDisplayText = I18n.View_VM_NameIsSharingFileName(document.userName, document.docTitle)
            }
        }

        setupMSThumbnail()
    }

    private func setupWhiteBoardInfoWith(_ info: WhiteboardInfo?) {
        guard info != nil else {
            self.speechFloatingView.shareDisplayText = ""
            return
        }

        self.sharingDefaultThumbnail.isHidden = true
        self.setupWhiteboard()
    }

    @objc func didTap(_ gr: UITapGestureRecognizer) {
        guard self.speechFloatingView.viewType != .up,
              !viewModel.meeting.shareData.isMySharingScreen,
              !viewModel.meeting.webSpaceData.isWebSpace,
              (viewModel.meeting.shareData.isSharingContent ||
              // TODO(webinar): @zhangji 考虑隐藏本人视图/隐藏非视频参会人/webinar 观众/嘉宾模式
               viewModel.meeting.participant.currentRoom.count > 1) else { return }
        self.didTapSwitch?()
    }

    private var lastLocation: CGPoint = .zero
    @objc func didPan(_ gr: UIPanGestureRecognizer) {
        let loc = gr.location(in: self.view)
        switch gr.state {
        case .began:
            lastLocation = loc
        case .changed:
            self.speechFloatingView.transform = self.speechFloatingView.transform.translatedBy(x: loc.x - lastLocation.x, y: loc.y - lastLocation.y)
            lastLocation = loc
        case .cancelled, .ended:
            if let transform = shouldChangeTransform(with: view.bounds.size) {
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.2, animations: {
                    self.speechFloatingView.transform = transform
                }, completion: { _ in
                    self.updateSpeechAbsoluteFrame()
                })
            }
            self.delegate?.speechFloatingEndDrag(isShrunken: self.speechFloatingView.speechViewIsUp.value)
        default:
            break
        }
    }

    /// 相对位置修正
    private func shouldChangeTransform(with size: CGSize) -> CGAffineTransform? {
        guard AppInfo.shared.applicationState != .background else {
            // 后台不修正位置
            return nil
        }

        let minX: CGFloat = -(size.width - 32 - speechFloatingView.bounds.size.width)
        let maxX: CGFloat = 0
        let middleX: CGFloat = minX / 2
        let minY: CGFloat = 0
        let maxY: CGFloat = size.height - speechFloatingView.bounds.size.height
        var transform = self.speechFloatingView.transform
        transform.tx = transform.tx < middleX ? minX : maxX
        if transform.ty > maxY || transform.ty < minY {
            transform.ty = min(maxY, max(minY, transform.ty))
        }
        return transform
    }

    /// VC窗口内绝对位置修正，修正时机：
    /// 1. 初始化
    /// 2. 沉浸台切换
    /// 3. 横竖屏切换
    /// 4. 分屏切换
    /// 5. 标注切换
    private func adjustSpeechFrame() {
        if speechFloatingView.transform.ty > 0 {
            let frame = view.convert(lastFrame, from: window)
            if frame.minY < 0 {
                speechFloatingView.transform.ty = 0
            } else if frame.maxY > view.frame.height {
                speechFloatingView.transform.ty = view.frame.height - frame.height
            } else {
                speechFloatingView.transform.ty = frame.origin.y
            }
        }
        if let transform = shouldChangeTransform(with: view.bounds.size) {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, animations: {
                self.speechFloatingView.transform = transform
            }, completion: { _ in
                self.updateSpeechAbsoluteFrame()
            })
        }
        self.updateSpeechAbsoluteFrame()
    }

    private func updateSpeechAbsoluteFrame() {
        lastFrame = view.convert(speechFloatingView.frame, to: window)
    }
}

extension InMeetSpeechFloatingViewController: StreamRenderViewListener {
    func streamRenderViewDidChangeRendering(_ renderView: StreamRenderView, isRendering: Bool) {
        sharingDefaultThumbnail.isHidden = isRendering
    }
}

// MARK: - Cursor
extension InMeetSpeechFloatingViewController {
    func setupMSThumbnail() {
        guard self.msThumbnailVC == nil else {
            return
        }
        let vm = InMeetFollowThumbnailVM(meeting: self.viewModel.meeting, resolver: viewModel.resolver)
        let vc = InMeetFollowThumbnailVC(viewModel: vm)
        vc.view.backgroundColor = UDColor.N200
        addChild(vc)
        self.speechFloatingView.insertShareContent(vc.view)
        vc.didMove(toParent: self)
        self.msThumbnailVC = vc
    }
    func cleanMSThumbnail() {
        guard let vc = self.msThumbnailVC,
              vc.parent != nil else {
            return
        }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        vc.didMove(toParent: nil)
        self.msThumbnailVC = nil
    }
}

extension InMeetSpeechFloatingViewController {
    func setupShareScreen() {
        guard self.shareScreenVC == nil,
            let vm = self.viewModel.shareScreenVM else {
            return
        }
        let vc = InMeetShareScreenVideoVC(viewModel: vm)
        addChild(vc)
        self.speechFloatingView.insertShareContent(vc.view)
        vc.didMove(toParent: self)
        self.shareScreenVC = vc
    }

    func cleanShareScreen() {
        guard let vc = self.shareScreenVC,
              vc.parent != nil else {
            return
        }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        vc.didMove(toParent: nil)
        self.shareScreenVC = nil
    }
}

// MARK: - whiteboard
extension InMeetSpeechFloatingViewController {
    func setupWhiteboard() {
        let vm = InMeetWhiteboardViewModel(resolver: viewModel.resolver)
        let wbVC = InMeetWhiteboardViewController(viewModel: vm)
        wbVC.isContentOnly = true
        wbVC.whiteboardVC.setLayerMiniScale()
        addChild(wbVC)
        self.speechFloatingView.insertShareContent(wbVC.view)
        wbVC.didMove(toParent: self)
        whiteboardViewController = wbVC

        vm.userNameObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] s in
                let displayName = I18n.View_G_NameSharingBoard_Status(s)
                self?.speechFloatingView.shareDisplayText = displayName
            })
            .disposed(by: self.disposeBag)
    }

    func clearWhiteboardViews() {
        if let whiteboardVC = whiteboardViewController, whiteboardVC.parent != nil {
            whiteboardVC.willMove(toParent: nil)
            whiteboardVC.view.removeFromSuperview()
            whiteboardVC.removeFromParent()
            whiteboardVC.didMove(toParent: nil)
        }
        whiteboardViewController = nil
    }
}

// MARK: - Watermark
extension InMeetSpeechFloatingViewController {
    func setupWatermark() {
        let combined = Observable.combineLatest(
            viewModel.meeting.service.larkUtil.getVCShareZoneWatermarkView(),
            viewModel.shareWatermark.showWatermarkRelay.asObservable().distinctUntilChanged())
        combined.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, showWatermark) in
                guard let self = self else { return }
                self.watermarkView?.removeFromSuperview()
                guard showWatermark, let view = view else {
                    self.watermarkView = nil
                    return
                }
                view.frame = self.speechFloatingView.bounds
                view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.speechFloatingView.addSubview(view)
                view.layer.zPosition = .greatestFiniteMagnitude
                self.watermarkView = view
            }).disposed(by: self.disposeBag)
    }
}
