//
//  InlineAIQuickActionHandler.swift
//  LarkAIInfra
//
//  Created by liujinwei on 2023/8/2.
//  


import Foundation
import LarkBaseKeyboard

final class InlineAIQuickActionHandler: QuickActionInputHandler {
    
    var placeHolderChangedBlock: (() -> Void)?
    
    private var placeHolderCount = 0
    
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        guard let attributedText = textView.attributedText else { return }
        var count = 0
        attributedText.enumerateAttribute(.paramPlaceholderKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, _, _) in
            if value == nil { return }
            count += 1
        })
        if count != placeHolderCount {
            placeHolderCount = count
            //placeHolder的数量发生变化，立刻重新计算输入框高度，避免发生跳动
            // https://meego.feishu.cn/larksuite/issue/detail/14048147
            placeHolderChangedBlock?()
        }
    }
    
}
