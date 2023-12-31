//
//  RNCommentDataManager.swift
//  SpaceKit
//
//  Created by zhongtianren on 2019/3/19.
//
// swiftlint:disable file_length

import UIKit
import SwiftyJSON
import RxSwift
import LarkLocalizations
import EENavigator
import SKFoundation
import SpaceInterface
import LarkReactionView

public final class CommentSendOperation {
    public static let fetch = "fetch" //请求全部评论数据
    public static let publish = "publish" //新建/回复评论
    public static let update = "update" //解决/重新打开/修改评论
    public static let delete = "delete" //删除评论
    public static let beginSync = "beginSync" //通知RN开始建立评论长链
    public static let endSync = "endSync" //通知RN结束评论长链
    public static let edit = "edit" //修改评论
    public static let translate = "translate" // 翻译评论
    public static let addTranslateComments = "addTranslateComments" // 添加需要翻译的评论id
    public static let setTranslateEnableLang = "setTranslateEnableLang" // 更新评论翻译配置

    public static let fetchMessage = "fetchMessage" //获取feed数据
    public static let updateMessage = "fetchMessage" //更新feed数据
    public static let resolveMessage = "resolveMessage" //处理消息
    
    public static let setOpenApiSession = "setOpenApiSession" // 注入小程序mina_session给RN
}

public protocol CommentDataDelegate: AnyObject {
    func didReceiveCommentData(response: RNCommentData, eventType: RNCommentDataManager.CommentReceiveOperation)
    func didReceiveUpdateFeedData(response: Any)
}

public final class RNCommentDataManager {
    public enum CommentReceiveOperation: String {
        case sendCommentsData //主动推送评论数据
        case response //RN告知Native请求结果
        case updateMessage //RN推送新Feed消息
    }

    public weak var delegate: CommentDataDelegate?
    let fileToken: String
    var fileType: Int
    var appId: String?
    let extraId: String //长链特别标识，因为ipad上有多webview打开相同文档的情况，所以增加一个extra标识
    public typealias ResponseCallback = (RNCommentData) -> Void
    public typealias FeedCallback = (Any) -> Void
    private var callbackDic = [String: ResponseCallback]() //评论回调
    private var feedCallbackDic = [String: FeedCallback]() //Feed数据回调
    private var serialQueue: OperationQueue

    public var needEndSync: Bool = true

    private let disposeBag = DisposeBag()
    
    /// 现在只有Drive会用到
    enum EnginType: String {
        case doc = "DOC"
        case sheet = "SPREADSHEET"
        case bitable = "BITABLE_TABLE"
        case mindnote = "MINDNOTE"
        case slide = "SLIDE"
        /// 演示文稿的长链
        case json = "JSON"
        case wiki = "WIKI"
        case docX = "DOCX"
        case drive = "BOX"
        
        init(type: Int) {
            let docsType = DocsType(rawValue: type)
            switch docsType {
            case .file:
                self = .drive
            case .doc:
                self = .doc
            case .docX:
                self = .docX
            case .sheet:
                self = .sheet
            case .slides:
                self = .slide
            case .bitable:
                self = .bitable
            case .wiki:
                self = .wiki
            case .mindnote:
                self = .mindnote
            default:
                self = .drive
            }
        }
    }
    
    public init(fileToken: String, type: Int, appId: String? = nil, extraId: String? = nil) {
        self.fileToken = fileToken
        self.fileType = type
        self.extraId = extraId ?? ""
        self.appId = appId
        self.serialQueue = OperationQueue()
        self.serialQueue.name = "RNCommentDataManager.serial.queue"
        self.serialQueue.maxConcurrentOperationCount = 1
        RNManager.manager.registerRnEvent(eventNames: [.comment], handler: self)
    }

    deinit {
        if !needEndSync {
            DocsLogger.info("RNCommentDataManager - deinit return", component: LogComponents.comment)
            return
        }
        endSync()
    }

    public func beginSync(_ extra: [String: Any]? = ["options": "{}"]) {
        DocsLogger.info("RNCommentDataManager - beginSync, file: \(DocsTracker.encrypt(id: fileToken))", component: LogComponents.comment)
        var data: [String: Any] = ["useMessageService": true]
        data["modules"] = ["translate", "sync", "reaction"]
        data["config"] = ["engineType": EnginType(type: self.fileType).rawValue]
        data.merge(other: extra)
        sendToRN(bodyData: data, operationKey: CommentSendOperation.beginSync)
    }

    public func endSync(_ extra: [String: Any]? = ["options": "{}"]) {
        guard !fileToken.isEmpty else {
            return
        }
        DocsLogger.info("RNCommentDataManager - endSync, file: \(DocsTracker.encrypt(id: fileToken))", component: LogComponents.comment)
        sendToRN(bodyData: extra, operationKey: CommentSendOperation.endSync)
    }

