//
//  RichTextView+Responder.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/2/20.
//

import Foundation

// MARK: RichTextViewResponderDelegate
extension RichTextWebView {
    public override var canBecomeFirstResponder: Bool {
        return responderDelegate?.docsWebViewShouldBecomeFirstResponder(self) ?? true
    }

    public override var canResignFirstResponder: Bool {
        return responderDelegate?.docsWebViewShouldResignFirstResponder(self) ?? true
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        guard let disable = responderDelegate?.disableBecomeFirstResponder(self),
              disable == false else {
            return false
        }
        responderDelegate?.docsWebViewWillBecomeFirstResponder(self)
        let res = super.becomeFirstResponder()
        responderDelegate?.docsWebViewDidBecomeFirstResponder(self)
        return res
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        responderDelegate?.docsWebViewWillResignFirstResponder(self)
        let res = super.resignFirstResponder()
        responderDelegate?.docsWebViewDidResignFirstResponder(self)
        return res
    }
}
