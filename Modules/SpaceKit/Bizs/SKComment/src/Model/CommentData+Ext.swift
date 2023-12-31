//
//  CommentData+Ext.swift
//  SKCommon
//
//  Created by huayufan on 2022/5/7.
//  
//  swiftlint:disable file_length

import SKFoundation
import SpaceInterface
import SwiftyJSON
import SKResource
import SKUIKit
import SKCommon

extension Array where Element == CommentItem {
    
    func safe(index: Int) -> CommentItem? {
        guard self.count > index, index >= 0 else {
            DocsLogger.error("get commentItem index:\(index) count:\(self.count) error", component: LogComponents.comment)
            spaceAssertionFailure("index error")
            return nil
        }
        return self[index]
    }
}

public extension Array where Element == Comment {
    
    func indexPath(of commentId: String, replyId: String) -> IndexPath? {
        guard let i = self.firstIndex(where: { $0.commentID == commentId }) else {
            return nil
        }
        let comment = self[i]
        if comment.interactionType == .reaction { // 表情卡片因为只有单条，所以直接定位到该条
            let reactionCardIndex = comment.commentList.lastIndex(where: { $0.uiType.isNormal })
            if let row = reactionCardIndex {
                return IndexPath(row: row, section: i)
            } else {
                return nil
            }
        }
        guard let j = comment.commentList.firstIndex(where: { $0.scrollReplyId == replyId }) else {
            return nil
        }
        return IndexPath(row: j, section: i)
    }
}



extension CommentItem {
    
    var showMore: Bool {
        return permission.contains(.canShowMore)
    }
    
    var showReaction: Bool {
        return permission.contains(.canReaction)
    }
    
    var showVoice: Bool {
        return permission.contains(.canShowVoice)
    }
    
    var canComment: Bool {
        return permission.contains(.canComment)
    }
    
    var padFont: UIFont {
        let fontZoomable = docsInfo?.fontZoomable ?? false
        return fontZoomable ? UIFont.ud.body2 : UIFont.systemFont(ofSize: 14)
    }
    

    var typeSupported: Bool {
        return replyType != nil
    }

    func getAttributeCache(content: String, font: UIFont) -> NSAttributedString? {
        let cacheKey = "\(content)_\(font.lineHeight)"
        return attrCache[cacheKey]
    }
    
    
    /// 返回格式化后的富文本
    /// - Parameters:
    ///   - selfNameMaxWidth: 高亮显示自己名字的最大宽度，0表示无限制
    ///   - permissionBlock: 人名高亮
    func attrContent(font: UIFont, color: UIColor, lineSpacing: CGFloat?, lineBreakMode: NSLineBreakMode?,
                     selfNameMaxWidth: CGFloat = 0, permissionBlock: PermissionQuerryBlock?) -> NSAttributedString? {

        var attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let style = NSMutableParagraphStyle()
        if let lineSpacing = lineSpacing {
            style.lineSpacing = lineSpacing
            attributes[.paragraphStyle] = style
        }
        // 新版loading 设置字符串换行模式
        if let lineBreakMode = lineBreakMode {
            style.lineBreakMode = lineBreakMode
            attributes[.paragraphStyle] = style
        }
        // 小程序场景，同个用户，小程序的用户token和登陆的user token不一样
        // 需要对比前端返回的commentUser token才能确定是否是 @ 自己
        var userId: String?
        if let docsInfo = docsInfo,
           let commentUser = docsInfo.commentUser,
           commentUser.useOpenId {
            userId = commentUser.id
        }
        if let attr = getAttributeCache(content: content ?? "", font: font) {
            return attr
        } else {
            return AtInfoXMLParser.attrString(encodeString: content ?? "",
                                     attributes: attributes,
                                     useSelfCache: true,
                                     permissionBlock: permissionBlock,
                                     userId: userId,
                                     selfNameMaxWidth: selfNameMaxWidth
                                     ).docs.urlAttributed
        }

    }

    
    func attrTranslationContent(font: UIFont, color: UIColor, lineSpacing: CGFloat?, lineBreakMode: NSLineBreakMode?, permissionBlock: PermissionQuerryBlock?, needUrlAttributed: Bool = false) -> NSAttributedString? {
        // 不支持的类型不展示
        var attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let style = NSMutableParagraphStyle()
        if let lineSpacing = lineSpacing {
            style.lineSpacing = lineSpacing
            attributes[.paragraphStyle] = style
        }
        // 新版loading 设置字符串换行模式
        if let lineBreakMode = lineBreakMode {
            style.lineBreakMode = lineBreakMode
            attributes[.paragraphStyle] = style
        }
        
        if let attr = getAttributeCache(content: translateContent ?? "", font: font) {
            return attr
        } else {
            if needUrlAttributed {
                return AtInfoXMLParser.attrString(encodeString: translateContent ?? "",
                                         attributes: attributes,
                                         useSelfCache: true,
                                         permissionBlock: permissionBlock
                                         ).docs.urlAttributed
            } else {
                return AtInfoXMLParser.attrString(encodeString: translateContent ?? "",
                                         attributes: attributes,
                                         useSelfCache: true,
                                         permissionBlock: permissionBlock)
            }
            
        }

    }
    
