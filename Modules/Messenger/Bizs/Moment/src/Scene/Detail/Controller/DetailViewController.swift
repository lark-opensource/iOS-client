//
//  DetailViewController.swift
//  Moment
//
//  Created by zhuheng on 2020/12/30.
//

import Foundation
import LarkUIKit
import RxSwift
import LarkMessageCore
import LarkContainer
import LarkModel
import UniverseDesignToast
import LarkAlertController
import LarkNavigation
import LarkMessengerInterface
import LarkSDKInterface
import SnapKit
import RustPB
import LarkRustClient
import LarkMenuController
import LarkTab
import EENavigator
import UniverseDesignEmpty
import LKCommonsLogging
import UIKit
import LarkSetting

final class DetailViewController: MomentsViewAdapterViewController, UITableViewDataSource, UITableViewDelegate, CommentTableViewDelegate {
    static let logger = Logger.log(DetailViewController.self, category: "Module.Moments.DetailViewController")
    private let viewModel: DetailViewModel

    //C视图下要与NavBar之间空出12的间距
    private lazy var tableHeaderView: UIView = {
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNormalMagnitude, height: 12))
        tableHeaderView.backgroundColor = .clear
        return tableHeaderView
    }()
    private lazy var tableBgView: UIView = {
        let tableBgView = UIView()
        tableBgView.backgroundColor = .ud.bgBody
        tableBgView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 8, height: 8))
        return tableBgView
    }()
    private lazy var tableView: CommentTableView = {
        let table = CommentTableView()
        table.separatorStyle = .none
        table.backgroundColor = UIColor.clear
        table.dataSource = self
        table.delegate = self
        table.commentTableViewDelegate = self
        table.register(CommentSkeletonlTableViewCell.self, forCellReuseIdentifier: CommentSkeletonlTableViewCell.identifier)
        table.register(PostInDetailSkeletonlTableViewCell.self, forCellReuseIdentifier: PostInDetailSkeletonlTableViewCell.identifier)
        table.register(CommentSectionHeader.self,
                       forHeaderFooterViewReuseIdentifier: String(describing: CommentSectionHeader.self))
        //拉到首屏数据前，禁用交互
        table.isUserInteractionEnabled = false
        return table
    }()
    let disposeBag = DisposeBag()
    private let keyboardTracker: DetailKeyBoadTracker

    typealias KeyboardBlock = (MomentsKeyboardDelegate & MomentsKeyboardViewModelDelegate) -> MomentsKeyboard
    let keyboardBlock: KeyboardBlock
    /// 第一次进入是否需要弹起键盘
    private var showKeyboardWhenEnter: Bool = false
    private var showKeyboardBlock: (() -> Void)?
    private var viewDidAppeared: Bool = false {
        didSet {
            if viewDidAppeared {
                showKeyboardBlock?()
                showKeyboardBlock = nil
            }
        }
    }
    private var shouldPopOnAppear: Bool = false
    /// 键盘
    private var _keyboard: MomentsKeyboard?
    fileprivate(set) var keyboard: MomentsKeyboard {
        get {
            if let _keyboard = self._keyboard {
                return _keyboard
            }
            let _keyboard = self.keyboardBlock(self)
            _keyboard.updateEnable(false)
            self._keyboard = _keyboard
            return _keyboard
        }
        set {
            _keyboard = newValue
        }
    }

    /// 键盘的view
    var keyboardView: MomentsKeyboardView {
        return self.keyboard.keyboardView
    }

    // load效果
    private var hudView: UDToast?
    let source: MomentsDetialPageSource?
    private var scrollState: PostDetailScrollState?
    private var highLightCommentId: String?
    private lazy var highLightCommentTime = Date() //记录评论开始高亮展示的时间

    private let canRouteToFeed: Bool

    @ScopedInjectedLazy private var navigationService: NavigationService?

    private lazy var moreButton: LKBarButtonItem = {
        let moreButton = LKBarButtonItem(image: Resources.momentsMoreNav, title: nil)
        moreButton.button.addTarget(self, action: #selector(menuTap), for: .touchUpInside)
        return moreButton
    }()

    @objc
    func menuTap() {
        self.viewModel.postCellViewModel?.onMenuTapped(pointView: moreButton.button)
    }

    private lazy var titleView: DetailTitleView = {
        let title = canRouteToFeed ? BundleI18n.Moment.Lark_Community_FromCommunityButton(MomentTab.tabTitle()) : BundleI18n.Moment.Lark_MomentsDetails_ListTitle
        let titleView = DetailTitleView(title: title, showArrow: canRouteToFeed)
        titleView.didTapped = { [weak self] in
            guard let self = self, let navigationService = self.navigationService else { return }
            let allTabs = navigationService.mainTabs + navigationService.quickTabs
            let url = Tab.moment.url
            guard allTabs.map({ $0.url }).contains(url) else { return }
            self.userResolver.navigator.switchTab(url, from: self, animated: false) { [weak self] _ in
                if let container = self?.animatedTabBarController?.viewController(for: Tab.moment)?.tabRootViewController as? MomentsFeedContainerViewController {
                    container.refreshCurrentDisplayVC()
                }
            }
        }
        return titleView
    }()

    private var sendCommentHud: UDToast?
    let tracker: MomentsCommonTracker = MomentsCommonTracker()

    override var scene: MomentContextScene {
        return .postDetail
    }

    init(userResolver: UserResolver,
         inputs: Detail.Inputs,
         scrollState: PostDetailScrollState?,
         postContext: BaseMomentContext,
         commentContext: BaseMomentContext,
         userPushCenter: PushNotificationCenter,
         showKeyboard: Bool,
         canRouteToFeed: Bool,
         source: MomentsDetialPageSource?,
         keyboardBlock: @escaping KeyboardBlock) {
        self.keyboardBlock = keyboardBlock
        self.showKeyboardWhenEnter = showKeyboard
        self.scrollState = scrollState
        self.source = source
        self.canRouteToFeed = canRouteToFeed
        self.viewModel = DetailViewModel(userResolver: userResolver,
                                         inputs: inputs,
                                         userPushCenter: userPushCenter,
                                         postContext: postContext,
                                         commentContext: commentContext)
        postContext.dataSourceAPI = self.viewModel
        commentContext.dataSourceAPI = self.viewModel
        self.keyboardTracker = DetailKeyBoadTracker(source: source, showKeyboardWhenEnter: showKeyboard)
        super.init(userResolver: userResolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self._keyboard?.viewModel.attachmentUploader.allFinishedCallback = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = titleView
        self.contentView.backgroundColor = UIColor.clear
        self.viewModel.securityAuditService?.auditEvent(.momentsShowDetail(postId: viewModel.postId), status: nil)
        observerMessageViewModel()
        self.addMenuObserver()
        self.viewModel.uploadPostView()
        self.keyboard.viewModel.attachmentUploader.allFinishedCallback = { [weak self] (_) in
            guard let self = self else {
                return
            }
            /// 存在图片上传失败的情况，弹窗提醒，将选定图片置空，防止无法再次选取图片，并且清空失败任务队列，load效果置空
            if !self.keyboard.viewModel.attachmentUploader.failedTasks.isEmpty {
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToUploadPicture, on: self.view)
                self.hudView = nil
                self.keyboard.viewModel.selectedImage = nil
                self.keyboard.viewModel.attachmentUploader.failedTasks.removeAllTasks()
            }
        }
        if let source = source {
            Tracer.trackCommunityDetailPageView(postID: viewModel.postId, source: source)
        }
        /// 恢复草稿
        self.viewModel.getDraftWith { [weak self] (anonymous, richText) in
            if let richText = richText,
               self?.viewModel.postCellViewModel?.entity.canCurrentAccountComment ?? true {
                self?.keyboardView.richText = richText
            }
            self?.keyboard.updateAnonymousStatus(anonymous)
        }
        /// 监听从后台进入前台，导航栏是否被隐藏
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if let nav = self.navigationController,
                   nav.navigationBar.isHidden,
                   nav.topViewController === self {
                    Self.logger.error("nav.navigationBar isHidden")
                    /// 重新setNavigationBarHidden
                    nav.setNavigationBarHidden(false, animated: false)
                }
            }).disposed(by: self.disposeBag)
        self.contentView.addSubview(tableBgView)
        self.view.addSubview(tableView)
        self.contentView.addSubview(keyboardView)
        keyboardView.snp.makeConstraints({ make in
            make.left.right.bottom.equalToSuperview()
        })
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.tableView.layoutIfNeeded()
    }

    override func loadFirstScreenData() {
        super.loadFirstScreenData()
        self.viewModel.initCurrentCircle { [weak self] circle in
            guard let self = self else {
                return
            }
            let fgValue = (try? self.userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.follow.disable") ?? false

            self.viewModel.followable = !(fgValue && circle?.disableFollowing ?? true) &&
            self.viewModel.momentsAccountService?.getCurrentOfficialUser() == nil
            self.viewModel.loadFirstScreenData(scrollState: self.scrollState)
        }
    }

    override func setDisplayStyleRegular() {
        super.setDisplayStyleRegular()
        tableView.tableHeaderView = tableHeaderView
        tableBgView.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(tableHeaderView.snp.bottom)
        }
    }

    override func setDisplayStyleCompact() {
        super.setDisplayStyleCompact()
        tableView.tableHeaderView = nil
        tableBgView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !viewDidAppeared {
            viewDidAppeared = true
        }
        /// 在当前页面出现的时候 刷新一下HUD，防止选择图片页面展示时候 loading无法展示的问题
        if self.hudView != nil {
            self.removeUploadHUD()
            self.showLoadingHudForUpload()
        }
        keyboardView.viewControllerDidAppear()
        if shouldPopOnAppear {
            UDToast.showTips(with: BundleI18n.Moment.Lark_Community_ThisActivityHasBeenDeleted, on: self.view.window ?? UIView(), delay: 1.5)
            self.popSelf()
        }
    }

    func removeUploadHUD() {
        self.hudView?.remove()
        self.hudView = nil
    }

    func showLoadingHudForUpload() {
        hudView = UDToast.showLoading(with: BundleI18n.Moment.Lark_Community_Uploading, on: self.view.window ?? self.view, disableUserInteraction: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardView.viewControllerWillDisappear()
        self.viewModel.saveDraftWith(anonymous: self.keyboard.viewModel.isAnonymous, richText: self.keyboardView.richText)
    }

    override func onResize(widthChanged: Bool, heightChanged: Bool) {
        super.onResize(widthChanged: widthChanged, heightChanged: heightChanged)
        if widthChanged {
            viewModel.postCellViewModel?.onResize()
            viewModel.uiDataSource.forEach {
                $0.forEach { cellVM in
                    cellVM.onResize()
                }
            }
            self.tableView.reloadData()
        }
    }

    private func observerMessageViewModel() {
        viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .postInitRefresh:
                    self?.viewModel.postLoading = false
                    self?.refreshTable(hasHeader: false, hasFooter: false, scrollTo: nil)
                    let item = self?.viewModel.tracker.getItemWithEvent(.showDetail) as? MomentsDetialItem
                    item?.endRender()
                case .firstScreenCommentRefresh(let hasHeader, let hasFooter, let scrollInfo, let sdkCost):
                    guard let self = self else { return }
                    self.tableView.snp.remakeConstraints { (make) in
                        make.top.left.right.equalToSuperview()
                        make.bottom.equalTo(self.keyboardView.snp.top)
                    }
                    self.viewModel.commentsLoading = false
                    self.refreshTable(hasHeader: hasHeader, hasFooter: hasFooter, layoutIfNeed: true, scrollTo: scrollInfo)
                    /// 这个接口会很快 即使延迟0.3秒之后 仍有可能会在viewDidAppear 之前调用
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        if self?.showKeyboardWhenEnter ?? false {
                            self?.showKeyboard()
                        }
                    }
                    let postEntity = self.viewModel.postCellViewModel?.entity
                    self.keyboard.viewModel.postEntity = postEntity
                    self.viewModel.endTrackForShowDetailWith(sdkCost: sdkCost)
                    self.updatePower(canComment: postEntity?.canCurrentAccountComment ?? true,
                                     canReaction: postEntity?.canCurrentAccountReaction(momentsAccountService: self.momentsAccountService) ?? true)
                    self.tableView.isUserInteractionEnabled = true
                    if self.viewModel.manageMode == .recommendV2Mode,
                        let isDeleted = self.viewModel.postCellViewModel?.entity.post.isDeleted,
                        !isDeleted {
                        self.navigationItem.rightBarButtonItem = self.moreButton
                    }
                case .refreshTable(let hasHeader, let hasFooter, let scrollInfo):
                    self?.refreshTable(hasHeader: hasHeader, hasFooter: hasFooter, scrollTo: scrollInfo)
                case .publishComment:
                    self?.sendCommentHud?.remove()
                    /// 发送评论之后 收取键盘
                    self?.keyboardView.fold()
                    self?.tableView.reloadData()
                    self?.tableView.scrollToBottom(animated: true)
                    self?.tracker.endTrackWithEvent(.momentsSendComment)
                case .scroll(let scrollTo):
                    self?.tableView.scrollToRow(at: scrollTo.indexPath,
                                                at: scrollTo.tableScrollPosition,
                                                animated: scrollTo.animation)
                case .postDeletedBySelf:
                    UDToast.showTips(with: BundleI18n.Moment.Lark_Community_ThisActivityHasBeenDeleted, on: self?.view.window ?? UIView())
                    self?.popSelfOnSuitableForDele()
                case .refreshCell(indexs: let indexPaths, animation: let animation):
                    self?.tableView.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: false)
                case .postDelete:
                    self?.viewModel.endTrackForShowDetailWith(sdkCost: nil)
                    self?.showTipViewAndHiddenNavTitle(tip: BundleI18n.Moment.Lark_Community_ThisActivityHasBeenDeleted, type: .noContent)
                case .refresh:
                    self?.tableView.reloadData()
                case .unsupportType:
                    self?.viewModel.endTrackForShowDetailWith(sdkCost: nil)
                    self?.showAlertForErrorMsg(BundleI18n.Moment.Lark_Community_IncludeUnsupportedContentTypes)
                }
            }).disposed(by: disposeBag)

        viewModel.errorDri
            .drive(onNext: { [weak self] (errorType) in
                switch errorType {
                case .loadMoreFail(let error):
                    self?.tableView.endBottomLoadMore(hasMore: true)
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToLoad, on: self?.view ?? UIView())
                case .fetchPostFail(let error):
                    if self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) == true {
                        return
                    }
                    if let error = error as? RCError {
                        switch error {
                        case .businessFailure(errorInfo: let info) where !info.displayMessage.isEmpty:
                            //无权限
                            if info.code == 330_300 || info.code == 330_503 {
                                self?.showTipViewAndHiddenNavTitle(tip: info.displayMessage,
                                                  type: .noAccess)
                                return
                            }
                        default:
                            break
                        }
                    }
                    self?.showAlertForErrorMsg(BundleI18n.Moment.Lark_Community_OopsSmthWrong)
                //其他报错
                case .sendCommentFail(let error):
                    self?.sendCommentHud?.remove()
                    MomentsErrorTacker.trackReciableEventError(error, sence: .MoPost, event: .momentsSendComment, page: "detail")
                    if (self?.momentsAccountService?.handleOfficialAccountErrorIfNeed(error: error, from: self) ?? false) == true {
                        return
                    }
                    var errorMessage = BundleI18n.Moment.Lark_Community_SendFailed
                    if let error = error as? RCError {
                        switch error {
                        case .businessFailure(errorInfo: let info)
                            where (!info.displayMessage.isEmpty && (self?.isEffectiveCode(info.code) ?? false)):
                            errorMessage = info.displayMessage
                        default:
                            break
                        }
                    }
                    UDToast.showFailure(with: errorMessage, on: self?.view.window ?? UIView())
                }
            }).disposed(by: disposeBag)
    }

    /// MOMENTS_CANNOT_CREATE_COMMENT = 330502
    private func isEffectiveCode(_ code: Int32) -> Bool {
        return code == 330_501 || code == 330_502
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = viewModel.cellForRow(tableView, at: indexPath)
        if isRegularStyle && indexPath.section == Detail.Sections.post && indexPath.row == 0 {
            cell.contentView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 8, height: 8))
        } else {
            cell.contentView.lu.addCorner(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], cornerSize: CGSize(width: 0, height: 0))
        }
        return cell
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            viewModel.cellVMDisplayStatusForIndexPath(indexPath, display: true)
            if let cellVM = self.viewModel.commentCellViewModelInForUI(indexPath: indexPath),
               cellVM.entity.comment.id == self.highLightCommentId {
                //是热评的话，则只在hotComments区域展示高亮动画
                if indexPath.section == Detail.Sections.hotComments || !cellVM.entity.comment.isHot {
                    let timeOffset = Date().timeIntervalSince(self.highLightCommentTime)
                    //如果tableView reload，可能会使高亮动画中断。所以要根据播放时间来判断
                    if timeOffset < MomentCommonCell.highlightDuration {
                        (cell as? MomentCommonCell)?.highlightView(timeOffset: timeOffset)
                    } else {
                        self.highLightCommentId = nil
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 不在屏幕内的才触发didEndDisplaying
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            viewModel.cellVMDisplayStatusForIndexPath(indexPath, display: false)
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForRow(at: indexPath)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let postCellVM = self.viewModel.postCellViewModel
        let numberOfRows = viewModel.numberOfRows(in: section)
        if section == Detail.Sections.hotComments,
           numberOfRows != 0,
           let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: CommentSectionHeader.self)) as? CommentSectionHeader {
            let count = postCellVM?.entity.hotComments.count
            let text = BundleI18n.Moment.Lark_Community_HotCommentsHotCommentNumber(stringValueForCount(count))
            header.updateRepliesTip(count ?? 0, text: text, showNoDataTip: false)
            header.delegate = nil
            return header
        } else if section == Detail.Sections.comments,
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: CommentSectionHeader.self)) as? CommentSectionHeader {
            let count = Int(postCellVM?.commentCount ?? 0)
            let text = BundleI18n.Moment.Lark_Community_AllCommentsAllCommentNumber(stringValueForCount(count))
            let showNoDataTip = !viewModel.commentsLoading && numberOfRows == 0
            header.updateRepliesTip(count, text: text, showNoDataTip: showNoDataTip)
            header.delegate = self
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == Detail.Sections.hotComments,
           viewModel.numberOfRows(in: section) != 0 {
            return 56
        } else if section == Detail.Sections.comments {
            if viewModel.commentsLoading {
                return 56
            }
            return viewModel.numberOfRows(in: section) == 0 ? 176 : 56
        }
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if section == Detail.Sections.hotComments,
           viewModel.numberOfRows(in: section) != 0 {
            return 56
        } else if section == Detail.Sections.comments {
            if viewModel.commentsLoading {
                return 56
            }
            return viewModel.numberOfRows(in: section) == 0 ? 176 : 56
        }
        return CGFloat.leastNormalMagnitude
    }

    /// 点击回复评论
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            return
        }
        if !(viewModel.postCellViewModel?.entity.canCurrentAccountComment ?? true) {
            return
        }
        if indexPath.section == Detail.Sections.post {
            foldKeyBoardIfNeedWithClearComment(true)
        } else if let cellVM = viewModel.commentCellViewModelInForUI(indexPath: indexPath) {
            // 如果当前已经有回复的评论了
            if keyboard.replyComment != nil {
                foldKeyBoardIfNeedWithClearComment(true)
            } else {
                cellVM.didSelectCell()
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.isTracking {
            self.foldKeyBoardIfNeedWithClearComment(false)
        }
    }

    // MARK: CommentTableViewDelegate
    func loadTopComments(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadTopComments(finish: finish)
    }

    func loadMoreCommens(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        viewModel.loadMoreCommens(finish: finish)
    }

    func commentCellViewModel(indexPath: IndexPath) -> MomentsCommentCellViewModel? {
        return self.viewModel.commentCellViewModelInForUI(indexPath: indexPath)
    }

    func postCellViewModel(indexPath: IndexPath) -> MomentPostCellViewModel? {
        return self.viewModel.postCellViewModel(indexPath: indexPath)
    }

    func refreshTable(hasHeader: Bool, hasFooter: Bool, layoutIfNeed: Bool = false, scrollTo: Detail.ScrollInfo?) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        guard let scrollTo = scrollTo else {
            return
        }
        self.highLightCommentId = scrollTo.highlightCommentId
        if layoutIfNeed {
            self.tableView.layoutIfNeeded()
        }
        self.tableView.scrollToRow(at: scrollTo.indexPath,
                                   at: scrollTo.tableScrollPosition,
                                   animated: scrollTo.animation)
    }

    func showTipViewAndHiddenNavTitle(tip: String, type: UDEmptyType ) {
        let tipView = MomentsEmptyView(frame: .zero, description: tip, type: type)
        tipView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(tipView)
        tipView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.isHidden = true
        titleView.isHidden = true
    }

    private func stringValueForCount(_ count: Int?) -> String {
        if let number = count {
            return number > 0 ? "\(number)" : ""
        }
        return ""
    }

    private func foldKeyBoardIfNeedWithClearComment(_ clear: Bool) {
        self.keyboardView.fold()
        self.keyboardTracker.clearData()
        if clear {
            self.keyboard.updateReplayComment(nil)
        }
    }

    private func popSelfOnSuitableForDele() {
        /// 当前页面在最上面
        if self.navigationController?.topViewController === self {
            self.popSelf()
        } else {
            self.shouldPopOnAppear = true
        }
    }

    private func showAlertForErrorMsg(_ msg: String) {
        self.showAlert(title: msg, message: "", handler: { [weak self] (_) in
            self?.popSelf()
        })
    }

    //更改回复和互动权限
    func updatePower(canComment: Bool, canReaction: Bool) {
        keyboard.updateEnable(canComment)
        keyboardView.inputPlaceHolder = canComment ? BundleI18n.Moment.Lark_Community_ShareYourComment : BundleI18n.Moment.Lark_Moments_CommentsTurnedOff
        if !canComment {
            keyboardView.richText = .none
        }
    }

    // MARK: - pageAPI
    /// 回复消息
    override func reply(by commentData: RawData.CommentEntity, fromMenu: Bool) {
        if !commentData.comment.canComment {
            return
        }
        self.keyboardTracker.action = fromMenu ? .long : .quick
        self.keyboardTracker.trackerSource = .detail
        self.keyboard.updateReplayComment(commentData)
        self.showKeyboard()
    }

    override func reply(by postData: RawData.PostEntity) {
        if !postData.canCurrentAccountComment {
            return
        }
        self.keyboardTracker.action = .btn
        self.keyboardTracker.trackerSource = .detail
        self.showKeyboard()
    }
}

