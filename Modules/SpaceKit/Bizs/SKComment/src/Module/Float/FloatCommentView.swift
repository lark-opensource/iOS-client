//
//  FloatCommentView.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/10.
//  
// swiftlint:disable file_length

import UIKit
import SKFoundation
import SKResource
import SKUIKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import SpaceInterface
import SKCommon

class FloatCommentView: UICollectionViewCell {
    
    struct Metrics {
        // 拖拽偏移量
        static let changePageTrigerOffset: CGFloat = 40
        static let bottomInset: CGFloat = 80
    }
    
#if BETA || ALPHA || DEBUG
    lazy var debugView: UIView = {
        let db = UIView()
        db.backgroundColor = UIColor.red
        db.isUserInteractionEnabled = false
        return db
    }()
#endif
    
    var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    class FloatCommentTableView: UITableView {
        var renderEnd: (() -> Void)?
        override func layoutSubviews() {
            super.layoutSubviews()
            if numberOfSections > 0 {
                renderEnd?()
            }
        }
    }

    lazy var tableView: UITableView = {
        let tv = FloatCommentTableView(frame: .zero, style: .plain)
        tv.clipsToBounds = true
        tv.allowsSelection = false
        tv.showsVerticalScrollIndicator = false
        tv.showsHorizontalScrollIndicator = false
        tv.bounces = true
        tv.separatorStyle = .none
        tv.estimatedRowHeight = 0
        tv.contentInsetAdjustmentBehavior = .never
        tv.register(CommentQuoteAndReplyCell.self, forCellReuseIdentifier: CommentQuoteAndReplyCell.cellId)
        tv.register(CommentTableViewCellV2.self, forCellReuseIdentifier: CommentTableViewCellV2.cellId)
        tv.register(ContentReactionPhoneCell.self, forCellReuseIdentifier: ContentReactionPhoneCell.cellId)
        tv.register(CommentUnsupportedCell.self, forCellReuseIdentifier: CommentUnsupportedCell.reusePhoneIdentifier)
        tv.tableHeaderView = self.headerView
        tv.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Metrics.bottomInset, right: 0)
        tv.renderEnd = { [weak self] in
            self?.viewInteraction?.emit(action: .renderEnd)
        }
        return tv
    }()

    fileprivate var docsInfo: DocsInfo?
    
    private(set) var commentPermission: CommentPermission = []
    
    var isActive = false

    var scrollFollowHandler: CommentScrollFollowHandler?
    
    private var comment: Comment?
    
    weak var cellDelegate: CommentTableViewCellDelegate?
    
    weak var dependency: DocsCommentDependency?
    
    weak var viewInteraction: CommentViewInteractionType?
    
    let latch = BehaviorRelay<Bool>(value: false)
    
    var disposeBag = DisposeBag()
    
    var mode: CardCommentMode = .browseMode
    
    var focusHighlightReplyId: String?
    
    var foucusWorkItem: DispatchWorkItem?
    
    var copyAnchorLinkEnable = false
    
    func config(dependency: DocsCommentDependency?,
                cellDelegate: CommentTableViewCellDelegate?,
                viewInteraction: CommentViewInteractionType?) {
        self.dependency = dependency
        self.viewInteraction = viewInteraction
        self.cellDelegate = cellDelegate
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func update(_ comment: Comment) {
        DocsLogger.info("update comment:\(comment.commentList.count) id:\(ObjectIdentifier(self))", component: LogComponents.comment)
        let oldComment = self.comment
        self.comment = comment
        if oldComment?.commentID == comment.commentID {
            // do nothing
        } else {
            resetPosition()
        }
    }
    
    func reloadView(force: Bool = true) {
        DocsLogger.info("reloadView id:\(ObjectIdentifier(self)) size:\(bounds.size)", component: LogComponents.comment)
        tableView.clearHeightCache()
        tableView.reloadData()
        if force {
            tableView.layoutIfNeeded()
        }
    }
    
    var translateConfig: CommentBusinessConfig.TranslateConfig?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        self.scrollFollowHandler = CommentScrollFollowHandler(commentView: self, commentScrollDelegate: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        //tableView.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.height > 1,
           bounds.width > 1,
           !latch.value {
            DocsLogger.info("===== float comment view didLayoutSubviews ===== id:\(ObjectIdentifier(self)) isActive:\(isActive)", component: LogComponents.comment)
            if let comment = self.comment {
                update(comment)
            }
            latch.accept(true)
        }
    }

    func ajustPositionWith(offset: CGFloat) {
        DocsLogger.info("ajust position:\(offset) ", component: LogComponents.comment)
        DispatchQueue.main.async {
            let originPoint = self.tableView.contentOffset
            self.clipsToBounds = true
//            self.isAjustLayoutAnimating = true
            UIView.animate(withDuration: 0.3) {
                self.tableView.contentOffset = CGPoint(x: originPoint.x, y: originPoint.y + offset)
            } completion: { (_) in
//                self.isAjustLayoutAnimating = false
                self.clipsToBounds = false
            }
        }
    }

    // 滚动某个item
    private func handleScrollToItem(_ indexPath: IndexPath, _ percent: CGFloat) {
        guard let comment = comment else {
            DocsLogger.error("comment is nil", component: LogComponents.comment)
            return
        }
        guard indexPath.row < comment.commentList.count else {
            DocsLogger.error("scrollToItem faile, indexPath:\(indexPath) larger than  count:\(comment.commentList.count)", component: LogComponents.comment)
            return
        }
        let cellRect = self.tableView.rectForRow(at: indexPath)
        let adjustPercentY = cellRect.height * percent
        //以initContentInsetTop作为锚点调整位置
        if topInset > 0 {
            let anchorFromTop = topInset
            let cellY = cellRect.origin.y
            var destOffset = cellY - anchorFromTop + adjustPercentY
            
            let maxTopOffset = tableView.contentSize.height - tableView.bounds.size.height + Metrics.bottomInset
            if maxTopOffset > 0, destOffset >= maxTopOffset {
                // 不能往上滚动时，停止滚动
                destOffset = maxTopOffset
                DocsLogger.info("[comment scroll] scrollItemToAnchor reset maxTopOffset:\(maxTopOffset) destOffset:\(destOffset)", component: LogComponents.comment)
            }
            DocsLogger.info("[comment scroll] scrollItemToAnchor,cOffset=\(tableView.contentOffset),cellY=\(cellY),cellHeight=\(cellRect.height),percent=\(percent)", component: LogComponents.comment)
            self.tableView.setContentOffset(CGPoint(x: 0, y: destOffset), animated: true)
        } else {
            skAssertionFailure("initContentInsetTop is 0")
            self.tableView.scrollRectToVisible(cellRect, animated: true)
        }
    }
    
    func vcFollowOnRoleChange(role: FollowRole) {
        scrollFollowHandler?.vcFollowOnRoleChange(role: role)
    }
    
    func cacheKey(for indexPath: IndexPath) -> String {
        let commentList = comment?.commentList
        guard let item = commentList?.safe(index: indexPath.row) else {
            return ""
        }
        return item.cacheKey
    }
    
    func clearCellCache(indexPaths: [IndexPath]) {
        DocsLogger.debug("clean cache indexPaths:\(indexPaths)", component: LogComponents.comment)
        let keys: [String] = indexPaths.compactMap {
            let key = cacheKey(for: $0)
            return !key.isEmpty ? key : nil
        }
        if !keys.isEmpty {
            tableView.clearHeightCacheFor(cacheKeys: keys)
        }
    }
}


