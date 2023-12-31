//
//  CommentScrollFollowHandler.swift
//  SKCommon
//
//  Created by huayufan on 2022/3/9.
//  


import SKFoundation
import SwiftUI
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon

protocol ScrollableCommentViewType: AnyObject {
    
    var highLightPageIndex: Int? { get }
    
    /// 锚点距离面板顶部的距离
    var anchorPointHeightFromTop: CGFloat { get }
    
    var conferenceInfo: CommentConference? { get }
    
    func getCurrentItemFor(indexPath: IndexPath) -> CommentItem?
    
    func getCurrentCommentId(at section: Int) -> String?
    
    /// 是否需要检测高亮评论滚动处屏幕外事件
    var detectOffScreen: Bool { get }
    
    /// 是否需要检测滚动并弹出激活评论提示
    var checkNotice: Bool { get }
    
    var commentCount: Int { get }
    
    var footerSectionHeight: CGFloat { get }
    
    var tableViewContentOffset: CGPoint { get }
    
    var tableViewBounds: CGRect { get }
    
    ///  根据indexPath的到对应cell在tableView的位置
    func commentRectForRow(at indexPath: IndexPath) -> CGRect
    
    ///  根据section的到对应section cell在tableView的位置
    func commentRect(forSection section: Int) -> CGRect
    
    /// 根据point得到对应tableViewCell的indexPath
    func commentIndexPathForRow(at point: CGPoint) -> IndexPath?
    
    /// tabelViewCell rect转换到评论容器的坐标
    func convertToContent(_ rect: CGRect) -> CGRect
    
    var docCommentScrollEnable: Bool { get }
}

protocol CommentScrollDelegate: AnyObject {
    
    /// iPad高亮评论滚出评论外
    func highlightedCommentBecomeInvisibale(info: CommentScrollInfo)
    
    func commentViewDidScroll(info: CommentScrollInfo)
}
 
class CommentScrollFollowHandler {
    
    /// iPad 弹窗条件
    struct TipsLimit {
        /// 滚动距离
        static let minOffset: CGFloat = 800
        /// 评论数>=2
        static let minCommentCount: Int = 2
        /// 参会人数>=3
        static let minParticipantCount: Int = 3
    }
    
    weak var commentView: ScrollableCommentViewType?
    
    weak var commentScrollDelegate: CommentScrollDelegate?
    
    /// 记录滚动出屏幕外的高亮评论，只有detectOffScreen为true时才用到
    var offScreenComments: [String: Bool] = [:]
    
    /// 记录是否展示过过评论提示 key：共享人deviceId
    var foucusRecord: [String: Bool] = [:]
    
    /// 300ms节流器
    let throttle: CommentThrottle
    
    lazy var debounce: DebounceProcesser = {
        return DebounceProcesser()
    }()
    
    /// 记录刚进入文档，P/F角色转换初期的时机
    private var isReady: Bool = false
    
    /// - Parameters:
    ///   - commentView: 评论容器
    ///   - commentScrollDelegate: 接收滚动信息代理
    init(commentView: ScrollableCommentViewType?, commentScrollDelegate: CommentScrollDelegate?) {
        self.commentView = commentView
        self.commentScrollDelegate = commentScrollDelegate
        self.throttle = CommentThrottle(dueTime: DispatchQueueConst.MilliSeconds_250)
        isReady = false
        debounce.debounce(.seconds(2)) { [weak self] in
            self?.isReady = true
        }
    }
    
    private var canMonitoring = true
    
    private var originOffsetY: CGFloat?
    
    public var showNotice = BehaviorRelay<Bool>(value: false)
    
    private(set) var docsInfo: DocsInfo?
    
    var isPresenter: Bool {
        guard let conferenceInfo = commentView?.conferenceInfo else {
            return false
        }
        let role = conferenceInfo.followRole
        return conferenceInfo.inConference && role == .presenter
    }
    
    var isFollower: Bool {
        guard let conferenceInfo = commentView?.conferenceInfo else {
            return false
        }
        let role = conferenceInfo.followRole
        return conferenceInfo.inConference && role == .follower
    }
    
    var supported: Bool {
        guard let docsInfo = docsInfo else {
            DocsLogger.error("[comment scroll] docsInfo is nil", component: LogComponents.comment)
            return false
        }
        let type = docsInfo.inherentType
        let docSupport = type == .doc || type == .docX || type == .sheet || type == .bitable
        if docSupport {
            let docCommentScrollEnable = commentView?.docCommentScrollEnable ?? false
            return docCommentScrollEnable && isPresenter
        } else {
            DocsLogger.debug("[comment scroll] docsType:\(docsInfo.inherentType) is unsupported", component: LogComponents.comment)
            return false
        }
    }
    
}

