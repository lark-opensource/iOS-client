//
//  CoverEditTextView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/6/7.
//

import Foundation
import UIKit

/// 行为上报，监听subject复制事件
protocol MailTextViewCopyDelegate: AnyObject {
    func textViewDidCopy()
}

/// 行为上报，监听subject复制事件
class MailBaseTextView: UITextView {
    weak var copyDelegate: MailTextViewCopyDelegate?

    override func copy(_ sender: Any?) {
        super.copy(sender)
        copyDelegate?.textViewDidCopy()
    }
}

class CoverEditTextView: MailBaseTextView {
    /// 解决光标因为 line spacing 而过高的问题
    override func caretRect(for position: UITextPosition) -> CGRect {
        var superRect = super.caretRect(for: position)
        guard let font = font else { return superRect }
        superRect.size.height = font.pointSize - font.descender
        return superRect
    }
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
    #else
        let notificationName = Notification.Name.UITextViewTextDidChange
    #endif
    NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: notificationName, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func textDidChange() {
        if let text = self.text,
            text.contains("\n") {
            self.text = text.replacingOccurrences(of: "\n", with: " ")
        }
    }
    
    deinit {
      #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
      #else
        let notificationName = Notification.Name.UITextViewTextDidChange
      #endif
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }
}
