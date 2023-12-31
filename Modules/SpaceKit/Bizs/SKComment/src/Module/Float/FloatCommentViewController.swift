//
//  FloatCommentViewController.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/10.
//  
// swiftlint:disable file_length

import SKUIKit
import SnapKit
import RxSwift
import RxCocoa
import SKFoundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignFont
import LarkKeyboardKit
import SpaceInterface
import EENavigator
import SKCommon

class FloatCommentViewController: UIViewController {
    
    struct Layout {
        static let pageControlLength: CGFloat = 130.0
        static let sideCarViewPadding: (left: CGFloat, right: CGFloat) = (46, 6)
        static var sideCarViewBottom: CGFloat { SKDisplay.pad ? 112 : 48 }
        static var sideCardViewHeight: CGFloat = 48.0
    }
    
    private(set) var commentSections = [CommentSection]()
    
    private(set) var page = 0
    
    private(set) var commentPermission: CommentPermission = []
    
    weak var viewInteraction: CommentViewInteractionType?
    
    private weak var textViewDependency: AtInputTextViewDependency?
    
    private weak var cellDelegate: CommentTableViewCellDelegate?
    
    private weak var dependency: DocsCommentDependency?
    
    private let disposeBag = DisposeBag()
    
    var isDismissing = false
    
    let latch = BehaviorRelay<Bool>(value: false)
    
    var state = BehaviorRelay<CommentState>(value: .loading(false))
    
    var docsInfo: DocsInfo? {
        didSet {
            inputSideCarView.zoomable = docsInfo?.fontZoomable ?? false
        }
    }
    
    var mode: CardCommentMode = .browseMode
    
    var showkeyboardCount: Int = 0
    
    lazy private var inputSideCarView: InputSideCarView = {
        let sideCarView = InputSideCarView()
        sideCarView.isHidden = true
        sideCarView.canShowDarkName = dependency?.businessConfig.canShowDarkName ?? false
        return sideCarView
    }()
    
    private(set) var pageControl: CommentPageControlV2 = {
        let layout = CommentPageControlLayoutV2()
        layout.scrollDirection = .vertical
        let pageControl = CommentPageControlV2(frame: .zero, collectionViewLayout: layout)
        pageControl.showsVerticalScrollIndicator = false
        pageControl.showsHorizontalScrollIndicator = false
        pageControl.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        return pageControl
    }()
    

    lazy var commentContainerView: UIView = {
        let result: UIView
        if ViewCapturePreventer.isFeatureEnable {
            result = viewCapturePreventer.contentView
        } else {
            result = UIView()
        }
        return result
    }()

    lazy var currentCommentView: FloatCommentView = {
        let commentView = FloatCommentView(frame: .zero)
        commentView.config(dependency: dependency,
                           cellDelegate: cellDelegate,
                           viewInteraction: viewInteraction)
        commentView.isActive = true
        return commentView
    }()
    
    lazy var preCommentView: FloatCommentView = {
        let commentView = FloatCommentView(frame: .zero)
        commentView.config(dependency: dependency,
                           cellDelegate: cellDelegate,
                           viewInteraction: viewInteraction)
        commentView.alpha = 0
        return commentView
    }()
    
    lazy var nextCommentView: FloatCommentView = {
        let commentView = FloatCommentView(frame: .zero)
        commentView.config(dependency: dependency,
                           cellDelegate: cellDelegate,
                           viewInteraction: viewInteraction)
        commentView.alpha = 0
        return commentView
    }()
    
    var preKeyboardOption: SKUIKit.Keyboard.KeyboardOptions?
    
    lazy var textView: AtInputTextView = {
        let fontZoomable = self.docsInfo?.fontZoomable ?? false
        let font: UIFont = fontZoomable ? UIFont.ud.body0 : defaultFont
        let textView = AtInputTextView(dependency: textViewDependency, font: font, ignoreRotation: false)
        textView.isHidden = true
        view.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            // 目前发现iOS 16.1分屏模式下，左边屏无法响应键盘布局事件 https://meego.feishu.cn/larksuite/issue/detail/13081648
            if #available(iOS 15.0, *), SKDisplay.pad, !SKDisplay.isInSplitScreen {
                make.bottom.equalTo(view.keyboardLayoutGuide.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
            make.height.greaterThanOrEqualTo(80)
        }
        
        if keyboardSafeAreaView.superview == nil {
            view.addSubview(keyboardSafeAreaView)
        }
        keyboardSafeAreaView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(textView.snp.bottom).priority(.low)
        }
        
