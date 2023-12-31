//
//  AtInputTextView+draft.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/10.
// swiftlint:disable pattern_matching_keywords


import Foundation
import SKFoundation
import SKUIKit
import SpaceInterface
import SKCommon

extension AtInputTextView: CommentDraftKeyProvider {
    
    public var commentDraftKey: CommentDraftKey {
        if let key = commentWrapper?.commentItem.commentDraftKey {
            return key
        }
        guard let dependency = dependency else {
            return CommentDraftKey(entityId: nil, sceneType: .newComment(isWhole: true))
        }
        
        let isWhole = (dependency.atInputTextType == .global)
        
        let docsInfo = dependency.commentDocsInfo as? DocsInfo
        guard let token = docsInfo?.token, !token.isEmpty else {
            return CommentDraftKey(entityId: nil, sceneType: .newComment(isWhole: isWhole))
        }
        guard let scene = dependency.commentDraftScene else {
            return CommentDraftKey(entityId: token, sceneType: .newComment(isWhole: isWhole))
        }
        return CommentDraftKey(entityId: token, sceneType: scene)
    }
}

extension AtInputTextView {

    /// 回复时在头部插入新的user
    func insertAtUserWhenReply(atInfo: AtInfo) {
        let textColor = UIColor.ud.textTitle
        let attributes = AtInfo.TextFormat.defaultAttributes(font: textFont, textColor: textColor)
        let newUserString = atInfo.attributedString(attributes: attributes, lineBreakMode: .byWordWrapping)
        
        let newString: NSMutableAttributedString
        if let current = inputTextView?.textView.attributedText {
            newString = NSMutableAttributedString(attributedString: current)
            let newUserMutableString = NSMutableAttributedString(attributedString: newUserString)
            newUserMutableString.append(NSAttributedString(string: " "))
            newString.insert(newUserMutableString, at: 0)
        } else {
            newString = NSMutableAttributedString(attributedString: newUserString)
            newString.append(NSAttributedString(string: " "))
        }
        textViewSet(attributedText: newString)
        if let textView = inputTextView?.textView {
            textChangeDelegate?.textViewDidChange(textView) // 避免显示`未换行`
        }
    }

    /// 回复场景下，ipad新建局部评论场景下，恢复草稿
    func restoreReplyAndNewCommentDraft() {
        switch commentDraftKey.sceneType {
        case .newReply:
            restoreDraft()
        case .newComment(let isWhole):
            if SKDisplay.pad, isWhole == false {
                restoreDraft()
            }
        case .editExisting:
            break
        }
    }

    func restoreDraft(draftKey: CommentDraftKey? = nil) {
        let textColor = UIColor.ud.textTitle
        let attributes = AtInfo.TextFormat.defaultAttributes(font: textFont, textColor: textColor)
        
        var key: CommentDraftKey
        if let inputKey = draftKey {
            key = inputKey
        } else {
            key = commentDraftKey
        }
        let draftResult: Swift.Result<CommentDraftModel, Error> = CommentDraftManager.shared.commentModel(for: key)
        if case .success(let model) = draftResult {
            let xmlParser = AtInfoXMLParserImp()
            let checkPermission = dependency?.canShowDraftDarkName ?? false
            let attrText = xmlParser.decodedAttrString(model: model, attributes: attributes, token: self.dependency?.fileToken ?? "", type: self.dependency?.fileType, checkPermission: checkPermission)
            let imageList = model.imageList.map { $0.lagacyModel() }
            textViewSet(attributedText: attrText)
            inputTextView?.updatePreviewWithImageInfos(imageList)
            inputTextView?.textView.dingOut()
        } else {
            self.clearAllContent()
        }
    }
    
