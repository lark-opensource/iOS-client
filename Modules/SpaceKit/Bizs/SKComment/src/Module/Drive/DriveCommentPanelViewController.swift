//
//  DriveCommentPanelViewController.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/24.
//
// swiftlint:disable file_length type_body_length

import SKUIKit
import RxSwift
import RxRelay
import SKFoundation
import UniverseDesignToast
import UniverseDesignEmpty
import SnapKit
import EENavigator
import SKResource
import SpaceInterface
import SKCommon

// 用来记录每个 indexPath 对应的 table view
private class Recorder {
    var records: [IndexPath: UITableView] = [:]

    func tableView(for indexPath: IndexPath) -> UITableView {
        var res: UITableView

        if let tableView = records[indexPath] {
            res = tableView
        } else {
            let tv = UITableView()
            tv.allowsSelection = false
            tv.showsVerticalScrollIndicator = false
            tv.showsHorizontalScrollIndicator = false
            tv.separatorStyle = .none
            tv.estimatedRowHeight = 66
            res = tv
            records[indexPath] = tv
        }

        res.removeFromSuperview()

        return res
    }
}

open class DriveCommentPanelViewController: DraggableViewController,
                                            UICollectionViewDelegateFlowLayout,
                                            UICollectionViewDataSource,
                                            UIGestureRecognizerDelegate {

    let latch = BehaviorRelay<Bool>(value: false)
    
    let disposeBag = DisposeBag()

    var state = BehaviorRelay<CommentState>(value: .loading(false))
    
    public var isDismissing: Bool = false

    private(set) var commentSections = [CommentSection]()
    
    var totalPage: Int {
        return commentSections.count
    }
    
    /// 如果外部有值，则由该值决定
    public var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask?
    
    
    var docsInfo: DocsInfo?
    
    private(set) var page = 0 {
        didSet {
            updateSolveButtonHiddenState(index: page)
        }
    }
    
    private weak var textViewDependency: AtInputTextViewDependency?
    
    private weak var cellDelegate: CommentCollectionViewCellDelegate?
    
    private weak var dependency: DocsCommentDependency?
    
    private let recorder = Recorder()

    weak var viewInteraction: CommentViewInteractionType?

    var translateConfig: CommentBusinessConfig.TranslateConfig?

    private(set) var commentPermission: CommentPermission = []

    /// 评论卡片在底部时的约束
    private var normalStyleConstraints: [SnapKit.Constraint] = []
    /// 评论卡片不在底部时的约束
    private var unNormalStyleConstraints: [SnapKit.Constraint] = []
    private var inputViewHiddenConstraints: [SnapKit.Constraint] = []
    
    /// 评论顶部数量显示
    private(set) lazy var commentHeaderView: DriveCommentHeaderView = {
        let commentTitleView = DriveCommentHeaderView(style: .normal)
        commentTitleView.delegate = self
        return commentTitleView
    }()
    
    private var showInput: Bool {
        let res = commentPermission.contains(.canComment)
        return res
    }
    
    var baseStyle: SpaceComment.Style = .normal
    
    public var style: SpaceComment.Style = .normal {
        didSet {
            DocsLogger.info("comment current style", extraInfo: ["currentStyle": "\(style.rawValue)"])
            switch style {
            case .normal:
                commentPageControl.isHidden = false
                commentCollectionView.isScrollEnabled = true
                normalStyleConstraints.forEach { $0.activate() }
                unNormalStyleConstraints.forEach { $0.deactivate() }
                inputViewHiddenConstraints.forEach { showInput ? $0.deactivate() : $0.activate() }
            case .fullScreen, .edit:
                commentPageControl.isHidden = true
                commentCollectionView.isScrollEnabled = false
                normalStyleConstraints.forEach { $0.deactivate() }
                unNormalStyleConstraints.forEach { $0.activate() }
            case .photo:
                normalStyleConstraints.forEach { $0.deactivate() }
                unNormalStyleConstraints.forEach { $0.activate() }
            case .backV2:
                commentPageControl.isHidden = false
                commentCollectionView.isScrollEnabled = true
                normalStyleConstraints.forEach { $0.activate() }
                unNormalStyleConstraints.forEach { $0.deactivate() }
                inputViewHiddenConstraints.forEach { showInput ? $0.deactivate() : $0.activate() }
            default: break
            }

            DispatchQueue.main.async {
                self.view.dingOut()
                self.flowLayout.invalidateLayout()
                self.commentPageControl.setProgress(self.commentCollectionView.contentOffset.x)
            }
            commentHeaderView.changeStyle(style)
            if totalPage < 2 {
                commentPageControl.isHidden = true
            }
        }
    }

    private(set) lazy var flowLayout = CommentCollectionViewFlowLayout()
    
    var mode: CardCommentMode = .browseMode

    /// 评论内容显示
    private(set) lazy var commentCollectionView: UICollectionView = { // 评论内容显示
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.backgroundColor = UIColor.ud.bgBody
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(CommentCollectionViewCell.self, forCellWithReuseIdentifier: CommentCollectionViewCell.reuseIdentifier)
        return cv
    }()

    private var contentWidth: CGFloat {
        return self.commentCollectionView.frame.width
    }
    
    /// 评论 page control V2
    private(set) lazy var commentPageControl: CommentPageControl = {
        let layout = CommentPageControlLayout()
        layout.scrollDirection = .horizontal

        let pageControl = CommentPageControl(frame: .zero, collectionViewLayout: layout)
        // MARK: - hyf 这是干啥的
        pageControl.progressHandler = fromL2RProgressHandler()

        pageControl.showsVerticalScrollIndicator = false
        pageControl.showsHorizontalScrollIndicator = false
        pageControl.backgroundColor = .clear
        return pageControl
    }()

    lazy var commentFooterView: CommentFooterView = {
        let footerView = CommentFooterView(self.textViewDependency)
        footerView.delegate = self
        footerView.atInputTextView.textChangeDelegate = self
        return footerView
    }()


    lazy var commentEmptyView: UDEmptyView = {
        let hintView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                 description: .init(descriptionText: ""),
                                                 imageSize: 100,
                                                 type: .noContact,
                                                 labelHandler: nil,
                                                 primaryButtonConfig: nil,
                                                 secondaryButtonConfig: nil))
        hintView.isHidden = true
        return hintView
    }()
    
    /// 主要是用来拦截hitTest事件
    class DriveContainerView: UIView {
        
        var customHitTest: ((_ point: CGPoint, _ event: UIEvent?) -> UIView?)?
        
        lazy var containerView: UIView = {
            let result: UIView
            if ViewCapturePreventer.isFeatureEnable {
                result = viewCapturePreventer.contentView
            } else {
                result = UIView()
            }
            return result
        }()
        
        lazy var viewCapturePreventer: ViewCapturePreventer = {
            let preventer = ViewCapturePreventer()
            preventer.notifyContainer = []
            return preventer
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(containerView)
            containerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let superHitTestView = super.hitTest(point, with: event)
            if let customiHitTest = customHitTest,
               superHitTestView == nil,
               let view = customiHitTest(point, event) {
                return view
            } else {
                return superHitTestView
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    lazy var containerView: DriveContainerView = {
        let view = DriveContainerView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    
    public var atInputFocusType: AtInputFocusType {
        return self.commentFooterView.atInputTextView.focusType
    }

    public var atInputTextType: AtInputTextType {
        return self.commentFooterView.atInputTextView.dependency?.atInputTextType ?? .cards
    }

    public var atInputTextView: AtInputTextView {
        return self.commentFooterView.atInputTextView
    }

    private(set) lazy var singleTapGesture: UITapGestureRecognizer = { // 点击空白收起页面手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(type(of: self).onTap))
        singleTap.delegate = self
        return singleTap
    }()

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func isShowingAtListView(isShowing: Bool) {
        let isUserInteractionEnabled = !isShowing

        self.commentHeaderView.isUserInteractionEnabled = isUserInteractionEnabled
        self.commentCollectionView.isUserInteractionEnabled = isUserInteractionEnabled
    }
    
    lazy var topLine: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        return lineView
    }()

    
    var preKeyboardOption: SKUIKit.Keyboard.KeyboardOptions?

    init(viewInteraction: CommentViewInteractionType?,
         textViewDependency: AtInputTextViewDependency?,
         cellDelegate: CommentCollectionViewCellDelegate?,
         dependency: DocsCommentDependency?) {

        super.init(nibName: nil, bundle: nil)
        
        self.dependency = dependency
        self.viewInteraction = viewInteraction
        self.textViewDependency = textViewDependency
        self.cellDelegate = cellDelegate
        
        NotificationCenter.default.addObserver(self, selector: #selector(commentViewReLayoutNoti), name: NSNotification.Name(rawValue: "COMMENT_VIEW_RE_LAYOUT"), object: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConfig()
        bind()
    }

    private func bind() {
        state.subscribe { [weak self] state in
            self?.handleState(state)
        }.disposed(by: disposeBag)
    }

    @objc
    func onTap() {
        viewInteraction?.emit(action: .tapBlank)
    }
    
    override public func dragDismiss() {
        super.dragDismiss()
        viewInteraction?.emit(action: .clickClose)
    }
    
    override public func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        super.handlePanGestureRecognizer(panGestureRecognizer)
        commentCollectionView.collectionViewLayout.invalidateLayout()
    }

    @objc
    func commentViewReLayoutNoti() {
        self.view.dingOut()
        self.commentCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let ioMask = supportedInterfaceOrientationsSetByOutsite {
            return ioMask
        }
        switch UIApplication.shared.statusBarOrientation {
        case .portrait:
            return .portrait
        default:
            return .allButUpsideDown
        }
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if SKDisplay.pad { return }
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeRight, .landscapeLeft:
            self.gapState = .min
        default:
            self.gapState = .max
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds.height > 1,
           view.bounds.width > 1,
           !latch.value {
            DocsLogger.info("===== drive comment vc didLayoutSubviews =====", component: LogComponents.comment)
            latch.accept(true)
            self.style = baseStyle
            viewInteraction?.emit(action: .panelHeightUpdate(height: containerView.bounds.size.height))
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewInteraction?.emit(action: .viewWillTransition)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        commentViewReLayoutNoti()
    }

    //外部调用
    public func hideCommentViewController(animate: Bool = true, completion: (() -> Void)? = nil) {
        transitioningDelegate = nil // 屏蔽由于 feed 的动画
        if self.navigationController != nil {
            self.navigationController?.dismiss(animated: animate, completion: completion)
        } else {
            dismiss(animated: animate, completion: completion)
        }
    }
    
    public override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        super.present(viewControllerToPresent, animated: flag, completion: completion)
        NotificationCenter.default.post(name: Notification.Name.BrowserFullscreenMode, object: nil,
                                        userInfo: ["enterFullscreen": true, "token": self.docsInfo?.objToken ?? ""])
    }

    override public func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        if self.presentedViewController == nil {
            isDismissing = true
        }
        if baseStyle == .backV2, let parent = self.presentingViewController {
            parent.dismiss(animated: flag, completion: completion)
        } else {
            super.dismiss(animated: flag, completion: completion)
        }
        NotificationCenter.default.post(name: Notification.Name.BrowserFullscreenMode, object: nil,
                                            userInfo: ["enterFullscreen": false, "token": self.docsInfo?.objToken ?? ""])
        // 改变状态
        NotificationCenter.default.post(name: Notification.Name.CommentVCDismiss,
                                        object: nil,
                                        userInfo: nil)
    }
    
    public func collectionView(_ collectionViecow: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return commentCollectionView.frame.size
    }

    public func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        // 这里是为了处理新增一条评论，但是reload data会滚动到前一条的问题
//        if changedPage != -1 && changedPage <= currentPage {
//            return CGPoint(x: CGFloat(currentPage) * collectionView.frame.width, y: 0)
//        }
        return proposedContentOffset
    }
    
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return commentSections.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCollectionViewCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? CommentCollectionViewCell {
            let comment = commentSections[indexPath.row].model
            cell.translateConfig = translateConfig
            cell.mode = self.mode
            cell.indexPath = indexPath
            cell.tableView = recorder.tableView(for: indexPath)
            cell.tableView?.bounces = false
            cell.docsInfo = docsInfo
            cell.permission = commentPermission
            cell.canComment = commentPermission.contains(.canComment)
            cell.canShowReaction = commentPermission.contains(.canReaction)
            cell.fromFeed = false
            cell.delegate = cellDelegate
            var forceHideMoreActionButtons = false
            switch mode {
            case .edit:
                forceHideMoreActionButtons = true
            default:
                forceHideMoreActionButtons = false
            }
            cell.isHideMoreActionButtons = forceHideMoreActionButtons
            cell.configComment(comment)
            cell.initUI()
        }
        return cell
    }
    
    // MARK: - gesture
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        swiftGestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    func swiftGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == singleTapGesture {
            let location = gestureRecognizer.location(in: view)
            let locationInCommentView = containerView.convert(location, from: view)
            var childVC = self.children.first ?? self.presentedViewController
            if let _ = childVC as? DocsReactionMenuViewController {
                return false
            }
            return (containerView.hitTest(locationInCommentView, with: nil) == nil)
        } else {
            return true
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard contentWidth > 0 else {
            return
        }
        guard scrollView.frame.height >= 10 else {
            return
        }

        commentPageControl.setProgress(scrollView.contentOffset.x)

        let currentIndex = Int((scrollView.contentOffset.x + scrollView.frame.width / 2.0) / scrollView.frame.width)
        commentPageControl.setHighLightColor(currentIndex)

        if currentIndex >= totalPage { return }

        guard page < totalPage else {
            DocsLogger.info("currentPage < comments.count currentPage=\(page),comments.count=\(totalPage)", component: LogComponents.comment)
            return
        }
        let floatIndex = scrollView.contentOffset.x / contentWidth
        let distance = Float(floatIndex) - Float(currentIndex) // 需要判断间距
        commentPageControl.setCurrentPageProgress(CGFloat(distance))

        if fabsf(distance) <= 0.05 {
            if currentIndex == 0 {
                commentPageControl.progressHandler = fromL2RProgressHandler()
            } else if currentIndex == totalPage {
                commentPageControl.progressHandler = fromR2LProgressHandler()
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard contentWidth > 0 else {
            return
        }
        guard scrollView.frame.height >= 10 else {
            return
        }
        let currentIndex = Int((scrollView.contentOffset.x + scrollView.frame.width / 2.0) / scrollView.frame.width)

        if currentIndex >= totalPage { return }

        if page != currentIndex {
            DocsLogger.info("currentPage=\(page),currentIndex=\(currentIndex), count=\(totalPage)", component: LogComponents.comment)
            page = currentIndex
            if let comment = commentSections[CommentIndex(currentIndex)] {
                viewInteraction?.emit(action: .switchCard(commentId: comment.commentID, height: containerView.bounds.size.height))
            }
        }
    }
}


// MARK: - capturePrevent

extension DriveCommentPanelViewController {

    public func setCapturePreventNotify(type: ViewCaptureNotifyContainer) {
        containerView.viewCapturePreventer.notifyContainer = type
    }
    
    public func setCaptureAllowed(_ allow: Bool) {
        containerView.viewCapturePreventer.isCaptureAllowed = allow
    }
}



extension DriveCommentPanelViewController {
    
    private func setupConfig() {
        // 设置顶部事件穿透
        containerView.customHitTest = { [weak self] (point, event) in
            guard let self = self, self.baseStyle != .backV2 else { return nil }
            return self.dependency?.driveCommentTopMaskHitTestView(point, event)
        }
        
        // 分页指示器
        commentPageControl.numberOfPages = totalPage
        commentPageControl.currentPage = page
        commentPageControl.isHidden = (totalPage == 0)
        
        atInputTextView.dependency = self.textViewDependency
        
        if !showInput {
            isCommentFooterViewHidden(true)
        }
        
        setCapturePreventNotify(type: .thisView)
    }

    private func setupUI() {
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(singleTapGesture)
        
        view.addSubview(containerView)
        contentView = containerView
        
        containerView.layer.cornerRadius = 12
        containerView.layer.maskedCorners = .top
        containerView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        containerView.layer.shadowOffset = CGSize(width: 5, height: -10)
        containerView.layer.shadowOpacity = 2
        containerView.layer.shadowRadius = 22
        
        
        containerView.addSubview(commentHeaderView)
        commentHeaderView.addGestureRecognizer(panGestureRecognizer)
        
        containerView.addSubview(topLine)
        containerView.addSubview(commentCollectionView)
        containerView.addSubview(commentEmptyView)
        containerView.addSubview(commentPageControl)
        
        containerView.addSubview(commentFooterView)
       

        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentViewMaxY)
            make.left.right.bottom.equalToSuperview()
        }
        // 空白页展示
        commentEmptyView.snp.makeConstraints { (make) in
            make.top.equalTo(commentHeaderView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        // 评论头部
        commentHeaderView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().labeled("comment header top")
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
        }

        // 线条
        topLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.top.equalTo(commentHeaderView.snp.bottom)
        }
        topLine.accessibilityIdentifier = "top line"

        // 评论底部
        commentFooterView.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(80)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)

            // WARNING: THIS CODE IS VERT IMPORTANT !!!
            // Fix: It is no response that click at list cell.
            inputViewHiddenConstraints
                .append(make.height.equalTo(commentFooterView.atInputTextView.containerView.snp.height).constraint)

            // 没有评论权限的时候需要隐藏
            let zeroHeight = make.height.equalTo(0).constraint
            zeroHeight.deactivate()
            inputViewHiddenConstraints
                .append(zeroHeight)
        }

        // 评论页面控制
        commentPageControl.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(106)
            make.height.equalTo(24)
            if let textViewSnp = commentFooterView.atInputTextView.inpuTextViewSnp {
                make.bottom.equalTo(textViewSnp.top).offset(-16).priority(.high)
            } else {
                make.bottom.equalTo(commentFooterView.atInputTextView.snp.top).offset(-16).priority(.high)
            }
            make.top.lessThanOrEqualToSuperview().priority(.low)
        }
        
        // 评论数据展示
        commentCollectionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(topLine.snp.bottom)
            normalStyleConstraints.append(make.bottom.equalTo(commentPageControl.snp.top).constraint)
            if let textViewSnp = commentFooterView.atInputTextView.inpuTextViewSnp {
                unNormalStyleConstraints.append(make.bottom.equalTo(textViewSnp.top).constraint)
            } else {
                unNormalStyleConstraints.append(make.bottom.equalTo(commentFooterView.atInputTextView.snp.top).constraint)
            }
        }
        
        inputViewHiddenConstraints.forEach { $0.deactivate() } // 默认不开启
    }
    
    private func isCommentFooterViewHidden(_ isHidden: Bool) {
        guard inputViewHiddenConstraints.count == 2 else { return }

        if isHidden {
            inputViewHiddenConstraints[0].deactivate()
            inputViewHiddenConstraints[1].activate()
        } else {
            inputViewHiddenConstraints[0].activate()
            inputViewHiddenConstraints[1].deactivate()
        }
    }

    private func fromL2RProgressHandler() -> CommentPageControl.ProgressHandler {
        return { [weak self] x in
            guard let self = self else {
                return 0
            }

            var y: CGFloat = 0.0

            let fixedCount: CGFloat = 2.0 // 固定前面两个

            if x <= fixedCount * self.contentWidth {
                y = 16.0 * fixedCount - 64.0
            } else {
                y = ( 16.0 * x ) / self.contentWidth - 64.0
            }

            return y
        }
    }
    
    private func fromR2LProgressHandler() -> CommentPageControl.ProgressHandler {
        return { [weak self] x in
            guard let self = self else {
                return 0
            }

            var y: CGFloat = 0.0

            let fixedCount: CGFloat = CGFloat(self.totalPage) - 1.0 - 2.0 // 固定最后两个

            if x >= CGFloat(fixedCount) * self.contentWidth {
                y = 16.0 * fixedCount - 32.0 // 向左偏移两个
            } else {
                y = ( 16.0 * x ) / self.contentWidth - 32.0
            }

            return y
        }
    }
}


