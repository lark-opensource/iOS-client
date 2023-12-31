//
//  FocusStatusTextView.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/4.
//

import UIKit
import Foundation
import LarkCore
import RxSwift
import RxCocoa
import RustPB
import EditTextView
import LKCommonsLogging
import LarkRichTextCore
import LarkKeyboardView
import TangramService
import LarkContainer
import LarkBaseKeyboard
import UniverseDesignColor

class FocusStatusTextView: LarkEditTextView, UserResolverWrapper {
    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    static let logger = Logger.log(FocusStatusTextView.self, category: "FocusStatusTextView")

    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    init(userResolver: UserResolver, frame: CGRect = CGRect.zero, textContainer: NSTextContainer? = nil) {
        self.userResolver = userResolver
        super.init(frame: .zero, textContainer: textContainer)
        self.font = UIFont.systemFont(ofSize: 16)
        self.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        self.textContainerInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        self.contentInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.alwaysBounceVertical = true
        self.alwaysBounceHorizontal = false
        self.isUserInteractionEnabled = true
        self.clipsToBounds = true
        self.isScrollEnabled = true
        self.maxHeight = 0
        self.supportNewLine = true
        self.layoutManager.allowsNonContiguousLayout = false
        self.returnKeyType = .done
        self.defaultTypingAttributes = [
            .font: Cons.descriptionFont,
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                return paragraphStyle
            }()
        ]
        /// 调整占位符格式
        self.placeholderTextView.typingAttributes = [
            .font: Cons.descriptionFont,
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        self.placeholder = BundleI18n.LarkFocus.Lark_Profile_StatusNote_Placeholder
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var inputManager: PostInputManager = {
        return PostInputManager(inputTextView: self)
    }()
}

// MARK: - Insert NSAttributedString
extension FocusStatusTextView {
    func insertAtTag(userName: String,
                     actualName: String,
                     userId: String = "",
                     isOuter: Bool = false) {
        if !userId.isEmpty {
            let info = AtChatterInfo(id: userId, name: userName, isOuter: isOuter, actualName: actualName)
            let atString = AtTransformer.transformContentToString(info,
                                                                  style: [:],
                                                                  attributes: self.inputManager.baseTypingAttributes())
            let mutableAtString = NSMutableAttributedString(attributedString: atString)
            mutableAtString.append(NSMutableAttributedString(string: " ", attributes: self.inputManager.baseTypingAttributes()))
            self.insert(mutableAtString, useDefaultAttributes: false)
        } else {
            self.insertText(userName)
        }
        self.becomeFirstResponder()
    }

    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        let content: LinkTransformer.DocInsertContent = (title, type, url, "")
        let urlString: String = url.absoluteString
        let defaultTypingAttributes = self.baseDefaultTypingAttributes
        let urlAttributedString = NSAttributedString(string: urlString, attributes: self.inputManager.baseTypingAttributes())
        self.insert(urlAttributedString, useDefaultAttributes: false)

        let attributedText = NSMutableAttributedString(attributedString: self.attributedText ?? NSAttributedString())
        let replaceStr = LinkTransformer.transformToDocAttr(content, attributes: defaultTypingAttributes)
        let range = (attributedText.string as NSString).range(of: urlString)
        if range.location != NSNotFound {
            attributedText.replaceCharacters(in: range, with: replaceStr)
            self.attributedText = attributedText
        }
        // 重置光标
        self.selectedRange = NSRange(location: range.location + replaceStr.length, length: 0)
        self.becomeFirstResponder()
    }

    func insertUrl(urlString: String) {
        let defaultTypingAttributes = self.baseDefaultTypingAttributes
        let urlAttributedString = NSAttributedString(string: urlString, attributes: inputManager.baseTypingAttributes())
        self.insert(urlAttributedString, useDefaultAttributes: false)

        guard let url = URL(string: urlString) else {
            return
        }
        urlPreviewAPI?.generateUrlPreviewEntity(url: urlString)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (inlineEntity, _) in
                guard let self = self, let entity = inlineEntity, !(entity.title ?? "").isEmpty else {
                    return
                }
                let attributedText = NSMutableAttributedString(attributedString: self.attributedText ?? NSAttributedString())
                let replaceStr = LinkTransformer.transformToURLAttr(entity: entity, originURL: url, attributes: defaultTypingAttributes)
                let range = (attributedText.string as NSString).range(of: urlString)
                if range.location != NSNotFound {
                    attributedText.replaceCharacters(in: range, with: replaceStr)
                    self.attributedText = attributedText
                } else {
                    Self.logger.info("urlPreviewAPI range.location is not Found")
                }
                // 重置光标
                self.selectedRange = NSRange(location: range.location + replaceStr.length, length: 0)
                self.becomeFirstResponder()
            })
            .disposed(by: self.disposeBag)
    }
}

extension FocusStatusTextView {

    enum Cons {
        static var descriptionFont: UIFont      { .systemFont(ofSize: 16) }
        static var cornerRadius: CGFloat        { 10 }
        static var borderWidth: CGFloat         { 1 }
        static var textTopPadding: CGFloat      { 8 }
        static var textLeftPadding: CGFloat     { 12 }
        static var textBottomPadding: CGFloat   { 28 }
        static var textRightPadding: CGFloat    { 12 }

        static var borderColor: UIColor         { UIColor.ud.lineBorderComponent }
        static var bgColor: UIColor             { UIColor.ud.udtokenComponentOutlinedBg }
        static var placeHolderColor: UIColor    { UIColor.ud.textPlaceholder }
    }
}
