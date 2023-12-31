//
//  CopyAttributedStringConverter.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/1/10.
//

import Foundation
import UIKit
import LarkRichTextCore
import RustPB
import LarkEMM
import LarkFeatureGating
import LarkMessengerInterface
import LarkContainer
import ByteWebImage
import LarkModel
import LKCommonsLogging
import LarkSDKInterface
import LarkSensitivityControl
import LarkBaseKeyboard
import UniverseDesignToast
import LarkMessageBase
import LarkCore
import LarkSetting

/// TODO: 图片 & 视频保存key的问题 现在的不太合理
class SecurityConfig {
    private static let logger = Logger.log(SecurityConfig.self, category: "SecurityConfig")

    var hasAuthority: Bool = false

    func checkAuthority(message: Message, chat: Chat, chatSecurityControlService: ChatSecurityControlService) -> SecurityConfig {
        let anonymousId = chat.anonymousId
        let canPreview = chatSecurityControlService.checkPermissionPreview(anonymousId: anonymousId,
                                                                    message: message).0
        let canCopy = chatSecurityControlService.checkPermissionFileCopy(anonymousId: anonymousId,
                                                                         message: message,
                                                                         ignoreSecurityOperate: true).0
        hasAuthority = canCopy && canPreview
        Self.logger.info("checkPermissionPreview message.id: \(message.id) chatId: \(message.channel.id) canPreview \(canPreview) - canCopy \(canCopy)")
        return self
    }

    static func showCopyPermissionAlertIfNeed(message: Message, chat: Chat, chatSecurityControlService: ChatSecurityControlService) {
        let anonymousId = chat.anonymousId
        let canCopy = chatSecurityControlService.checkPermissionFileCopy(anonymousId: anonymousId,
                                                                         message: message,
                                                                         ignoreSecurityOperate: false).0
        Self.logger.info("showAlertIfNeed message.id: \(message.id) chatId: \(message.channel.id) - canCopy \(canCopy)")
    }
}

public class CopyToPasteboardManager {
    private static let logger = Logger.log(CopyToPasteboardManager.self, category: "CopyToPasteboardManager")

    public enum FileAuthority {
        case message(Message, Chat, ChatSecurityControlService)
        case canCopy(Bool)
    }