extension DriveCommentPanelViewController: CommentHeaderViewDelegate {
    func didClickBackButton() {
        viewInteraction?.emit(action: .clickClose)
        if self.baseStyle == .backV2 {
            NotificationCenter.default.post(name: Notification.Name.CommentFeedV2Back,
                                            object: nil,
                                            userInfo: ["gapState": gapState])
        }
    }
    
    func didExitEditing(needReload: Bool) {
        viewInteraction?.emit(action: .tapBlank)
    }
    
    func didClickResolveButton(_ fromView: UIView, comment: Comment?) {
        if let comment = commentSections[CommentIndex(page)] {
            viewInteraction?.emit(action: .clickResolve(comment: comment, trigerView: fromView))
        } else {
            DocsLogger.error("page:\(page) is out of range", component: LogComponents.comment)
        }
    }
    
}


extension DriveCommentPanelViewController: CommentFooterViewDelegate {
    func changeEditState(_ isEditing: Bool) {
        
    }
}

extension DriveCommentPanelViewController {
    
    // swiftlint:disable cyclomatic_complexity
    func handleState(_ state: CommentState) {
        switch state {
        case let .toast(hud):
            self.handleToast(hud)
        case let .updateTitle(title):
            commentHeaderView.setCommentCount(title)
            
        case .reload:
            commentCollectionView.reloadData()
            
        case let .syncData(data):
            handleSyncData(data)
            
        case let .foucus(indexPath, _, highlight):
            handleFoucus(indexPath: indexPath, highlight: highlight)
            
        case let .updateDocsInfo(docsInfo):
            self.docsInfo = docsInfo
            atInputTextView.atListView.updateDocsInfo(docsInfo)
    
        case let .updatePermission(permission):
            handleUpdatePermission(permission)

        case let .updateFloatTextView(active, draftKey):
            handleUpdateFloatTextView(active, draftKey)
        
        case let .updaCardCommentMode(mode):
            self.mode = mode
            switch mode {
            case .browseMode:
                commentCollectionView.isScrollEnabled = true
                resetBrowseModeUI()
            default:
                commentCollectionView.isScrollEnabled = false
            }
            commentCollectionView.reloadData()
            
        case let .openDocs(url):
            var presentVC: UIViewController?
            if baseStyle == .backV2, let parent = self.presentingViewController?.presentingViewController {
                presentVC = parent
            } else {
                presentVC = self.presentingViewController
            }
            guard let fromVC = presentVC else {
                DocsLogger.error("presentVC not found", component: LogComponents.comment)
                return
            }
            if DocsUrlUtil.url(type: .file, token: docsInfo?.token ?? "").absoluteString == url.absoluteString {
                handleToast(.failure(BundleI18n.SKResource.Drive_Drive_LinkToCurrentFile))
                return
            }

            if let delegate = dependency?.vcFollowDelegate?.browserDelegate {
                self.dismiss(animated: false) {
                    delegate.follow(onOperate: .vcOperation(value: .openUrl(url: url.absoluteString)))
                }
            } else if let delegate = dependency?.vcFollowDelegate?.spaceDelegate {
                self.dismiss(animated: false) {
                    delegate.follow(nil, onOperate: .vcOperation(value: .openUrl(url: url.absoluteString)))
                }
            } else {
                self.viewInteraction?.emit(action: .clickClose)
                self.dismiss(animated: false) {
                    Navigator.shared.push(url, from: fromVC)
                }
            }
            
        case let .scanQR(code):
            var presentVC: UIViewController?
            if baseStyle == .backV2, let parent = self.presentingViewController?.presentingViewController {
                presentVC = parent
            } else {
                presentVC = self.presentingViewController
            }
            guard let fromVC = presentVC else {
                DocsLogger.error("presentVC not found", component: LogComponents.comment)
                return
            }
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
            
        case let .showUserProfile(userId, from):
            var fromVC = from
            if fromVC == nil {
                if baseStyle == .backV2, let parent = self.presentingViewController?.presentingViewController {
                    fromVC = parent
                } else {
                    fromVC = self.presentingViewController
                }
            }
            guard let topVC = fromVC else {
                DocsLogger.error("presentVC not found", component: LogComponents.comment)
                return
            }
            self.viewInteraction?.emit(action: .clickClose)
            let title = docsInfo?.title ?? ""
            self.dismiss(animated: false) {
                HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: title, fromVC: topVC))
            }
            