// MARK: - 外部调用
extension CommentScrollFollowHandler {
    
    func stopMonitoring() {
        canMonitoring = false
    }
    
    func beginMonitoring() {
        canMonitoring = true
    }
    
    func commentViewWillBeginDragging() {
        guard let commentView = commentView else { return }
        self.originOffsetY = commentView.tableViewContentOffset.y
    }
    
    func commentViewDidScroll() {
        guard let commentView = commentView else { return }
        guard canMonitoring, supported else {
            return
        }
        throttle.throttle {
            self.handleCommentScroll()
        }
        checkTipsStatus(currentOffsetY: commentView.tableViewContentOffset.y)
    }
    
    func commentViewDidEndScrolling() {
        // 防止节流器没有捕获到停止时的滚动位置
        guard canMonitoring else {
            return
        }
        self.handleCommentScroll()
    }
    
    func updateActiveComment(_ comment: Comment?) {
        guard let commentView = commentView,
              commentView.checkNotice == true,
              supported,
              comment != nil else {
            return
        }
        guard let context = commentView.conferenceInfo?.context else {
            return
        }
        // 确保之前没有展示过
        foucusRecord[context.presenterDeviceId] = true
    }
    
    func vcFollowOnRoleChange(role: FollowRole) {
        isReady = false
        debounce.debounce(.seconds(2)) { [weak self] in
            self?.isReady = true
        }
    
        guard role == .presenter else {
            DocsLogger.info("[comment scroll] change role return", component: LogComponents.comment)
            return
        }
        DocsLogger.info("[comment scroll] become presenter", component: LogComponents.comment)
        // 抢共享人时需要将当前位置信息同步出去
        // 延迟一段时间发送，防止VC时序有问题
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000, execute: { [weak self] in
            self?.handleCommentScroll()
        })
        
    }
    
    func updateDocsInfo(_ docsInfo: DocsInfo?) {
        self.docsInfo = docsInfo
    }
    
    var isReadyForAnimate: Bool {
        return isReady
    }
    
}


// MARK: - 滚动处理
extension CommentScrollFollowHandler {
    func handleCommentScroll() {
        guard let commentView = commentView else {
            return
        }
        guard supported else {
//            DocsLogger.debug("[comment scroll] current user is not supported", component: LogComponents.comment)
            return
        }
        // 找锚点
        var anchoPoint = CGPoint(x: commentView.tableViewBounds.width / 2, y: 0)
        var isHighLight = false
        var sectionRect: CGRect = .zero
        let anchorFromTop = commentView.anchorPointHeightFromTop
        var highlightedCommentId: String?
        if let section = commentView.highLightPageIndex { // 高亮滚动
            isHighLight = true
            highlightedCommentId = commentView.getCurrentCommentId(at: section)
            anchoPoint = CGPoint(x: commentView.tableViewBounds.width / 2, y: anchorFromTop)
            sectionRect = commentView.commentRect(forSection: section)
        }
        
        // 判断高亮评论是否滚出屏幕外
        let recorded = self.offScreenComments[highlightedCommentId ?? ""] ?? false
        if isHighLight,
           commentView.detectOffScreen,
           !recorded,
           detectOffScreenEvent(sectionRect, commentView) {
            let info = CommentScrollInfo(commentId: highlightedCommentId ?? "",
                                         replyId: "",
                                         replyPercentage: 0)
           commentScrollDelegate?.highlightedCommentBecomeInvisibale(info: info)
           self.offScreenComments[info.commentId] = true
        }
        
        // 如果锚点不显示评论，本轮不需要处理
        let relativePoint = CGPoint(x: anchoPoint.x, y: commentView.tableViewContentOffset.y + anchoPoint.y)
        guard let indexPath = commentView.commentIndexPathForRow(at: relativePoint) else {
            DocsLogger.info("[comment scroll] blank", component: LogComponents.comment)
            return
        }
        
        // 找到锚点处对应评论的滚动信息
        guard let commentItem = commentView.getCurrentItemFor(indexPath: indexPath),
              commentItem.uiType != .footer else {
            DocsLogger.error("[comment scroll] can not find commentItem at:\(indexPath)", component: LogComponents.comment)
            return
        }
        
        // 新建评论不需要处理
        guard commentItem.isNewInput == false else {
            DocsLogger.info("[comment scroll] ignore new input at:\(indexPath)", component: LogComponents.comment)
            return
        }
        
        // 算出最终的滚动信息
        let info = caculateScrollInfo(commentView: commentView,
                                      commentItem: commentItem,
                                      anchoPoint: anchoPoint,
                                      indexPath: indexPath)
        
        let offsetY = commentView.tableViewContentOffset.y
        DocsLogger.debug("[comment scroll] isHL:\(isHighLight) index:\(indexPath) ancho:\(anchoPoint) cmId:\(info.commentId) rpId:\(info.replyId) pc:\(info.replyPercentage) tbOffY:\(offsetY)",
                         component: LogComponents.comment)
        
        commentScrollDelegate?.commentViewDidScroll(info: info)
    }