    func sendToRN(bodyData: [String: Any]? = nil, operationKey: String, requestId: String? = nil, docInfo: DocsInfo? = nil) {
        let token = docInfo?.token ?? fileToken
        var identifier: [String: Any] = ["token": token,
                          "type": fileType,
                          "extraId": extraId]
        if let appId = appId {
            identifier["appId"] = appId
        }
        if let appId = appId {
            identifier["appId"] = appId
        }
        var data: [String: Any] = ["operation": operationKey,
                                   "identifier": identifier]
        if let requestId = requestId {
            data["header"] = ["requestId": requestId]
        }
        if let bodyData = bodyData {
            data["body"] = bodyData
        }
        let composedData: [String: Any] = ["business": "comment",
                                           "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
    }

    public func generateRequestID(response: @escaping ResponseCallback) -> String {
        let requestId = "\(Date().timeIntervalSince1970)_comment"
        callbackDic[requestId] = response
        return requestId
    }

    func generateFeedRequestID(response: @escaping FeedCallback) -> String {
        let requestId = "\(Date().timeIntervalSince1970)_feed"
        feedCallbackDic[requestId] = response
        return requestId
    }

    public func update(_ fileType: Int) {
        self.fileType = fileType
    }
}

/// public api
extension RNCommentDataManager {

    /// fetch a comment of a certain file.
    public func fetchComment(extra: [String: Any]? = ["options": "{}"], response: @escaping ResponseCallback) {
        sendToRN(bodyData: extra, operationKey: CommentSendOperation.fetch, requestId: generateRequestID(response: response))
    }

    /// 给drive的接口
    public func publishCommentV2(comment: MountComment,
                                 extranInfo: [String: Any]? = nil,
                                 response: @escaping ResponseCallback) {
        let commentContent = comment.content
        let text = commentContent.content
        let isWhole = false // 和xurunkang确认这里设置成局部评论

        var data: [String: Any] = [
            "content": text,
            "is_whole": isWhole
        ]

        data.merge(other: extranInfo)

        if let commentID = comment.info.commentID {
            data["comment_id"] = commentID
        }

        if let imageInfos = commentContent.imageInfos {
            var imageList: [Any] = []
            imageInfos.forEach { (info) in
                let imageDic: [String: Any] = ["uuid": info.uuid ?? "",
                                               "token": info.token ?? "",
                                               "src": info.src
                                            ]
                imageList.append(imageDic)
            }
            var extraDic = data["extra"] as? [String: Any] ?? [:]
            extraDic["image_list"] = imageList
            data["extra"] = extraDic
        }

        sendToRN(bodyData: data, operationKey: CommentSendOperation.publish, requestId: generateRequestID(response: response))
    }

    /// publish a comment to a certain file.
    ///
    /// - parameter content: comment content.
    /// - parameter commentID: the comment card you reply, can be nil when you are creating a new comment card
    public func publishComment(
        content: CommentContent,
        commentID: String?,
        parentType: String? = nil,
        parentToken: String? = nil,
        isWhole: Bool? = false,
        tmpCommentID: String? = nil,
        quote: String? = nil,
        localCommentID: String? = nil,
        type: Int? = nil,
        replyID: String? = nil,
        bizParams: [String: Any]?,
        position: String? = nil,
        response: @escaping ResponseCallback
    ) {
        let text = content.content
        var data: [String: Any] = ["content": text]

        if let commentID = commentID {
            data["comment_id"] = commentID
        }

        if let tmpCommentID = tmpCommentID {
            data["tmp_comment_id"] = tmpCommentID
        }

        if let quote = quote {
            data["quote"] = quote
        }

        if isWhole == true {
            data["is_whole"] = true
        }

        if let pType = parentType {
            data["parent_type"] = pType
        }

        if let pToken = parentToken {
            data["parent_token"] = pToken
        }

        if let localCommentID = localCommentID {
            data["local_comment_id"] = localCommentID
        }

        if let type = type {
            data["type"] = type
        }

        if let replyID = replyID {
            data["reply_id"] = replyID
        }
        if let bizParams = bizParams {
            data["bizParams"] = bizParams
        }
        if let position = position {
            data["position"] = position
        }
        if let imageInfos = content.imageInfos {
            var imageList: [Any] = []
            imageInfos.forEach { (info) in
                let imageDic: [String: Any] = ["uuid": info.uuid ?? "",
                                               "token": info.token ?? "",
                                               "src": info.src
                                            ]
                imageList.append(imageDic)
            }
            var extraDic = data["extra"] as? [String: Any] ?? [:]
            extraDic["image_list"] = imageList
            data["extra"] = extraDic
        }

        DocsLogger.info("CommentSendOperation.publish, commentID=\(String(describing: commentID)), replyID=\(String(describing: replyID))", component: LogComponents.comment)
        sendToRN(bodyData: data, operationKey: CommentSendOperation.publish, requestId: generateRequestID(response: response))
    }