    /// 回复场景下，恢复草稿，指定CommentId
    func restoreReplyCommentDraftWithCommentId(_ commentId: String) {
        let entity = commentDraftKey.entityId
        let newKey = CommentDraftKey(entityId: entity, sceneType: .newReply(commentId: commentId))
        let draftResult: Swift.Result<CommentDraftModel, Error> = CommentDraftManager.shared.commentModel(for: newKey)
        if case .success(let model) = draftResult {
            let xmlParser = AtInfoXMLParserImp()
            let textColor = UIColor.ud.textTitle
            let checkPermission = dependency?.canShowDraftDarkName ?? false
            let attributes = AtInfo.TextFormat.defaultAttributes(font: textFont, textColor: textColor)
            let attrText = xmlParser.decodedAttrString(model: model, attributes: attributes, token: self.dependency?.fileToken ?? "", type: self.dependency?.fileType, checkPermission: checkPermission)
            let imageList = model.imageList.map { $0.lagacyModel() }
            textViewSet(attributedText: attrText)
            inputTextView?.updatePreviewWithImageInfos(imageList)
        }
    }
    
    /// 上报草稿事件
    func reportDraftEvent() {
        var docsInfo = commentWrapper?.comment.docsInfo
        if docsInfo == nil {
            docsInfo = self.dependency?.commentDocsInfo as? DocsInfo
        }
        guard let info = docsInfo else { return }
        
        let commentId: String
        let replyId: String
        let hasDraft: Bool
        let contentLength: Int
        let imageCount: Int
        
        let draftKey = commentDraftKey
        switch draftKey.sceneType {
        case .newComment:
            commentId = ""
            replyId = ""
        case .newReply(let comment_id):
            commentId = comment_id
            replyId = ""
        case .editExisting(let comment_id, let reply_id):
            commentId = comment_id
            replyId = reply_id
        }
        let draftResult: Swift.Result<CommentDraftModel, Error> = CommentDraftManager.shared.commentModel(for: draftKey)
        switch draftResult {
        case .success(let model):
            hasDraft = (model.originFrom == nil)
            contentLength = hasDraft ? model.content.count : 0
            imageCount = hasDraft ? model.imageList.count : 0
        case .failure:
            hasDraft = false
            contentLength = 0
            imageCount = 0
        }
        
        let fileId = DocsTracker.encrypt(id: info.token)
        let parameter: [String: Any] = ["file_type": info.type.name,
                                        "file_id": fileId,
                                        "comment_id": commentId,
                                        "reply_id": replyId,
                                        "has_draft": hasDraft.description,
                                        "content_length": contentLength,
                                        "image_count": imageCount]
        DocsTracker.newLog(enumEvent: .commentDraftInputShow, parameters: parameter)
    }
}


extension AtInputTextView {
    
    /// 保存评论草稿，因为某些情况不会触发`textDidChangeNotification`，需要手动保存一下
    /// 某些情况：新增或删除atinfo、语音评论产生的文字...
    /// isNewReply：是否是新的回复，决定需要判断是否`无草稿`
    func saveCommentDraftManually(isNewReply: Bool = false) {
        let key = commentDraftKey
        let attributedText = inputTextView?.textView.attributedText ?? NSAttributedString()
        let value = AtInfo.encodedString(attributedString: attributedText)
        if isNewReply {
            let draftResult = CommentDraftManager.shared.commentModel(for: key)
            let newModel: CommentDraftModel
            switch draftResult {
            case .success(let oldModel):
                newModel = CommentDraftModel(content: value, imageList: oldModel.imageList) // 去除originFrom
            case .failure:
                newModel = CommentDraftModel(content: value, imageList: [], originFrom: .reply)
            }
            CommentDraftManager.shared.updateComment(model: newModel, for: key)
        } else {
            CommentDraftManager.shared.updateCommentText(value, for: key)
        }
    }
    
    /// 当在ipad上发送回复完成时，清除文本框内容和图片
    func cleariPadInputContentAfterSendIfNeeded() {
        guard !ignoreRotation else {
            return
        }
        let scene = self.commentDraftKey.sceneType
        if case .newReply = scene, SKDisplay.pad {
            textViewSet(attributedText: .init())
            inputTextView?.updatePreviewWithImageInfos([])
        }
    }
}
