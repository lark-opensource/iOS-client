//
//  CommentAPIPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/5.
//  
//  swiftlint:disable cyclomatic_complexity

import UIKit
import SKResource
import SKFoundation
import SpaceInterface
import SKCommon
/// 负责构造前端/RN需要的数据
class CommentAPIPlugin: CommentPluginType {
    
    weak var context: CommentServiceContext?

    static let identifier = "APIPlugin"
    
    lazy var needRequestUids = Set<String>()
    
    lazy var atUserRequestDebounce = DebounceProcesser()
    
    private var api: CommentAPIAdaper?
    
    /// 新接口
    init(api: CommentAPIAdaper?) {
        self.api = api
    }
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .api(action, callback):
            handleAPI(action, callback)
        case let .retryAddNewComment(commentId):
            handleRetryAddNewComment(commentId)

        default:
            break
        }
    }
    
    
    struct PluginContext: CommentAdaptContext {
        var currentCommentID: String
        var currentComment: Comment?
        var currentCommentType: CommentData.CommentType
        var currentEditingCommentItem: CommentItem?
        var atInputTextType: AtInputTextType
        var atInputFocusType: AtInputFocusType
        var commentViewHeight: CGFloat?
        var from: CommentFrom
        func showSuccess(_ text: String) {}
        func showFailed(_ text: String) {}
    }
    
    func handleRetryAddNewComment( _ commentId: String) {
        api?.retryAddNewComment(CommentAPIContent([.commentId: commentId]))
        let uuid = commentId
        context?.scheduler?.dispatch(action: .tea(.reportCreateCommentSend(uuid: uuid)))
    }
    
    func handleAPI(_ action: CommentAction.API, _ callback: CommentAction.API.Callback?) {
        switch action {

        case let .addComment(content, wrapper):
            handleAddComment(content, wrapper)

        case let .editComment(content, wrapper):
            handleEditComment(content, wrapper)

        case .cancelGloablNewInput:
            api?.cancelActive(.init([.type: CancelType.globalComment.rawValue]))

        case .cancelPartialNewInput:
            handleCancelPartialNewInput()
    
        case .closeComment:
            api?.close(CommentAPIContent([.type: CancelType.close.rawValue]))
    
        case let .inviteUserRequest(atInfo, sendLark):
            handelInviteUserRequest(atInfo, sendLark)
    
        case let .switchCard(commentId, height):
            // TODO: - hyf from 前端还需要吗
            var content = CommentAPIContent([.comment_id: commentId,
                                             .from: "web",
                                             .height: height])
            addRNExtraSwitchCardParams(sendContent: &content, commentId: commentId)
            api?.switchCard(content)
            api?.panelHeightUpdate(.init([.height: height]))
            DocsLogger.info("panelHeightUpdate:\(height)", component: LogComponents.comment)
        case let .panelHeightUpdate(height):
            api?.panelHeightUpdate(.init([.height: height]))
            DocsLogger.info("panelHeightUpdate:\(height)", component: LogComponents.comment)

        case let .retry(item):
            guard let commentId = item.commentId else {
                DocsLogger.error("retry item:\(item.replyID) commentId is nil", component: LogComponents.comment)
                return
            }
            var sendContent = CommentAPIContent([.commentId: commentId, .replyId: item.replyID])
            
            addRNExtraRetryCommentParams(sendContent: &sendContent, item: item)

            api?.retry(sendContent)

            if let retryType = item.retryType {
                let event: CommentAction.Tea?
                switch retryType {
                case .add:
                    event = .reportCreateCommentSend(uuid: item.commentId ?? "")
                case .reply:
                    event = .reportReplyCommentSend(uuid: item.replyUUID)
                case .update:
                    event = .reportEditCommentSend(uuid: item.replyUUID)
                case .delete:
                    event = nil
                }
                if let event = event {
                    context?.scheduler?.dispatch(action: .tea(event))
                }
            }
        case let .delete(item):
            guard let commentId = item.commentId else {
                DocsLogger.error("delete item:\(item.replyID) commentId is nil", component: LogComponents.comment)
                return
            }
            var sendContent = CommentAPIContent([.commentId: commentId,
                                                 .replyId: item.replyID])
            addRNExtraDeleteCommentParams(sendContent: &sendContent, item: item)
            api?.deleteReply(sendContent)
            context?.scheduler?.dispatch(action: .tea(.deleteClick(item)))
    
        case let .readMessage(item):
            handleReadMessage(item)

        case let .contentBecomeInvisibale(info):
            api?.activeCommentInvisible(.init([.curCommentId: info.commentId]))
            
        case let .magicShareScroll(info):
            api?.scrollComment(.init([.curCommentId: info.commentId,
                                     .replyId: info.replyId,
                                     .replyPercentage: info.replyPercentage]))

        case let .requestAtUserPermission(uid):
            handleRequestAtUserPermission(uid, callback)
            
        case let .didMention(atInfo):
            handleMention(atInfo)

        case let .resolveComment(commentId, activeCommentId):
            var sendContent = CommentAPIContent([.commentId: commentId, .activeCommentId: activeCommentId])
            addRNExtraResolveCommentParams(sendContent: &sendContent,
                                           commentId: commentId,
                                           activeCommentId: activeCommentId)
            api?.resolveComment(sendContent)
            let isSame = commentId == activeCommentId
            context?.scheduler?.dispatch(action: .tea(.finishClick(commentId: commentId, isSame: isSame)))
            
        case let .addReaction(reactionKey, item):
            api?.addReaction(.init([.reactionKey: reactionKey,
                                     .replyId: item.replyID]))
            context?.scheduler?.dispatch(action: .tea(.reactionComment(item, isNew: true, key: reactionKey)))
            
        case let .removeReaction(reactionKey, item):
            api?.removeReaction(.init([.reactionKey: reactionKey,
                                       .replyId: item.replyID]))
            context?.scheduler?.dispatch(action: .tea(.reactionComment(item, isNew: false, key: reactionKey)))
            
        case let .addContentReaction(reactionKey, item):
            api?.addContentReaction(.init([.reactionKey: reactionKey,
                                           .commentId: item.commentId ?? ""]))
            context?.scheduler?.dispatch(action: .tea(.reactionComment(item, isNew: true, key: reactionKey)))
            
        case let .removeContentReaction(reactionKey, item):
            api?.removeContentReaction(.init([.reactionKey: reactionKey,
                                              .commentId: item.commentId ?? ""]))
            context?.scheduler?.dispatch(action: .tea(.reactionComment(item, isNew: false, key: reactionKey)))

        case let .setDetailPanel(reaction, show):
            // RN需要
            api?.setDetailPanel(.init([.referType: reaction.referKey ?? "",
                                       .referKey: reaction.referKey ?? "",
                                       .status: show ? 1 : 0]))
            
        case let .getReactionDetail(item, reaction):
            var sendContent = CommentAPIContent([.replyId: item.replyID])
            addRNExtraGetReactionDetail(sendContent: &sendContent, reaction: reaction)
            api?.getReactionDetail(sendContent)
            
        case let .getContentReactionDetail(item):
            api?.getContentReactionDetail(.init([.commentId: item.commentId ?? ""]))
            
        case let .translate(item):
            var sendContent = CommentAPIContent([.commentId: item.commentId ?? "",
                                                 .replyId: item.replyID,
                                                 .targetLanguage: item.targetLanguage ?? ""])
            addRNExtraTranslateCommentParams(sendContent: &sendContent, item: item)
            api?.translate(sendContent)
            
        case let .activateImageChange(item, index):
            api?.activateImageChange(.init([.commentId: item.commentId ?? "",
                                     .replyId: item.replyID,
                                     .index: index]))
        case let .anchorLinkSwitch(commentId):
            api?.anchorLinkSwitch(.init([.commentId: commentId]))
            
        case let .copyAnchorLink(comment):
            let sendContent = CommentAPIContent([.commentId: comment.commentID,
                                                 .menuId: "COPY_LINK"])
            api?.clickQuoteMenu(sendContent)
            
        case let .shareAnchorLink(comment):
            let sendContent = CommentAPIContent([.commentId: comment.commentID,
                                                 .menuId: "SEND_IM"])
            api?.clickQuoteMenu(sendContent)
        }
    }
    
}

