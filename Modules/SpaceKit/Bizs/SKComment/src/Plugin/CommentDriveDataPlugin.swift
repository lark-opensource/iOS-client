//
//  CommentDriveDataPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/25.
//  


import UIKit
import SKFoundation
import SpaceInterface
import SKCommon

class CommentDriveDataPlugin: CommentDiffDataPlugin, CommentPluginType {

    static let identifier = "DriveDataPlugin"
    
    var mode: CardCommentMode = .browseMode
    var preMode: CardCommentMode = .browseMode
    
    var localCommentIds: [String] = []
    
    /// 接收action，对数据进行处理
    func mutate(action: CommentAction) {
        switch action {
        case let .updateData(commentData):
            handelUpdateData(commentData)
            checkMunuAndDismissIfNeed()
        case let .switchComment(commentId):
            var currentId = commentId
            if commentId.isEmpty {
                let commentID = commentSections.first?.model.commentID ?? ""
                if commentID.isEmpty {
                    return
                }
                currentId = commentID
            }
            handleSwitchComment(commentId: currentId)
            updateTitle()
            if let view = context?.commentPluginView {
                var height = view.bounds.size.height
                if height < 10 {
                    height = 500
                }
                scheduler?.dispatch(action: .api(.switchCard(commentId: currentId, height: height), nil))
            }
        case let .updateDocsInfo(docsInfo):
            self.docsInfo = docsInfo
            commentSections.forEach {
                $0.model.commentDocsInfo = docsInfo
            }
            scheduler?.reduce(state: .updateDocsInfo(docsInfo))
        case let .interaction(ui):
            handelUIAction(ui)
        case let .ipc(action, callback):
              handleIPC(action, callback)
        default:
            break
        }
    }
    
    private func handelUpdateData(_ commentData: CommentData) {
        var data = commentData
        let oldActiveComment = commentSections.activeComment
        let commentId = data.currentCommentID
        
        if !commentData.localCommentIds.isEmpty {
            localCommentIds = commentData.localCommentIds
        }
        
        // 如果没有数据，关掉评论
        if data.comments.isEmpty {
            scheduler?.dispatch(action: .interaction(.clickClose))
            return
        }
        let preIsEmpty = oldActiveComment == nil
        var samePage = false
        if let oldComment = oldActiveComment,
           let currentCommentID = commentData.currentCommentID,
           oldComment.comment.commentID == currentCommentID{
            samePage = true
        }

        prepareCurrentPage(commentSections, &data)

    
        let oldCommentSections = commentSections
        commentSections = constructArraySection(data.comments)
    
        scheduler?.reduce(state: .setTranslateConfig(context?.businessDependency?.businessConfig.translateConfig))
        
        commentPermission = data.commentPermission
        docsInfo = data.docsInfo

        if let docsInfo = data.docsInfo {
            scheduler?.reduce(state: .updateDocsInfo(docsInfo))
        } else {
            DocsLogger.error("docsInfo is nil", component: LogComponents.comment)
        }
        scheduler?.reduce(state: .updatePermission(data.commentPermission))
        
        // 同步数据并更新UI
        scheduler?.reduce(state: .syncData(commentSections))
        scheduler?.reduce(state: .reload)

        let needSwitch = preIsEmpty || !samePage
        if needSwitch,
           let curId = commentSections.activeComment?.comment.commentID,
            let commentPluginView = context?.commentPluginView {
            context?.scheduler?.dispatch(action: .api(.switchCard(commentId: curId,
                                                                  height: commentPluginView.bounds.size.height),
                                                                   nil))
            afterUpdateUI(commentId: curId, replyId: data.currentReplyID)
        } else {
            afterUpdateUI(commentId: commentId, replyId: data.currentReplyID)
        }
        updateTitle()
        udpateTextDraft()

        checkEditModeItemAndFixStatus()
        
        if case .browseMode = self.mode {
            scrollToBottomWhenSending(oldCommentSections, commentSections)
        }
        
        if commentSections.activeComment == nil, let firstComment = data.comments.first {
            activate(comment: firstComment)
        }
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
    
    private func afterUpdateUI(commentId: String?, replyId: String?) {
        guard let commentId = commentId,
              !commentId.isEmpty else {
            return
        }
        // 处理foucus滚动
        guard let replyId = replyId, !replyId.isEmpty, let index = self.commentSections[commentId, replyId] else {
            if let groupIdx = self.commentSections[commentId, nil] {
                scheduler?.reduce(state: .foucus(indexPath: groupIdx, position: .top, highlight: false))
            }
            return
        }
        // index中section必须是0,float comment只有一组数据，否则会越界，单测会校验。
        scheduler?.reduce(state: .foucus(indexPath: index, position: .top, highlight: true))
    }
    
    private func updateTitle() {
        var section = 0
        if let index = self.commentSections.activeComment?.index {
            section = index
        }
        let text = commentSections.isEmpty ? " " : " \(section + 1)/\(commentSections.count)"
        scheduler?.reduce(state: .updateTitle(text))
    }
}

extension CommentDriveDataPlugin {
    private func handleIPC(_ action: CommentAction.IPC, _ callback: CommentAction.IPC.Callback?) {
        switch action {
        case let .setDriveCommentMode(mode):
            handleModeChange(mode: mode)
        case let .refresh(commentId, replyId):
            if let idx = self.commentSections[commentId, replyId] {
                if idx.row == 0 { // 0是虚拟header数据源，表示更新整个section
                    scheduler?.reduce(state: .updateSections([idx.section]))
                } else {
                    scheduler?.reduce(state: .updateItems([idx]))
                }
            }
        case .fetchSnapshoot:
            handleFetchSnapshoot(callback)

        default:
            break
        }
    }
    
    
    