        case let .setTranslateConfig(config):
            self.translateConfig = config
            
        default:
            break
        }
    }
    
    func handleSyncData(_ data: [CommentSection]) {
        self.commentSections = data
        if let idx = data.activeComment?.index {
            self.page = idx
        } else {
            DocsLogger.error("handleSyncData index is nil", component: LogComponents.comment)
        }
        commentPageControl.numberOfPages = totalPage
        commentPageControl.currentPage = page
        commentPageControl.isHidden = (totalPage == 0)
        commentPageControl.reloadPage()
        commentEmptyView.isHidden = (totalPage != 0)
    }
    
    func handleUpdatePermission(_ permission: CommentPermission) {
        let odlPermission = self.commentPermission
        self.commentPermission = permission
        if odlPermission != permission {
            inputViewHiddenConstraints.forEach { showInput ? $0.deactivate() : $0.activate() }
            self.view.dingOut()
            self.flowLayout.invalidateLayout()
        }
        updateSolveButtonHiddenState(index: self.page)
    }
    
    func handleUpdateFloatTextView(_ active: Bool,
                                   _ draftKey: CommentDraftKey?) {
        if let key = draftKey {
            atInputTextView.restoreDraft(draftKey: key)
        } else {
            atInputTextView.clearAllContent()
        }
        let currentIsFirstResponder = atInputTextView.textViewIsFirstResponder()
        if active {
            if !currentIsFirstResponder {
                atInputTextView.textviewBecomeFirstResponder()
            }
        } else {
            if currentIsFirstResponder {
                atInputTextView.textViewResignFirstResponder()
            }
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
    
    func handleFoucus(indexPath: IndexPath, highlight: Bool) {
        if indexPath.section < totalPage {
            let clView = commentCollectionView
            let currentIndex = Int((clView.contentOffset.x + clView.frame.width / 2.0) / clView.frame.width)
            let diffrencePage = currentIndex != indexPath.section
            self.page = indexPath.section
            var numberItems = commentCollectionView.numberOfItems(inSection: 0)
            if indexPath.section > numberItems {
                DocsLogger.error("handleSyncData \(indexPath) greater than \(numberItems)", component: LogComponents.comment)
                commentCollectionView.reloadData()
            }
            numberItems = commentCollectionView.numberOfItems(inSection: 0)
            if diffrencePage, indexPath.section <= numberItems {
                let tableViewIndexPath = IndexPath(row: indexPath.section, section: 0)
                commentCollectionView.isPagingEnabled = false
                commentCollectionView.scrollToItem(at: tableViewIndexPath, at: .centeredHorizontally, animated: false)
                commentCollectionView.layoutIfNeeded()
                commentCollectionView.isPagingEnabled = true
            }
            guard highlight else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in
                guard let self = self else { return }
                guard let comment = self.commentSections[CommentIndex(self.page)] else {
                    return
                }
                let count = comment.commentList.count
                let sectionPath = IndexPath(row: indexPath.section, section: 0)
                if let cell = self.commentCollectionView.cellForItem(at: sectionPath) as? CommentCollectionViewCell {
                    let rows = cell.tableView?.numberOfRows(inSection: 0) ?? 0
                    if indexPath.row < count, indexPath.row < rows {
                        let cellPath = IndexPath(row: indexPath.row, section: 0)
                        cell.tableView?.scrollToRow(at: cellPath, at: .none, animated: true)
                    }
                }
            }
            view.dingOut()
        }
    }

    private func updateSolveButtonHiddenState(index: Int) {
        let canResolve: Bool
        if 0 <= index, index < commentSections.count {
            let reply = commentSections[page].items.first
            canResolve = reply?.permission.contains(.canResolve) ?? false
        } else {
            canResolve = false
        }
        commentHeaderView.setCommentSolveButtonHidden(totalPage == 0 || !canResolve)
    }
}