// MARK: - 键盘代理
extension DetailViewController: MomentsKeyboardDelegate {

    /// 键盘要弹起
    func handleKeyboardAppear() {
        guard let comment = self.keyboard.replyComment else {
            self.keyboardTracker.uploadDataWithForReplay(contenType: .post, postID: self.viewModel.postId, commentID: nil)
            return
        }
        self.keyboardTracker.uploadDataWithForReplay(contenType: .comment, postID: self.viewModel.postId, commentID: comment.id)
    }

    func keyboardFrameChange(frame: CGRect) {
        guard self.keyboardView.observeKeyboard else {
            return
        }
        let tableHeight = self.view.bounds.height - self.keyboardView.frame.height
        let oldHeight = self.tableView.frame.height
        let oldOffsetY = self.tableView.contentOffset.y
        let maxOffset = self.tableView.contentSize.height - tableHeight
        if maxOffset > 0 {
            var newOffsetY = oldOffsetY + (oldHeight - tableHeight)
            if newOffsetY > maxOffset {
                newOffsetY = maxOffset
            }
            self.tableView.setContentOffset(CGPoint(x: 0, y: newOffsetY), animated: false)
        }
    }

    func inputTextViewFrameChange(frame: CGRect) {
    }

    func getKeyboardStartupState() -> KeyboardStartupState {
        return KeyboardStartupState(type: .inputView)
    }