    /// update a comment.
    ///
    /// - parameter finish: true: finish a comment, false: reopen a comment
    /// - parameter commentID: the comment card you wanna update
    public func updateComment(commentID: String, finish: Bool, response: @escaping ResponseCallback) {
        let data: [String: Any] = ["comment_id": commentID, "finish": finish ? 1 : 0, "options": "{}"]
        sendToRN(bodyData: data, operationKey: CommentSendOperation.update, requestId: generateRequestID(response: response))
    }

    /// edit a comment.
    ///
    /// - parameter commentID: the comment card id
    /// - parameter replyID: the comment message you wanna edit
    /// - parameter content: comment content.
    public func editComment(commentID: String, replyID: String, content: CommentContent, bizParams: [String: Any]? = nil, response: @escaping ResponseCallback) {
        var data: [String: Any] = ["comment_id": commentID, "reply_id": replyID, "content": content.content, "options": "{}"]
        if let bizParams = bizParams {
            data["bizParams"] = bizParams
        }
        if let imageInfos = content.imageInfos {
            var imageList: [Any] = []
            imageInfos.forEach { (info) in
                let imageDic: [String: Any] = ["uuid": info.uuid ?? "",
                                               "token": info.token ?? "",
                                               "src": info.src,
                                               "originalSrc": info.originalSrc ?? ""
                                            ]
                imageList.append(imageDic)
            }
            var extraDic = data["extra"] as? [String: Any] ?? [:]
            extraDic["image_list"] = imageList
            data["extra"] = extraDic
        }
        sendToRN(bodyData: data, operationKey: CommentSendOperation.edit, requestId: generateRequestID(response: response))
    }

    /// delete a comment.
    ///
    /// - parameter commentID: the comment card you wanna delete
    /// - parameter replyID: the comment message you wanna delete
    /// - parameter content: comment content.
    public func deleteComment(commentID: String, replyID: String, response: @escaping ResponseCallback) {
        let data: [String: Any] = ["comment_id": commentID, "reply_id": replyID, "options": "{}"]
        sendToRN(bodyData: data, operationKey: CommentSendOperation.delete, requestId: generateRequestID(response: response))
     }

    /// translate comment
    public func translateComment(commentID: String, replyID: String, options: String? = nil, response: @escaping ResponseCallback) {
        let data: [String: Any] = ["comment_id": commentID, "reply_id": replyID, "options": options ?? "{}"] // {} 前端说默认这个
        sendToRN(bodyData: data, operationKey: CommentSendOperation.translate, requestId: generateRequestID(response: response))
    }

    public func addTranslateComments(options: String?, response: @escaping ResponseCallback) {
        let data: [String: Any] = ["options": options ?? "{}"]
        sendToRN(bodyData: data, operationKey: CommentSendOperation.addTranslateComments, requestId: generateRequestID(response: response))
    }
    
    public func addTranslateComments(commentIds: [[String: Any]], response: @escaping ResponseCallback) {
        let data: [String: Any] = ["comments": commentIds]
        sendToRN(bodyData: data, operationKey: CommentSendOperation.addTranslateComments, requestId: generateRequestID(response: response))
    }

    public func setTranslateEnableLang(options: String?, response: @escaping ResponseCallback) {
        let data: [String: Any] = ["options": options ?? "{}"]
        sendToRN(bodyData: data, operationKey: CommentSendOperation.setTranslateEnableLang, requestId: generateRequestID(response: response))
    }
    
    public func setTranslateEnableLang(auto: Bool, lang: String, response: @escaping ResponseCallback) {
        let data: [String: Any] = ["isEnableTranslate": auto,
                                   "translateLang": lang]
        sendToRN(bodyData: data, operationKey: CommentSendOperation.setTranslateEnableLang, requestId: generateRequestID(response: response))
    }

    public func fetchFeedData(docInfo: DocsInfo, response: @escaping FeedCallback) {
        sendToRN(operationKey: CommentSendOperation.fetchMessage, requestId: generateFeedRequestID(response: response), docInfo: docInfo)
    }

    public func resolveMessage(docInfo: DocsInfo, messages: [String], response: @escaping FeedCallback) {
        sendToRN(bodyData: ["messageIds": messages,
                            "solveStatus": 1],
                 operationKey: CommentSendOperation.resolveMessage,
                 requestId: generateFeedRequestID(response: response),
                 docInfo: docInfo)
    }

}

extension RNCommentDataManager: RNMessageDelegate {