        textView.textChangeDelegate = self
        self.inputSideCarView.updatePlaceHolder(with: textView.inputTextView?.placeholder)
        self.inputSideCarView.commentDraftKeyDataSource = textView
        textView.layoutIfNeeded()
        return textView
    }()
    
    lazy var keyboardSafeAreaView: UIView = {
        let safeAreaView = UIView()
        safeAreaView.backgroundColor = UIColor.ud.bgBody
        safeAreaView.isHidden = true
        return safeAreaView
    }()
    
    let defaultFont = UIFont.systemFont(ofSize: 16)
    
    private lazy var viewCapturePreventer: ViewCapturePreventer = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = []
        return preventer
    }()

    init(viewInteraction: CommentViewInteractionType?,
         textViewDependency: AtInputTextViewDependency?,
         cellDelegate: CommentTableViewCellDelegate?,
         dependency: DocsCommentDependency?) {
        super.init(nibName: nil, bundle: nil)
        self.docsInfo = dependency?.commentDocsInfo as? DocsInfo
        self.dependency = dependency
        self.viewInteraction = viewInteraction
        self.textViewDependency = textViewDependency
        self.cellDelegate = cellDelegate
        addNotification()
    }
    
    private func addNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(commentPotraintNotification),
                                               name: Notification.Name.commentForcePotraint,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(commentCancelPotraintNotification),
                                               name: Notification.Name.commentCancelForcePotraint,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var maskView = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInit()
        setupLayout()
        bind()
        if UIApplication.shared.statusBarOrientation.isLandscape {
            updateCanShowInputViewOb()
        }
    }
    
    private func setupInit() {
        view.backgroundColor = UDColor.bgMask
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapMaskView))
        tap.delegate = self
        view.addGestureRecognizer(tap)

        commentContainerView.backgroundColor = .clear
        view.addSubview(commentContainerView)
        commentContainerView.addSubview(preCommentView)
        commentContainerView.addSubview(nextCommentView)
        commentContainerView.addSubview(currentCommentView)
        
        view.addSubview(inputSideCarView)
        view.addSubview(pageControl)
        

        view.addSubview(keyboardSafeAreaView)
        view.addSubview(textView)
        
        inputSideCarView.delegate = self
        
        setCapturePreventNotify(type: .thisView)
    }
    
    private func bind() {
        state.subscribe { [weak self] state in
            self?.handleState(state)
        }.disposed(by: disposeBag)
    }
    
    private func setupLayout() {
    
        inputSideCarView.snp.makeConstraints { (make) in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).inset(Layout.sideCarViewPadding.left)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(Layout.sideCarViewPadding.right)
            make.height.equalTo(Layout.sideCardViewHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-Layout.sideCarViewBottom)
        }
        
        commentContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalTo(inputSideCarView)
            make.bottom.equalTo(inputSideCarView.snp.top).offset(4)
        }
        
        [preCommentView, currentCommentView, nextCommentView].forEach {
            $0.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
        }

        pageControl.snp.makeConstraints { (make) in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.width.equalTo(24)
            make.height.equalTo(Layout.pageControlLength)
            make.centerY.equalToSuperview()
        }
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
        NotificationCenter.default.post(name: Notification.Name.BrowserFullscreenMode, object: nil,
                                        userInfo: ["enterFullscreen": true, "token": self.docsInfo?.objToken ?? ""])
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        if self.presentedViewController == nil {
            isDismissing = true
        }
        NotificationCenter.default.post(name: Notification.Name.BrowserFullscreenMode, object: nil,
                                            userInfo: ["enterFullscreen": false, "token": self.docsInfo?.objToken ?? ""])
        // 改变状态
        NotificationCenter.default.post(name: Notification.Name.CommentVCDismiss,
                                        object: nil,
                                        userInfo: nil)
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if LKFeatureGating.enableScreenViewHorizental {
            if self.textView.showNoKeyboardView {
                // 展示图片和语音输入时 不允许横屏
                return .portrait
            }
            // 接入方自定义设置
            if let ioMask = dependency?.supportedInterfaceOrientationsSetByOutsite {
                return ioMask
            }
        } else {
            if let ioMask = dependency?.supportedInterfaceOrientationsSetByOutsite, !textView.keyboard.isShow {
                return ioMask
            }
        }
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return .portrait
        default:
            return .allButUpsideDown
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.height > 1,
           view.bounds.width > 1,
           !latch.value {
            DocsLogger.info("===== float comment vc didLayoutSubviews =====", component: LogComponents.comment)
            latch.accept(true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewInteraction?.emit(action: .viewWillTransition)
            self.currentCommentView.reloadView(force: false) // 行高变化后 需要刷新
            let viewHeight = self.view.frame.size.height
            let height = viewHeight - self.currentCommentView.topInset
            self.viewInteraction?.emit(action: .panelHeightUpdate(height: height))
        }
    }
    
    
    @objc
    func commentPotraintNotification() {
        if docsInfo?.isInVideoConference == true {
            viewInteraction?.emit(action: .keepPotraint(force: true))
        }
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    @objc
    func commentCancelPotraintNotification() {
        if docsInfo?.isInVideoConference == true {
            viewInteraction?.emit(action: .keepPotraint(force: false))
        }
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    @objc
    func tapMaskView() {
        if viewInteraction == nil {
            DocsLogger.error("viewInteraction is nil", component: LogComponents.comment)
            // 兜底逻辑要关闭
            self.dismiss(animated: false)
            self.presentingViewController?.dismiss(animated: false)
        }
        self.viewInteraction?.emit(action: .tapBlank)
    }
    
    public func updateSession(session: Any) {
        textView.updateSession(session: session)
    }
    
    public func update(useOpenID: Bool) {
        textView.update(useOpenID: useOpenID)
    }
    
    deinit {
        DocsLogger.info("float comment vc deinit", component: LogComponents.comment)
    }
}

// MARK: - 手势冲突处理
extension FloatCommentViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else {
            return true
        }
        if touchView.isDescendant(of: self.currentCommentView.tableView) {
            if touch.view != self.currentCommentView.tableView /*|| self.isReloading*/ {
                return false
            }
             return true
        } else if touchView.isDescendant(of: self.textView) || touchView.isDescendant(of: self.inputSideCarView) {
            return false
        }
        if touch.view === self.view {
            return true
        }
        return false
    }
}


