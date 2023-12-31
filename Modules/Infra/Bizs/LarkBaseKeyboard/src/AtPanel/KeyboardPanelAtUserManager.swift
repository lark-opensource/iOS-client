//
//  KeyboardPanelAtUserManager.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/14.
//

import UIKit
import LarkKeyboardView
import EditTextView
import TangramService
import LarkContainer
import RustPB
import RxSwift
import LKCommonsLogging

public class KeyboardPanelAtUserItemLogger {
    public static let logger = Logger.log(KeyboardPanelAtUserItemLogger.self, category: "Module.Inputs")
}

public class KeyboardPanelAtUserItemConfig {
    public enum InsertType {
        case at
        case url
        case none
    }
    let itemIconColor: UIColor?
    var afterInsertCallBack: ((InsertType) -> Void)?
    var shouldInsert: ((_ id: String) -> Bool)?
    
    weak var textView: LarkEditTextView?
    weak var delegate: KeyboardPanelAtUserManagerDelegate?

    public init(itemIconColor: UIColor?,
                afterInsertCallBack: ((InsertType) -> Void)?,
                shouldInsert: ((_ id: String) -> Bool)?,
                textView: LarkEditTextView?,
                delegate: KeyboardPanelAtUserManagerDelegate?) {

        self.itemIconColor = itemIconColor
        self.afterInsertCallBack = afterInsertCallBack
        self.shouldInsert = shouldInsert
        self.textView = textView
        self.delegate = delegate
    }
}

public protocol KeyboardPanelAtUserManagerDelegate: AnyObject {
    func showAtPicker(cancel: (() -> Void)?, complete: (([LarkBaseKeyboard.InputKeyboardAtItem]) -> Void)?)
    func didSelectedItem()
    func becomeFirstResponderAfterComplete() -> Bool
    func becomeFirstResponderhAfterCancel() -> Bool
    func insert(userName: String, actualName: String, userId: String, isOuter: Bool)
    func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum)
    func insertUrl(urlString: String)
}

public class KeyboardPanelAtUserManager {

    public let config: KeyboardPanelAtUserItemConfig

    @InjectedLazy var urlPreviewAPI: URLPreviewAPI

    private let disposeBag = DisposeBag()

    public init(config: KeyboardPanelAtUserItemConfig) {
        self.config = config
    }

    public func createItem() -> InputKeyboardItem? {
        return LarkKeyboard.buildAt(iconColor: config.itemIconColor) { [weak self] in
            guard let self = self, let inputTextView = self.config.textView else { return false }
            self.config.delegate?.didSelectedItem()
            inputTextView.insertText("@")
            let selectedRange = inputTextView.selectedRange
            inputTextView.resignFirstResponder()
            let defaultTypingAttributes = inputTextView.defaultTypingAttributes
            self.config.delegate?.showAtPicker(cancel: { [weak self] in
                if self?.config.delegate?.becomeFirstResponderhAfterCancel() == true {
                    self?.config.textView?.becomeFirstResponder()
                } else {
                    self?.config.textView?.resignFirstResponder()
                }
            }, complete: { [weak self] (selectItems) in
                self?.config.textView?.selectedRange = selectedRange
                self?.config.textView?.deleteBackward()
                selectItems.forEach({ item in
                    switch item {
                    case .chatter(let item):
                        if let shouldInsert = self?.config.shouldInsert,
                           !shouldInsert(item.id) {
                            self?.config.afterInsertCallBack?(.none)
                        } else {
                            if item.id.isEmpty {
                                self?.config.textView?.insertText(item.name)
                            } else {
                                self?.insert(userName: item.name,
                                             actualName: item.actualName,
                                             userId: item.id,
                                             isOuter: item.isOuter)
                            }
                            self?.config.afterInsertCallBack?(.at)
                        }
                    case .doc(let url, let title, let type), .wiki(let url, let title, let type):
                        if let url = URL(string: url) {
                            self?.insertUrl(title: title, url: url, type: type)
                        } else {
                            self?.insertUrl(urlString: url)
                        }
                        self?.config.afterInsertCallBack?(.url)
                    }
                })
                self?.config.textView?.defaultTypingAttributes = defaultTypingAttributes
                if self?.config.delegate?.becomeFirstResponderAfterComplete() == true {
                    self?.config.textView?.becomeFirstResponder()
                }
            })
            return false
        }
    }

    public static func insert(inputTextView: LarkEditTextView, userName: String, actualName: String, userId: String, isOuter: Bool) {
        KeyboardViewInputTool.insertAtForTextView(inputTextView,
                                                  userName: userName,
                                                  actualName: actualName,
                                                  userId: userId,
                                                  isOuter: isOuter)

    }

