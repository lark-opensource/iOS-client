//
//  InlineAIURLInputHandler.swift
//  LarkInlineAI
//
//  Created by liujinwei on 2023/7/4.
//  


import UIKit
import Foundation
import RxSwift
import EditTextView
import TangramService
import LarkBaseKeyboard
import LarkEMM
import LarkSensitivityControl

// 处理URL中台预览：为了与Doc的处理逻辑分开(LinkInputHandler)
public final class InlineAIURLInputHandler: TagInputHandler {
    public var previewCompleteBlock: ((_ textView: UITextView) -> Void)?
    let urlPreviewAPI: URLPreviewAPI?
    let disposeBag: DisposeBag = DisposeBag()

    let psdaToken = "LARK-PSDA-inline_ai_preview_url_input_handler"

    private var lastTextViewSelectedRange: NSRange = NSRange(location: 0, length: 0)

    public init(urlPreviewAPI: URLPreviewAPI?) {
        self.urlPreviewAPI = urlPreviewAPI
        super.init(key: LinkTransformer.LinkAttributedKey)
    }

    // swiftlint:disable all
    public override func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let defaultTypingAttributes = textView.defaultTypingAttributes
        let handler = SubInteractionHandler()
        handler.pasteHandler = { [weak self] textView in
            guard let self = self else { return false }
            return self.handlePaste(textView: textView, typingsAttributes: defaultTypingAttributes)
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    public override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let result = super.textView(textView, shouldChangeTextIn: range, replacementText: text)

        if result, let attributedText = textView.attributedText {
            attributedText.enumerateAttributes(in: attributedText.fullRange) { attributes, range, stop in
                if attributedText.attribute(LinkTransformer.LinkAttributedKey, at: range.location, effectiveRange: nil) == nil,
                   attributes[ImageTransformer.RemoteIconAttachmentAttributedKey] != nil ||
                   attributes[ImageTransformer.LocalIconAttachmentAttributedKey] != nil {
                    // 把本地图片替换为一个不可见的 attachment
                    let newAttributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                    newAttributedText.replaceCharacters(in: range, with: ImageTransformer.LocalEmptyImage)
                    let selectedRange: NSRange = textView.selectedRange
                    textView.attributedText = newAttributedText
                    textView.selectedRange = selectedRange
                    stop.pointee = true
                }
            }
        }
        return result
    }

    public override func textViewDidChange(_ textView: UITextView) {

    }
    
    //点击at文档的文本范围时，光标需要落在at文档两侧
    func textViewDidChangeSelection(_ textView: UITextView) {
        let currentRange = textView.selectedRange
        if currentRange.length > 0 {
            return
        }
        let atRanges = textView.attributedText.getRanges(ofKey: LinkTransformer.LinkAttributedKey)
        if let atRange = atRanges.first(where: { $0.contains(textView.selectedRange) }) {
            guard currentRange.location < atRange.location + atRange.length, currentRange.location > atRange.location else {
                return
            }
            if lastTextViewSelectedRange.location < textView.selectedRange.location {
                textView.selectedRange = NSRange(location: atRange.location + atRange.length, length: 0)
            } else {
                textView.selectedRange = NSRange(location: atRange.location, length: 0)
            }
        }
        lastTextViewSelectedRange = textView.selectedRange
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
                let urlRange = (attributedText.string as NSString).range(of: string)
                guard attributedText.fullRange.contains(urlRange) else { 
                    LarkInlineAILogger.error("text out of range when parse url")
                    return 
                }
                let attributes = attributedText.attributes(at: urlRange.location, effectiveRange: nil)
                let titleStr = LinkTransformer.transformToURLAttr(entity: entity, originURL: url, attributes: attributes)
                let beforeSelectedRange = textView.selectedRange
                if urlRange.location != NSNotFound && urlRange.length > 0 {
                    attributedText.replaceCharacters(in: urlRange, with: titleStr)
                    textView.attributedText = attributedText
                    textView.selectedRange = NSRange(location: beforeSelectedRange.location + titleStr.length - urlRange.length, length: 0)
                    if let completeBlock = self?.previewCompleteBlock {
                        completeBlock(textView)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func handlePaste(textView: UITextView, typingsAttributes: [NSAttributedString.Key: Any]) -> Bool {
        let config = PasteboardConfig(token: Token(self.psdaToken))
        if let string = SCPasteboard.general(config).string,
           let url = URL(string: string) {
            markAnchorAsInlinePreviewIfNeeded(string, url: url, typingAttributes: typingsAttributes, in: textView)
        }
        return false
    }
}