// MARK: - CommentInputSideCarViewDelegate
extension FloatCommentViewController: CommentInputSideCarViewDelegate {

    func didClickInputActiveBtn(attributedText: NSAttributedString, imageList: [CommentImageInfo]) {
        guard !isLandscapeBaned else { return }
        if let dependency = self.dependency,
           !dependency.textViewShouldBeginEditing {
            DocsLogger.warning("textView editing is baned", component: LogComponents.comment)
        } else {
            viewInteraction?.emit(action: .clickInputBarView)
        }
        
    }

    func didClickInputSendBtn(attributedText: NSAttributedString, imageList: [CommentImageInfo]) {
        guard !isLandscapeBaned else { return }
        if let dependency = self.dependency,
           !dependency.textViewShouldBeginEditing {
            DocsLogger.warning("textView editing is baned", component: LogComponents.comment)
        } else {
            viewInteraction?.emit(action: .clickInputBarSendBtn(textView: textView,
                                                                attributedText: attributedText,
                                                                imageList: imageList))
        }
    }
    
}


extension FloatCommentViewController {
    
    // swiftlint:disable cyclomatic_complexity
    func handleState(_ state: CommentState) {
        switch state {
        case let .syncPageData(data, page): // 前端的数据需要立即刷新
            handleUpdate(data, page)

        case let .updateDocsInfo(info):
            handleUpdateDocsInfo(state, info)

        case let .updatePermission(permission):
            self.commentPermission = permission
            self.preCommentView.handleState(state)
            self.nextCommentView.handleState(state)

        case let .prePaging(page):
            updatePage(page)
            goPre(page: page)
            
    
        case let .nextPaging(page):
            updatePage(page)
            goNext(page: page)

        case let .refreshFloatBarView(show, draftKey):
            guard isLandscapeBaned == false else {
                DocsLogger.info("landscapeBaned working", component: LogComponents.comment)
                return
            }
            inputSideCarView.isHidden = !show
            inputSideCarView.updateDraft(with: draftKey, docsInfo: self.docsInfo)
    
        case let .toast(hud):
            handleToast(hud)
            
        case let .updateFloatTextView(active, draftKey):
            guard isLandscapeBaned == false else {
                DocsLogger.info("landscapeBaned working", component: LogComponents.comment)
                return
            }
            handleUpdateFloatTextView(active, draftKey)
            
        case let .updaCardCommentMode(mode):
            self.mode = mode
            // sheet也有修复类似问题，复用sheet FG
            textView.fixPadKeyboardInputView = SKDisplay.pad && UserScopeNoChangeFG.LJW.sheetInputViewFix
            switch mode {
            case .newInput:
                view.backgroundColor = UIColor.clear
            default:
                view.backgroundColor = UDColor.bgMask
            }
            
        case let .updateSections(sections):
            handleUpdateSections(sections)

        case let .scanQR(code):
            handleScanQR(code)
            
        case .refreshAtUserText:
            textView.refreshAtUserTextPermission(needToastFor: nil)

        case let .showUserProfile(userId, from):
            if let nav = from { // 优先使用指定了的导航
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: nav))
            } else {
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: self.navigationController ?? self))
            }
        
        case let .openDocs(url):
            let from = self.navigationController ?? self
            Navigator.shared.push(url, from: from)

        case let .setCopyAnchorLinkEnable(enable):
            currentCommentView.copyAnchorLinkEnable = enable
            preCommentView.copyAnchorLinkEnable = enable
            nextCommentView.copyAnchorLinkEnable = enable
            
        case let .setTranslateConfig(config):
            currentCommentView.translateConfig = config
            preCommentView.translateConfig = config
            nextCommentView.translateConfig = config

        default:
            break
        }
        currentCommentView.handleState(state)
    }
    
    func handleUpdateDocsInfo(_ state: CommentState, _ info: DocsInfo) {
        let sameToken = info.token == self.docsInfo?.token
        self.docsInfo = info
        let font = info.fontZoomable ? UIFont.ud.body0 : UIFont.systemFont(ofSize: 16)
        if !sameToken, textView.textFont.lineHeight != font.lineHeight {
            textView.updateFont(font)
        }
        textView.atListView.updateDocsInfo(info)
        self.preCommentView.handleState(state)
        self.nextCommentView.handleState(state)
    }
    
    func handleScanQR(_ code: String) {
        guard let fromVC = self.presentingViewController else { return }
        if let delegate = dependency?.vcFollowDelegate?.browserDelegate {
            self.viewInteraction?.emit(action: .clickClose)
            self.dismiss(animated: false) {
                ScanQRManager.openScanQR(code: code, fromVC: fromVC, vcFollowDelegateType: .browser(delegate))
            }
        } else if let delegate = dependency?.vcFollowDelegate?.spaceDelegate {
            self.viewInteraction?.emit(action: .clickClose)
            self.dismiss(animated: false) {
                ScanQRManager.openScanQR(code: code, fromVC: fromVC, vcFollowDelegateType: .space(delegate))
            }
        } else {
            self.viewInteraction?.emit(action: .clickClose)
            self.dismiss(animated: false) {
                ScanQRManager.openScanQR(code: code, fromVC: fromVC, vcFollowDelegateType: .browser(nil))
            }
        }
    }

    func updatePage(_ page: Int) {
        if page < commentSections.count {
            self.page = page
            pageControl.reloadDataWithPage(page)
        } else {
            DocsLogger.error("page out of range", component: LogComponents.comment)
        }
    }
    
    func handleUpdate(_ data: [CommentSection], _ currentPage: Int) {
        let totalPage = data.count
        let preIsEmpty = commentSections.isEmpty
        let currentId = commentSections.activeComment?.comment.commentID
        let nextId = data.activeComment?.comment.commentID
        commentSections = data
        self.page = currentPage
        pageControl.numberOfPages = totalPage
        pageControl.isHidden = (totalPage <= 1)
        pageControl.reloadDataWithPage(page)
        // 第一次需要延时预加载
        let duration: TimeInterval = preIsEmpty ? 0.3 : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.preloadComment()
        }
        
        // 激活评论发生改变（可能是解决了评论），补发一次switchCard
        let viewHeight = self.view.frame.size.height
        if let id = nextId, nextId != currentId, viewHeight > 10 {
            let height = viewHeight - self.currentCommentView.topInset
            self.viewInteraction?.emit(action: .switchCard(commentId: id, height: height))
        }
        
    }
    
    func handleToast(_ hud: CommentState.HUD) {
        let on: UIView = self.view.window ?? self.view
        switch hud {
        case .success(let msg):
            UDToast.showSuccess(with: msg, on: on)
        case .failure(let msg):
            UDToast.showFailure(with: msg, on: on)
        case .tips(let msg):
            UDToast.showTips(with: msg, on: on)
        }
    }
    
    func handleUpdateFloatTextView(_ active: Bool, _ draftKey: CommentDraftKey?) {
        textView.isHidden = !active
        keyboardSafeAreaView.isHidden = !active
        if let key = draftKey {
            textView.restoreDraft(draftKey: key)
        } else {
            textView.clearAllContent()
        }
        let currentIsFirstResponder = textView.textViewIsFirstResponder()
        if active {
            if !currentIsFirstResponder {
                textView.textviewBecomeFirstResponder()
            }
        } else {
            if currentIsFirstResponder {
                textView.textViewResignFirstResponder()
            }
        }
    }
    
    func handleUpdateSections(_ sections: [Int]) {
        let reloadSection = sections.filter { $0 == self.page }
        guard reloadSection.first != nil else {
            return
        }
        currentCommentView.reloadView(force: false)
    }
}

