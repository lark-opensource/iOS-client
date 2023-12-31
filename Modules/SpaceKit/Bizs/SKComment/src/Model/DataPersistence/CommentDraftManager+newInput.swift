//
//  CommentDraftManager+newInput.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/21.
//  


import Foundation
import SpaceInterface
import SKCommon

extension CommentDraftManager {
    
    func newInputViewModelGetCommentDraft(atInputTextView: AtInputTextView?,
                                          permissionBlock: PermissionQuerryBlock?) -> (NSAttributedString, [CommentImageInfo]) {
        
        var attributedText = NSAttributedString(string: "")
        var imageInfos = [CommentImageInfo]()
        
        if let draftKey = atInputTextView?.commentDraftKey {
            let draftResult: Swift.Result<CommentDraftModel, Error> = CommentDraftManager.shared.commentModel(for: draftKey)
            if case .success(let model) = draftResult {
                let attrText = model.decodedAttrString(attributes: AtInfo.TextFormat.defaultAttributes(),
                                                       permissionBlock: permissionBlock)
                let images = model.imageList.map { $0.lagacyModel() }
                attributedText = attrText
                imageInfos = images
            }
        }
        
        return (attributedText, imageInfos)
    }

    /// 编辑评论时，先保存为草稿
    func saveCommentDraftWhenEdit(model: CommentShowInputModel) -> (String, [CommentImageInfo]) {
        let draftResult: Swift.Result<CommentDraftModel, Error> = CommentDraftManager.shared.commentModel(for: model.draftKey)
        switch draftResult {
        case .success(let oldModel):
            let images = oldModel.imageList.map { $0.lagacyModel() }
            let newModel = CommentDraftModel(content: oldModel.content, imageList: oldModel.imageList) // 去除originFrom
            CommentDraftManager.shared.updateComment(model: newModel, for: model.draftKey)
            return (oldModel.content, images)
        case .failure:
            let content = model.content ?? ""
            let imageInfos = model.extra?.imageList ?? []
            let images = imageInfos.map { CommentDraftImage(from: $0) }
            let draftModel = CommentDraftModel(content: content, imageList: images, originFrom: .edit)
            CommentDraftManager.shared.updateComment(model: draftModel, for: model.draftKey)
            return (content, imageInfos)
        }
    }
    
    /// 回复评论时，先保存为草稿
    func saveCommentDraftWhenReply(model: CommentShowInputModel) -> (String, [CommentImageInfo]) {
        let draftResult: Swift.Result<CommentDraftModel, Error> = CommentDraftManager.shared.commentModel(for: model.draftKey)
        switch draftResult {
        case .success(let draft):
            let images = draft.imageList.map { $0.lagacyModel() }
            var newEncoded: String = draft.content
            if let originContent = model.content, // 前端传了文字
               !originContent.isEmpty {
                // 看前端是否有@人的文本
                let newUserText = originContent.trimmingCharacters(in: .whitespaces)
                let noNeedInsertUser = newEncoded.hasPrefix(newUserText) && !newUserText.isEmpty
                if !noNeedInsertUser { // 带了@ 人的文本但是草稿没有，在草稿补上
                    newEncoded = newUserText + " " + newEncoded
                    let newDraft = CommentDraftModel(content: newEncoded, imageList: draft.imageList) // 去除originFrom
                    CommentDraftManager.shared.updateComment(model: newDraft, for: model.draftKey)
                }
            }
            return (newEncoded, images)
        case .failure:
            let content = model.content ?? ""
            let imageInfos = model.extra?.imageList ?? []
            let images = imageInfos.map { CommentDraftImage(from: $0) }
            let draftModel = CommentDraftModel(content: content, imageList: images, originFrom: .reply)
            CommentDraftManager.shared.updateComment(model: draftModel, for: model.draftKey)
            return (content, imageInfos)
        }
    }
}