// MARK: - update keybaord constraint

extension DriveCommentPanelViewController: CommentTextViewTextChangeDelegate {
    
    func keyboard(change option: SKUIKit.Keyboard.KeyboardOptions, textView: AtInputTextView) {
        let event = option.event
        if preKeyboardOption?.event == event, preKeyboardOption?.endFrame == option.endFrame {
            return
        }
        updateTextViewConstraints(option)
        self.preKeyboardOption = option
        viewInteraction?.emit(action: .keyboardChange(options: option))
    }
    

    func updateTextViewConstraints(_ option: SKUIKit.Keyboard.KeyboardOptions) {
        guard let currentWindowHeight = view.window?.frame.height else {
            DocsLogger.error("failed to get current window when keyboard show")
            return
        }
        
        var inset: CGFloat = 0
        var keyboardShow = false
        // sideCar底部和键盘顶部的距离，大于0表示距离在键盘下方
        if option.event == .willShow || option.event == .didShow {
            keyboardShow = true
            let commentFrameInWindow = view.convert(view.frame, to: nil)
            let bottomExtraOffset = currentWindowHeight - commentFrameInWindow.maxY
            let bottomOffset = option.endFrame.size.height - bottomExtraOffset
            var actualOffset = max(0, bottomOffset)
            let isSelectingImage = atInputTextView.isSelectingImage
            // iOS 15 iPad选择图片时系统返回键盘高度偏小，需要加上14的高度
            if #available(iOS 15.0, *),
               SKDisplay.pad,
               isSelectingImage {
                actualOffset += 14
            }
            inset = actualOffset
            self.style = .fullScreen
        } else if option.event == .willHide || option.event == .didHide {
            self.style = baseStyle
            // iOS 15下外接键盘时，一些场景需要留一个高度展示系统keyboadBar（正常情况下应该会触发键盘willShow，但是没有触发）
            if option.endFrame.size.height < 100, option.endFrame.maxY <= SKDisplay.windowBounds(self.view).height {
                inset = option.endFrame.size.height
            }
        }
        
        UIView.animate(withDuration: option.animationDuration) {
            self.containerView.snp.updateConstraints({ (make) in
                make.top.equalTo(keyboardShow ? self.contentViewMinY: self.contentViewMaxY)
            })
            self.commentFooterView.snp.updateConstraints { make in
                if inset > 0 {
                    // 键盘起来的时候，安全区就不要算在底部的高度
                    inset = max(inset - self.view.safeAreaInsets.bottom, 0)
                }
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(inset)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    func resetBrowseModeUI() {
        self.style = baseStyle
        self.containerView.snp.updateConstraints({ (make) in
            make.top.equalTo(self.contentViewMaxY)
        })
        self.commentFooterView.snp.updateConstraints { make in
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
    }
}

extension DriveCommentPanelViewController: ClipboardProtectProtocol {
    public func getDocumentToken() -> String? {
        docsInfo?.token
    }
}