    public func compareIdentifierEquality(identifier: [String: Any]) -> Bool {
        // type不强制判断是因为小程序没有type
        let type = identifier["type"] as? Int ?? 0
        guard let token = identifier["token"] as? String else {
            spaceAssertionFailure("missing essential value in identifier \(LogComponents.comment)")
            return false
        }
        return token == fileToken && type == fileType
    }

    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let operation = data["operation"] as? String,
            let body = data["body"] as? [String: Any],
            let operationType = CommentReceiveOperation(rawValue: operation) else { spaceAssertionFailure("no operation in data"); return }

        DocsLogger.info("receive response eventName: \(eventName)", component: LogComponents.comment)

        switch operationType {
        case .updateMessage:
            delegate?.didReceiveUpdateFeedData(response: body)
        case .response:
            if let header = data["header"] as? [String: Any], let requestId = header["requestId"] as? String {
                if requestId.hasSuffix("_comment") {// 2. 给业务方CURD回调
                    serialQueue.addOperation {
                        let responseModel = RNCommentData()
                        responseModel.serialize(data: body)
                        DispatchQueue.main.async {
                            self.handleResponse(response: responseModel, requestId: requestId)
                        }
                    }
                } else if requestId.hasSuffix("_feed") {
                    handleFeedResponse(response: body, requestID: requestId)
                }
            }
        case .sendCommentsData: // 1. 给业务方change回调，一般会回调两次
            serialQueue.addOperation {
                let responseModel = RNCommentData()
                responseModel.serialize(data: body)
                DispatchQueue.main.async {
                    self.delegate?.didReceiveCommentData(response: responseModel, eventType: operationType)
                }
            }
        }
    }

    func handleResponse(response: RNCommentData, requestId: String) {
        if let callback = callbackDic[requestId] {
            callback(response)
            callbackDic[requestId] = nil
        } else {
            DocsLogger.info("receive response but missing callback:\(requestId), the response might be handled by another instance")
        }
    }

    func handleFeedResponse(response: Any, requestID: String) {
        if let callback = feedCallbackDic[requestID] {
            callback(response)
            feedCallbackDic[requestID] = nil
        } else {
            DocsLogger.info("receive feed response but missing callback, the response might be handled by another instance")
        }
    }
}

public struct CommentEntities {
    public let notNotifyUsers: [EntityUser]?

    public init(_ entities: [String: Any]) {

        if let notNotifyUsers = entities["not_notify_users"] as? [[String: Any]] {
            self.notNotifyUsers = notNotifyUsers.map( EntityUser.init )
        } else {
            self.notNotifyUsers = nil
        }
    }
}

public struct EntityUser {
    public let name: String

    public init(_ user: [String: Any]) {
        self.name = (user["name"] as? String).or("")
    }
}

private extension Optional {
    func or(_ defaultValue: Wrapped) -> Wrapped {
        return self ?? defaultValue
    }
}

public final class RNCommentData {
    public class DiffComment {
        /// 远端更新评论
        public var addedComments: [Comment]?
        /// 远端删除评论
        public var deletedComments: [Comment]?
        /// 远端更新评论
        public var updatedComments: [Comment]?
        /// 远端解决评论
        public var resolveStatusChangedComments: [Comment]?
        init() {}
    }
    public var code: Int?
    public var msg: String?
    public var currentCommentID: String?
    public var comments = [Comment]()
    public var diffComments: DiffComment?
    public var entities: CommentEntities?
    public var rawData: [String: Any]?

    public init() {}

