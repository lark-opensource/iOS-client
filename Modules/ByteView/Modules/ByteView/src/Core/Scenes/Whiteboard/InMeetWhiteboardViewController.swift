//
//  InMeetWhiteboardViewController.swift
//  ByteView
//
//  Created by Prontera on 2022/3/20.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import Whiteboard
import SnapKit
import ByteViewNetwork
import RxSwift

// 用于更新context
protocol InMeetWhiteboardDelegate: AnyObject {
    func whiteboardDidShowMenu()
    func whiteboardDidHideMenu(isUpdate: Bool)
    func isWhiteboardMenuEnabled() -> Bool
    func whiteboardEditAuthorityChanged(canEdit: Bool)
}

class InMeetWhiteboardViewController: VMViewController<InMeetWhiteboardViewModel>, MeetingLayoutStyleListener, PIPObserver {
    static let watermarkViewTag = 1001
    static var hasShowToast: Bool = false
    lazy var whiteboardVC: WhiteboardViewController = {
        let wbVC = viewModel.getWbVC(viewStyle: self.getViewStyle())
        wbVC.configDataDelegate(delegate: self)
        wbVC.setShowContentOnly(isOnly: isContentOnly)
        wbVC.configDependencies(viewModel)
        return wbVC
    }()

    let disposeBag = DisposeBag()
    lazy var bottomView: WhiteboardBottomView = {
        let view = WhiteboardBottomView(isSharer: self.viewModel.isSelfSharingWb)
        view.stopSharingButton.addTarget(self, action: #selector(stopSharing), for: .touchUpInside)
        return view
    }()

    lazy var bottomLineView: UIView = {
        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.ud.bgBase
        return bottomLineView
    }()

    private var attachedToLayoutContainer: Bool = false {
        didSet {
            guard self.attachedToLayoutContainer != oldValue else {
                return
            }
            updateFloatingTopOrBottomShareBarGuide()
        }
    }
    private var topOrBottomShareBarGuideToken: MeetingLayoutGuideToken?
    private var invisibleBottomShareBarGuideToken: MeetingLayoutGuideToken?
    private var sketchMenuGuideToken: MeetingLayoutGuideToken?
    private var layoutContainer: InMeetLayoutContainer?

    var bottomLineHeightConstraint: Constraint?

    let parentContainerGuide = UILayoutGuide()

    let contentLayoutGuide = UILayoutGuide()

    let bottomBarLayoutGuide = UILayoutGuide()

    var meetingLayoutStyle: MeetingLayoutStyle = .tiled {
        didSet {
            guard meetingLayoutStyle != oldValue else {
                return
            }
            setMeetingLayoutStyleToWb(style: meetingLayoutStyle)
            updateBottomViewIsHidden()
            updateBgColor()
            updateViewConstraint()
        }
    }

    // 白板 VC 不显示底部工具栏，用于浮窗，宫格 Cell
    var isContentOnly: Bool = false {
        didSet {
            guard isContentOnly != oldValue else {
                return
            }
            updateBottomViewIsHidden()
            updateViewConstraint()
            if Display.pad {
                whiteboardVC.setShowContentOnly(isOnly: isContentOnly)
            }
        }
    }

    weak var delegate: InMeetWhiteboardDelegate?
    var viewLayoutStyle: WhiteboardViewStyle = Display.phone ? .phone : .ipad
    convenience init(viewModel: InMeetWhiteboardViewModel, delegate: InMeetWhiteboardDelegate?) {
        self.init(viewModel: viewModel)
        self.delegate = delegate
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.N300
        addChild(whiteboardVC)
        view.addSubview(whiteboardVC.view)
        whiteboardVC.didMove(toParent: self)
        view.addLayoutGuide(parentContainerGuide)
        view.addLayoutGuide(contentLayoutGuide)
        view.addLayoutGuide(bottomBarLayoutGuide)
        view.addSubview(bottomLineView)
        view.addSubview(bottomView)
        whiteboardVC.bottomBarGuide.snp.remakeConstraints { maker in
            maker.edges.equalTo(bottomBarLayoutGuide)
        }
        if Display.phone {
            remakeBottomViewHeight(currentLayoutContext.layoutType.isCompact)
        }
        bottomLineView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
            bottomLineHeightConstraint = $0.height.equalTo(0).constraint
        }
        updateBgColor()
        updateBottomViewIsHidden()
        updateViewConstraint()
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.updateBgColor()
        self.updateViewConstraint()
        if Display.phone {
            self.remakeBottomViewHeight(newContext.layoutType.isCompact)
            self.bottomView.remakeLayout()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if Display.pad {
            let style = getViewStyle()
            whiteboardVC.setNewViewLayoutStyle(style)
            if self.viewLayoutStyle != style {
                self.updateBgColor()
                self.updateBottomViewIsHidden()
                self.updateViewConstraint()
            }
            self.viewLayoutStyle = style
        }
    }

    override func bindViewModel() {
        viewModel.delegate = self
        viewModel.meeting.pip.addObserver(self)

        // 设置共享白板水印
        Observable.combineLatest(viewModel.meeting.service.larkUtil.getVCShareZoneWatermarkView(),
                                 viewModel.shareWatermark.showWatermarkRelay.asObservable().distinctUntilChanged())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, show) in
                self?.configWatermarkView(showWatermark: show, view: view)
            }).disposed(by: self.disposeBag)
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 暂时先屏蔽扬声器toast
            self.viewModel.meeting.canShowAudioToast = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.meeting.canShowAudioToast = true
            }
            if !self.isContentOnly, !Self.hasShowToast {
                let text = self.viewModel.isSelfSharingWb ? I18n.View_MV_UseWhiteboardTip : I18n.View_G_NameSharingBoard_Toast(self.viewModel.userName)
                Toast.showOnVCScene(text)
                Self.hasShowToast = true
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.restoreWhiteboardIfNeeded()
        // 用于恢复菜单显示
        if viewModel.shouldShowMenuFromFloatingWindow, viewLayoutStyle == .phone {
            whiteboardVC.shouldShowMenuFromFloatingWindow(shouldShow: true)
        }
        viewModel.shouldShowMenuFromFloatingWindow = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.parent is InMeetFlowAndShareContainerViewControllerV2,
           self.view.window != nil {
            // 加进 collectionView cell 时，需要刷新约束
            self.topOrBottomShareBarGuideToken?.layoutGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.bottomView)
            }
            self.invisibleBottomShareBarGuideToken?.layoutGuide.snp.remakeConstraints { make in
                make.edges.equalTo(self.bottomView)
            }

            if Display.phone,
               let phoneToolbarGuide = self.whiteboardVC.phoneToolBarGuide {
                self.sketchMenuGuideToken?.layoutGuide.snp.remakeConstraints({ make in
                    make.left.right.bottom.equalTo(phoneToolbarGuide)
                    make.top.equalTo(phoneToolbarGuide).offset(currentLayoutContext.layoutType.isPhoneLandscape ? 52.0 : 0.0)
                })
            }
        }
        if currentLayoutContext.layoutType.isPhoneLandscape {
            updateViewConstraint()
        }
    }

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        self.meetingLayoutStyle = container.meetingLayoutStyle
    }

    private func getViewStyle() -> WhiteboardViewStyle {
        if Display.phone { return .phone }
        return traitCollection.isCompact ? .phone : .ipad
    }

    private func setMeetingLayoutStyleToWb(style: MeetingLayoutStyle) {
        switch style {
        case .tiled:
            whiteboardVC.changeMeetingLayoutStyle(to: 1)
        case .overlay:
            whiteboardVC.changeMeetingLayoutStyle(to: 2)
        case .fullscreen:
            whiteboardVC.changeMeetingLayoutStyle(to: 3)
        }
    }

    private func updateBottomViewIsHidden() {
        var isBottomViewHidden = meetingLayoutStyle == .fullscreen || isContentOnly
        if Display.phone {
            isBottomViewHidden = isBottomViewHidden || viewModel.isWhiteboardMenuDisplaying
        }
        self.bottomView.isHidden = isBottomViewHidden
        self.bottomLineView.isHidden = isBottomViewHidden
        self.updateFloatingTopOrBottomShareBarGuide()
        self.updateFloatingSketchMenuGuide()
    }

    private func updateViewConstraint() {
        guard self.isViewLoaded, bottomView.superview != nil, whiteboardVC.view.superview != nil else {
            return
        }
        // 这三个view应该都是加在self.view上的，检查避免约束导致crash。
        guard whiteboardVC.view.superview == self.view, bottomView.superview == self.view, bottomLineView.superview == self.view else {
            return
        }
        let isWhiteboardMenuShowing = viewModel.isWhiteboardMenuDisplaying
        bottomView.snp.remakeConstraints {
            let viewHight: CGFloat
            if Display.pad {
                viewHight = 32
            } else if !currentLayoutContext.layoutType.isPhoneLandscape {
                viewHight = 40
            } else if view.safeAreaInsets.bottom > 0 {
                viewHight = view.safeAreaInsets.bottom + 31
            } else {
                viewHight = 36
            }
            $0.height.equalTo(viewHight)
            $0.left.right.equalToSuperview()
            if Display.pad {
                $0.top.equalTo(contentLayoutGuide.snp.top)
            } else {
                if isWhiteboardMenuShowing {
                    $0.top.equalTo(bottomBarLayoutGuide)
                } else {
                    $0.bottom.lessThanOrEqualTo(parentContainerGuide.snp.bottom)
                    $0.bottom.lessThanOrEqualTo(bottomBarLayoutGuide.snp.top)
                    $0.bottom.equalTo(parentContainerGuide.snp.bottom).priority(998)
                    $0.bottom.equalTo(bottomBarLayoutGuide.snp.top).priority(999)
                }
            }
        }
        if !self.bottomView.isHidden && self.meetingLayoutStyle == .overlay {
            bottomView.vc.addOverlayShadow(isTop: !Display.phone)
        } else {
            bottomView.vc.removeOverlayShadow()
        }

        whiteboardVC.view.snp.remakeConstraints {
            if self.isContentOnly {
                $0.edges.equalToSuperview()
            } else {
                $0.left.right.equalToSuperview()
                switch (Display.pad, meetingLayoutStyle == .tiled) {
                case (true, true):
                    $0.top.equalTo(bottomView.snp.bottom)
                    $0.bottom.equalToSuperview()
                case (true, false):
                    if meetingLayoutStyle == .fullscreen {
                        $0.top.equalToSuperview()
                    } else {
                        $0.top.equalTo(bottomView.snp.bottom)
                    }
                    $0.bottom.equalToSuperview()
                case (false, true):
                    $0.top.equalToSuperview()
                    $0.bottom.equalTo(self.bottomLineView.snp.top)
                case (false, false):
                    $0.top.equalToSuperview()
                    $0.bottom.equalToSuperview()
                }
            }
        }
    }

    private func remakeBottomViewHeight(_ isPortrait: Bool) {
        let bottomLineHeight = (currentLayoutContext.layoutType.isPhoneLandscape && meetingLayoutStyle == .tiled) ? 1 : 0
        bottomLineHeightConstraint?.update(offset: bottomLineHeight)
    }

    private func updateBgColor() {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            whiteboardVC.setScrollViewBgColor(UIColor.ud.bgBase)
        } else if Display.pad, meetingLayoutStyle != .tiled {
            whiteboardVC.setScrollViewBgColor(UIColor.ud.vcTokenMeetingBgCamOff)
        } else {
            whiteboardVC.setScrollViewBgColor(UIColor.ud.vcTokenMeetingBgCamOff)
        }
        let bottomColor = UIColor.ud.vcTokenMeetingBgVideoOff
        bottomView.backgroundColor = meetingLayoutStyle != .tiled ? bottomColor.withAlphaComponent(0.92) : bottomColor
    }

    @objc private func stopSharing() {
        guard let whiteboardId = viewModel.whiteboardInfo?.whiteboardID else { return }
        let meetingMeta = MeetingMeta(meetingID: self.viewModel.meeting.meetingId)
        let request = OperateWhiteboardRequest(action: .stopWhiteboard, meetingMeta: meetingMeta, whiteboardSetting: nil, whiteboardId: whiteboardId)
        WhiteboardTracks.trackStopButtonClick(whiteboardId: whiteboardId)
        HttpClient(userId: self.viewModel.meeting.userId).getResponse(request) { r in
            switch r {
            case .success:
                Self.logger.info("operateWhiteboard stopWhiteboard success")
            case .failure(let error):
                Self.logger.info("operateWhiteboard stopWhiteboard error: \(error)")
            }
        }
        if viewModel.meeting.subType == .screenShare {
            viewModel.meeting.leave()
        }
    }

    private func configWatermarkView(showWatermark: Bool, view: UIView?) {
        // 大小窗切换时，watermark view 信号会不断发出新实例，whiteboardVC 是复用的，而 InMeetWhiteboardViewController 不复用，
        // 因此水印视图不能保存在 InMeetWhiteboardViewController 中，而要记录在 whiteboardVC 层级，最简单的无侵入方法就是使用 tag
        whiteboardVC.view.viewWithTag(Self.watermarkViewTag)?.removeFromSuperview()
        guard showWatermark, let view = view else {
            return
        }
        view.tag = Self.watermarkViewTag
        view.frame = whiteboardVC.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        whiteboardVC.view.addSubview(view)
        view.layer.zPosition = .greatestFiniteMagnitude
    }
}