extension CommentAPIPlugin {
    
    func handleAddComment(_ content: CommentContent, _ wrapper: CommentWrapper) {
        var sendContent = CommentAPIContent([.commentId: wrapper.comment.commentID,
                                         .imageList: content.imagesParams(update: false),
                                         .content: content.content,
                                             .isWhole: wrapper.comment.isWhole])
        addRNExtraAddAndRetryCommentParams(sendContent: &sendContent, content, wrapper)
        // TEA
        if api?.apiType == .rn {
            sendContent.set { [weak self] data in
                guard let self = self,
                      let rnCommentData = data as? RNCommentData,
                      let comment = rnCommentData.comments.last else {
                    return
                }
                let isFirst = comment.commentList.count == 1
                self.context?.scheduler?.dispatch(action: .tea(.addComment(comment, isFirst: isFirst)))
            }
        }
        
        if wrapper.comment.isNewInput {
            api?.addComment(sendContent)
            let uuid = wrapper.comment.commentID
            if wrapper.comment.isWhole == false { // 排除全文评论,全文评论由前端上报,全文评论的`新增`和`回复`都算是`新增`
                context?.scheduler?.dispatch(action: .tea(.reportCreateCommentSend(uuid: uuid)))
            }
        } else {
            let replyUUID = UUID().uuidString.lowercased()
            sendContent.update(params: [.replyUUID: replyUUID])
            api?.addReply(sendContent)
            context?.scheduler?.dispatch(action: .tea(.reportReplyCommentSend(uuid: replyUUID)))
        }
    }
    