    public func serialize(data: [String: Any]) {
        rawData = data

        guard let jsonString = data["data"] as? String,
            let d = jsonString.data(using: .utf8),
            let dic = try? JSONSerialization.jsonObject(with: d, options: []) as? [String: Any] else {
            code = data["code"] as? Int
            msg = data["msg"] as? String
            DocsLogger.error("serialize comment error msg:\(msg) code:\(code)", component: LogComponents.comment)
            return
        }

        code = data["code"] as? Int
        msg = data["msg"] as? String

        var commentData: [[String: Any]] = []

        // 自己发送后过来的数据和请求返回的格式不一致，我不知道为什么会有三种情况，要吐了
        if let aCts = dic["allComments"] as? [String: Any],
        let cts = aCts["comments"] as? [[String: Any]] {
            commentData = cts
            if let entities = aCts["entities"] as? [String: Any] {
                self.entities = CommentEntities(entities)
            }
            code = 0
            msg = data["msg"] as? String
            currentCommentID = dic["cur_comment_id"] as? String
        } else if let cts = dic["comments"] as? [[String: Any]] {
            commentData = cts
            if let entities = dic["entities"] as? [String: Any] {
                self.entities = CommentEntities(entities)
            }
            code = data["code"] as? Int
            msg = data["msg"] as? String
            currentCommentID = dic["cur_comment_id"] as? String
        } else if let ct = dic["comment"] as? [String: Any] {
            commentData = [ct]
            code = data["code"] as? Int
            msg = data["msg"] as? String
            currentCommentID = ct["commentId"] as? String
        }

        comments = serializeComment(dict: commentData)

        if let diffComments = dic["diffComments"] as? [String: Any] {
            self.diffComments = DiffComment()
            if let added = diffComments["addedComments"] as? [[String: Any]] {
                self.diffComments?.addedComments = serializeComment(dict: added)
            }
            if let deleted = diffComments["deletedComments"] as? [[String: Any]] {
                self.diffComments?.deletedComments = serializeComment(dict: deleted)
            }
            if let updated = diffComments["updatedComments"] as? [[String: Any]] {
                self.diffComments?.updatedComments = serializeComment(dict: updated)
            }
            if let resolveStatusChanged = diffComments["resolveStatusChangedComments"] as? [[String: Any]] {
                self.diffComments?.resolveStatusChangedComments = serializeComment(dict: resolveStatusChanged)
            }
           
        }
    }
    
    private func serializeComment(dict: [[String: Any]]) -> [Comment] {
        var tempComments = [Comment]()
        dict.forEach { (commentCardDic) in
            guard let commentId = commentCardDic["commentId"] as? String else { return }
            let comment = Comment()
            comment.commentID = commentId
            comment.serialize(json: JSON(commentCardDic))
            comment.commentList = []
            tempComments.append(comment)
            if let commentList = commentCardDic["commentList"] as? [[String: Any]] {
                commentList.forEach({ (commentItemDic) in
                    let commentItem = CommentItem()
                    commentItem.serialize(dict: commentItemDic)
                    commentItem.commentId = commentId
                    comment.commentList.append(commentItem)
                })
            } else if let reactionList = commentCardDic["reactionList"] as? [[String: Any]] {
                var reactions = [CommentReaction]()
                reactionList.forEach { itemDic in
                    guard let data = try? JSONSerialization.data(withJSONObject: itemDic, options: []),
                          let model = try? JSONDecoder().decode(CommentReaction.self, from: data) else {
                        DocsLogger.error("serialize reactionList error", component: LogComponents.comment)
                        return
                    }
                    if model.userList.isEmpty {
                        DocsLogger.error("userList isEmpty on reaction:\(model.reactionKey)", component: LogComponents.comment)
                    } else {
                        reactions.append(model)
                    }
                }
                let commentItem = CommentReaction.transformToCommentItem(reactions: reactions, docsInfo: nil, commentId: commentId)
                comment.commentList = [commentItem]
            }
        }
        return tempComments
    }
}

extension RNCommentDataManager {
    public func sendComment(bodyData: [String: Any], operationKey: String, response: @escaping ResponseCallback) {
        sendToRN(bodyData: bodyData, operationKey: operationKey, requestId: generateRequestID(response: response))
    }
}


public extension Comment {
    
    func serialize(json: JSON) {
        finish = json["finish"].int
        quote = json["quote"].string
        finishUserID = json["finishUserId"].string
        userId = json["userId"].stringValue
        isWhole = json["isWhole"].boolValue
        parentToken = json["parentToken"].string
        parentType = json["parentType"].string
        isUnsummit = json["unSubmitComment"].boolValue
        position = json["position"].string
        bizParams = json["bizParams"].dictionaryObject
        commentUUID = json["commentUUID"].stringValue
        if let commentID = json["commentId"].string {
            self.commentID = commentID
        }
        
        isNewInput = json["isNewInput"].boolValue
        if isNewInput {
            DocsLogger.info("isnewInput, commentId=\(commentID)", component: LogComponents.comment)
            addHeader()
            return
        }
        let interactionType = DocsInteractionType(rawValue: json["commentType"].intValue)
        self.interactionType = interactionType
        switch interactionType {
        case .comment, .none:
            for commentItemJSON in json["commentList"].arrayValue {
                var commentItem = CommentItem()
                commentItem.serialize(json: commentItemJSON)
                commentItem.commentId = commentID
                commentItem.commentDocsInfo = docsInfo
                commentItem.isNewInput = isNewInput
                commentItem.updateInteractionType(.comment)
                commentList.append(commentItem)
            }
        case .reaction:
            var reactions = [CommentReaction]()
            for reactionItemJSON in json["reactionList"].arrayValue {
                let dict = reactionItemJSON.dictionaryObject ?? [:]
                guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                      let model = try? JSONDecoder().decode(CommentReaction.self, from: data) else {
                    DocsLogger.error("serialize reactionList error", component: LogComponents.comment)
                    continue
                }
                if model.userList.isEmpty {
                    DocsLogger.error("userList isEmpty on reaction:\(model.reactionKey)", component: LogComponents.comment)
                } else {
                    reactions.append(model)
                }
            }
            let commentItem = CommentReaction.transformToCommentItem(reactions: reactions, docsInfo: docsInfo, commentId: commentID)
            commentList = [commentItem]
        }
        if !commentList.isEmpty {
            addHeader()
        }
    }
    
