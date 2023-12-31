//
//  HashTagInputHandler.swift
//  LarkCore
//
//  Created by liluobin on 2021/6/30.
//

import UIKit
import Foundation
import LarkUIKit
import EditTextView

public final class HashTagInputHandler: TextViewInputProtocol {
    let showHashTagListCallBack: (() -> Void)?
    let handlerTextChangeCallBack: (() -> Void)?
    public init(showHashTagListCallBack: (() -> Void)?,
         handlerTextChangeCallBack: (() -> Void)?) {
        self.showHashTagListCallBack = showHashTagListCallBack
        self.handlerTextChangeCallBack = handlerTextChangeCallBack
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "#" {
            let isDelete = !NSEqualRanges(range, textView.selectedRange) && range.length > 0
            if !isDelete {
                showHashTagListCallBack?()
            }
        }
        return true
    }

    public func textViewDidChange(_ textView: UITextView) {
        handlerTextChangeCallBack?()
    }
}