extension FloatCommentView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comment?.commentList.count ?? 0
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let curComment = comment,
               indexPath.row < curComment.commentList.count else {
            return
        }
        let item = curComment.commentList[indexPath.row]
        if let cell = cell as? CommentTableViewCell, cell.contentAtInfos.count > 0 {
            viewInteraction?.emit(action: .didShowAtInfo(item: item, atInfos: cell.contentAtInfos))
        }
        guard isActive,
              self.alpha == 1, indexPath.row < curComment.commentList.count else {
            return
        }
        guard item.status == .unread, item.uiType.isNormal else {
            return
        }
        viewInteraction?.emit(action: .willDisplayUnread(item))
        item.status = .read
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let commentList = comment?.commentList
        guard let item = commentList?.safe(index: indexPath.row) else {
            return 0
        }
        return CGFloat(tableView.getHeightForCell(cellId: item.uiType.phoneUIIdentify, cacheKey: item.cacheKey, configBlock: { (cell) in
            self.configDataWithCell(cell, indexPath: indexPath, item: item)
        }))
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = comment?.commentList.safe(index: indexPath.row) {
            let cell = tableView.dequeueReusableCell(withIdentifier: item.uiType.phoneUIIdentify, for: indexPath)
            configDataWithCell(cell, indexPath: indexPath, item: item)
            return cell
        }
        return UITableViewCell()
    }

    private func configDataWithCell(_ cell: UITableViewCell, indexPath: IndexPath, item: CommentItem) {
        let canShowMore = true
        let commentPermission = item.permission
        let canShowReaction = commentPermission.contains(.canReaction)
        let fontZoomable = docsInfo?.fontZoomable ?? false
        if let cell = cell as? CommentQuoteAndReplyCell {
            cell.delegate = self
            cell.updateWithQuoteText(text: comment?.quote, fontZoomable: fontZoomable)
            let canResolve = commentPermission.contains(.canResolve)
            cell.canResolve = canResolve
            cell.backgroundColor = .clear
            cell.curCommment = comment
            cell.updateResolveStyle(copyAnchorLinkEnable ? .onlyMore : .onlyResolve)
        } else if let cell = cell as? CommentTableViewCellV2, let curComment = comment {
                cell.translateConfig = translateConfig
                cell.delegate = cellDelegate
                cell.zoomable = fontZoomable
                cell.cellWidth = self.frame.size.width > 0 ? self.frame.size.width : nil
                cell.permission = commentPermission
                cell.atInfoPermissionBlock = self.getPermssionQueryBlock()
                cell.canShowMoreActionButton = canShowMore
                cell.canShowReactionView = (canShowReaction)
                cell.configCellData(item, isFailState: curComment.isUnsummit || item.errorCode != 0, isLoadingState: item.isSending)
                cell.setBgViewColor(color: UIColor.ud.bgFloat)
                if case let .edit(commentItem) = mode,
                   commentItem.replyID == item.replyID { // 正在编辑的 cell
                    cell.setBgViewColor(color: UIColor.ud.Y100 & UIColor.ud.N900.withAlphaComponent(0.3))  // 设置背景颜色
                } else if let focusId = focusHighlightReplyId,
                          focusId == item.replyID { // 还有未执行完毕的高亮动画
        
                    cell.setBgViewColor(color: UIColor.ud.Y100 & UIColor.ud.N900.withAlphaComponent(0.3)) // 高亮

                    
                let resetItem = DispatchWorkItem { [weak self] in
                       guard let self = self else { return }
                       
                       // 还原
                       
                       guard let realCell = self.tableView.cellForRow(at: indexPath) as? CommentHighLightAnimationPerformer else {
                           self.focusHighlightReplyId = nil
                           cell.setBgViewColor(color: UIColor.ud.bgFloat)
                           return
                       }
                       UIView.animate(withDuration: 0.5) { [weak realCell, weak self] in
                           guard let realCell = realCell else { return }
                           self?.focusHighlightReplyId = nil
                           realCell.setBgViewColor(color: UIColor.ud.bgFloat)
                       }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000, execute: resetItem)
                foucusWorkItem = resetItem
                } else {
                    cell.setBgViewColor(color: UIColor.ud.bgFloat)
                }
        } else if let cell = cell as? ContentReactionPhoneCell {
            let items = comment?.commentList.last
            cell.delegate = cellDelegate
            cell.setCanTriggerReaction(commentPermission.contains(.canComment))
            cell.cellWidth = frame.width > 0 ? frame.width : nil
            cell.updateCommentItem(items)
        }
    }

    func getPermssionQueryBlock() -> PermissionQuerryBlock? {
        //不显示灰色名字，则不用读取权限，默认就是现实蓝色
        if dependency?.businessConfig.canShowDarkName == false {
            return nil
        }
        let block: PermissionQuerryBlock? = { [weak self] atInfo in
            guard let self = self else { return nil }
            guard atInfo.type == .user, let docsinfo = self.docsInfo else {
                return nil
            }
            let uid = atInfo.token
            let docsKey = AtUserDocsKey(token: docsinfo.token, type: docsinfo.type)
            return AtPermissionManager.shared.hasPermission(uid, docsKey: docsKey)
        }
        return block
    }
    
    func canReload(with item: CommentItem) -> Bool {
        let index = comment?.commentList.firstIndex(where: { $0.replyID == item.replyID })
        return index != nil
    }
    
    func reloadComment(with item: CommentItem) {
        let index = comment?.commentList.firstIndex(where: { $0.replyID == item.replyID })
        if let idx = index {
            self.tableView.clearHeightCacheFor(cacheKeys: [item.cacheKey])
            DocsLogger.info("reload \(IndexPath(row: idx, section: 0))", component: LogComponents.comment)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.tableView.reloadRows(at: [IndexPath(row: idx, section: 0)], with: .none)
            CATransaction.commit()
        }
    }
}