    /// 有关消息复制的权限判断+埋点+弹toast的收敛方法
    /// - Parameters:
    ///   - attr: 选中的富文本
    ///   - message: 消息实体
    ///   - chat: 会话实体
    ///   - byCommand: 是否通过键盘快捷键触发
    ///   - pasteboardToken: 安全侧提供的唯一PasteboardToken
    ///   - targetVC: 弹Toast的目标ViewController
    public static func msgCopyToPasteboardFormAttribute(_ attr: NSAttributedString,
                                                        message: Message,
                                                        chat: Chat,
                                                        chatSecurityControlService: ChatSecurityControlService,
                                                        selectedType: CopyMessageSelectedType,
                                                        byCommand: Bool = false,
                                                        pasteboardToken: String,
                                                        toastFromVC targetVC: UIViewController?,
                                                        fgService: FeatureGatingService) {
        var allSelect = false
        if case .all = selectedType { allSelect = true }
        IMCopyPasteMenuTracker.trackCopy(chat: chat, message: message, byCommand: false, allSelect: allSelect, text: attr)
        if CopyToPasteboardManager.copyToPasteboardFormAttribute(attr,
                                                                 fileAuthority: .message(message, chat, chatSecurityControlService),
                                                                 pasteboardToken: pasteboardToken,
                                                                 fgService: fgService) {
            guard let window = targetVC?.view.window else { return }
            UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_Legacy_JssdkCopySuccess, on: window)
        } else {
            guard let window = targetVC?.view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
        }
    }

    @discardableResult
    public static func copyToPasteboardFormAttribute(_ attr: NSAttributedString,
                                                     fileAuthority: FileAuthority,
                                                     pasteboardToken: String,
                                                     fgService: FeatureGatingService) -> Bool {
        if pasteboardToken.isEmpty {
            assertionFailure("pasteboardToken is empty")
        }
        if LarkPasteboardConfig.useRedesign {
            return usePbJsonConfigPasteboardFrom(attr: attr, fileAuthority: fileAuthority,
                                                 pasteboardToken: pasteboardToken,
                                                 fgService: fgService)
        } else {
            return useStyleItemsConfigPasteboardFrom(attr: attr)
        }
    }

    @discardableResult
    public static func useStyleItemsConfigPasteboardFrom(attr: NSAttributedString) -> Bool {
        // TODO: 暂时不接管控，以后会废弃
        SCPasteboard.generalPasteboard().string = attr.string
        let items = Self.getStyleItemsFrom(copy: attr)
        items.forEach { item in
            SCPasteboard.generalPasteboard().addItems(item)
        }
        return true
    }

    public static func getStyleItemsFrom(copy: NSAttributedString) -> [[[String: Any]]] {
        var items: [[[String: Any]]] = []
        // 向剪切板里面添加字体相关信息
        let style = FontStyleItemProvider.styleForAttributedString(copy)
        if !style.isEmpty, let json = FontStyleItemProvider.JSONStringWithStyle(style, content: copy.string) {
            items.append([[FontStyleItemProvider.typeIdentifier: json]])
        }
        // 向剪切板里面添加emojiKey相关信息
        let emoji = EmojiItemProvider.emojiKeyForAttributedString(copy)
        if !emoji.isEmpty, let json = EmojiItemProvider.JSONStringWithEmoji(emoji, content: copy.string) {
            items.append([[EmojiItemProvider.emojiIdentifier: json]])
        }
        // 向剪切板里面添加代码块相关信息
        let code = CodeItemProvider.codeKeyForAttributedString(copy)
        if !code.isEmpty, let json = CodeItemProvider.JSONStringWithCode(code, content: copy.string) {
            items.append([[CodeItemProvider.codeIdentifier: json]])
        }
        return items
    }

    // nolint: long_function
    @discardableResult
    private static func usePbJsonConfigPasteboardFrom(attr: NSAttributedString,
                                                      fileAuthority: FileAuthority,
                                                      pasteboardToken: String,
                                                      fgService: FeatureGatingService) -> Bool {
        let resourcesCopyFG = fgService.staticFeatureGatingValue(with: "messenger.message.copy")
        let atCopyFG = fgService.staticFeatureGatingValue(with: "messenger.input.copy_@")

        let config = PasteboardConfig(token: Token(pasteboardToken))
        do {
            try SCPasteboard.generalUnsafe(config).string = attr.string
        } catch {
            // 复制失败兜底逻辑
            Self.logger.error("PasteboardConfig init fail token:\(pasteboardToken)")
            return false
        }

        var needToSaveJson = false
        let keys: [NSAttributedString.Key] = [FontStyleConfig.underlineAttributedKey,
                                              FontStyleConfig.strikethroughAttributedKey,
                                              FontStyleConfig.italicAttributedKey,
                                              FontStyleConfig.boldAttributedKey]
        for key in keys {
            if needToSaveJson {
                break
            }
            attr.enumerateAttribute(key, in: NSRange(location: 0, length: attr.length)) { value, _, stop in
                if value != nil {
                    needToSaveJson = true
                    stop.pointee = true
                }
            }
        }

        let processor: RichViewAttributeStringProcessor
        switch fileAuthority {
        case .message(let message, _, _):
            processor = RichViewAttributeStringProcessor(fromMessage: message, attr: attr)
        default:
            processor = RichViewAttributeStringProcessor(fromMessage: nil, attr: attr)
        }

        if processor.handleEmoji() { needToSaveJson = true }
        if processor.handleCodeBlock() { needToSaveJson = true }
        var copyMessage: Message?
        if resourcesCopyFG {
            let block: (Bool) -> Bool = { canCopy in
                let value = processor.handleImageAndVideo(canCopy: canCopy)
                if value.needHandle { needToSaveJson = true }
                return value.interceptCopyResource
            }
            switch fileAuthority {
            case .message(let message, let chat, let chatSecurityControlService):
                copyMessage = message
                let config = SecurityConfig().checkAuthority(message: message,
                                                             chat: chat,
                                                             chatSecurityControlService: chatSecurityControlService)
                /// 如果因为权限的问题 导致了不能弹出图片 需要给用户提示
                if block(config.hasAuthority) {
                    SecurityConfig.showCopyPermissionAlertIfNeed(message: message,
                                                                 chat: chat,
                                                                 chatSecurityControlService: chatSecurityControlService)
                }
            case .canCopy(let copy):
                _ = block(copy)
            }
        }

        var isSingleUrlInLine: Bool = false
        if TextViewCustomPasteConfig.useNewPasteFG {
            let value = processor.handleAnchorAndLink()
            if value.needHandle { needToSaveJson = true }
            isSingleUrlInLine = value.isSingleUrlInLine
        }

        if atCopyFG {
            if processor.handleAt() { needToSaveJson = true }
        }

        if needToSaveJson,
           let pb = RichTextTransformKit.transformStringToRichText(string: processor.targeAttr),
           let json = try? pb.jsonString(),
           !json.isEmpty {
            let key = LarkPasteboardConfig.pasteboardItemRandomKey()
            var expandInfo = ["chatId": copyMessage?.channel.id ?? ""]
            if isSingleUrlInLine {
                expandInfo[CustomTextViewInteractionHandler.isSingleUrlInLineKey] = "true"
            }
            let value = CustomPasteboardModel(content: json, expandInfo: expandInfo).stringify()
            CustomPasteboardCache.share.saveInfo([key: value])
            SCPasteboard.general(config).addItems([[CopyRichStyleItemProvider.typeIdentifier: key]])
        }
        return true
    }
    // enable-lint: long_function

    @discardableResult
    public static func copyToPasteboardFormRichText(richText: RustPB.Basic_V1_RichText,
                                                    pasteboardToken: String) -> Bool {
        let config = PasteboardConfig(token: Token(pasteboardToken))
        do {
            if let string = RichTextTransformKit.transformRichTexToText(richText) {
                try SCPasteboard.generalUnsafe(config).string = string
            }
        } catch {
            // 复制失败兜底逻辑
            Self.logger.error("copy richText PasteboardConfig init fail token:\(pasteboardToken)")
            return false
        }
        if let json = try? richText.jsonString(),
           !json.isEmpty {
            let key = LarkPasteboardConfig.pasteboardItemRandomKey()
            CustomPasteboardCache.share.saveInfo([key: json])
            SCPasteboard.general(config).addItems([[CopyRichStyleItemProvider.typeIdentifier: key]])
        }
        return true
    }

    public static func addRemoteResourcesCopyTagFor(_ attr: NSAttributedString) {
        ImageTransformer.fetchAllRemoteImageAttachemnt(attributedText: attr).forEach { value in
            value.2.fromCopy = true
        }
        VideoTransformer.fetchAllRemoteVideoAttachemnt(attributedText: attr).forEach { value in
            value.2.copyImage = true
            value.2.copyMedia = true
        }
    }
}