    func addHeader() {
        if commentList.first?.uiType == .header {
            return
        }
        // 添加header数据
        let headerItem = CommentItem()
        headerItem.uiType = .header
        headerItem.replyID = "\(self.commentID)_IN_HEADER"
        headerItem.commentId = self.commentID
        headerItem.isNewInput = isNewInput
        headerItem.isActive = isActive
        headerItem.commentDocsInfo = docsInfo
        headerItem.quote = self.quote
        if commentList.isEmpty {
            commentList.append(headerItem)
        } else {
            commentList.insert(headerItem, at: 0)
        }
    }

    var docsInfo: DocsInfo? {
       return commentDocsInfo as? DocsInfo
    }
    
    func addFooter() {
        let lastItem = commentList.last
        if lastItem?.uiType == .footer || lastItem?.uiType == .unsupported {
            return
        }
        // 添加footer数据
        let footerItem = CommentItem()
        footerItem.uiType = .footer
        footerItem.replyID = "\(self.commentID)_footer"
        footerItem.commentId = self.commentID
        footerItem.isActive = isActive
        footerItem.isNewInput = isNewInput
        footerItem.permission = permission
        footerItem.commentDocsInfo = docsInfo
        if isActive, permission.contains(.canComment) {
            switch interactionType {
            case .comment, .none:
                footerItem.viewStatus = .reply(isFirstResponser: isNewInput)
            case .reaction:
                footerItem.viewStatus = .normal
            }
        }
        commentList.append(footerItem)
    }
    
    func serialize(json: JSON, msgArr: [JSON], isOwner: Bool) {
        serialize(json: json)
    }
}


public extension CommentItem {
    var docsInfo: DocsInfo? {
       return commentDocsInfo as? DocsInfo
    }

    func serialize(json: JSON) {
        replyID = json["replyId"].stringValue
        userID = json["userId"].stringValue
        var replyTypeValue = 0
        if let value = json["replyType"].int {
            replyTypeValue = value
        } else if let value = json["reply_type"].int {
            replyTypeValue = value
        }
        replyType = ReplyType(rawValue: replyTypeValue)
        if replyType == nil {
            uiType = .unsupported
        }
        content = json["content"].string // 保存原始字符
        name = json["name"].string
        avatarURL = json["avatarUrl"].string
        createTimeStamp = json["createTimestamp"].double
        updateTimeStamp = json["updateTimestamp"].double
        modify = json["modify"].int
        commentId = json["commentId"].string
        audioDuration = json["extra"]["attachment"]["audio_duration"].double
        audioFileToken = json["extra"]["attachment"]["audio_file_token"].string
        status = CommentReadStatus(rawValue: json["readStatus"].intValue) ?? .undefined
        messageId = json["messageId"].stringValue
        imageList.removeAll()
        if let imageListJson = json["extra"]["image_list"].array,
           imageListJson.count > 0 {
            imageListJson.forEach { (imageDic) in
                let token = imageDic["token"].string
                let uuid = imageDic["uuid"].string
                let src = imageDic["src"].string
                let originalSrc = imageDic["originalSrc"].string
                if let src = src {
                    let info = CommentImageInfo(uuid: uuid, token: token, src: src, originalSrc: originalSrc)
                    imageList.append(info)
                }
            }
        }

        if let reactionsArray = json["reaction"].array {
            self.reactions = reactionsArray
                .map { reaction -> CommentReaction? in
                    let jsonDic = reaction.dictionaryObject
                    guard let jsonTemp = jsonDic, let data = try? JSONSerialization.data(withJSONObject: jsonTemp, options: []) else {
                        DocsLogger.error("reaction transform err, jsonDic=\(String(describing: jsonDic))")
                        return nil
                    }
                    var model = try? JSONDecoder().decode(CommentReaction.self, from: data)
                    model?.replyId = self.replyID
                    return model
                }.compactMap({ // 过滤掉空数据
                $0
            }).filter({ // 过滤掉有 reactionKey 却没有 userList 的情况
                !$0.userList.isEmpty
            })
        }

        reactionType = json["reactionType"].string

        translateContent = json["translateContent"].string // 保存原始字符

        if let status = json["translateStatus"].string {
            translateStatus = CommentTranslateStatus(rawValue: status)
        }

        anonymous = json["anonymous"].boolValue
        
        isSending = json["sending"].boolValue
        errorCode = json["error"]["code"].intValue
        errorMsg = json["error"]["msg"].stringValue
        retryType = CommentItemRetryType(rawValue: json["retryType"].stringValue)
        replyUUID = json["replyUUID"].stringValue
    }
    
