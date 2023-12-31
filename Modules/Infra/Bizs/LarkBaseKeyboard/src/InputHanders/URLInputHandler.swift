//
//  URLInputHandler.swift
//  LarkCore
//
//  Created by 袁平 on 2021/6/22.
//

import UIKit
import Foundation
import EditTextView
import TangramService
import RxSwift
import LarkEMM
import LarkFeatureGating
import LarkSensitivityControl

struct TextAnchorInfo {
    let range: NSRange
    let info: AnchorTransformInfo
}

// 处理URL中台预览：为了与Doc的处理逻辑分开(LinkInputHandler)
public final class URLInputHandler: BaseURLInputHander {

    public override var psdaToken: String {
        return "LARK-PSDA-url_preview_url_input_handler"
    }

    @FeatureGating("messenger.chat.editor_hyper_link_support_cnchar")
    var urlSupportedCNisOn: Bool

    /// 标记需要被添加Anchor标签的Range
    private var markAnchorInfo: TextAnchorInfo?


    // swiftlint:disable all
    public override func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let defaultTypingAttributes = textView.defaultTypingAttributes
        let handler = CustomSubInteractionHandler()

        let handerEntity = URLHanderEntity { str in
            return !str.isEmpty
        } handerBlock: { [weak self, weak textView] string, isAnchor, attributes in
            guard let self = self, let textView = textView else {
                return NSAttributedString(string: string, attributes: attributes)
            }
            if self.urlSupportedCNisOn {
                if let url = try? URL.forceCreateURL(string: string) {
                    var targetAttributes = attributes
                    if isAnchor {
                        targetAttributes[AnchorTransformer.AnchorAttributedKey] = AnchorTransformInfo(isCustom: false,
                                                                                                      scene: .copyPasteText,
                                                                                                      contentLength: string.utf16.count)
                        targetAttributes[.foregroundColor] = UIColor.ud.textLinkNormal
                    }
                    let urlStr = NSAttributedString(string: string, attributes: targetAttributes)
                    self.markAnchorAsInlinePreviewIfNeeded(string, url: url, typingAttributes: attributes, in: textView)
                    return urlStr
                }
                return NSAttributedString(string: string, attributes: attributes)
            }
            if let url = URL(string: string) {
                self.markAnchorAsInlinePreviewIfNeeded(string, url: url, typingAttributes: attributes, in: textView)
            }
            return NSAttributedString(string: string, attributes: attributes)
        }

        handler.handerPasteTextType = .url(.linkUrl(handerEntity))