extension InMeetWhiteboardViewController: InMeetWhiteboardViewModelDelegate {

    func didChangeWhiteboardInfo(_ info: WhiteboardInfo) {
        self.whiteboardVC.receiveWhiteboardInfo(info)
    }

    func updateSharingUserName(_ name: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard I18n.View_G_NameSharingBoard_Status(name) != self.bottomView.sharingLabel.text else {
                return
            }
            self.bottomView.sharingLabel.text = I18n.View_G_NameSharingBoard_Status(name)
            self.logger.info("didUpdateWhiteboardUserName:\(name.hash)")
        }
    }

    func didChangeEditAuthority(canEdit: Bool) {
        DispatchQueue.main.async {
            self.whiteboardVC.didChangeEditAuthority(canEdit: canEdit)
            self.delegate?.whiteboardEditAuthorityChanged(canEdit: canEdit)
        }
    }

    func whiteboardDidShowMenu() {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.updateBottomViewIsHidden()
            self.updateViewConstraint()
            if Display.phone {
                self.bottomView.alpha = 0
            }
            self.viewModel.shouldShowMenuFromFloatingWindow = false
            self.delegate?.whiteboardDidShowMenu()
            self.view.window?.layoutIfNeeded()
        }, completion: { _ in
            if Display.phone {
                self.bottomView.isHidden = true
            }
        })
    }

    func whiteboardDidHideMenu(isUpdate: Bool) {
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.bottomView.isHidden = false
            self.bottomView.alpha = 1.0
            self.updateBottomViewIsHidden()
            self.updateViewConstraint()
            self.delegate?.whiteboardDidHideMenu(isUpdate: isUpdate)
        }, completion: { _ in
        })
    }

    func pictureInPictureDidStop() {
        Util.runInMainThread {
            guard self.view.window != nil else {
                return
            }
            self.restoreWhiteboardIfNeeded()
        }
    }

    func restoreWhiteboardIfNeeded() {
        guard !self.children.contains(self.whiteboardVC) else {
            return
        }
        self.logger.info("restoreWhiteboardIfNeeded")
        self.whiteboardVC.willMove(toParent: nil)
        self.whiteboardVC.view.removeFromSuperview()
        self.whiteboardVC.removeFromParent()
        self.whiteboardVC.didMove(toParent: nil)
        self.addChild(self.whiteboardVC)
        self.view.insertSubview(self.whiteboardVC.view, belowSubview: self.bottomLineView)
        self.whiteboardVC.didMove(toParent: self)
        self.viewModel.delegate = self
        self.whiteboardVC.bottomBarGuide.snp.remakeConstraints { maker in
            maker.edges.equalTo(self.bottomBarLayoutGuide)
        }
        self.updateViewConstraint()
        let style = self.getViewStyle()
        self.whiteboardVC.setShowContentOnly(isOnly: self.isContentOnly)
        self.whiteboardVC.configDependencies(self.viewModel)
        self.whiteboardVC.setNewViewLayoutStyle(style, true)
        self.view.layoutIfNeeded()
        self.updateFloatingSketchMenuGuide()
    }
}