    func updateInteractionType(_ type: DocsInteractionType?) {
        interactionType = type
    }
}


extension Comment {
    
    public func serialize(dict: [String: Any]) {
        finish = dict.getIntOrNil(for: "finish")
        quote = dict.getStringOrNil(for: "quote")
        finishUserID = dict.getStringOrNil(for: "finishUserId")
        userId = dict.getString(for: "userId")
        isWhole = dict.getBool(for: "isWhole")
        parentToken = dict.getStringOrNil(for: "parentToken")
        parentType = dict.getStringOrNil(for: "parentType")
        isUnsummit = dict.getBool(for: "unSubmitComment")
        position = dict.getStringOrNil(for: "position")
        bizParams = dict["bizParams"] as? [String: Any]
        
        if let commentID = dict.getStringOrNil(for: "commentId") {
            self.commentID = commentID
        }
        commentUUID = dict.getString(for: "commentUUID")
        
        isNewInput = dict.getBool(for: "isNewInput")
        if isNewInput {
            DocsLogger.info("isnewInput, commentId=\(commentID)", component: LogComponents.comment)
            addHeader()
            return
        }
        let interactionType = DocsInteractionType(rawValue: dict.getInt(for: "commentType"))
        self.interactionType = interactionType
        switch interactionType {
        case .comment, .none:
            for commentItemJSON in dict.getArray(for: "commentList") {
                let commentItem = CommentItem()
                commentItem.serialize(dict: commentItemJSON)
                commentItem.commentId = commentID
                commentItem.commentDocsInfo = docsInfo
                commentItem.isNewInput = isNewInput
                commentItem.updateInteractionType(.comment)
                commentList.append(commentItem)
            }
        case .reaction:
            var reactions = [CommentReaction]()
            for reactionItemJSON in dict.getArray(for: "reactionList") {
                let dict = reactionItemJSON
                guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
                      let model = try? JSONDecoder().decode(CommentReaction.self, from: data) else {
                    DocsLogger.error("serialize reactionList error", component: LogComponents.comment)
                    continue
                }
                if model.userList.isEmpty {
                    DocsLogger.error("userList isEmpty on reaction:\(model.reactionKey)", component: LogComponents.comment)
                } else {
                    reactions.append(model)
                }
            }
            let commentItem = CommentReaction.transformToCommentItem(reactions: reactions, docsInfo: docsInfo, commentId: commentID)
            commentList = [commentItem]
        }
        if !commentList.isEmpty {
            addHeader()
        }
    }
}


extension CommentItem {