extension FloatCommentView: UITableViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewInteraction?.emit(action: .willBeginDragging(items: []))
        scrollFollowHandler?.beginMonitoring()
        scrollFollowHandler?.commentViewWillBeginDragging()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let commentList = comment?.commentList, commentList.count > 0 else {
            return
        }
        if latch.value, self.isActive {
            scrollFollowHandler?.commentViewDidScroll()
        }
    }
    
    // 惯性滚动停止
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let commentList = comment?.commentList, commentList.count > 0 else {
            return
        }
        if latch.value, self.isActive {
            viewInteraction?.emit(action: .didEndDecelerating)
            scrollFollowHandler?.commentViewDidEndScrolling()
        }
    }

    // MARK: - 翻页滚动
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let comment = comment else {
             return
        }
        if latch.value, self.isActive {
            if !decelerate {
                viewInteraction?.emit(action: .didEndDragging)
            }
            scrollFollowHandler?.commentViewDidEndScrolling()
        }
        markReadMessageIfNeed()
        let offsetTriger = Metrics.changePageTrigerOffset
        let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        let maxTopOffScreent = scrollView.contentSize.height - scrollView.bounds.size.height + offsetTriger + topInset
        if offsetY < 0,
           offsetY < -offsetTriger {
            // 上一页
            viewInteraction?.emit(action: .goPrePage(current: comment))
        } else if ((maxTopOffScreent > 0 && (offsetY - maxTopOffScreent) > offsetTriger)) || (maxTopOffScreent < 0 && offsetY > offsetTriger) {
            
            // 下一页
            viewInteraction?.emit(action: .goNextPage(current: comment))
        }
    }
    
    func readyForNextPage() {
        let offsetOfInset: CGFloat = 50 //为了让滚动更顺畅，增加个补偿
        self.tableView.contentInset = UIEdgeInsets(top: -tableView.contentOffset.y - offsetOfInset, left: 0, bottom: tableView.contentInset.bottom, right: 0)
    }
    
    func readyForPrePage() {
        let offsetOfInset: CGFloat = 50 //为了让滚动更顺畅，增加个补偿
        self.tableView.contentInset = UIEdgeInsets(top: -tableView.contentOffset.y + offsetOfInset, left: 0, bottom: tableView.contentInset.bottom, right: 0)
    }
    
    private var contentInsetTopFactor: CGFloat {
        var compensationFactor: CGFloat = 0
        // VC场景需要往上移动一点
        if conferenceInfo?.inConference == true {
            compensationFactor = 0.18
        }
        guard let count = comment?.commentList.realCount else {
            return 0.3333
        }
        let isSmallScreen = SKDisplay.mainScreenBounds.width <= 375
        switch count {
        case 1:
            let factor: CGFloat = (SKDisplay.pad || isSmallScreen) ? 0.4 : 0.5
            return factor - compensationFactor
        case 2:
            return 0.4 - compensationFactor
        default:
            return 0.3333 - compensationFactor
        }
    }
    
    func resetPosition() {
        let size = self.bounds.size
        var height: CGFloat = 0
        switch mode {
        case.browseMode:
            height = size.height * contentInsetTopFactor
        case .reply, .edit:
            height = 20
        default:
            height = size.height * contentInsetTopFactor
        }
        tableView.contentOffset = CGPoint(x: 0, y: -height)
        tableView.contentInset = UIEdgeInsets(top: height, left: 0, bottom: tableView.contentInset.bottom, right: 0)
    }
    
    var topInset: CGFloat {
        var height = tableView.contentInset.top
        if height == 0 {
            height = self.bounds.size.height * contentInsetTopFactor
        }
        return height
    }
}