    func handleEditComment(_ content: CommentContent, _ wrapper: CommentWrapper) {
        var sendContent = CommentAPIContent([.commentId: wrapper.comment.commentID,
                                             .replyId: wrapper.commentItem.replyID,
                                             .imageList: content.imagesParams(update: true),
                                             .content: content.content])
        let replyUUID = wrapper.commentItem.replyUUID // 复用已有的uuid,不重新创建
        sendContent.update(params: [.replyUUID: replyUUID])
        addRNExtraEditCommentParams(sendContent: &sendContent, content, wrapper)
        api?.updateReply(sendContent)
        if wrapper.comment.isWhole == false { // 排除全文评论,全文评论由前端上报
            context?.scheduler?.dispatch(action: .tea(.reportEditCommentSend(uuid: replyUUID)))
        }
    }
    
    func handleMention(_ atInfo: AtInfo) {
        let content = CommentAPIContent([.id: atInfo.id ?? "",
                      .avatarUrl: atInfo.avatarUrl ?? "",
                      .name: atInfo.name ?? "",
                      .cnName: atInfo.cnName ?? "",
                      .enName: atInfo.enName ?? "",
                      .unionId: atInfo.unionId ?? "",
                      .department: atInfo.department ?? ""])
        api?.onMention(content)
    }
    

    func handleReadMessage(_ item: CommentItem) {
        switch item.interactionType {
        case .reaction:
            api?.readMessageByCommentId(.init([.commentId: item.commentId ?? ""]))
        case .comment, .none:
            api?.readMessage(.init([.msgIds: [item.messageId]]))
        }
        guard let awesomeManager = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
            DocsLogger.error("awesomeManager not register", component: LogComponents.comment)
            return
        }
        guard let docsInfo = context?.docsInfo else {
            DocsLogger.error("docsInfo is nil", component: LogComponents.comment)
            return
        }
        let params: [String: Any] = [DocsSDK.Keys.readFeedMessageIDs: [item.messageId],
                                     "doc_type": docsInfo.inherentType,
                                     "isFromFeed": true,
                                     "obj_token": docsInfo.token]
        awesomeManager.sendReadMessageIDs(params, in: nil, callback: { _ in })
    }
    
    func handleCancelPartialNewInput() {
        let content = CommentAPIContent([.comment_id: ""])
        api?.switchCard(content)
        api?.cancelActive(.init([.type: CancelType.newInput.rawValue]))
    }
}

// MARK: - InviteUser
extension CommentAPIPlugin {
    private func handelInviteUserRequest(_ atInfo: AtInfo, _ sendLark: Bool) {
        guard let docsInfo = context?.docsInfo else { return }
        let docsKey = AtUserDocsKey(token: docsInfo.objToken, type: docsInfo.type)
        AtPermissionManager.shared.inviteUserRequest(atInfo: atInfo, docsKey: docsKey, sendLark: sendLark) { [weak self] errMsg in
            guard let self = self else { return }
            if let errMsg {
                self.context?.scheduler?.reduce(state: .toast(.failure(errMsg)))
                return
            }
            if let result = AtPermissionManager.shared.hasPermission(atInfo.token, docsKey: docsKey), result == true {
                self.context?.scheduler?.reduce(state: .toast(.success(BundleI18n.SKResource.CreationMobile_mention_sharing_success)))
                self.context?.scheduler?.dispatch(action: .ipc(.inviteUserDone, nil))
                NotificationCenter.default.post(name: Notification.Name.FeatchAtUserPermissionResult, object: nil)
            }
        }
    }
    
    private func handleRequestAtUserPermission(_ uid: Set<String>, _ callback: CommentAction.API.Callback?) {
        guard let docsInfo = context?.docsInfo else { return }
        needRequestUids = needRequestUids.union(uid)
        atUserRequestDebounce.debounce(DispatchQueueConst.MilliSeconds_500) { [weak self] in
            guard let self = self else { return }
            let docsKey = AtUserDocsKey(token: docsInfo.objToken, type: docsInfo.type)
            let requestArray = Array(self.needRequestUids)
            self.needRequestUids.removeAll()
            AtPermissionManager.shared.fetchAtUserPermission(ids: requestArray, docsKey: docsKey, handler: self) { allCache in
                var callbackUids: [String: UserPermissionMask] = [:]
                for requestUid in requestArray {
                    if let result = allCache[requestUid] {
                        callbackUids[requestUid] = result
                    }
                }
                callback?(callbackUids, nil)
                NotificationCenter.default.post(name: Notification.Name.FeatchAtUserPermissionResult, object: nil)
            }
        }
    }
}


