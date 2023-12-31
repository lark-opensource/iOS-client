//
//  FeedMessageModel+DataSource.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/14.
//  


import UIKit
import SKFoundation
import SKResource
import UniverseDesignIcon
import LarkEmotion
import SpaceInterface
import SKInfra

// MARK: - 只有UI想知道的字段

extension FeedMessageModel: FeedCellDataSource {
    
    var typeSupported: Bool {
        return type != nil
    }

    var avatarResouce: (url: String?, placeholder: UIImage?, defaultDocsImage: UIImage?) {
        if typeSupported {
            return (url: avatarUrl, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder, defaultDocsImage: nil)
        } else {
            return (url: avatarUrl, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder, defaultDocsImage: UDIcon.fileRoundDocColorful)
        }
    }
    
    private static var contentCanCopyKey = UInt8(0)
    
    var contentCanCopy: Bool {
        get {
            return (objc_getAssociatedObject(self, &Self.contentCanCopyKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &Self.contentCanCopyKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    private static var feedFormattedTitleKey = UInt8(0)
    
    var titleText: String { // 组装一次，之后复用
        guard typeSupported else {
            // 不支持的类型显示默认文案
            return BundleI18n.SKResource.LarkCCM_Docs_Feed_VersionCompatibility
        }
        if let value = objc_getAssociatedObject(self, &Self.feedFormattedTitleKey) as? String {
            return value
        }
        // TODO: displayName 待后续接入
//        let value = self.autoStyled.titleTextFormatter(displayName)
        let value = self.autoStyled.titleTextFormatter(name)
        objc_setAssociatedObject(self, &Self.feedFormattedTitleKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return value
    }
    
    var quoteText: String? {
        let string = self.autoStyled.shouldDisplayQuoteText ? quote : nil
        let trimed = string?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimed
    }
    
    func getContentConfig(result: @escaping (FeedMessageContent) -> Void) {
        formatMessage()
        guard typeSupported else {
            result(.init(text: nil, actions: [], translateStatus: nil))
            return
        }
        // 如果点击了翻译，并且翻译偏好设置设为【仅译文】，返回的是翻译的内容
        let isShowTranslation = showTranslation()
        if isShowTranslation, checkShowTranslateAlone() == false {
            getTranslateConfig(skipCondition: true) { [weak self] (res) in
                let actions: [FeedContentView.MenuAction]
                if self?.contentCanCopy ?? false {
                    actions = [.copy, .showOriginal]
                } else {
                    actions = [.showOriginal]
                }
                result(.init(text: res.text, actions: actions, translateStatus: res.translateStatus))
            }
            return
        }
        var actions: [FeedContentView.MenuAction] = []
        if !self.content.isEmpty {
            if contentCanCopy {
                actions.append(.copy)
            }
           if !isShowTranslation, canTranslation() {
               actions.append(.translate)
           }
        }
        
        // AtInfo.attrString方法比较耗时，懒加载处理，并将结果保存起来。
        if let contentAttiStr = contentAttiString {
            result(.init(text: contentAttiStr, actions: actions, translateStatus: nil))
        } else {
            if self.type == .docsReaction {
                self.contentAttiString = Self.getReactionAttrString(contentReactionKey: contentReactionKey)
            } else {
                self.contentAttiString = Self.getContentAttrString(content: content)
            }
            result(.init(text: self.contentAttiString, actions: actions, translateStatus: nil))
        }
    }
    
    static func parsingAttrString(encodeString: String,
                           attributes: [NSAttributedString.Key: Any],
                           atSelfYOffset: CGFloat? = nil,
                           atInfoTransform: ((AtInfo) -> AtInfo)?) -> NSAttributedString {
        guard let xmlParser =  DocsContainer.shared.resolve(AtInfoXMLParserInterface.self) else {
            DocsLogger.error("xmlParser not found")
            return NSAttributedString()
        }
        return xmlParser.attrString(encodeString: encodeString, attributes: attributes, isHighlightSelf: true, useSelfCache: true, lineBreakMode: .byWordWrapping, permissionBlock: nil, userId: nil, selfNameMaxWidth: 0, atSelfYOffset: atSelfYOffset, atInfoTransform: atInfoTransform)
    }

    public static func getContentAttrString(content: String, attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16)], atSelfYOffset: CGFloat? = nil) -> NSAttributedString {
        let atInfoTransform: (AtInfo) -> AtInfo = { info in
            let user = MentionedEntityLocalizationManager.current.getUserById(info.token)
            if let user = user { // 这个at是人
                return AtInfo(type: info.type, href: info.href, token: info.token, at: user.localizedName)
            }
            let meta = MentionedEntityLocalizationManager.current.getDocMetaByToken(info.token)
            if let meta = meta, let newTitle = meta.localizedTitle { // 这个at是文档
                return AtInfo(type: info.type, href: info.href, token: info.token, at: newTitle)
            }
            return info
        }
        let attrString = Self.parsingAttrString(encodeString: content, attributes: attributes, atSelfYOffset: atSelfYOffset, atInfoTransform: atInfoTransform)
        return attrString.docs.urlAttributed
    }
    
    public static func getReactionAttrString(contentReactionKey: String, targetHeight: CGFloat = 20, yOffset: CGFloat? = nil) -> NSAttributedString {
        let image = EmotionResouce.shared.imageBy(key: contentReactionKey) // e.g. "OK"
        let attachment = NSTextAttachment()
        attachment.image = image
        let height: CGFloat = targetHeight // 20的实际效果是高度24
        let size = image?.calculatedSize(targetHeight: height) ?? CGSize(width: height, height: height)
        attachment.bounds = CGRect(origin: .init(x: 0, y: yOffset ?? 0), size: size)
        return NSAttributedString(attachment: attachment)
    }
    
    func getTranslateConfig(result: @escaping (FeedMessageContent) -> Void) {
        formatMessage()
        self.getTranslateConfig(skipCondition: false, result: result)
    }
    
    func getTranslateConfig(skipCondition: Bool = false, result: @escaping (FeedMessageContent) -> Void) {
        if !skipCondition {
            guard showTranslation(), checkShowTranslateAlone() else {
                result(.init(text: nil, actions: [], translateStatus: nil))
                return
            }
        }
        if let translateAttiString = self.translateAttiString {
            let actions: [FeedContentView.MenuAction]
            if contentCanCopy {
                actions = [.copy]
            } else {
                actions = []
            }
            result(.init(text: translateAttiString, actions: actions, translateStatus: showTranslateIconState()))
        } else {
            let translateContent: String? = self.translateContent
            guard let transContent = translateContent else {
                result(.init(text: nil, actions: [], translateStatus: nil))
                return
            }
            let attrString = Self.parsingAttrString(encodeString: transContent, attributes: [.font: UIFont.systemFont(ofSize: 16)], atInfoTransform: nil)
            let translateAttiStr = attrString.docs.urlAttributed
            let actions: [FeedContentView.MenuAction]
            if contentCanCopy {
                actions = [.copy]
            } else {
                actions = []
            }
            result(.init(text: translateAttiStr, actions: actions, translateStatus: showTranslateIconState()))
            self.translateAttiString = translateAttiStr
        }
    }
    
    func getTime(time: @escaping (String) -> Void) {
        var createTime = ""
        if self.type == .mention ||
            self.type == .share ||
            self.type == .docsReaction ||
            self.subType == .commentSolve ||
            self.subType == .commentReopen ||
            self.subType == .reaction ||
            self.subType == .like {
            createTime = self.createTime.stampDateFormatter
        } else {
            createTime = self.commentCreateTime.stampDateFormatter
        }
        createTime = createTime.trimmingCharacters(in: .whitespaces) // 使UI左对齐
        time(createTime)
    }
    
    /// 是否展示未读小红点
    var showRedDot: Bool {
        return status == .unread
    }
    
    /// 展示评论和不展示评论分为两种UI Identifier
    var cellIdentifier: String {
        self.autoStyled.feedCellReuseId
    }
}

// MARK: - 翻译相关

extension FeedMessageModel: CommentTranslationStore {
    
    public var key: String {
       return "\(commentId)_\(replyId)"
    }
    
    var translationTools: CommentTranslationToolProtocol?  {
        guard let tool = DocsContainer.shared.resolve(CommentTranslationToolProtocol.self) else {
            DocsLogger.feedError("translationTools is nil")
            return nil
        }
        return tool
    }
    /// 是否展示翻译
    func showTranslation() -> Bool {
        guard translateContent?.isEmpty == false else {
            return false
        }
        let type = SpaceTranslationCenter.standard.displayType
        guard type == .onlyShowTranslation || type == .bothShow else {
            return false
        }
        let contain = translationTools?.contain(store: self) ?? false
        return !contain
    }
    
    /// 是否一行单独显示翻译。 只有上面checkIsShowTranslate返回true才有意义
    /// true-在原评论下面显示翻译; false - 翻译替换原评论内容
    func checkShowTranslateAlone() -> Bool {
        guard showTranslation() else {
            return false
        }
        return SpaceTranslationCenter.standard.displayType == .bothShow
    }
    
    /// 支持翻译功能
    func canTranslation() -> Bool {
        let type = SpaceTranslationCenter.standard.displayType
        guard type != .unKnown else {
            return false
        }
        return true
    }
    /// 有三种状态： 隐藏，loading，静止显示
    func showTranslateIconState() -> FeedContentView.TranslateStatus? {
        guard SpaceTranslationCenter.standard.enableCommentTranslate, showTranslation() else {
            return nil
        }
        guard let state = translateStatus else {
            return nil
        }
        switch state {
        case .loading:
            return .play
        case .success, .error:
            return .stop
        }
    }
}

extension UIImage {
//    /// 缩放至目标高度
//    fileprivate func scaledTo(targetHeight: CGFloat) -> UIImage {
//        let currentHeight = max(1, size.height)
//        let ratio = size.width / currentHeight // 宽/高
//        let targetWidth = ratio * targetHeight
//        let size = CGSize(width: targetWidth, height: targetHeight)
//        UIGraphicsBeginImageContext(size)
//        draw(in: CGRect(origin: .zero, size: size))
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return newImage ?? self
//    }
    
    fileprivate func calculatedSize(targetHeight: CGFloat) -> CGSize {
        let currentHeight = max(1, size.height)
        let ratio = size.width / currentHeight // 宽/高
        let targetWidth = ratio * targetHeight
        let size = CGSize(width: targetWidth, height: targetHeight)
        return size
    }
}