    public func serialize(dict: [String: Any]) {
        replyID = dict.getString(for: "replyId")
        userID = dict.getString(for: "userId")
        var replyTypeValue = 0
        if let value = dict.getIntOrNil(for: "replyType") {
            replyTypeValue = value
        } else if let value = dict.getIntOrNil(for: "reply_type") {
            replyTypeValue = value
        }
        replyType = ReplyType(rawValue: replyTypeValue)
        if replyType == nil {
            uiType = .unsupported
        }
        content = dict.getStringOrNil(for: "content") // 保存原始字符
        name = dict.getStringOrNil(for: "name")
        aliasInfo = UserAliasInfo(data: (dict["display_name"] as? [String: Any]) ?? [:])
        avatarURL = dict.getStringOrNil(for: "avatarUrl")
        createTimeStamp = dict.getDoubleOrNil(for: "createTimestamp")
        updateTimeStamp = dict.getDoubleOrNil(for: "updateTimestamp")
        modify = dict.getIntOrNil(for: "modify")
        commentId = dict.getStringOrNil(for: "commentId")
        audioDuration = dict.getDoubleOrNil(keyPath: "extra.attachment.audio_duration")
        audioFileToken = dict.getStringOrNil(keyPath: "extra.attachment.audio_file_token")
        status = CommentReadStatus(rawValue: dict.getInt(for: "readStatus")) ?? .undefined
        messageId = dict.getString(for: "messageId")
        imageList.removeAll()
        if let imageListJson = dict.getArrayOrNil(keyPath: "extra.image_list"),
           imageListJson.count > 0 {
            imageListJson.forEach { (imageDic) in
                let token = imageDic.getStringOrNil(for: "token")
                let uuid = imageDic.getStringOrNil(for: "uuid")
                let src = imageDic.getStringOrNil(for: "src")
                let originalSrc = imageDic.getStringOrNil(for: "originalSrc")
                if let src = src {
                    let info = CommentImageInfo(uuid: uuid, token: token, src: src, originalSrc: originalSrc)
                    imageList.append(info)
                }
            }
        }

        if let reactionsArray = dict.getArrayOrNil(for: "reaction") {
            self.reactions = reactionsArray
                .map { reaction -> CommentReaction? in
                    let jsonTemp = reaction
                    guard let data = try? JSONSerialization.data(withJSONObject: jsonTemp, options: []) else {
                        DocsLogger.error("reaction transform err, jsonDic=\(String(describing: jsonTemp))")
                        return nil
                    }
                    var model = try? JSONDecoder().decode(CommentReaction.self, from: data)
                    model?.replyId = self.replyID
                    return model
                }.compactMap({ // 过滤掉空数据
                $0
            }).filter({ // 过滤掉有 reactionKey 却没有 userList 的情况
                !$0.userList.isEmpty
            })
        }

        reactionType = dict.getStringOrNil(for: "reactionType")

        translateContent = dict.getStringOrNil(for: "translateContent") // 保存原始字符

        if let status = dict.getStringOrNil(for: "translateStatus") {
            translateStatus = CommentTranslateStatus(rawValue: status)
        }

        targetLanguage = dict.getStringOrNil(for: "targetLanguage")
        contentSourceLanguage = dict.getStringOrNil(for: "srcLanguage")
        defaultTargetLanguage = dict.getStringOrNil(for: "userDefaultTargetLang")
        userMainLanguage = dict.getStringOrNil(for: "userMainLang")


        anonymous = dict.getBool(for: "anonymous")
        
        isSending = dict.getBool(for: "sending")
        errorCode = dict.getInt(keyPath: "error.code")
        errorMsg = dict.getString(keyPath: "error.msg")
        retryType = CommentItemRetryType(rawValue: dict.getString(for: "retryType"))
        replyUUID = dict.getString(for: "replyUUID")
    }
}

extension CommentReaction: CommentReactionInfoType {
    
    /// 将表情列表转化为一条回复，其类型为.reaction
    static func transformToCommentItem(reactions: [CommentReaction],
                                       docsInfo: DocsInfo?,
                                       commentId: String) -> CommentItem {
        
        var newReactions = [CommentReaction]()
        for item in reactions {
            var newItem = item
            newItem.commentId = commentId
            newReactions.append(newItem)
        }
        guard let reactionItem = newReactions.first else { return CommentItem() }
        
        let commentItem = CommentItem()
        commentItem.replyID = reactionItem.referKey ?? ""
        commentItem.replyType = .content
        commentItem.reactions = newReactions
        commentItem.reactionType = reactionItem.referType
        commentItem.updateInteractionType(.reaction)
        commentItem.uiType = .normal_reaction
        commentItem.commentDocsInfo = docsInfo
        commentItem.commentId = commentId
        return commentItem
    }
    
   public func toLarkReactionInfo() -> ReactionInfo {
        return ReactionInfo(reactionKey: reactionKey, users: _toLarkReactionUser())
    }
}

extension CommentItem {
    public var aliasInfo: UserAliasInfo? {
        get {
            let obj = objc_getAssociatedObject(self, &CommentPropertyAssociatedKey.aliasInfo) as? CommentPropertyWrapper
            return obj?.value as? UserAliasInfo
        }
        set {
            let obj = newValue.map { CommentPropertyWrapper($0) }
            objc_setAssociatedObject(self, &CommentPropertyAssociatedKey.aliasInfo, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private struct CommentPropertyAssociatedKey {
    static var docsInfo = "docsInfo"
    static var aliasInfo = "aliasInfo"
}

private class CommentPropertyWrapper: NSObject {
    var value: Any?
    init(_ info: Any) {
        self.value = info
    }
}

private extension CommentReaction {
    private func _toLarkReactionUser() -> [ReactionUser] {
        var reactionUsers = userList.map({ (userInfo) -> ReactionUser in
            // TODO: displayName 待后续接入
//            return ReactionUser(id: userInfo.userId, name: userInfo.displayName)
            return ReactionUser(id: userInfo.userId, name: userInfo.userName)
        })

        // 无奈之举, reaction 组件本来不支持分页的，如果不添加假数据，more 的人数显示会有问题
        if reactionUsers.count < totalCount, let last = reactionUsers.last {
            for _ in reactionUsers.count..<totalCount {
                reactionUsers.append(last)
            }
        }

        return reactionUsers
    }
}