    func handleModeChange(mode: CardCommentMode) {
        self.preMode = self.mode
        self.mode = mode
        udpateTextDraft()
        // 同步mode到UI
        scheduler?.reduce(state: .updaCardCommentMode(self.mode))
    }
    
    func udpateTextDraft() {
        switch mode {
        case .newInput:
             // 无此模式
             break
        case .browseMode:
            var draftKey: CommentDraftKey?
            if let commentId = commentSections.activeComment?.comment.commentID,
               let token = docsInfo?.token,
               !token.isEmpty {
                draftKey = CommentDraftKey(entityId: token,
                                       sceneType: .newReply(commentId: commentId))
            }
            scheduler?.reduce(state: .updateFloatTextView(active: false, draftKey: draftKey))
        case let .reply(item):
            scheduler?.reduce(state: .updateFloatTextView(active: true, draftKey: item.newReplyKey))
        case let .edit(item):
            scheduler?.reduce(state: .updateFloatTextView(active: true, draftKey: item.editDraftKey))
        }
    }
}

extension CommentDriveDataPlugin {
    
    func handelUIAction(_ action: CommentAction.UI) {
        switch action {
        case let .switchCard(commentId, _):
            handleSwitchComment(commentId: commentId)
            updateTitle()
        default:
            break
        }
    }
    
    private func deactivate(comment: Comment) {
        comment.isActive = false
        comment.commentList.forEach {
            $0.viewStatus = .normal
        }
    }
    
    func handleSwitchComment(commentId: String) {
        guard let index = commentSections[commentId, nil],
              let current = commentSections[CommentIndex(index.section)] else {
            DocsLogger.error("switch comment commentId:\(commentId) not found", component: LogComponents.comment)
            return
        }
        if let (comment, _) = commentSections.activeComment {
            deactivate(comment: comment)
        }
        activate(comment: current)

        // 草稿
        udpateTextDraft()
        scheduler?.reduce(state: .foucus(indexPath: index, position: .top, highlight: false))
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
    
}