extension FloatCommentView: CommentQuoteAndResolveViewDelegate {

    func didClickResolveBtn(from: UIView, comment: Comment?) {
        guard let comment = comment else { return }
        viewInteraction?.emit(action: .clickResolve(comment: comment, trigerView: from))
    }

    func didClickMoreBtn(from: UIView, comment: Comment?) {
        guard let comment = comment else { return }
        viewInteraction?.emit(action: .clickQuoteMore(comment: comment, trigerView: from))
    }
}

// MARK: - 清红点

extension FloatCommentView {
    
    func switchComplete() {
        markReadMessageIfNeed()
    }
    
    /// 标记消息为已读处理，因为评论卡片模块有预加载原因，tableView(_: willDisplay:forRowAt:) 不准确
    /// 为了性能考虑，该方法在停止滚动时才会调用。
    func markReadMessageIfNeed() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else {
            return
        }
        for indexPath in indexPaths {
            guard let item = comment?.commentList.safe(index: indexPath.row),
                  item.uiType.isNormal,
                  item.status == .unread else {
                continue
            }
            viewInteraction?.emit(action: .willDisplayUnread(item))
            item.status = .read
        }
    }
}

// MARK: - ScrollableCommentViewType

extension FloatCommentView: ScrollableCommentViewType {
    
