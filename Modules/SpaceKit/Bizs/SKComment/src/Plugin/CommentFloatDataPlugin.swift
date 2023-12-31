//
//  CommentFloatDataPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/26.
//  


import UIKit
import SKFoundation
import SKResource
import SpaceInterface
import SKCommon

enum CardCommentMode: Equatable, CustomStringConvertible {
    case newInput(CommentShowInputModel)
    case browseMode
    /// 回复某条评论并弹起键盘，除了输入框有`@人`草稿，数据和browseMode没有区别
    case reply(CommentItem)
    case edit(CommentItem)

    var pagingEnable: Bool {
        switch self {
        case .reply, .edit:
            return false
        default:
            return true
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.newInput, .newInput): return true
        case (.browseMode, .browseMode): return true
        case (.reply, .reply): return true
        case (.edit, .edit): return true
        default:
            return false
       }
    }
    
    var description: String {
        switch self {
        case let .newInput(model):
            return "newInput cId:\(model.commentID)"
        case .browseMode:
            return "browseMode"
        case let .reply(item):
            return "reply cId:\(item.commentId) rId:\(item.replyID)"
        case let .edit(item):
            return "edit cId:\(item.commentId) rId:\(item.replyID)"
        }
    }
    
}

class CommentFloatDataPlugin: CommentDiffDataPlugin, CommentPluginType {

    static let identifier = "FloatDataPlugin"
    
    var preMode: CardCommentMode = .browseMode
    
    var mode: CardCommentMode = .browseMode

    /// 接收action，对数据进行处理
    func mutate(action: CommentAction) {
        switch action {
        case let .updateData(commentData):
            handelUpdateData(commentData)
            checkMunuAndDismissIfNeed()
        case let .updateNewInputData(model):
            handleUpdateNewInputData(model)
        case let .updateCopyTemplateURL(templateUrlString):
            let canCopyCommentLink = self.context?.businessDependency?.businessConfig.canCopyCommentLink ?? false
            if templateUrlString != self.templateUrlString,
               canCopyCommentLink {
                self.templateUrlString = templateUrlString
                self.scheduler?.reduce(state: .setCopyAnchorLinkEnable(!templateUrlString.isEmpty))
                scheduler?.reduce(state: .reload)
            }
        case let .vcFollowOnRoleChange(role):
            if self.role == .none, role == .follower {
                switch mode {
                case .edit, .reply:
                    handleModeChange(mode: .browseMode)
                default: break
                }
            }
            self.role = role
        case let .scrollComment(commentId, replyId, percent):
            handleScrollComment(commentId, replyId, percent)
        case let .interaction(ui):
            handelUIAction(ui)
        case let .ipc(action, callback):
              handleIPC(action, callback)
        case .reloadData:
            scheduler?.reduce(state: .reload)
        default:
            break
        }
    }
    
    func handleUpdateNewInputData(_ model: CommentShowInputModel) {
        self.mode = .newInput(model)
        self.docsInfo = model.docsInfo
        if let docsInfo = self.docsInfo {
            scheduler?.reduce(state: .updateDocsInfo(docsInfo))
        }
        if self.statsExtra == nil,
           let statsExtra = model.statsExtra {
            self.statsExtra = statsExtra
        }
        self.handleModeChange(mode: self.mode)
    }
    
    private func handelUpdateData(_ commentData: CommentData) {
        if case .newInput = self.mode {
            self.mode = .browseMode
            self.handleModeChange(mode: self.mode)
        }
        var data = commentData
        let commentId = data.currentCommentID
        let replyId = data.currentReplyID

        // 如果没有数据，关掉评论
        if data.comments.isEmpty {
            scheduler?.dispatch(action: .interaction(.clickClose))
            return
        }

        if self.statsExtra == nil,
           let statsExtra = data.statsExtra {
            self.statsExtra = statsExtra
        }

        payload = data.paylod

        prepareCurrentPage(commentSections, &data)
        
        var page = 0
        if let currentPage = data.currentPage {
            page = currentPage
        } else {
            DocsLogger.error("currentPage is nil, set default page 0", component: LogComponents.comment)
        }
        
        let oldCommentSections = commentSections
        commentSections = constructArraySection(data.comments)
        
        commentPermission = data.commentPermission
        docsInfo = data.docsInfo

        if let docsInfo = data.docsInfo {
            scheduler?.reduce(state: .updateDocsInfo(docsInfo))
        } else {
            DocsLogger.error("docsInfo is nil", component: LogComponents.comment)
        }
        scheduler?.reduce(state: .updatePermission(data.commentPermission))
        
        scheduler?.reduce(state: .setTranslateConfig(context?.businessDependency?.businessConfig.translateConfig))

        // 更新浮窗条状态
        updateFloatBarView()
        
        // 同步数据并更新UI
        scheduler?.reduce(state: .syncPageData(data: commentSections, currentPage: page))
        scheduler?.reduce(state: .reload)
        
        // 如果是Feed跳转需要高亮评论
        afterUpdateUI(commentId: commentId, replyId: replyId, page: page)
        
        checkEditModeItemAndFixStatus()

        if case .browseMode = self.mode {
            scrollToBottomWhenSending(oldCommentSections, commentSections)
        }
    }
    
