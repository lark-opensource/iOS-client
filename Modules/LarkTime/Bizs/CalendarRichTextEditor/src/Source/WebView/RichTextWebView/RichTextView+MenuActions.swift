//
//  RichTextView+MenuActions.swift
//  CalendarRichTextEditor
//
//  Created by Rico on 2021/2/20.
//

import Foundation

// MARK: - WebView override
@objc
extension RichTextWebView: _ActionHelperActionDelegate {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        let res = _actionHelper.canPerformAction(action, withSender: sender)
        return res
    }

    func canSuperPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
    }

    func canPerformUndefinedAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return canSuperPerformAction(action, withSender: sender)
    }
}

extension RichTextWebView {

    var _actionHelper: _ActionHelper {
        set { objc_setAssociatedObject(self, &RichTextWebView._kActionHelperKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        get {
            guard let helper = objc_getAssociatedObject(self, &RichTextWebView._kActionHelperKey) as? _ActionHelper else {
                let obj = _ActionHelper()
                obj.delegate = self
                self._actionHelper = obj
                return obj
            }
            return helper
        }
    }

    private static var _kActionHelperKey: UInt8 = 0
}