        if TextViewCustomPasteConfig.useNewPasteFG {
            handler.supportPasteType = .link
        }
        handler.copyHandler = { (textViewInner) in
            if !TextViewCustomPasteConfig.useNewPasteFG {
                return false
            }
            let selectedRange = textViewInner.selectedRange
            var hasAnchor = false
            if selectedRange.length > 0, let attributedText = textViewInner.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                let range = NSRange(location: 0, length: subAttributedText.length)
                subAttributedText.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: range, options: [], using: { (value, _, stop) in
                    if value != nil {
                        hasAnchor = true
                        stop.pointee = true
                    }
                })
            }
            return hasAnchor
        }

        handler.cutHandler = handler.copyHandler

        handler.pasteHandler = { [weak self] textView in
            guard let self = self else { return false }
            if self.urlSupportedCNisOn {
                return self.urlPasteHandlerNew(textView: textView, typingsAttributes: defaultTypingAttributes)
            }
            return self.urlPasteHandlerOld(textView: textView, typingsAttributes: defaultTypingAttributes)
        }

        handler.willAddInfoToPasteboard =  { attr in
            guard TextViewCustomPasteConfig.useNewPasteFG else { return attr }
            let muattr = NSMutableAttributedString(attributedString: attr)
            muattr.enumerateAttribute(LinkTransformer.LinkAttributedKey, in: NSRange(location: 0, length: attr.length), options: []) { value, range, _ in
                if let value = value as? LinkTransformInfo, (range.location == 0 || range.location + range.length == attr.length) {
                    let subStr = (muattr.attributedSubstring(from: range).string as NSString)
                    if subStr.length < value.titleLength {
                        muattr.removeAttribute(LinkTransformer.LinkAttributedKey, range: range)
                    }
                }
            }
            return muattr
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    public override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        /// 当每次有新的shouldChangeTextIn来的时候，清空一下
        markAnchorInfo = nil
        /// Insert
        guard let editTextView = textView as? LarkEditTextView else { return true }
        let result = super.textView(textView, shouldChangeTextIn: range, replacementText: text)
        /// 该逻辑线上已经不生效，和产品讨论后，后续无用户反馈可以干掉
        if !TextViewCustomPasteConfig.useNewPasteFG {
            if result, !text.isEmpty, let attributedText = textView.attributedText {
                /// 这里可能会导致LarkEmoji在链接中编辑变成纯文本。这种情况不符合预期，但当前架构确实无法处理好这个问题，需要较大redesign工作。
                attributedText.enumerateAttribute(
                    AnchorTransformer.AnchorAttributedKey,
                    in: NSRange(location: 0, length: attributedText.length),
                    options: []
                ) { anchor, anchorRange, stop in
                    if let anchor = anchor as? AnchorTransformInfo,
                       range.intersection(anchorRange) != nil {
                        /// 如果这段文字需要被添加Anchor标签，在defaultTypingAttributes添加 自动就会带上(粘贴的除外)
                        markAnchorInfo = TextAnchorInfo(range: NSRange(location: range.location,
                                                                       length: text.utf16.count), info: anchor)
                        editTextView.defaultTypingAttributes[AnchorTransformer.AnchorAttributedKey] = anchor
                        stop.pointee = true
                    }
                }
            }
        }

        if result, let attributedText = textView.attributedText {
            attributedText.enumerateAttribute(
                ImageTransformer.RemoteIconAttachmentAttributedKey,
                in: NSRange(location: 0, length: attributedText.length),
                options: []) { (value, r, stop) in
                    if value != nil,
                        attributedText.attribute(LinkTransformer.LinkAttributedKey, at: r.location, effectiveRange: nil) == nil {
                        // 把本地图片替换为一个不可见的 attachment
                        let newAttributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                        newAttributedText.replaceCharacters(in: r, with: ImageTransformer.LocalEmptyImage)
                        let selectedRange: NSRange = textView.selectedRange
                        textView.attributedText = newAttributedText
                        textView.selectedRange = selectedRange
                        markAnchorInfo = nil
                        self.deleAnchorKeyIfNeed(textView: textView)
                        stop.pointee = true
                    }
            }
        }

        return result
    }

    public override func textViewDidChange(_ textView: UITextView) {
        /// 粘贴的时候editTextView.defaultTypingAttributes的信息并不能应用到pasteString上，会出现问题
        /// 所以这里做个兜底。应该加上Anchor标签的判断一下是否加上，没有的话补上
        if let anchorInfo = self.markAnchorInfo {
            let newAttributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
            let attributes = newAttributedText.attributes(at: anchorInfo.range.location, effectiveRange: nil)
            /// 如果该有的没有AnchorAttributedKey 补上这个信息
            if attributes[AnchorTransformer.AnchorAttributedKey] == nil,
               anchorInfo.range.location + anchorInfo.range.length <= newAttributedText.length {
                newAttributedText.addAttributes([AnchorTransformer.AnchorAttributedKey: anchorInfo.info], range: anchorInfo.range)
                textView.attributedText = newAttributedText
                textView.selectedRange = NSRange(location: anchorInfo.range.upperBound,
                                                 length: 0)
                /// 使用完成之后 置为空
                self.markAnchorInfo = nil
            }
        }
        deleAnchorKeyIfNeed(textView: textView)
    }

    func deleAnchorKeyIfNeed(textView: UITextView) {
        guard let editTextView = textView as? LarkEditTextView else { return }
        if editTextView.defaultTypingAttributes[AnchorTransformer.AnchorAttributedKey] != nil {
            editTextView.defaultTypingAttributes[AnchorTransformer.AnchorAttributedKey] = nil
        }
    }

    private func urlPasteHandlerNew(textView: UITextView, typingsAttributes: [NSAttributedString.Key: Any]) -> Bool {
        let config = PasteboardConfig(token: Token(self.psdaToken))
        if let string = SCPasteboard.general(config).string?.trimmingCharacters(in: .whitespacesAndNewlines),
           !string.isEmpty,
           AnchorTransformer.isURL(url: string),
           let url = try? URL.forceCreateURL(string: string),
            URLInputManager.checkURLType(string) == .normal {
            self.markStringAsAnchor(string, typingAttributes: typingsAttributes, in: textView)
            self.markAnchorAsInlinePreviewIfNeeded(string, url: url, typingAttributes: typingsAttributes, in: textView)
            return true
        }
        return false
    }

    private func urlPasteHandlerOld(textView: UITextView, typingsAttributes: [NSAttributedString.Key: Any]) -> Bool {
        let config = PasteboardConfig(token: Token(self.psdaToken))
        if let string = SCPasteboard.general(config).string,
           let url = URL(string: string) {
            markAnchorAsInlinePreviewIfNeeded(string, url: url, typingAttributes: typingsAttributes, in: textView)
        }
        return false
    }

    @inline(__always)
    private func markStringAsAnchor(_ string: String, typingAttributes: [NSAttributedString.Key: Any], in textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        var attributes = typingAttributes
        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
        /// Only mark as anchor, because delete may lead `href` change, so `href` is caculated by text string.
        attributes[AnchorTransformer.AnchorAttributedKey] = AnchorTransformInfo(isCustom: false, scene: .copyPasteText, contentLength: string.utf16.count)
        let urlStr = NSAttributedString(string: string, attributes: attributes)
        let replaceRange = textView.selectedRange
        let range = NSRange(location: replaceRange.location, length: urlStr.length)
        let interactionHandler = textView.interactionHandler as? CustomTextViewInteractionHandler
        if interactionHandler?.shouldChange?(replaceRange, urlStr) ?? true {
            attributedText.replaceCharacters(in: replaceRange, with: urlStr)
            textView.attributedText = attributedText
            textView.selectedRange = NSRange(location: range.location + range.length, length: 0)
            interactionHandler?.didChange?()
        }
    }

    @inline(__always)
    private func markAnchorAsInlinePreviewIfNeeded(
        _ string: String,
        url: URL,
        typingAttributes: [NSAttributedString.Key : Any],
        in textView: UITextView) {

        self.urlPreviewAPI?.generateUrlPreviewEntity(url: url.absoluteString)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] inlineEntity, _ in
                // 三端对齐，title为空时不进行替换
                guard let entity = inlineEntity, !(entity.title ?? "").isEmpty else { return }
                /// 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                let urlStr = LinkTransformer.transformToURLAttr(entity: entity, originURL: url, attributes: typingAttributes)
                let range = (attributedText.string as NSString).range(of: string)
                if range.location != NSNotFound && range.length > 0 {
                    let interactionHandler = (textView as? LarkEditTextView)?.interactionHandler as? CustomTextViewInteractionHandler
                    if interactionHandler?.shouldChange?(range, urlStr) ?? true {
                        attributedText.replaceCharacters(in: range, with: urlStr)
                        textView.attributedText = attributedText
                        interactionHandler?.didChange?()
                    }
                    if let completeBlock = self?.previewCompleteBlock {
                        completeBlock(textView)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }
}
