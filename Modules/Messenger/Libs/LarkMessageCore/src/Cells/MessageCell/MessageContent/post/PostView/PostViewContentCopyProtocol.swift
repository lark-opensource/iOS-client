//
//  PostViewContentCopyProtocol.swift
//  LarkMessageCore
//
//  Created by llb on 2020/12/15.
//

import Foundation
import UIKit
import LarkMessageBase
import LarkMessengerInterface
import RichLabel
import LarkSetting
import LKRichView

public protocol PostViewContentCopyProtocol: UIView {
    /// 获取PostViewcopy信息
    /// - Parameters:
    ///   - cell: MessageCommonCell
    ///   - location: 点击点
    func postViewCopyInfoForCell(_ cell: MessageCommonCell, location: CGPoint) -> [String: Any]
    /// 获取PostView点击触发位置信息
    /// - Parameters:
    ///   - cell: MessageCommonCell
    ///   - location: 点击点
    func getPostViewComponentConstant(_ cell: MessageCommonCell, location: CGPoint) -> (String?, CopyMessageType)
}

public extension PostViewContentCopyProtocol {

    func postViewCopyInfoForCell(_ cell: MessageCommonCell, location: CGPoint) -> [String: Any] {
        var copyInfo: [String: Any] = ["copyType": CopyMessageType.message]
        // 点在文本内容里
        if let label = cell.getView(by: PostViewComponentConstant.contentKey),
           label.bounds.contains(self.convert(location, to: label)) {
            copyInfo["copyType"] = CopyMessageType.origin
            copyInfo["contentLabelKey"] = PostViewComponentConstant.contentKey
        }
        // 点在翻译内容里
        if let contentLabel = cell.getView(by: PostViewComponentConstant.translateContentKey),
           contentLabel.bounds.contains(self.convert(location, to: contentLabel)) {
            copyInfo["copyType"] = CopyMessageType.translate
            copyInfo["contentLabelKey"] = PostViewComponentConstant.translateContentKey
        }
        if !copyInfo.keys.contains(MessageCardSurpportCopyKey.contentLabelKey),
           MessageCardSurpportCopyFG.enableCopy {
            copyInfo = self.messageCardcopyInfoForCell(cell, location: location)
            copyInfo[MessageCardSurpportCopyKey.isMessageCard] = true
        }
        return copyInfo
    }

    func getPostViewComponentConstant(_ cell: MessageCommonCell, location: CGPoint) -> (String?, CopyMessageType) {
        var contentLabelKey: String?
        var copyInfo: CopyMessageType = .message
        // 点在文本内容里
        if let label = cell.getView(by: PostViewComponentConstant.contentKey),
           label.bounds.contains(self.convert(location, to: label)) {
            contentLabelKey = PostViewComponentConstant.contentKey
            copyInfo = .origin
        }
        // 点在翻译内容里
        if let contentLabel = cell.getView(by: PostViewComponentConstant.translateContentKey),
           contentLabel.bounds.contains(self.convert(location, to: contentLabel)) {
            contentLabelKey = PostViewComponentConstant.translateContentKey
            copyInfo = .translate
        }
        // 点在卡片内容里
        if contentLabelKey == nil {
            let params = messageCardcopyInfoForCell(cell, location: location)
            if MessageCardSurpportCopyFG.enableCopy,
               let cardContentKey = params[MessageCardSurpportCopyKey.contentLabelKey] as? String,
               let msgCardSelectedViewContent = params[MessageCardSurpportCopyKey.msgCardSelectedViewContent] as? (() -> NSAttributedString) {
                contentLabelKey = cardContentKey
                copyInfo = .card(msgCardSelectedViewContent)
            }
        }
        return (contentLabelKey, copyInfo)
    }

    func messageCardcopyInfoForCell(_ cell: MessageCommonCell, location: CGPoint) -> [String: Any] {
        var copyInfo: [String: Any] = [MessageCardSurpportCopyKey.copyType: CopyMessageType.message]
        if let views = cell.getViews(by: MessageCardSurpportCopyKey.msgCardCopyableBaseKey) {
            for view in views {
                if !view.bounds.contains(self.convert(location, to: view)) {
                    continue
                }
                if let label = view as? LKSelectionLabel,
                   MessageCardSurpportCopyFG.messageCardEnableCopy {
                    copyInfo[MessageCardSurpportCopyKey.contentLabelKey] = label.getASComponentKey()
                    copyInfo[MessageCardSurpportCopyKey.msgCardSelectedViewContent] = { [weak label] in
                        return label?.attributedText ?? NSAttributedString()
                    }
                    return copyInfo
                }
                if let label = view as? LKRichContainerView,
                   MessageCardSurpportCopyFG.newMessageCardEnableCopy {
                    copyInfo[MessageCardSurpportCopyKey.contentLabelKey] = label.getASComponentKey()
                    copyInfo[MessageCardSurpportCopyKey.msgCardSelectedViewContent] = { [weak label] in
                        let attr = label?.richView.getCopyString()?.string ?? ""
                        return NSAttributedString(string: attr)
                    }
                    return copyInfo
                }
            }
        }
        return copyInfo
    }
}

public struct MessageCardSurpportCopyKey {
    // 消息卡片支持复制组件的baseKey
    public static let msgCardCopyableBaseKey = "msgCardCopyableBaseKey"
    // 当前选中组件的所有文本内容
    public static let msgCardSelectedViewContent = "msgCardSelectedViewContent"
    // 当前复制操作是否是消息卡片
    public static let isMessageCard = "isMessageCard"
    // 当前选中组件的componenntKey
    public static let contentLabelKey = "contentLabelKey"
    // 复制源类型，卡片复制中不使用
    public static let copyType = "copyType"
}

public struct MessageCardSurpportCopyFG {
    //richtext消息卡片支持复制FG
    @FeatureGatingValue(key: "messagecard.surpportcopy.enable")
    public static var messageCardEnableCopy: Bool
    //jsoncard消息卡片支持复制FG
    @FeatureGatingValue(key: "messagecard.jsoncardsurpportcopy.enable")
    public static var newMessageCardEnableCopy: Bool
    public static var enableCopy: Bool {
        return newMessageCardEnableCopy || messageCardEnableCopy
    }
}