    private func afterUpdateUI(commentId: String?, replyId: String?, page: Int) {
        guard let commentId = commentId,
              !commentId.isEmpty,
              let replyId = replyId,
              !replyId.isEmpty else {
            return
        }
        // 处理foucus滚动
        guard let index = self.commentSections[commentId, replyId],
              page == index.section else {
            return
        }
        scheduler?.reduce(state: .foucus(indexPath: IndexPath(row: index.row, section: 0), position: .top, highlight: true))
    }
    
    /// 更新floatBar的隐藏和显示状态，并更新草稿
    /// - Parameter commentId: 不设置时默认使用当前激活评论的草稿
    func updateFloatBarView(commentId: String? = nil) {
        var draftKey: CommentDraftKey?
        let draftCommentId = commentId ?? commentSections.activeComment?.comment.commentID
        var showBar = false
        if case .browseMode = mode {
            if commentPermission.contains(.canComment) {
                showBar = true
            }
            if let currentCommentID = draftCommentId {
                draftKey = CommentDraftKey(entityId: docsInfo?.token,
                                           sceneType: .newReply(commentId: currentCommentID))
            }
        }
        if let comment = self.commentSections.activeComment?.comment,
           comment.interactionType == .reaction {
            showBar = false
        }
        let state = CommentState.refreshFloatBarView(show: showBar, draftKey: draftKey)
        scheduler?.reduce(state: state)
    }
    
    private func handleScrollComment(_ commentId: String,
                                     _ replyId: String,
                                     _ percent: CGFloat) {
        let activeComemtnId = commentSections.activeComment?.comment.commentID
        guard activeComemtnId == commentId else {
            DocsLogger.error("activeComemtnId:\(activeComemtnId) not equal to dst:\(commentId)", component: LogComponents.comment)
            return
        }
        var index = 0
        if replyId == "IN_HEADER", commentSections[commentId, nil] != nil {
            index = 0
        } else if let idxPath = commentSections[commentId, replyId] {
            index = idxPath.row
        } else {
            DocsLogger.error("\(Self.identifier) found nil comment when handling scroll comment", component: LogComponents.comment)
            return
        }
        scheduler?.reduce(state: .scrollToItem(indexPath: IndexPath(row: index, section: 0), percent: percent))
    }
}


// MARK: - IPC
extension CommentFloatDataPlugin {
    
    private func handleIPC(_ action: CommentAction.IPC, _ callback: CommentAction.IPC.Callback?) {
        switch action {
        case let .setFloatCommentMode(mode):
            handleModeChange(mode: mode)
        case let .refresh(commentId, replyId):
            if let idx = self.commentSections[commentId, replyId] {
                if idx.row == 0 { // 0是虚拟header数据源，表示更新整个section
                    scheduler?.reduce(state: .updateSections([idx.section]))
                } else {
                    scheduler?.reduce(state: .updateItems([IndexPath(row: idx.row, section: 0)]))
                }
            }
        case .fetchSnapshoot:
            handleFetchSnapshoot(callback)
        case .inviteUserDone:
            markInputPermission()
        case .fetchCommentDataDesction:
            handleFetchCommentDataDesction(callback)
        case let .resetDataCache(statsExtra, action):
            switch action {
            case .render:
                let recordedEdit = self.statsExtra?.recordedEdit == true
                if statsExtra == nil, !recordedEdit {
                    return
                }
                self.statsExtra = statsExtra
            case .edit:
                self.statsExtra = statsExtra
            }
        default:
            break
        }
    }
    
