//
//  CommentShowInputModel.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/5.
//  


import SKFoundation
import SpaceInterface
import SKCommon

public struct CommentShowInputModel: CommentInputModelType, Decodable {

    public enum CommentType: Int, Decodable {
        case new // 新建
        case edit // 编辑
    }

    public struct ExtraData: Decodable {
        public let imageList: [CommentImageInfo]?
        enum CodingKeys: String, CodingKey {
            case imageList = "image_list"
        }
    }

    public let isWhole: Bool // 是否是全文评论
    public let token: String
    public let type: CommentType
    public var showVoice: Bool = false
    public let quote: String?
    public var showKeyboard: Bool = true // 是否调起键盘
    public let position: String? // 透传给RN

    // optional for edit/定向回复 commment
    // 在编辑、定向回复评论会用到
    public let content: String?
    public let commentID: String?
    public let replyID: String?
    public let extra: ExtraData?
    
    public let bizParams: [String: Any]?

    /// 定向回复
    public let directionalReplyId: String?

    public let parentToken: String?
    public let parentType: String?

    public let localCommentID: String?
    
    public let needLoading: Bool?
    
    public var commentDocsInfo: CommentDocsInfo?
    
    var docsInfo: DocsInfo? {
        return commentDocsInfo as? DocsInfo
    }
    
    public var statsExtra: CommentStatsExtra?

    public var sended = false
    
    public mutating func update(docsInfo: CommentDocsInfo) {
        self.commentDocsInfo = docsInfo
    }
    
    mutating public func markSended() {
        self.sended = true
    }

    public enum CodingKeys: String, CodingKey {
        case isWhole = "is_whole"
        case token = "token"
        case type
        case content
        case extra
        case commentID = "comment_id"
        case replyID = "reply_id"
        case showVoice = "show_voice"
        case quote
        case showKeyboard = "keyboard_pop"
        case parentToken = "parent_token"
        case parentType = "parent_type"
        case localCommentID = "local_comment_id"
        case directionalReplyId = "directional_reply_id"
        case position
        case bizParams
        case needLoading = "need_loading"
        case statsExtra
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        isWhole = try values.decode(Bool.self, forKey: .isWhole)
        token = try values.decode(String.self, forKey: .token)
        type = try values.decode(CommentType.self, forKey: .type)

        content = try values.decodeIfPresent(String.self, forKey: .content)
        commentID = try values.decodeIfPresent(String.self, forKey: .commentID)
        replyID = try values.decodeIfPresent(String.self, forKey: .replyID)
        extra = try values.decodeIfPresent(ExtraData.self, forKey: .extra)

        showVoice = try values.decodeIfPresent(Bool.self, forKey: .showVoice) ?? false
        quote = try values.decodeIfPresent(String.self, forKey: .quote)
        showKeyboard = try values.decodeIfPresent(Bool.self, forKey: .showKeyboard) ?? true

        directionalReplyId = try values.decodeIfPresent(String.self, forKey: .directionalReplyId)

        parentToken = try values.decodeIfPresent(String.self, forKey: .parentToken)
        parentType = try values.decodeIfPresent(String.self, forKey: .parentType)

        localCommentID = try values.decodeIfPresent(String.self, forKey: .localCommentID)
        
        position = try values.decodeIfPresent(String.self, forKey: .position)
        
        bizParams = try values.decodeIfPresent([String: Any].self, forKey: .bizParams)
        
        needLoading = try? values.decodeIfPresent(Bool.self, forKey: .needLoading)
        
        statsExtra = try? values.decodeIfPresent(CommentStatsExtra.self, forKey: .statsExtra)
    }
    
    public init(isWhole: Bool,
                token: String,
                type: CommentShowInputModel.CommentType,
                docsInfo: CommentDocsInfo? = nil,
                commentId: String? = nil, // 编辑全文评论时
                localCommentId: String? = nil,
                quote: String? = nil) {
        self.isWhole = isWhole
        self.token = token
        self.type = type
        self.quote = quote
        self.commentID = commentId
        self.commentDocsInfo = docsInfo

        self.position = nil
        self.content = nil
        self.bizParams = nil
        self.needLoading = false
        self.localCommentID = localCommentId
        self.replyID = nil
        self.parentType = nil
        self.parentToken = nil
        self.extra = nil
        self.directionalReplyId = nil
    }
}

extension CommentShowInputModel {

    public func toCommentWrapper() -> CommentWrapper {
        let comment = Comment()
        let item = CommentItem()
        
        if type == .new {
            comment.commentID = self.localCommentID ?? ""
        } else {
            comment.commentID = self.commentID ?? ""
        }
        
        comment.quote = self.quote
        comment.parentType = self.parentType
        comment.parentToken = self.parentToken
        comment.bizParams = self.bizParams
        comment.position = self.position
        comment.isWhole = self.isWhole
        comment.isNewInput = true

        item.commentId = comment.commentID
        item.replyID = replyID ?? ""
        return CommentWrapper(commentItem: item, comment: comment)
    }
    
    public var draftKey: CommentDraftKey {
        switch type {
        case .new:
            return CommentDraftKey(entityId: token, sceneType: .newComment(isWhole: isWhole))
        case .edit:
            return CommentDraftKey(entityId: token,
                                   sceneType: .editExisting(commentId: commentID ?? "", replyId: replyID ?? ""))
        }
    }
}


class CommentShowInputDecoderImp: CommentShowInputDecoder {

    init() {}

    func decode(data: Data) -> CommentInputModelType? {
        do {
            let inputModel = try JSONDecoder().decode(CommentShowInputModel.self, from: data)
            return inputModel
        } catch {
            DocsLogger.error("new input data is invalid:\(error)", component: LogComponents.comment)
            return nil
        }
    }
}