    public func insert(userName: String,
                     actualName: String,
                     userId: String = "",
                     isOuter: Bool = false) {
        guard let inputTextView = self.config.textView else { return }
        self.config.delegate?.insert(userName: userName, actualName: actualName, userId: userId, isOuter: isOuter)
        Self.insert(inputTextView: inputTextView,
                    userName: userName,
                    actualName: actualName,
                    userId: userId,
                    isOuter: isOuter)
    }

    public static func insertUrl(inputTextView: LarkEditTextView, title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        let content: LinkTransformer.DocInsertContent = (title, type, url, "")
        let urlString: String = url.absoluteString
        let defaultTypingAttributes = KeyboardViewInputTool.baseTypingAttributesFor(inputTextView: inputTextView)
        let urlAttributedString = NSAttributedString(string: urlString,
                                                     attributes: defaultTypingAttributes)
        inputTextView.insert(urlAttributedString, useDefaultAttributes: false)

        guard let url = URL(string: urlString) else {
            KeyboardPanelAtUserItemLogger.logger.info("insertUrl urlString is not URL \(urlString)")
            return
        }

        let attributedText = NSMutableAttributedString(attributedString: inputTextView.attributedText ?? NSAttributedString())
        /// 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
        let replaceStr = LinkTransformer.transformToDocAttr(content, attributes: defaultTypingAttributes)
        let range = (attributedText.string as NSString).range(of: urlString)
        if range.location != NSNotFound {
            attributedText.replaceCharacters(in: range, with: replaceStr)
            inputTextView.attributedText = attributedText
        } else {
            KeyboardPanelAtUserItemLogger.logger.info("urlPreviewAPI range.location is not Found")
        }
        // 重置光标
        inputTextView.selectedRange = NSRange(location: range.location + replaceStr.length, length: 0)
        inputTextView.becomeFirstResponder()
    }

    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {
        guard let inputTextView = self.config.textView else { return }
        self.config.delegate?.insertUrl(title: title, url: url, type: type)
        Self.insertUrl(inputTextView: inputTextView, title: title, url: url, type: type)
    }

    public static func insertUrl(inputTextView: LarkEditTextView,
                                 urlPreviewAPI: URLPreviewAPI,
                                 urlString: String,
                                 disposeBag: DisposeBag,
                                 finish:(()-> Void)?) {
        let defaultTypingAttributes = KeyboardViewInputTool.baseTypingAttributesFor(inputTextView: inputTextView)
        let urlAttributedString = NSAttributedString(string: urlString,
                                                     attributes: defaultTypingAttributes)
        inputTextView.insert(urlAttributedString, useDefaultAttributes: false)
        guard let url = URL(string: urlString) else {
            KeyboardPanelAtUserItemLogger.logger.info("insertUrl urlString is not URL")
            return
        }
        urlPreviewAPI.generateUrlPreviewEntity(url: urlString)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { inlineEntity, _ in
                // 三端对齐，title为空时不进行替换
                guard let entity = inlineEntity, !(entity.title ?? "").isEmpty else {
                    KeyboardPanelAtUserItemLogger.logger.info("urlPreviewAPI res title is Emtpy")
                    return
                }
                let attributedText = NSMutableAttributedString(attributedString: inputTextView.attributedText ?? NSAttributedString())
                /// 这里与产品沟通 粘贴的文字不携带样式，使用原有样式
                let replaceStr = LinkTransformer.transformToURLAttr(entity: entity, originURL: url, attributes: defaultTypingAttributes)
                let range = (attributedText.string as NSString).range(of: urlString)
                if range.location != NSNotFound {
                    attributedText.replaceCharacters(in: range, with: replaceStr)
                    inputTextView.attributedText = attributedText
                } else {
                    KeyboardPanelAtUserItemLogger.logger.info("urlPreviewAPI range.location is not Found")
                }
                // 重置光标
                inputTextView.selectedRange = NSRange(location: range.location + replaceStr.length, length: 0)
                inputTextView.becomeFirstResponder()
                finish?()
            })
            .disposed(by: disposeBag)

    }

    public func insertUrl(urlString: String) {
        guard let inputTextView = self.config.textView else { return }
        self.config.delegate?.insertUrl(urlString: urlString)
        Self.insertUrl(inputTextView: inputTextView, urlPreviewAPI: self.urlPreviewAPI, urlString: urlString, disposeBag: self.disposeBag) { [weak self] in
            self?.config.afterInsertCallBack?(.url)
        }
    }

}