    var docCommentScrollEnable: Bool {
        guard let type = docsInfo?.inherentType else {
            DocsLogger.error("[comment scroll] docs type is nil", component: LogComponents.comment)
            return false
        }
        if type == .bitable || type == .sheet {
            return true
        } else if type == .doc || type == .docX {
            return true
        }
        return false
    }
    
    var highLightPageIndex: Int? {
        return 0
    }
    
    /// 锚点距离面板顶部的距离
    var anchorPointHeightFromTop: CGFloat {
        guard let superview = self.superview else { return 0 }
#if BETA || ALPHA || DEBUG
        if CommentDebugModule.canDebug {
            if debugView.superview == nil {
                addSubview(debugView)
            }
            bringSubviewToFront(debugView)
             debugView.frame = CGRect(x: 0, y: topInset, width: bounds.size.width, height: 2)
        }
#endif
        // iPhone顶部偏移计算需要加上少量间距才能计算准确
        return topInset + 10
    }
    
    var conferenceInfo: CommentConference? {
        return dependency?.commentConference
    }
    
    func getCurrentItemFor(indexPath: IndexPath) -> CommentItem? {
        return comment?.commentList.safe(index: indexPath.row)
    }
    
    var detectOffScreen: Bool {
        return false
    }
    
    var checkNotice: Bool {
        return false
    }
    
    var commentCount: Int {
        // iPhone一页只显示一组评论
        return 1
    }
    
    func getCurrentCommentId(at section: Int) -> String? {
        return comment?.commentID
    }
    