extension InMeetWhiteboardViewController: WhiteboardDataDelegate {
    func didChangeSnapshotSaveState(isSaved: Bool) {
        viewModel.meeting.shareData.isWhiteBoardSaved = isSaved
    }
}

class WhiteboardBottomView: UIView {

    private let isSharer: Bool
    private let leftSpacer = UILayoutGuide()
    private let rightSpacer = UILayoutGuide()

    let sharingLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = ""
        label.numberOfLines = 1
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.backgroundColor = UIColor.clear
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    let stopSharingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        button.setTitle(I18n.View_VM_StopSharing, for: .normal)
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.layer.borderColor = UIColor.ud.functionDangerContentDefault.cgColor
        button.layer.borderWidth = 1
        button.titleEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    let containerView: UIView = {
        let view = UIView()
        return view
    }()

    init(isSharer: Bool) {
        self.isSharer = isSharer
        super.init(frame: .zero)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        addSubview(containerView)
        containerView.addSubview(sharingLabel)
        if isSharer {
            containerView.addSubview(stopSharingButton)
            containerView.addLayoutGuide(leftSpacer)
            containerView.addLayoutGuide(rightSpacer)
            leftSpacer.snp.makeConstraints { maker in
                maker.left.equalToSuperview().inset(12)
                maker.width.equalTo(rightSpacer)
            }
            rightSpacer.snp.makeConstraints { maker in
                maker.right.equalToSuperview().inset(12)
            }
        }
        remakeLayout()
    }