    func currentDisplayVC() -> UIViewController {
        return self.navigationController ?? self
    }
    func emojiClick() {
        self.viewModel.trackDetailPageClick(.input_emoji)
    }

    func pictureClick() {
        self.viewModel.trackDetailPageClick(.input_picture)
    }
}

extension DetailViewController: MomentsKeyboardViewModelDelegate {
    /// 发送富文本消息
    func defaultInputSendTextMessage(_ content: RustPB.Basic_V1_RichText?, imageInfo: RawData.ImageInfo?, replyComment: RawData.CommentEntity?, isAnonymous: Bool) {
        if isAnonymous {
            sendCommentHud = UDToast.showLoading(with: BundleI18n.Moment.Lark_Community_Sending, on: self.view)
        }

        let item = MomentsSendCommentItem(biz: .Moments, scene: .MoFeed, event: .momentsSendComment, page: "detail")
        item.isAnonymous = isAnonymous
        self.tracker.startTrackWithItem(item)

        self.viewModel.createCommentByContent(content, imageInfo: imageInfo, replyComment: replyComment, isAnonymous: isAnonymous)
        if let replyComment = replyComment {
            self.keyboardTracker.uploadDataWithForReplaySend(contenType: .comment, postID: self.viewModel.postId, commentID: replyComment.id)
        } else {
            self.keyboardTracker.uploadDataWithForReplaySend(contenType: .post, postID: self.viewModel.postId, commentID: nil)
        }
        self.foldKeyBoardIfNeedWithClearComment(false)
    }