// MARK: - CommentTextViewTextChangeDelegate

extension FloatCommentViewController: CommentTextViewTextChangeDelegate {
    
    func commentTextView(textView: UITextView, didMention atInfo: AtInfo) {
        viewInteraction?.emit(action: .didMention(atInfo))
    }
    
    func textViewDidTriggerAtAction(_ textView: AtInputTextView, at rect: CGRect) {
        viewInteraction?.emit(action: .mention(atInputTextView: textView, rect: rect))
    }
    
    func atListViewShouldRefresh(_ keyword: String) {
        viewInteraction?.emit(action: .mentionKeywordChange(keyword: keyword))
    }
    
    func keyboard(change option: SKUIKit.Keyboard.KeyboardOptions, textView: AtInputTextView) {
        let event = option.event
        if preKeyboardOption?.event == event, preKeyboardOption?.endFrame == option.endFrame {
            return
        }
        guard let commentEvent = CommentKeyboardOptions.KeyboardEvent.convertKeyboardEvent(event) else {
            return
        }
        let commentOption = CommentKeyboardOptions(event: commentEvent,
                                              beginFrame: option.beginFrame,
                                              endFrame: option.endFrame,
                                              animationCurve: option.animationCurve,
                                              animationDuration: option.animationDuration)
        dependency?.keyboardChange(didTrigger: commentEvent, options: commentOption, textViewHeight: textView.contentHeight)
        updateTextViewConstraints(option)
        self.preKeyboardOption = option
        viewInteraction?.emit(action: .keyboardChange(options: option))
    }
    