    func handleModeChange(mode: CardCommentMode) {
        self.preMode = self.mode
        self.mode = mode
        // 输入框激活状态设置
        switch mode {
        case let .newInput(model) :
            // 更新草稿
            self.scheduler?.dispatch(action: .ipc(.setNewInputDraft(model), nil))
            self.scheduler?.reduce(state: .updateFloatTextView(active: true, draftKey: model.draftKey))
        case .browseMode:
            scheduler?.reduce(state: .updateFloatTextView(active: false, draftKey: nil))
        case let .reply(item):
            scheduler?.reduce(state: .updateFloatTextView(active: true, draftKey: item.newReplyKey))
            
        case let .edit(item):
            if checkEditModeItemAndFixStatus() {
                scheduler?.reduce(state: .updateFloatTextView(active: true, draftKey: item.editDraftKey))
            }
        }
        
        // 同步mode到UI
        scheduler?.reduce(state: .updaCardCommentMode(self.mode))
        
        // 跟新输入条隐藏或者显示
        updateFloatBarView()
    }
    
    /// 检测当前编辑模式下的item是否存在，不存在则重置为browseMode
    /// - Returns: true表示有做了重置处理
    @discardableResult
    func checkEditModeItemAndFixStatus() -> Bool {
        switch mode {
        case let .reply(item),
            let .edit(item):
            let commentId = item.commentId ?? ""
            if commentSections[commentId, item.replyID] != nil {
                return true
            } else {
                // 校验如果不存在，则恢复成browseMode
                DocsLogger.info("cId:\(item.commentId) rId:\(item.replyID) was deleted, set to browseMode", component: LogComponents.comment)
                self.mode = .browseMode
                self.preMode = .browseMode
                scheduler?.reduce(state: .updateFloatTextView(active: false, draftKey: nil))
                scheduler?.reduce(state: .updaCardCommentMode(.browseMode))
                return false
            }
        default:
            return false
        }
    }
    
    private func handleFetchSnapshoot( _ callback: CommentAction.IPC.Callback?) {
        guard let tuple = commentSections.activeComment else {
            callback?(nil, DataIPCError.snapshootNotFound)
            return
        }
        let res = CommentSnapshootImpl(commentId: tuple.comment.commentID,
                                       replyId: "",
                                       indexPath: IndexPath(item: 0, section: tuple.index),
                                       isNewInput: tuple.comment.isNewInput,
                                       isAcivte: true,
                                       viewStatus: .normal)
        callback?(res, nil)
    }
    
    func markInputPermission() {
        scheduler?.reduce(state: .refreshAtUserText(at: IndexPath()))
    }
}

extension CommentFloatDataPlugin {
    
    func handelUIAction(_ action: CommentAction.UI) {
        switch action {
        case let .goPrePage(current):
            handleGoPrePage(current)
        case let .goNextPage(current):
            handleGoNextPage(current)
        default:
            break
        }
    }
    
    private func handleGoPrePage(_ current: Comment) {
        guard mode.pagingEnable else { return }
        if let index = commentSections[current.commentID, nil],
           let comment = commentSections[CommentIndex(index.section - 1)] {
            // 更新激活数据
            deactivate(comment: current)
            activate(comment: comment)
            // 通知UI做切换
            scheduler?.reduce(state: .prePaging(index.section - 1))
            
            // 更新bar草稿
            updateFloatBarView(commentId: comment.commentID)
        } else {
            scheduler?.reduce(state: .toast(.tips(BundleI18n.SKResource.Doc_Comment_IsFirstComment)))
        }
    }

    private func handleGoNextPage(_ current: Comment) {
        guard mode.pagingEnable else { return }
        if let index = commentSections[current.commentID, nil],
           let comment = commentSections[CommentIndex(index.section + 1)] {
            // 更新激活数据
            deactivate(comment: current)
            activate(comment: comment)
            // 通知UI做切换
            scheduler?.reduce(state: .nextPaging(index.section + 1))
            // 更新bar草稿
            updateFloatBarView(commentId: comment.commentID)
        } else {
            scheduler?.reduce(state: .toast(.tips(BundleI18n.SKResource.Doc_Comment_NoMoreComments)))
        }
    }
    
    private func deactivate(comment: Comment) {
        comment.isActive = false
        comment.commentList.forEach {
            $0.viewStatus = .normal
        }
        // 兜底：防止comment并非内部实例
        let filterModel = commentSections.first { $0.model.commentID == comment.commentID }
        filterModel?.model.isActive = false
        filterModel?.model.commentList.forEach {
            $0.viewStatus = .normal
        }
    }
}