    // 国际化后的别名
    public var displayName: String? {
        if let displayName = aliasInfo?.currentLanguageDisplayName {
            return displayName
        } else {
            return name ?? ""
        }
    }
    
    var errorMsgFromCode: String {
        if let enumError = enumError {
            return enumError.errorMsg
        } else { // 返回默认
            return BundleI18n.SKResource.CreationMobile_Error_Comment_UnableToSend
        }
    }
}

// MARK: - VC Follow
extension CommentItem {
    var scrollReplyId: String {
        switch uiType {
        case .normal_reply, .normal_reaction, .unsupported:
            return replyID
        case .header:
            return "IN_HEADER"
        case .footer:
            return ""
        }
    }
}

// MARK: - Cache
extension CommentItem {
    var cacheKey: String {
        if errorCode == ErrorCode.loadImageError.rawValue {
            return "\(replyID) + \(errorCode)"
        }
        return replyID
    }
}


extension CommentItem: CommentTranslationStore {
    
    public var key: String {
       return "\(commentId ?? "")_\(replyID)"
    }
}


extension CommentItem.ErrorCode {
    var errorMsg: String {
        switch self {
        case .network:
            return BundleI18n.SKResource.CreationMobile_Error_Comment_NetworkError
        case .permission:
            return BundleI18n.SKResource.CreationMobile_Error_Comment_NoPerm
        case .violateTOS1, .violateTOS2:
            return BundleI18n.SKResource.Doc_Review_Fail_Notify_Member()
        case .loadImageError:
            return BundleI18n.SKResource.CreationMobile_Error_Comment_UnableToLoadImage
        case .mgError1, .mgError2:
            return BundleI18n.SKResource.CreationMobile_Error_Comment_NotSupported
        case .preparingData:
            return BundleI18n.SKResource.CreationMobile_Error_Comment_PreparingData
        }
    }
    
    var canDeleteComment: Bool {
        return self != .loadImageError
    }
}

extension CommentItem.UIType {
    
    public var padUIIdentify: String {
        switch self {
        case .header:
            return AsideCommentView.ipadHeadCellId
        case .normal_reply:
            return AsideCommentView.ipadBodyCellId
        case .normal_reaction:
            return ContentReactionPadCell.cellId
        case .footer:
            return AsideCommentView.ipadFooterCellId
        case .unsupported:
            return CommentUnsupportedCell.reusePadIdentifier
        }
    }
    
    public var phoneUIIdentify: String {
        switch self {
        case .header:
            return CommentQuoteAndReplyCell.cellId
        case .normal_reply:
            return CommentTableViewCellV2.cellId
        case .normal_reaction:
            return ContentReactionPhoneCell.cellId
        case .footer: // 暂无footer
            return ""
        case .unsupported:
            return CommentUnsupportedCell.reusePhoneIdentifier
        }
    }
}


extension Comment: CustomStringConvertible {
    
    var showResolve: Bool {
        return permission.contains(.canResolve)
    }

    public var description: String {
        var quote = ""
#if DEBUG || BETA
        quote = self.quote ?? ""
#endif
        return "commentId:\(commentID) quote:\(quote)"
    }
}

private class CommentPropertyWrapper: NSObject {
    var value: Any?
    init(_ info: Any) {
        self.value = info
    }
}



// MARK: - 业务字段

private struct CommentPropertyAssociatedKey {
    static var docsInfo = "docsInfo"
    static var aliasInfo = "aliasInfo"
}


//extension Comment {
//    var docsInfo: DocsInfo? {
//        get {
//            let obj = objc_getAssociatedObject(self, &CommentPropertyAssociatedKey.docsInfo) as? CommentPropertyWrapper
//            return obj?.value as? DocsInfo
//        }
//        set {
//            let obj = newValue.map { CommentPropertyWrapper($0) }
//            objc_setAssociatedObject(self, &CommentPropertyAssociatedKey.docsInfo, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//}

//extension CommentItem {
//    var docsInfo: DocsInfo? {
//        get {
//            let obj = objc_getAssociatedObject(self, &CommentPropertyAssociatedKey.docsInfo) as? CommentPropertyWrapper
//            return obj?.value as? DocsInfo
//        }
//        set {
//            let obj = newValue.map { CommentPropertyWrapper($0) }
//            objc_setAssociatedObject(self, &CommentPropertyAssociatedKey.docsInfo, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//
//    var aliasInfo: UserAliasInfo? {
//        get {
//            let obj = objc_getAssociatedObject(self, &CommentPropertyAssociatedKey.aliasInfo) as? CommentPropertyWrapper
//            return obj?.value as? UserAliasInfo
//        }
//        set {
//            let obj = newValue.map { CommentPropertyWrapper($0) }
//            objc_setAssociatedObject(self, &CommentPropertyAssociatedKey.aliasInfo, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//        }
//    }
//}
