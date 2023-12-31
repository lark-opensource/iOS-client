//
//  CommentDraftPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/24.
//  


import UIKit
import SpaceInterface
import SKCommon

class CommentDraftPlugin: CommentPluginType {

    weak var context: CommentServiceContext?

    static let identifier: String = "DraftPlugin"
    
    func apply(context: CommentServiceContext) {
        self.context = context
    }
    
    func mutate(action: CommentAction) {
        switch action {
        case let .ipc(action, _):
            handleIPCAction(action: action)
        default:
            break
        }
    }

    
    func handleIPCAction(action: CommentAction.IPC) {
        switch action {
        case let .setEditDraft(item):
            handleEditDraft(item)
        case let .setReplyDraft(item, atInfo):
            handleReplyDraft(item, atInfo)
        case let .clearDraft(draftKey):
            handleClearDraft(draftKey)
        case let .setNewInputDraft(model):
            handleNewInputDraft(model)
        default:
            break
        }
    }
    
    
}

extension CommentDraftPlugin {
    
    
    /// 设置编辑评论草稿
    /// - Parameter item: 需要编辑的评论
    func handleEditDraft(_ item: CommentItem) {
        let draftKey = item.editDraftKey
        let draftResult = CommentDraftManager.shared.commentModel(for: draftKey)
        
        func setContentToDraft() {
            let text = item.content ?? ""
            let images = item.previewImageInfos.map { CommentDraftImage(from: $0) }
            let model = CommentDraftModel(content: text, imageList: images, originFrom: .edit)
            CommentDraftManager.shared.updateComment(model: model, for: draftKey)
        }
        
        // 没有草稿则保存现有数据作为草稿
        switch draftResult {
        case .failure:
            setContentToDraft()
        case let .success(model):
            if model.content.isEmpty, model.imageList.isEmpty {
                setContentToDraft()
            }
        }
    }

    
    /// 回复的评论草稿
    /// - Parameters:
    ///   - item: 被回复的评论
    ///   - atInfo: 被回复的评论发送人信息
    func handleReplyDraft(_ item: CommentItem, _ atInfo: AtInfo) {
        // 1. 获取草稿
        let draftKey = item.newReplyKey
        let draftResult = CommentDraftManager.shared.commentModel(for: draftKey)
        var text = ""
        var imageInfos: [CommentDraftImage] = []
        if case .success(let model) = draftResult {
            text = model.content
            imageInfos = model.imageList
        }
        // 2. 判断是否需要在文字开头插入at人
        guard CommentDraftManager.shouldInsert(newUserId: item.userID, text: text) else {
            return
        }
        let attributes = AtInfo.TextFormat.defaultAttributes()
        let newUserString = atInfo.attributedString(attributes: attributes, lineBreakMode: .byWordWrapping)
        let atText = AtInfo.encodedString(attributedString: newUserString)
        text = atText + " " + text
        let modle = CommentDraftModel(content: text,
                          imageList: imageInfos,
                          originFrom: .reply)
        CommentDraftManager.shared.updateComment(model: modle, for: draftKey)
    }
    
    func handleClearDraft(_ draftKey: CommentDraftKey) {
        CommentDraftManager.shared.removeCommentModel(forKey: draftKey)
    }
    
    func handleNewInputDraft( _ model: CommentShowInputModel) {
        if model.type == .edit {
            CommentDraftManager.shared.saveCommentDraftWhenEdit(model: model)
        } else {
            CommentDraftManager.shared.saveCommentDraftWhenReply(model: model)
        }
    }
}