// MARK: - RN 接口参数补充
extension CommentAPIPlugin {
    
    func addRNExtraAddAndRetryCommentParams(sendContent: inout CommentAPIContent, _ content: CommentContent, _ wrapper: CommentWrapper) {
        guard api?.apiType == .rn else { return }
        
        sendContent.update(params: [.content: content.content,
                                 .comment_id: wrapper.comment.commentID,
                                 .rnIsWhole: wrapper.comment.isWhole,
                                    .type: wrapper.comment.isNewInput ? 0 : 2, // 0: 新增 2: 回复
                                 .bizParams: wrapper.comment.bizParams ?? [:],
                                 .position: wrapper.comment.position ?? ""])
        
        // 补充图片
        if let infos = content.imageInfos, !infos.isEmpty {
            sendContent.update(key: .extra, value: ["image_list": content.imagesRNParams()])
        }
        
        // 新增评论特有需求
        if wrapper.comment.isNewInput {
            sendContent.update(params: [
                                    .quote: wrapper.comment.quote ?? "",
                                    .rnParentType: wrapper.comment.parentType ?? "",
                                    .rnParentToken: wrapper.comment.parentType ?? "",
                                    .localCommentId: wrapper.comment.commentID])
        }
    }
    
    func addRNExtraEditCommentParams(sendContent: inout CommentAPIContent, _ content: CommentContent, _ wrapper: CommentWrapper) {
        guard api?.apiType == .rn else { return }

        sendContent.update(params: [.comment_id: wrapper.comment.commentID,
                                .rnReplyId: wrapper.commentItem.replyID,
                                .bizParams: wrapper.comment.bizParams ?? [:],
                                .position: wrapper.comment.position ?? ""])
        // 补充图片
        if let infos = content.imageInfos, !infos.isEmpty {
            sendContent.update(key: .extra, value: ["image_list": content.imagesRNParams()])
        }
    }
    
    func addRNExtraRetryCommentParams(sendContent: inout CommentAPIContent, item: CommentItem) {
        guard api?.apiType == .rn else { return }

        if let comment = context?.scheduler?.fastState.activeComment {
            let content = CommentContent(content: item.content ?? "", imageInfos: item.previewImageInfos, pcmData: nil, pcmDataTime: nil, attrContent: nil, isAudio: false)
            addRNExtraAddAndRetryCommentParams(sendContent: &sendContent,
                                               content,
                                               CommentWrapper(commentItem: item,
                                                              comment: comment))
            
        } else {
            DocsLogger.error("retry found comment is nil", component: LogComponents.comment)
        }
    }
    
    func addRNExtraDeleteCommentParams(sendContent: inout CommentAPIContent, item: CommentItem) {
        guard api?.apiType == .rn else { return }

        sendContent.update(params: [.comment_id: item.commentId ?? "",
                                .rnReplyId: item.replyID])
    }
    
    func addRNExtraTranslateCommentParams(sendContent: inout CommentAPIContent, item: CommentItem) {
        guard api?.apiType == .rn else { return }

        sendContent.update(params: [.comment_id: item.commentId ?? "",
                                    .rnReplyId: item.replyID])
    }
    
    func addRNExtraResolveCommentParams(sendContent: inout CommentAPIContent, commentId: String, activeCommentId: String) {
        guard api?.apiType == .rn else { return }

        sendContent.update(params: [.comment_id: commentId,
                                    .activeCommentId: activeCommentId,
                                    .finish: 1])
    }
    
    func addRNExtraSwitchCardParams(sendContent: inout CommentAPIContent, commentId: String) {
        guard api?.apiType == .rn else { return }
        var section: Int?
        let action = CommentAction.ipc(.fetchSnapshoot, { (result, error) in
            guard let snapshoot = result as? CommentSnapshootType else {
                DocsLogger.error("fetch snapshoot, error", error: error, component: LogComponents.comment)
                return
            }
            section = snapshoot.indexPath.section
        })
        context?.scheduler?.dispatch(action: action)
        
        if let sec = section {
            sendContent.update(params: [.page: sec])
        }
    }
    
    func addRNExtraGetReactionDetail(sendContent: inout CommentAPIContent, reaction: CommentReaction) {
        guard api?.apiType == .rn else { return }
        sendContent.update(params: [.referType: reaction.referKey ?? "",
                                    .referKey: reaction.referKey ?? ""])
    }
}