    var footerSectionHeight: CGFloat {
        return 0
    }
    
    var tableViewContentOffset: CGPoint {
        tableView.contentOffset
    }
    
    var tableViewBounds: CGRect {
        tableView.bounds
    }
    
    ///  根据indexPath的到对应cell在tableView的位置
    func commentRectForRow(at indexPath: IndexPath) -> CGRect {
        tableView.rectForRow(at: indexPath)
    }
    
    ///  根据section的到对应section cell在tableView的位置
    func commentRect(forSection section: Int) -> CGRect {
        tableView.rect(forSection: section)
    }
    
    /// 根据point得到对应tableViewCell的indexPath
    func commentIndexPathForRow(at point: CGPoint) -> IndexPath? {
        tableView.indexPathForRow(at: point)
    }
    
    /// tabelViewCell rect转换到评论容器的坐标
    func convertToContent(_ rect: CGRect) -> CGRect {
        tableView.convert(rect, to: self)
    }
}


extension FloatCommentView: CommentScrollDelegate {
    
    func highlightedCommentBecomeInvisibale(info: CommentScrollInfo) {
        viewInteraction?.emit(action: .contentBecomeInvisibale(info))
    }
    
    func commentViewDidScroll(info: CommentScrollInfo) {
        viewInteraction?.emit(action: .magicShareScroll(info))
    }
}

// MARK: - handleState
extension FloatCommentView {

    func handleState(_ state: CommentState) {
        switch state {
        case let .syncPageData(data, currentPage):
            guard let comment = data[CommentIndex(currentPage)] else {
                DocsLogger.error("syncPageData page:\(currentPage) is out of range", component: LogComponents.comment)
                return
            }
            update(comment)
            
        case .reload:
            reloadView()

        case let .updateDocsInfo(info):
            self.docsInfo = info
            self.scrollFollowHandler?.updateDocsInfo(info)

        case let .updatePermission(permission):
            self.commentPermission = permission
            
        case let .foucus(indexPath, position, hilight):
            handelFoucus(indexPath, position, hilight)

        case let .updaCardCommentMode(mode):
            self.mode = mode
            tableView.reloadData()
            
        case let .updateItems(indexs):
            handleUpdateItem(indexs)
            
        case let .scrollToItem(indexPath, percent):
            handleScrollToItem(indexPath, percent)
        default:
            break
        }
    }
    
    func handelFoucus(_ indexPath: IndexPath, _ position: UITableView.ScrollPosition, _ highlight: Bool) {
        guard let comment = comment else { return }
        let row = indexPath.row
        let commentItem = comment.commentList.safe(index: row)
        if let item = commentItem {
            let index = IndexPath(row: row, section: 0)
            if highlight {
                foucusWorkItem?.cancel()
                foucusWorkItem = nil
                focusHighlightReplyId = item.replyID
                tableView.reloadRows(at: [index], with: .none)
            }
            let row = tableView.numberOfRows(inSection: 0)
            if indexPath.row < row {
                tableView.scrollToRow(at: index, at: position, animated: false)
                tableView.setNeedsLayout()
            } else {
                DocsLogger.error("foucus indexPath:\(index) is out of range1", component: LogComponents.comment)
            }
            
        } else {
            DocsLogger.error("foucus indexPath:\(indexPath) is out of range2", component: LogComponents.comment)
        }
    }
    
    func handleUpdateItem(_ indexs: [IndexPath]) {
        let indexPaths = indexs.filter { indexPath in
            let count = self.comment?.commentList.count ?? 0
            return indexPath.section == 0 && indexPath.row < count
        }
        if indexs.count != indexPaths.count {
            spaceAssertionFailure("indexs contain invalid index")
            DocsLogger.error("indexs contain invalid index", component: LogComponents.comment)
        }
        scrollFollowHandler?.stopMonitoring()
        clearCellCache(indexPaths: indexPaths)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tableView.reloadRows(at: indexPaths, with: .none)
        tableView.layoutIfNeeded()
        CATransaction.commit()
    }
}
