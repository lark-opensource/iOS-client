//
//  TextViewInteractionHandler.swift
//  EditTextView
//
//  Created by 李晨 on 2019/4/8.
//

import Foundation

open class TextViewInteractionHandler {

    public init() {
    }

    public var subHandlers: [SubInteractionHandler] = []

    public func registerSubInteractionHandler(handler: SubInteractionHandler) {
        if !self.subHandlers.contains(handler) {
            self.subHandlers.append(handler)
        }
    }

    public func unregisterSubInteractionHandler(handler: SubInteractionHandler) {
        if let index = self.subHandlers.firstIndex(of: handler) {
            self.subHandlers.remove(at: index)
        }
    }

    open func copyHandler(_ textView: BaseEditTextView) -> Bool {
        var handleCopy: Bool = false
        self.subHandlers.forEach { (sub) in
            if let copyHandler = sub.copyHandler,
                copyHandler(textView) {
                handleCopy = true
            }
        }
        return handleCopy
    }

    open func pasteHandler(_ textView: BaseEditTextView) -> Bool {
        self.pasteCallBack(textView)
        var handlePaste: Bool = false
        self.subHandlers.forEach { (sub) in
            if let pasteHandler = sub.pasteHandler,
                pasteHandler(textView) {
                handlePaste = true
            }
        }
        return handlePaste
    }

    open func pasteCallBack(_ textView: BaseEditTextView) {
        self.subHandlers.forEach { sub in
            sub.pasteCallBack?(textView)
        }
    }

    open func cutHandler(_ textView: BaseEditTextView) -> Bool {
        var handleCut: Bool = false
        self.subHandlers.forEach { (sub) in
            if let cutHandler = sub.cutHandler,
                cutHandler(textView) {
                handleCut = true
            }
        }
        return handleCut
    }
}

open class SubInteractionHandler: NSObject {
    // 下面的闭包中 返回 true 的话，代表不执行系统默认 copy/cut/paste 操作
    open var copyHandler: ((BaseEditTextView) -> Bool)?
    open var pasteHandler: ((BaseEditTextView) -> Bool)?
    open var cutHandler: ((BaseEditTextView) -> Bool)?
    open var pasteCallBack:  ((BaseEditTextView) -> Void)?

    public override init() {
        super.init()
    }
}