    func textViewDidEndEditing(_ textView: AtInputTextView) {
        textView.hideAtListView()
        viewInteraction?.emit(action: .textViewDidEndEditing(textView))
    }
}

// MARK: - update keybaord constraint

extension FloatCommentViewController {
    
    func updateTextViewConstraints(_ option: SKUIKit.Keyboard.KeyboardOptions) {
        guard let currentWindowHeight = view.window?.frame.height else {
            DocsLogger.error("failed to get current window when keyboard show")
            return
        }
        
        var inset: CGFloat = 0
        var keyboardShow = false
        if option.event == .willShow || option.event == .didShow {
            let commentFrameInWindow = view.convert(view.frame, to: nil)
            let bottomExtraOffset = currentWindowHeight - commentFrameInWindow.maxY
            let bottomOffset = option.endFrame.size.height - bottomExtraOffset
            let actualOffset = max(0, bottomOffset)
            inset = actualOffset
            keyboardShow = true
        } else if option.event == .willHide || option.event == .didHide {
            inset = self.view.safeAreaInsets.bottom
            // iOS 15下外接键盘时，一些场景需要留一个高度展示系统keyboadBar（正常情况下应该会触发键盘willShow，但是没有触发）
            if option.endFrame.size.height < 100, option.endFrame.maxY <= SKDisplay.windowBounds(self.view).height {
                inset = option.endFrame.size.height
            }
        }
        
        
        UIView.animate(withDuration: option.animationDuration) {
            if #available(iOS 15.0, *), SKDisplay.pad, !SKDisplay.isInSplitScreen {
                var offset: CGFloat = 0
                // iPad外接键盘时，键盘的布局过高，需要往下偏移一点
                if self.textView.showNoKeyboardView,
                   option.event == .didShow,
                   self.showkeyboardCount < 2 {
                    offset = 7
                    self.showkeyboardCount += 1
                } else if option.event == .didHide {
                    self.showkeyboardCount = 0
                }
                self.textView.snp.remakeConstraints{ (make) in
                    make.left.right.equalToSuperview()
                    make.height.greaterThanOrEqualTo(80)
                    make.bottom.equalTo(self.view.keyboardLayoutGuide.snp.top).offset(-offset)
                }
            } else {
                self.textView.snp.remakeConstraints{ (make) in
                    make.left.right.equalToSuperview()
                    make.height.greaterThanOrEqualTo(80)
                    make.bottom.equalToSuperview().inset(inset)
                }
                self.textView.snp.updateConstraints({ (make) in
                   make.bottom.equalToSuperview().inset(inset)
                })
            }
            self.inputSideCarView.snp.updateConstraints { make in
                if keyboardShow {
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-inset)
                } else {
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-Layout.sideCarViewBottom)
                }
            }
            
            self.pageControl.snp.updateConstraints { (make) in
                let offset: CGFloat = keyboardShow ? option.endFrame.size.height / 2 : 0
                make.centerY.equalToSuperview().offset(-offset)
            }
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - CapturePrevent
extension FloatCommentViewController {
    public func setCapturePreventNotify(type: ViewCaptureNotifyContainer) {
        viewCapturePreventer.notifyContainer = type
    }

