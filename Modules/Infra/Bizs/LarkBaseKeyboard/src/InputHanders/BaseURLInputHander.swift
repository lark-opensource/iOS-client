//
//  BaseURLInputHander.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/8/16.
//

import UIKit
import Foundation
import EditTextView
import TangramService
import RxSwift
import LarkEMM
import LarkFeatureGating
import LarkSensitivityControl

/**
 很多业务都有粘贴一个URL，支持解析为标题+ icon的样式的希求
 之前有一个URLInputHandler。但是随着功能的迭代，URLInputHandler被加入了anchor的逻辑。
 导致一些业务不敢复用 or 复用了将来功能修改的时候，会引入问题。
 导致该类被重复实现，故抽取一个单纯的基类，业务入注入后可以实现基础的粘贴功能，也可以继承后自定义
 */
open class BaseURLInputHander: TagInputHandler {

    public var previewCompleteBlock: ((_ textView: UITextView) -> Void)?

    let urlPreviewAPI: URLPreviewAPI?
    let disposeBag: DisposeBag = DisposeBag()

    open var psdaToken: String {
        assertionFailure("need psda Token")
        return ""
    }

    public init(urlPreviewAPI: URLPreviewAPI?) {
        self.urlPreviewAPI = urlPreviewAPI
        super.init(key: LinkTransformer.LinkAttributedKey)
    }

    // swiftlint:disable all
    open override func register(textView: UITextView) {
        guard let textView = textView as? LarkEditTextView else { return }
        let defaultTypingAttributes = textView.defaultTypingAttributes
        let handler = SubInteractionHandler()
        handler.pasteHandler = { [weak self] textView in
            guard let self = self else { return false }
            self.urlPasteHandler(textView: textView, typingsAttributes: defaultTypingAttributes)
            return false
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    open override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let result = super.textView(textView, shouldChangeTextIn: range, replacementText: text)
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
                        stop.pointee = true
                    }
                }
        }
        return result
    }

    private func urlPasteHandler(textView: UITextView, typingsAttributes: [NSAttributedString.Key: Any]) {
        let config = PasteboardConfig(token: Token(self.psdaToken))
        if let string = SCPasteboard.general(config).string {
            self.urlPasteHandler(textView: textView, string: string, typingsAttributes: typingsAttributes)
        }
    }

    public func urlPasteHandler(textView: UITextView, string: String, typingsAttributes: [NSAttributedString.Key: Any]) {
        guard let url = URL(string: string) else { return }
        self.urlPreviewAPI?.generateUrlPreviewEntity(url: url.absoluteString)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] inlineEntity, _ in
                // 三端对齐，title为空时不进行替换
                guard let entity = inlineEntity, !(entity.title ?? "").isEmpty else { return }
                /// 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
                let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                let urlStr = LinkTransformer.transformToURLAttr(entity: entity, originURL: url, attributes: typingsAttributes)
                let range = (attributedText.string as NSString).range(of: string)
                /// 这个需要确保有range，且 range.length > 0. (kCFNotFound = -1) != NSNotFound
                if range.location != NSNotFound, range.length > 0 {
                    attributedText.replaceCharacters(in: range, with: urlStr)
                    textView.attributedText = attributedText
                    if let completeBlock = self?.previewCompleteBlock {
                        completeBlock(textView)
                    }
                }
            }).disposed(by: self.disposeBag)
    }
}
