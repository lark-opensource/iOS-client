//
//  CommentRNAPIAdaper.swift
//  SKBrowser
//
//  Created by huayufan on 2022/10/14.
//  
// 因为小程序需要，暂时放在SKCommon

import UIKit
import SKFoundation
import SKResource
import SpaceInterface

public protocol CommentRNAPIAdaperDependency: AnyObject {
    
    var docInfo: DocsInfo? { get }
    
    func showError(msg: String)
    
    /// 转换的逻辑转移到接入方处理！
    func transformer(rnComment: RNCommentData) -> CommentData
}

public extension CommentRNAPIAdaperDependency {
    func transformer(rnComment: RNCommentData) -> CommentData {
        return CommentData(comments: [],
                           currentPage: nil,
                           style: .normal,
                           docsInfo: nil,
                           commentType: .card,
                           commentPermission: [])
    }
}

public typealias CommentRNResponseCallback = (CommentData) -> Void

public protocol CommentRNAPIAdaperType: CommentAPIAdaper {
    func fetchComment(response: @escaping CommentRNResponseCallback)
}


public final class CommentRNAPIAdaper {
    
    weak var dependency: CommentRNAPIAdaperDependency?

    /// 评论/reaction请求
    weak var rnRequest: CommentRNRequestType?
    
    /// 部分接口还是需要回调给前端
    weak var commentService: CommentServiceType?
    
    public var apiType: CommentAPIAdaperType { .rn }
    
    public init(rnRequest: CommentRNRequestType,
         commentService: CommentServiceType,
         dependency: CommentRNAPIAdaperDependency) {
        self.rnRequest = rnRequest
        self.commentService = commentService
        self.dependency = dependency
    }
    
    typealias CommentCallback = RNCommentDataManager.ResponseCallback
    
    func sendComment(bodyData: [String: Any], operationKey: String, response: @escaping CommentCallback) {
        guard let commentManager = rnRequest?.commentManager else {
            DocsLogger.error("sendComment commentManager is nil", component: LogComponents.comment)
            return
        }
        var params = bodyData
        params["options"] = "{}"
        // resolve、 delete、 publish、 edit、 translate需要在callback返回时
        // 调用requestNativeService.callAction告诉前端
        commentManager.sendComment(bodyData: bodyData, operationKey: operationKey, response: response)
    }
    
    func sendReaction(bodyData: [String: Any], operation: CommonSendOperation) {
        guard let commonManager = rnRequest?.commonManager else {
            DocsLogger.error("sendReaction commonManager is nil", component: LogComponents.comment)
            return
        }
        commonManager.sendToRN(bodyData: bodyData, operationKey: operation.rawValue)
    }
    
    func callFunction(_ action: CommentEventListenerAction, _ params: [String: Any]?) {
        guard let commentService = commentService else {
            DocsLogger.error("commentService is nil request action:\(action) fail", component: LogComponents.comment)
            return
        }
        commentService.callFunction(for: action, params: params)
    }
    
    func handelPublishResult(rnCommentData: RNCommentData) {
        rnRequest?.callAction(.publish, rnCommentData.rawData)
        guard let code = rnCommentData.code,
              code == DocsNetworkError.Code.reportError.rawValue || code == DocsNetworkError.Code.auditError.rawValue else {
            return
        }
        guard let docType = dependency?.docInfo?.type else {
            DocsLogger.error("publish dataSouce docsInfo is nil", component: LogComponents.comment)
            return
        }
        if docType != .doc && docType != .wiki {
            dependency?.showError(msg: BundleI18n.SKResource.Doc_Review_Fail_Notify_Member())
        }
    }
    
    func handelDeleteResult(rnCommentData: RNCommentData) {
        rnRequest?.callAction(.delete, rnCommentData.rawData)
    }
    
    func handelEditResult(rnCommentData: RNCommentData) {
        rnRequest?.callAction(.edit, rnCommentData.rawData)
    }
    
    func handelTranslateResult(rnCommentData: RNCommentData) {
        rnRequest?.callAction(.translate, rnCommentData.rawData)
    }
    
    func handelResolveResult(rnCommentData: RNCommentData, activeCommentId: String) {
        var rawData = rnCommentData.rawData ?? [:]
        if var dataStr = rawData["data"] as? String,
           var dict = convertToDictionary(text: dataStr) {
            dict["currentActiveCommentId"] = activeCommentId
            if let responseDataStr = self.convertDictionaryToString(dict: dict) {
                rawData["data"] = responseDataStr
            }
        }
        rnRequest?.callAction(.resolve, rawData)
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return [:]
    }
    
    func convertDictionaryToString(dict: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dict) else {
            spaceAssertionFailure("JSONSerialization, not Valid data")
            return nil
        }
        guard let responseData = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let responseDataStr = String(data: responseData, encoding: String.Encoding.utf8) else {
            spaceAssertionFailure()
            return nil
        }
        return responseDataStr
    }
    
    
}
    
extension CommentRNAPIAdaper: CommentRNAPIAdaperType {
    /// 拉取评论的能力
    public func fetchComment(response: @escaping CommentRNResponseCallback) {
        rnRequest?.commentManager?.fetchComment { [weak self] rnData in
            guard let self = self else { return }
            guard let dependency = self.dependency else {
                DocsLogger.error("dependency can not be nil", component: LogComponents.comment)
                return
            }
            
            let commentData = dependency.transformer(rnComment: rnData)
            response(commentData)
        }
    }

