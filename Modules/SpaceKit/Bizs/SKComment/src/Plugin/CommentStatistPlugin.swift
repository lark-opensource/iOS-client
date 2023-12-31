//
//  CommentStatistPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/25.
//  


import UIKit
import SKFoundation
import SpaceInterface

class CommentStatistPlugin: CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "StatistPlugin"

    var identifier: String {
        return Self.identifier
    }

    private var sendResultReporter: CommentSendResultReporterType? {
        context?.businessDependency?.businessConfig.sendResultReporter
    }

    func apply(context: CommentServiceContext) {
        self.context = context
    }

    func mutate(action: CommentAction) {
        switch action {
        case let .interaction(action):
            handleUIAction(action: action)
        case let .tea(event):
            handleTeaEvent(event)
        case let .updateData(commentData):
            sendResultReporter?.markEventEndBy(commentData: commentData)
        case let .addNewCommentFinished(uuid, isSuccess, errorCode):
            let result: CommentBusinessConfig.SendResult = isSuccess ? .success : .failure(reason: errorCode ?? "")
            sendResultReporter?.markEventEndBy(uuid: uuid, result: result)
        default:
            break
        }
    }

    /// 监听UI事件的时候就可以直接报
    func handleUIAction(action: CommentAction.UI) {
        switch action {
        case let .reply(item):
            handleReplyComment(item)
        case let .edit(item):
            handleEditComment(item)
        default:
            break
        }
    }
    
    
    //swiftlint:disable cyclomatic_complexity
    /// 其他plugin处理后上报
    func handleTeaEvent(_ event: CommentAction.Tea) {
        guard let context = context,
              let docsInfo = context.docsInfo,
              let fastState = context.scheduler?.fastState else {
            DocsLogger.error("[Statist] basic info is missing", component: LogComponents.comment)
            return
        }
        
        switch event {
        case let .cancelTranslateClick(item):
            CommentTracker.commentReport(action: .cancel_translate_click,
                                         docsInfo: docsInfo,
                                         cardId: item.commentId  ?? "",
                                         id: item.replyID,
                                         isFullComment: false,
                                         extra: [:])
        case let .showOriginalClick(item):
            CommentTracker.commentReport(action: .show_original_click,
                                         docsInfo: docsInfo,
                                         cardId: item.commentId  ?? "",
                                         id: item.replyID,
                                         isFullComment: false,
                                         extra: [:])
        case .cancelClick:
            let isWhole = context.scheduler?.fastState.mode?.isWhole ?? false
            CommentTracker.commentReport(action: .cancel_click, docsInfo: docsInfo, cardId: nil, id: nil, isFullComment: isWhole, extra: [:])
        
        case let .addComment(comment, isFirst): // 只有Drive评论需要
            handleAddComment(comment, isFirst)

        case let .reactionComment(item, isNew, key): // drive/局部评论
            var action: ClientCommentAction = .reaction_comment
            if !isNew { // 取消
                action = .cancel_reaction_comment
            }
            let isPart = isPartComment(item.commentId)
            CommentTracker.commentReport(action: action,
                                         docsInfo: docsInfo,
                                         cardId: item.commentId ?? "",
                                         id: item.replyID,
                                         isFullComment: !isPart,
                                         extra: ["emoji": "\(key)"])

        case let .finishClick(commentId, isSame): // 只有Drive评论需要
            guard context.pattern == .drive else { return }
            let isPart = fastState.localCommentIds.contains(commentId)
            CommentTracker.commentReport(action: .finish_click,
                                         docsInfo: docsInfo,
                                         cardId: commentId,
                                         id: nil,
                                         isFullComment: !isPart,
                                         extra: ["status": isSame ? "active" : "none"])

        case let .editConfirm(item): // drive 发送编辑请求前
            guard context.pattern == .drive else { return }
            let commentId = item.commentId ?? ""
            let isPart = fastState.localCommentIds.contains(commentId)
            CommentTracker.commentReport(action: .edit_confirm,
                                         docsInfo: docsInfo,
                                         cardId: commentId,
                                         id: item.replyID,
                                         isFullComment: !isPart,
                                         extra: [:])

        case let .deleteClick(item): // drive点击确认删除时上报
            guard context.pattern == .drive else { return }
            let commentId = item.commentId ?? ""
            let isPart = isPartComment(commentId)
            CommentTracker.commentReport(action: .delete_click,
                                         docsInfo: docsInfo,
                                         cardId: commentId,
                                         id: item.replyID,
                                         isFullComment: !isPart,
                                         extra: ["app_form": "none"])

        case .beginEdit: // 点击定位到评论输入框时触发上报
            handleEdit()
            
        case let .translateClick(item): // 点击"翻译"时上报
            let isPart = isPartComment(item.commentId)
            var extra: [String: Any] = [:]
            extra["before_language"] = item.contentSourceLanguage
            extra["after_language"] = item.targetLanguage
            extra["user_main_lang"] = item.userMainLanguage
            extra["user_default_lang"] = item.defaultTargetLanguage
            extra["menu_level"] = "first"
            CommentTracker.commentReport(action: .translate_click,
                                         docsInfo: docsInfo,
                                         cardId: item.commentId ?? "",
                                         id: item.replyID,
                                         isFullComment: !isPart,
                                         extra: extra)
        case let .reactionCommentPanel(item): // 展开评论reaction面板
            let isPart = isPartComment(item.commentId)
            CommentTracker.commentReport(action: .reaction_comment_panel,
                                         docsInfo: docsInfo,
                                         cardId: item.commentId ?? "",
                                         id: item.replyID,
                                         isFullComment: !isPart)
        case let .copyAnchorLink(comment):
            if comment.interactionType == .reaction {
                CommentTracker.commentReactionClick(click: .copyLink, cardId: comment.commentID, docsInfo: docsInfo)
            } else {
                CommentTracker.commentReport(action: .copy_link,
                                             docsInfo: docsInfo,
                                             cardId: comment.commentID,
                                             id: comment.commentID,
                                             isFullComment: false)
            }
            CommentTracker.commentCopyLinkSuccess(cardType: comment.interactionType == .reaction ? .reaction : .partComment,
                                                  docsInfo: docsInfo)
        case let .shareAnchorLink(comment):
            if comment.interactionType == .reaction {
                CommentTracker.commentReactionClick(click: .sendLark, cardId: comment.commentID, docsInfo: docsInfo)
            } else {
                CommentTracker.commentReport(action: .send_to_chat,
                                             docsInfo: docsInfo,
                                             cardId: comment.commentID,
                                             id: comment.commentID,
                                             isFullComment: false)
            }
            CommentTracker.commentShareLinkToLark(cardType: comment.interactionType == .reaction ? .reaction : .partComment,
                                                  docsInfo: docsInfo)
        case let .fpsPerformance(params):
            CommentTracker.fpsRecord(params: params, docsInfo: docsInfo)
        case let .renderPerformance(params):
            CommentTracker.renderRecord(params: params, docsInfo: docsInfo)
        case let .editPerformance(params):
            CommentTracker.editRecord(params: params, docsInfo: docsInfo)
        case let .reportCreateCommentSend(uuid):
            sendResultReporter?.markEventStart(uuid: uuid, scene: .add)
        case let .reportReplyCommentSend(uuid):
            sendResultReporter?.markEventStart(uuid: uuid, scene: .reply)
        case let .reportEditCommentSend(uuid):
            sendResultReporter?.markEventStart(uuid: uuid, scene: .edit)
        }
    }
    
    func isPartComment(_ commentId: String?) -> Bool {
        guard let context = context,
              let fastState = context.scheduler?.fastState else {
            DocsLogger.error("[Statist] basic info is missing", component: LogComponents.comment)
            return false
        }
        var isPart = true
        if context.pattern == .drive, let id = commentId {
            return fastState.localCommentIds.contains(id)
        }
        if let mode = fastState.mode {
            switch mode {
            case let .newInput(model):
                if model.isWhole {
                    isPart = false
                }
            default:
                break
            }
        }
        return isPart
    }
    
    func handleEdit() {
        guard let context = context,
              let docsInfo = context.docsInfo,
              let fastState = context.scheduler?.fastState else {
            DocsLogger.error("[Statist] basic info is missing", component: LogComponents.comment)
            return
        }
        if context.pattern == .aside,
           let activeComment = fastState.activeComment {
            var replyId = ""
            for item in activeComment.commentList where item.viewStatus.isEdit {
                replyId = item.replyID
                break
            }
            if replyId.isEmpty {
                let count = activeComment.commentList.count
                replyId = activeComment.commentList.safe(index: count - 2)?.replyID ?? ""
            }
            CommentTracker.commentReport(action: .begin_edit,
                                         docsInfo: docsInfo,
                                         cardId: activeComment.commentID,
                                         id: replyId,
                                         isFullComment: false)
        } else {
            let activeComment = fastState.activeComment
            var commentId = activeComment?.commentID ?? ""
            let count = activeComment?.commentList.count ?? 0
            var replyId = ""
            if let mode = fastState.mode {
                switch mode {
                case let .newInput(model):
                    commentId = model.commentID ?? ""
                    if model.type == .edit {
                        replyId = model.replyID ?? ""
                    }
                case let .reply(item):
                    replyId = item.replyID
                case let .edit(item):
                    replyId = item.replyID
                default:
                    break
                }
            }
            if replyId.isEmpty, count > 0 {
                replyId = activeComment?.commentList.safe(index: count - 1)?.replyID ?? ""
            }
            let isPart = isPartComment(commentId)
            CommentTracker.commentReport(action: .begin_edit,
                                         docsInfo: docsInfo,
                                         cardId: commentId,
                                         id: replyId,
                                         isFullComment: !isPart)
        }
    }
    
    func handleAddComment(_ comment: Comment, _ isFirst: Bool) {
        guard let context = context,
              let docsInfo = context.docsInfo else {
            DocsLogger.error("[Statist] basic info is missing", component: LogComponents.comment)
            return
        }
        guard context.pattern == .drive else { return }
        let isPart = isPartComment(comment.commentID)
        var extra: [String: Any] = ["is_part_image_flag": "\(isPart)",
                                    "is_content_image_flag": "false"]
        if isFirst {
            extra["is_first_flag"] = "true"
        } else {
            extra["is_first_flag"] = "false"
        }
        if comment.commentList.last?.imageList.isEmpty == false {
            extra["is_content_image_flag"] = "true"
        }
        CommentTracker.commentReport(action: .add_comment,
                                     docsInfo: docsInfo,
                                     cardId: comment.commentID,
                                     id: comment.commentList.last?.replyID,
                                     isFullComment: !isPart,
                                     extra: extra)
    }
}

