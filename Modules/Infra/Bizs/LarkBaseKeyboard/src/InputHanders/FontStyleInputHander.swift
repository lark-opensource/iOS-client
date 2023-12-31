//
//  FontStyleInputHander.swift
//  LarkCore
//
//  Created by liluobin on 2021/10/9.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView
import LarkEMM

public final class FontStyleInputHander: TextViewInputProtocol {
    private let fontStyleInputService: FontStyleInputService
    private let pasteCallBack: () -> Void

    public init(pasteCallBack: @escaping () -> Void, supportCopyStyle: Bool = true) {
        self.pasteCallBack = pasteCallBack
        /// 内部实现 不需要用注入的方式。直接创建对象
        self.fontStyleInputService = FontStyleInputServiceImp(supportCopyStyle: supportCopyStyle)
    }

    public func register(textView: UITextView) {
        self.fontStyleInputService.observeTextView(textView, pasteCallBack: self.pasteCallBack)
    }
}

public protocol FontStyleInputService {
    func observeTextView(_ textView: UITextView, pasteCallBack: @escaping () -> Void)
    func removerObserveForTextView(_ textView: UITextView)
}

public final class FontStyleInputServiceImp: FontStyleInputService {

    private let supportCopyStyle: Bool
    private weak var handler: CustomSubInteractionHandler?

    private var pasteboardRedesignFg: Bool {
        return LarkPasteboardConfig.useRedesign
    }

    public init(supportCopyStyle: Bool) {
        self.supportCopyStyle = supportCopyStyle
    }
    public func observeTextView(_ textView: UITextView, pasteCallBack: @escaping () -> Void) {
        guard let textView = textView as? LarkEditTextView else { return }
        let handler = CustomSubInteractionHandler()
        handler.supportPasteType = .font
        handler.copyHandler = { [weak self] (textView) in
            guard let self = self, self.supportCopyStyle else { return false }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                let style = FontStyleItemProvider.styleForAttributedString(subAttributedText)
                if self.pasteboardRedesignFg {
                    return !style.isEmpty
                } else {
                    if !style.isEmpty, let json = FontStyleItemProvider.JSONStringWithStyle(style, content: subAttributedText.string) {
                        DispatchQueue.main.async {
                            SCPasteboard.generalPasteboard().string = subAttributedText.string
                            SCPasteboard.generalPasteboard().addItems([[FontStyleItemProvider.typeIdentifier: json]])
                        }
                    }
                }
            }
            return false
        }

        handler.pasteCallBack = { _ in
            pasteCallBack()
        }

        handler.cutHandler = { [weak self] (textView) in
            guard let self = self, self.supportCopyStyle else { return false }
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0, let attributedText = textView.attributedText.mutableCopy() as? NSMutableAttributedString {
                let subAttributedText = attributedText.attributedSubstring(from: selectedRange)
                let style = FontStyleItemProvider.styleForAttributedString(subAttributedText)
                if self.pasteboardRedesignFg {
                    return !style.isEmpty
                } else {
                    if !style.isEmpty, let json = FontStyleItemProvider.JSONStringWithStyle(style, content: subAttributedText.string) {
                        DispatchQueue.main.async {
                            SCPasteboard.generalPasteboard().string = subAttributedText.string
                            SCPasteboard.generalPasteboard().addItems([[FontStyleItemProvider.typeIdentifier: json]])
                        }
                    }
                }
            }
            return false
        }
        self.handler = handler
        textView.interactionHandler.registerSubInteractionHandler(handler: handler)
    }

    public func removerObserveForTextView(_ textView: UITextView) {
        guard let handler = self.handler, let textView = textView as? LarkEditTextView else { return }
        textView.interactionHandler.unregisterSubInteractionHandler(handler: handler)
    }

}