    func commentBecomActivated(comment: Comment) {
        guard comment.isNewInput == false, supported else { return }
        if !comment.commentID.isEmpty {
            self.offScreenComments[comment.commentID] = false
            DocsLogger.info("[comment scroll] off screen reset commentId:\(comment.commentID)", component: LogComponents.comment)
        } else {
            DocsLogger.error("[comment scroll] off screen try to reset nil commentId", component: LogComponents.comment)
        }
        
    }
}



// MARK: - 内部计算
extension CommentScrollFollowHandler {
    
    
    /// 如果高亮评论滚出容器外，通知前端
    /// - Parameters:
    ///   - commentRect: 一组评论在tableView上的frame
    ///   - commentView: 评论tableView的容器
    ///   - tableView: zhsnhitableView
    func detectOffScreenEvent(_ commentRect: CGRect, _ commentView: ScrollableCommentViewType) -> Bool {
        // commentRect转换成在commentView上的frame
        let sectionRectInTableViewFrame = commentView.convertToContent(commentRect)
        
        let maxY = sectionRectInTableViewFrame.maxY
        let y = sectionRectInTableViewFrame.origin.y
        if maxY <= commentView.footerSectionHeight || y >= commentView.tableViewBounds.height {
            DocsLogger.info("[comment scroll] off screen ✅", component: LogComponents.comment)
           return true
        } else {
            DocsLogger.debug("[comment scroll] off screen maxY:\(maxY)❌", component: LogComponents.comment)
        }
        return false
    }
    
    
    /// 根据锚点，评论计算出滚动百分比信息
    /// - Parameters:
    ///   - commentItem: 锚点对应的评论模型
    ///   - anchoPoint: 锚点的坐标
    ///   - indexPath: 锚点对应的评论在tableView的分组信息
    /// - Returns: 计算好的滚动信息
    func caculateScrollInfo(commentView: ScrollableCommentViewType, commentItem: CommentItem, anchoPoint: CGPoint, indexPath: IndexPath) -> CommentScrollInfo {
        let rectInTableViewContent = commentView.commentRectForRow(at: indexPath)
        let rectInTableViewFrame = commentView.convertToContent(rectInTableViewContent)
        let percent = (anchoPoint.y - rectInTableViewFrame.origin.y) / rectInTableViewFrame.size.height
        spaceAssert(percent >= 0, "[comment scroll] percent is invalid:\(percent)")
        let commentId = commentItem.commentId ?? ""
        let replyId = commentItem.scrollReplyId
        // 确定信息返回给前端
        return CommentScrollInfo(commentId: commentId, replyId: replyId, replyPercentage: percent)
    }
}

// MARK: - 过评论提示
extension CommentScrollFollowHandler {
    
    func checkTipsStatus(currentOffsetY: CGFloat) {
        
        // 确保是共享人，且评论可以弹tips
        guard supported,
              let commentView = commentView,
              commentView.checkNotice == true,
              let begin = originOffsetY else {
            return
        }
        
        let type = docsInfo?.inherentType
        if type == .sheet || type == .bitable {
            return
        }
        
        // 非激活评论滚动
        guard commentView.highLightPageIndex == nil else {
            return
        }
        
        // 返回vcFollow信息
        guard let context = commentView.conferenceInfo?.context else {
            return
        }
        
        // 确保之前没有展示过
        let record = foucusRecord[context.presenterDeviceId] ?? false
        guard record == false else {
            return
        }
        
        let offset = abs(currentOffsetY - begin)
        if offset >= TipsLimit.minOffset,
           context.participantCount >= TipsLimit.minParticipantCount,
           commentView.commentCount >= TipsLimit.minCommentCount {
            foucusRecord[context.presenterDeviceId] = true
            DocsLogger.info("[comment scroll] show tips", component: LogComponents.comment)
            showNotice.accept(true)
        } else {
            showNotice.accept(false)
        }
    }
}
