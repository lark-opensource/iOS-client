//
//  ReturnInputHandler.swift
//  Todo
//
//  Created by 张威 on 2021/12/3.
//

// 参考自: LarkCore/ReturnInputHandler
class ReturnInputHandler: TextViewInputProtocol {

    let returnFunc: (UITextView) -> Bool
    var newlineFunc: ((UITextView) -> Bool)? // 匹配 \r\r 搜狗换行

    init(returnFunc: @escaping (UITextView) -> Bool) {
        self.returnFunc = returnFunc
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            return self.returnFunc(textView)
        } else if text == "\r\r", let newlineFunc = self.newlineFunc {
            return newlineFunc(textView)
        } else {
            return true
        }
    }
}