    func remakeLayout() {
        containerView.snp.remakeConstraints { maker in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(Display.pad ? 32 : isPhonePortrait ? 40 : 36)
        }
        if !isSharer {
            sharingLabel.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview().inset(12)
                maker.top.bottom.equalToSuperview()
            }
        } else {
            if isPhonePortrait {
                sharingLabel.snp.remakeConstraints { maker in
                    maker.left.equalToSuperview().inset(12)
                    maker.right.lessThanOrEqualTo(stopSharingButton.snp.left).offset(-8)
                    maker.centerY.equalToSuperview()
                    maker.height.equalTo(18)
                }
                stopSharingButton.snp.remakeConstraints { maker in
                    maker.right.equalToSuperview().inset(12)
                    maker.centerY.equalToSuperview()
                    maker.width.equalTo(stopSharingButton.intrinsicContentSize.width + 16)
                    maker.height.equalTo(28)
                }
            } else {
                sharingLabel.snp.remakeConstraints { maker in
                    maker.left.equalTo(leftSpacer.snp.right)
                    maker.height.equalTo(Display.phone ? 18 : 20)
                    maker.centerY.equalToSuperview()
                }
                stopSharingButton.snp.remakeConstraints { maker in
                    maker.right.equalTo(rightSpacer.snp.left)
                    maker.left.equalTo(sharingLabel.snp.right).offset(8)
                    maker.width.equalTo(stopSharingButton.intrinsicContentSize.width + 16)
                    maker.height.equalTo(Display.phone ? 28 : 24)
                    maker.centerY.equalToSuperview()
                }
            }
        }
        sharingLabel.textAlignment = isPhonePortrait ? .left : .center
    }
}