    func willStartUploadUserSelectedImage() {
        hudView = UDToast.showLoading(with: BundleI18n.Moment.Lark_Community_Uploading, on: view, disableUserInteraction: true)
    }

    func uploadUserSelectedImageFinished(error: Error?) {
        if let apiError = error?.underlyingError as? APIError {
            switch apiError.type {
            case .cloudDiskFull:
                let alertController = LarkAlertController()
                alertController.showCloudDiskFullAlert(from: self, nav: self.navigator)
            case .securityControlDeny(let message):
                self.viewModel.chatSecurityControlService?.authorityErrorHandler(event: .sendImage,
                                                                                authResult: nil,
                                                                                from: self,
                                                                                errorMessage: message)
            default: break
            }
        }
        /// 上传成功后移除loading标志，并将其置空
        removeUploadHUD()
    }

    private func showKeyboard() {
        let action = { [weak self] in
            if !(self?.keyboardView.inputViewIsFirstResponder() ?? false) {
                self?.keyboardView.inputViewBecomeFirstResponder()
            }
        }
        if !viewDidAppeared {
            showKeyboardBlock = action
        } else {
            action()
        }
    }
}

extension DetailViewController: CommentSectionHeaderDelegate {
    func noDataTipClick() {
        if self.viewModel.postCellViewModel?.entity.canCurrentAccountComment == false {
            return
        }
        self.showKeyboard()
    }
}

extension DetailViewController: MenuObserverProtocol {
    func pauseQueue() {
        viewModel.pauseQueue()

    }
    func resumeQueue() {
        viewModel.resumeQueue()
    }
}