    // 不需要callback
    public func addComment(_ content: CommentAPIContent) {
        let res = content.parsing([.content,
                                   .comment_id,
                                   .rnIsWhole,
                                   .quote,
                                   .rnParentType,
                                   .rnParentToken,
                                   .localCommentId,
                                   .type,
                                   .rnReplyId,
                                   .bizParams,
                                   .position,
                                   .extra])
        sendComment(bodyData: res, operationKey: CommentSendOperation.publish, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelPublishResult(rnCommentData: rnCommentData)
            content.resonse?(rnCommentData)
        })
    }
    
    
    public func retryAddNewComment(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    // 不需要callback
    public func addReply(_ content: CommentAPIContent) {
        let res = content.parsing([.content,
                                   .comment_id,
                                   .rnIsWhole,
                                   .quote,
                                   .rnParentType,
                                   .rnParentToken,
                                   .localCommentId,
                                   .type,
                                   .rnReplyId,
                                   .bizParams,
                                   .position,
                                   .extra])
        sendComment(bodyData: res, operationKey: CommentSendOperation.publish, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelPublishResult(rnCommentData: rnCommentData)
            content.resonse?(rnCommentData)
        })
    }
    
    // 不需要callback
    public func updateReply(_ content: CommentAPIContent) {
        let res = content.parsing([.content,
                                   .comment_id,
                                   .rnReplyId,
                                   .bizParams,
                                   .extra])
        sendComment(bodyData: res, operationKey: CommentSendOperation.edit, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelEditResult(rnCommentData: rnCommentData)
            content.resonse?(rnCommentData)
        })
    }
    
    public func deleteReply(_ content: CommentAPIContent) {
        let res = content.parsing([.comment_id,
                                   .rnReplyId])
        sendComment(bodyData: res, operationKey: CommentSendOperation.delete, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelDeleteResult(rnCommentData: rnCommentData)
            content.resonse?(rnCommentData)
        })
    }
    
    public func resolveComment(_ content: CommentAPIContent) {
        let res = content.parsing([.comment_id,
                                   .finish])
        let activeCommentId: String? = content[.activeCommentId]
        sendComment(bodyData: res, operationKey: CommentSendOperation.update, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelResolveResult(rnCommentData: rnCommentData,
                                      activeCommentId: activeCommentId ?? "")
            content.resonse?(rnCommentData)
        })
    }
    
    public func retry(_ content: CommentAPIContent) {
        let res = content.parsing([.content,
                                   .comment_id,
                                   .rnIsWhole,
                                   .quote,
                                   .rnParentType,
                                   .rnParentToken,
                                   .localCommentId,
                                   .type,
                                   .rnReplyId,
                                   .bizParams,
                                   .position,
                                   .extra])
        sendComment(bodyData: res, operationKey: CommentSendOperation.publish, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelPublishResult(rnCommentData: rnCommentData)
            content.resonse?(rnCommentData)
        })
    }
    
    public func translate(_ content: CommentAPIContent) {
        let res = content.parsing([.comment_id,
                                   .rnReplyId])
        sendComment(bodyData: res, operationKey: CommentSendOperation.translate, response: {  [weak self] rnCommentData in
            guard let self = self else { return }
            self.handelTranslateResult(rnCommentData: rnCommentData)
            content.resonse?(rnCommentData)
        })
    }
    
    public func addReaction(_ content: CommentAPIContent) {
        let res = content.parsing([.reactionKey,
                                   .replyId])
        sendReaction(bodyData: res, operation: .addReaction)
    }
    
    public func removeReaction(_ content: CommentAPIContent) {
        let res = content.parsing([.reactionKey,
                                   .replyId])
        sendReaction(bodyData: res, operation: .removeReaction)
    }
    
    public func getReactionDetail(_ content: CommentAPIContent) {
        let res = content.parsing([.referType,
                                   .referKey])
        sendReaction(bodyData: res, operation: .getReactionDetail)
        
    }
    
    public func setDetailPanel(_ content: CommentAPIContent) {
        let res = content.parsing([.referType,
                                   .referKey,
                                   .status])
        sendReaction(bodyData: res, operation: .setReactionDetailPanelStatus)
    }
    
    public func readMessage(_ content: CommentAPIContent) {
        let res = content.parsing([.msgIds])
        callFunction(.readMessage, res)
    }
    
    public func readMessageByCommentId(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func scrollComment(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func activeCommentInvisible(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func addContentReaction(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func removeContentReaction(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func getContentReactionDetail(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func close(_ content: CommentAPIContent) {
        let res = content.parsing([.type])
        callFunction(.cancel, res)
    }
    
    public func cancelActive(_ content: CommentAPIContent) {
        let res = content.parsing([.type])
        callFunction(.cancel, res)
    }
    
    public func switchCard(_ content: CommentAPIContent) {
        let res = content.parsing([.comment_id, .from, .height, .page])
        callFunction(.switchCard, res)
    }
    
    public func panelHeightUpdate(_ content: CommentAPIContent) {
        let res = content.parsing([.height])
        callFunction(.panelHeightUpdate, res)
    }
    
    public func onMention(_ content: CommentAPIContent) {
        let res = content.parsing([.id, .avatarUrl, .name, .cnName, .enName, .unionId, .department])
        callFunction(.onMention, res)
    }
    
    public func activateImageChange(_ content: CommentAPIContent) {
        let res = content.parsing([.commentId, .replyId, .index])
        callFunction(.activateImageChange, res)
    }
    
    public func anchorLinkSwitch(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
    
    public func clickQuoteMenu(_ content: CommentAPIContent) {
        // Drive和小程序无该功能，不需要处理
    }
}
