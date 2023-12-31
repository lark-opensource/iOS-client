//
//  CommentDriveInteractionPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/10.
//


import UIKit
import SKFoundation
import SKUIKit
import SpaceInterface

final class CommentDriveInteractionPlugin: CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "InteractionPlugin"
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .interaction(uiAction):
            handleUIAction(action: uiAction)
        default:
            break
        }
    }
    
    func handleUIAction(action: CommentAction.UI) {
        switch action {

        case let .edit(item):
            handleEdit(item)

        case let .reply(item):
            handleReply(item)

        case .hideComment:
            scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
            // drive评论比较特殊，就算是外面触发的，也要手动调用closeComment让外面
            // 知道面板关掉了重新设置图片预览的高度
            scheduler?.dispatch(action: .api(.closeComment, nil))

        case .tapBlank:
            handleTapBlank()
            
        case .clickClose:
            handleClickClose()

        case let .willDisplayUnread(item):
            scheduler?.dispatch(action: .api(.readMessage(item), nil))


        case let .clickRetry(item):
            handleClickRetry(item)

        case let .didMention(atInfo):
            scheduler?.dispatch(action: .api(.didMention(atInfo), nil))
            
        case let .switchCard(commentId, height):
            scheduler?.dispatch(action: .api(.switchCard(commentId: commentId, height: height), nil))
            
        case .viewWillTransition:
            handleClickClose()
            
        case let .panelHeightUpdate(height):
            scheduler?.dispatch(action: .api(.panelHeightUpdate(height: height), nil))
        default:
            break
        }
    }
    
    var scheduler: CommentSchedulerType? {
        return context?.scheduler
    }
}

extension CommentDriveInteractionPlugin {
    
    func handleClickClose() {
        scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
        scheduler?.dispatch(action: .api(.closeComment, nil))
        scheduler?.reduce(state: .dismiss)
    }

    private func handleClickRetry(_ item: CommentItem) {
        let error = item.enumError
        if error == .violateTOS1 || error == .violateTOS1 {
            // TODO: - hyf 待测试
            handleEdit(item)
        } else if error == .loadImageError {
            DocsLogger.info("reload image replyId:\(item.replyID)", component: LogComponents.comment)
            // TODO: - hyf 待测试
            item.errorCode = 0
            scheduler?.dispatch(action: .ipc(.refresh(commentId: item.commentId ?? "", replyId: item.replyID), nil))
            // TODO: - hyf 埋点
//                let isActive = currentComment?.commentID == commentItem.commentId
//                CommentTracker.retryLoadImage(docsInfo: commentData.docsInfo, isActive: isActive, commentId: commentItem.commentId ?? "")
        } else { // 其他失败
            scheduler?.dispatch(action: .api(.retry(item), nil))
        }
    }

    private func handleTapBlank() {
        guard let mode = context?.scheduler?.fastState.mode else {
            return
        }
        switch mode {
        case .browseMode:
            handleClickClose()
            
        case .newInput:
            break
        case .reply, .edit:
            self.scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .browseMode), nil))
        }
    }

    private func handleEdit(_ item: CommentItem) {
        guard item.canComment else {
            DocsLogger.error("handle reply error, permission denied", component: LogComponents.comment)
            return
        }

        item.viewStatus = .edit(isFirstResponser: true)
        // 设置草稿
        scheduler?.dispatch(action: .ipc(.setEditDraft(item), nil))
        
        scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .edit(item)), nil))
    }
    
    private func handleReply(_ item: CommentItem) {
        guard item.canComment else {
            DocsLogger.error("handle reply error, permission denied", component: LogComponents.comment)
            return
        }
        guard let name = item.name else {
            DocsLogger.error("handleReply commentId is nil", component: LogComponents.comment)
            return
        }
        
        item.viewStatus = .reply(isFirstResponser: true)
        
        // 设置草稿
        let atInfo = AtInfo(type: .user, href: "", token: item.userID, at: name)
        scheduler?.dispatch(action: .ipc(.setReplyDraft(item, atInfo), nil))
        
        scheduler?.dispatch(action: .ipc(.setDriveCommentMode(mode: .reply(item)), nil))
    }
}