extension CardCommentMode {
    var isWhole: Bool {
        switch self {
        case let .newInput(model):
            return model.isWhole
        default:
            return false
        }
    }
    
    var editItem: CommentItem? {
        switch self {
        case let .edit(item):
            return item
        default:
            return nil
        }
    }
    
    var replyItem: CommentItem? {
        switch self {
        case let .reply(item):
            return item
        default:
            return nil
        }
    }
}

extension CommentStatistPlugin {
    
    func handleReplyComment(_ item: CommentItem) {
        guard let docsInfo = context?.docsInfo else {
            DocsLogger.error("[Statist] reply docsInfo is nil", component: LogComponents.comment)
            return
        }
        CommentTracker.commentReport(action: .addition_click,
                                     docsInfo: docsInfo,
                                     cardId: item.commentId  ?? "",
                                     id: nil,
                                     isFullComment: false,
                                     extra: [:])
        handleEdit()
    }
    
    func handleEditComment(_ item: CommentItem) {
        guard let docsInfo = context?.docsInfo else {
            DocsLogger.error("[Statist] edit docsInfo is nil", component: LogComponents.comment)
            return
        }
        CommentTracker.commentReport(action: .edit_click,
                                     docsInfo: docsInfo,
                                     cardId: item.commentId  ?? "",
                                     id: item.replyID,
                                     isFullComment: false,
                                     extra: [:])
        handleEdit()
    }
}
