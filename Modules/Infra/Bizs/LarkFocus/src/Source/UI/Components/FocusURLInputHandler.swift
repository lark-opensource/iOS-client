//
//  FocusURLInputHandler.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/4.
//

import UIKit
import Foundation
import RxSwift
import LarkEMM
import LarkModel
import EditTextView
import TangramService
import LarkContainer
import LarkRichTextCore
import LKCommonsLogging
import LarkBaseKeyboard

// 处理URL中台预览：为了与Doc的处理逻辑分开(LinkInputHandler)
public final class FocusURLInputHandler: TagInputHandler {
    static let logger = Logger.log(FocusURLInputHandler.self, category: "FocusURLInputHandler")
    public var previewCompleteBlock: ((_ textView: UITextView) -> Void)?

    let disposeBag: DisposeBag = DisposeBag()
    let urlPreviewAPI: URLPreviewAPI?

    static let iconColorKey = NSAttributedString.Key("inline.iconColor")
    static let tagTypeKey = NSAttributedString.Key("inline.tagType")

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
            if let string = SCPasteboard.generalPasteboard().string,
               let url = URL(string: string) {
                self.urlPreviewAPI?.generateUrlPreviewEntity(url: string)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] inlineEntity, _ in
                        guard let entity = inlineEntity, !(entity.title ?? "").isEmpty else { return }
                        let typingAttributes = defaultTypingAttributes
                        let attributedText = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
                        let replaceStr = FocusURLInputHandler.transformToURLAttr(entity: entity, originURL: url, attributes: typingAttributes)
                        let range = (attributedText.string as NSString).range(of: string)
                        if range.location != NSNotFound {
                            attributedText.replaceCharacters(in: range, with: replaceStr)
                            textView.attributedText = attributedText
                            if let completeBlock = self?.previewCompleteBlock {
                                completeBlock(textView)
                            }
                        } else {
                            Self.logger.info("urlPreviewAPI range.location is not Found")
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
            return false
        }
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    public override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let result = super.textView(textView, shouldChangeTextIn: range, replacementText: text)
        if result, let attributedText = textView.attributedText {
            attributedText.enumerateAttribute(
                ImageTransformer.RemoteIconAttachmentAttributedKey,
                in: NSRange(location: 0, length: attributedText.length) ,
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

    public static func transformToURLAttr(entity: InlinePreviewEntity,
                                           originURL: URL,
                                           attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let summerize = NSMutableAttributedString()
        if let imageAttr = ImageTransformer.transformToURLIconAttr(entity: entity, attributes: attributes) {
            summerize.append(imageAttr)
        }
        if let title = entity.title, !title.isEmpty {
            summerize.append(NSAttributedString(string: title, attributes: attributes))
        } else {
            return NSAttributedString(string: originURL.path, attributes: attributes)
        }
        if let tagAttr = transformToURLTagAttr(entity: entity, attributes: attributes) {
            summerize.append(tagAttr)
        }
        summerize.addAttribute(LinkTransformer.LinkAttributedKey,
                               value: LinkTransformInfo(url: originURL, titleLength: summerize.length),
                               range: NSRange(location: 0, length: summerize.length))
        summerize.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: NSRange(location: 0, length: summerize.length))
        return summerize
    }

    private static func transformToURLTagAttr(entity: InlinePreviewEntity, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard let tag = entity.tag, !tag.isEmpty else { return nil }
        var attributes = attributes
        attributes[FocusURLInputHandler.tagTypeKey] = TagType.link
        guard let attr = FocusURLInputHandler.getKeyboardTagAttr(entity: entity,
                                                                   inlinePreviewService: InlinePreviewService(),
                                                                   customAttributes: attributes) else { return nil }
        attr.addAttribute(LinkTransformer.TagAttributedKey, value: tag, range: NSRange(location: 0, length: 1))
        return attr
    }

    private static func getKeyboardTagAttr(entity: InlinePreviewEntity,
                                           inlinePreviewService: InlinePreviewService,
                                           customAttributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString? {
        guard inlinePreviewService.hasTag(entity: entity) else { return nil }
        let tag = entity.tag ?? ""
        let font = customAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 10)
        let size = inlinePreviewService.tagViewSize(text: tag, titleFont: font)
        let bounds = CGRect(x: 4,
                            y: -(size.height - font.ascender - font.descender) / 2,
                            width: size.width,
                            height: size.height)
        let tagType = customAttributes[FocusURLInputHandler.tagTypeKey] as? TagType ?? .link
        let tagView = inlinePreviewService.tagView(text: tag, titleFont: font, type: tagType)
        let attachMent = CustomTextAttachment(customView: tagView, bounds: bounds)
        let attr = NSMutableAttributedString(attachment: attachMent)
        attr.addAttributes(customAttributes, range: NSRange(location: 0, length: 1))
        return attr
    }
}
