//
//  CommentDraftManager.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/9.
//


import Foundation
import SKFoundation
import SpaceInterface
import SKCommon
import SKInfra

/// 评论草稿管理器
public final class CommentDraftManager: CCMTextDraftManager, CommentDraftManagerInterface {
    
    
    public static let shared = CommentDraftManager()
    
    private init() {
        let path: String = "draft_comment"
        super.init(path: path)
        setupNotification()
    }
}

extension CommentDraftManager {
    
    /// 更新评论草稿中的文字和图片
    @discardableResult
    public func updateComment(model: CommentDraftModel, for key: CommentDraftKey) -> Bool {
        if model.content.isEmpty && model.imageList.isEmpty {
            removeCommentModel(forKey: key)
            return true
        }
        return updateModel(model, forKey: key)
    }
    
    /// 更新评论草稿中的文字
    @discardableResult
    public func updateCommentText(_ text: String, for key: CommentDraftKey) -> Bool {
        let result = commentModel(for: key)
        let imageList: [CommentDraftImage]
        switch result {
        case .success(let oldModel):
            imageList = oldModel.imageList
        case .failure:
            imageList = []
        }
        let newModel = CommentDraftModel(content: text, imageList: imageList)
        if newModel.content.isEmpty && newModel.imageList.isEmpty {
            removeCommentModel(forKey: key)
            return true
        }
        return updateModel(newModel, forKey: key)
    }
    
    /// 更新评论草稿中的图片
    @discardableResult
    public func updateCommentImages(_ images: [CommentDraftImage], for key: CommentDraftKey) -> Bool {
        //debugPrint("feat: comment draft: image:\(images), for key:\(key)")
        let result = commentModel(for: key)
        let content: String
        switch result {
        case .success(let oldModel):
            content = oldModel.content
        case .failure:
            content = ""
        }
        let newModel = CommentDraftModel(content: content, imageList: images)
        if newModel.content.isEmpty && newModel.imageList.isEmpty {
            removeCommentModel(forKey: key)
            return true
        }
        return updateModel(newModel, forKey: key)
    }
    
    /// 获取评论草稿model
    public func commentModel(for key: CommentDraftKey) -> Swift.Result<CommentDraftModel, Error> {
        let result: Swift.Result<CommentDraftModel, Error> = getModel(forKey: key)
        if case .success(var model) = result {
            model.markAccessed()
            updateModel(model, forKey: key)
        }
        return result
    }
    
    /// 获取评论草稿model
    public func commentContent(for key: CommentDraftKey, textFont: UIFont, docsInfo: DocsInfo?, checkPermission: Bool) -> CommentContent? {
        let result: Swift.Result<CommentDraftModel, Error> = getModel(forKey: key)
        if case .success(let model) = result {
            let attributes = AtInfo.TextFormat.defaultAttributes(font: textFont, textColor: UIColor.ud.textTitle)
            let xmlParser = AtInfoXMLParserImp()
            let attrText = xmlParser.decodedAttrString(model: model, attributes: attributes, token: docsInfo?.token ?? "", type: docsInfo?.type, checkPermission: checkPermission)
            let imageList = model.imageList.map { $0.lagacyModel() }
            return CommentContent(content: model.content,
                                  imageInfos: imageList,
                                  pcmData: nil,
                                  pcmDataTime: nil,
                                  attrContent: attrText,
                                  isAudio: false)
        } else {
            return nil
        }
    }
    
    /// 删除指定评论草稿
    public func removeCommentModel(forKey key: CommentDraftKey) {
        removeModel(forKey: key)
    }
    
    /// 移除过期的model（超过seconds秒数未访问的）
    @discardableResult
    public func removeExpiredModels(seconds: Int? = nil) -> Bool {
        let oneDaySeconds = 1 * 24 * 60 * 60 // 兜底1天
        let targetSeconds = SettingConfig.commentDraftConfig?.draftValidityPeriod ?? oneDaySeconds
        let deltaSeconds = seconds ?? targetSeconds // 相差的秒数
        let filter: (Data) -> Bool = { data in // 过滤出过期的草稿key
            if let model = try? JSONDecoder().decode(CommentDraftModel.self, from: data) {
                let now = Int64(CFAbsoluteTimeGetCurrent())
                let expired = (now - model.lastAccessTime > deltaSeconds)
                return expired
            }
            return false
        }
        mmkvStorage.removeAllData(filter: filter)
        DocsLogger.info("comment draft cleaned: deltaSeconds:\(deltaSeconds)")
        return true
    }
}

private enum CommentDraftError: LocalizedError {
    case featureDisabled
    
    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "feature disabled"
        }
    }
}

extension CommentDraftManager {
    
    /// 回复某人的评论时，是否需要在头部新插入该用户: 新的atinfo与旧的一致则不插入，否则插入
    public static func shouldInsert(newUserId: String, currentAttrString: NSAttributedString?) -> Bool {
        guard let currentAttrText = currentAttrString else {
            return true
        }
        let currentEncodedText = AtInfo.encodedString(attributedString: currentAttrText)
        return shouldInsert(newUserId: newUserId, text: currentEncodedText)
    }
    
    public static func shouldInsert(newUserId: String, text: String) -> Bool {
        guard let regex = AtInfo.mentionRegex else {
            return true
        }
        let results = try? AtInfo.parseMessageContent(in: text, pattern: regex,
                                                      makeInfo: AtInfoXMLParser.getMentionDataFrom)
        if let firstItem = results?.first, case .atInfo(let oldInfo) = firstItem {
            return oldInfo.token != newUserId
        }
        return true
    }
}