class RichViewAttributedStringConverter {

    private static let logger = Logger.log(RichViewAttributedStringConverter.self, category: "RichViewAttributedStringConverter")

    static func richTextFor(attr: NSAttributedString, copyMessage: Message?) -> RustPB.Basic_V1_RichText {
        let processor = RichViewAttributeStringProcessor(fromMessage: copyMessage, attr: attr)
        let attr = processor.handPartialAllTag()
        attr.enumerateAttribute(AnchorTransformer.AnchorAttributedKey, in: NSRange(location: 0, length: attr.length)) { value, range, _ in
            if let value = value as? AnchorTransformInfo {
                let text = attr.attributedSubstring(from: range).string
                value.customTransformToRichTextBlock = { _ in
                    var anchorProperty = RustPB.Basic_V1_RichTextElement.AnchorProperty()
                    anchorProperty.href = value.href ?? ""
                    anchorProperty.content = text
                    anchorProperty.textContent = text
                    anchorProperty.isCustom = value.isCustom
                    anchorProperty.scene = value.scene
                    return anchorProperty
                }
            }
        }

        if let pb = RichTextTransformKit.transformStringToRichText(string: attr) {
            return pb
        }

        Self.logger.warn("RichTextTransformKit.transformStringToRichText fail  --- \(attr.length)")
        /// 如果转换后的失败，直接使用降级的文字来处理
        return RichTextTransformKit.transformStringToRichText(string: NSAttributedString(string: attr.string)) ?? Basic_V1_RichText()
    }
}