extension InMeetWhiteboardViewController: InMeetFlowAndShareProtocol {
    var shareVideoView: UIView? {
        self.whiteboardVC.view
    }

    var shareBottomView: UIView? {
        self.bottomView
    }

    var shareBottomBackgroundView: UIView? {
        self.bottomView
    }

    var singleTapGestureRecognizer: UITapGestureRecognizer? {
        get { nil }
        set { _ = newValue }
    }
}

extension InMeetWhiteboardViewController: InMeetLayoutContainerAware {
    func didAttachToLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        self.layoutContainer = layoutContainer
        self.attachedToLayoutContainer = true
    }
    func didDetachFromLayoutContainer(_ layoutContainer: InMeetLayoutContainer) {
        self.attachedToLayoutContainer = false
        self.layoutContainer = nil
    }

    private func updateFloatingSketchMenuGuide() {
        if !self.attachedToLayoutContainer || !self.whiteboardVC.isPhoneToolbarVisible {
            self.sketchMenuGuideToken?.invalidate()
            self.sketchMenuGuideToken = nil
        } else {
            if self.sketchMenuGuideToken == nil,
               let phoneToolbarGuide = self.whiteboardVC.phoneToolBarGuide {
                self.sketchMenuGuideToken = self.layoutContainer?.registerAnchor(anchor: .bottomSketchBar)
                self.sketchMenuGuideToken?.layoutGuide.snp.remakeConstraints({ make in
                    make.edges.equalTo(phoneToolbarGuide)
                })
            }

        }

    }

    private func updateFloatingTopOrBottomShareBarGuide() {
        var isBottomViewHidden = meetingLayoutStyle == .fullscreen || isContentOnly
        if Display.phone {
            isBottomViewHidden = isBottomViewHidden || viewModel.isWhiteboardMenuDisplaying
        }

        if isBottomViewHidden || !self.attachedToLayoutContainer {
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
}