    public func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}


// MARK: - statusBarOrientationChange

extension FloatCommentViewController {
    
    var isLandscapeBaned: Bool {
        if case .newInput = self.mode {
            // newInput不拦截
            return false
        }
        let support = docsInfo?.inherentType.supportCommentWhenLandscape ?? false
        return !SKDisplay.pad && !support && UIApplication.shared.statusBarOrientation.isLandscape
    }

    @objc
    func statusBarOrientationChange() {
        self.view.layoutIfNeeded()
        self.currentCommentView.resetPosition()
        self.updateCanShowInputViewOb()
        self.updateConstraintsWhenOrientationChangeIfNeed()
    }
    
    private func updateCanShowInputViewOb() {
        // sheet下可以横屏，但是输入框隐藏，等sheet接入横屏后再注视掉
        let supportCommentWhenLandscape = docsInfo?.inherentType.supportCommentWhenLandscape ?? false
    
        if !SKDisplay.pad && !supportCommentWhenLandscape {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                if textView.textViewIsFirstResponder() {
                    textView.textViewResignFirstResponder()
                }
                inputSideCarView.isHidden = true
                inputSideCarView.snp.updateConstraints { make in
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(Layout.sideCardViewHeight)
                }
            } else {
                if case .browseMode = self.mode,
                   commentPermission.contains(.canComment) {
                    inputSideCarView.isHidden = false
                }
                inputSideCarView.snp.updateConstraints { make in
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-Layout.sideCarViewBottom)
                }
            }
            
            pageControl.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
            }
        }
    }
    
    private func updateConstraintsWhenOrientationChangeIfNeed() {
        guard let supportCommentWhenLandscape = docsInfo?.inherentType.supportCommentWhenLandscape else {
            return
        }
        let isChangeLandscape = !SKDisplay.pad && UIApplication.shared.statusBarOrientation.isLandscape && supportCommentWhenLandscape
        if isChangeLandscape {
            textView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(50)
            }
        } else {
            textView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(80)
            }
        }
        textView.updateConstraintsWhenOrientationChangeIfNeed()
    }
}

public final class CommentNavigationController: SKNavigationController, HierarchyIndependentController {

    public var businessIdentifier: String = "DocComment"
    // 可能会显示正文图片在底部，优先级定为20，评论图片为30
    public var hierarchyPriority: HierarchyIndependentPriority = .comment
    
    public var representEnable: Bool = true

    var baned = false
    var isBegingPresenting = false

    func banPanGesture() {
        guard baned == false else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) { [weak self] in
            guard let self = self else { return }
            self.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panAction)))
        }
    }
    
    @objc
    func panAction() {}
}
