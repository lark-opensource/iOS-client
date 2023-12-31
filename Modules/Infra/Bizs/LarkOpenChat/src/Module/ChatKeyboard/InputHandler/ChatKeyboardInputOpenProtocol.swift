//
//  ChatKeyboardInputOpenProtocol.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2022/2/8.
//

import UIKit
import Foundation

public protocol ChatKeyboardInputOpenProtocol {
    var type: ChatKeyboardInputOpenType { get }
    func register(textView: UITextView)
    func textViewDidChange(_ textView: UITextView)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
}

/// 键盘输入框 input handler 类型
/// - 此处顺序会影响整体排序，越小的越靠前
/// - 白名单管控
public enum ChatKeyboardInputOpenType: Int {
    case quickAction
    case `return`
    case atPicker
    case atUser
    case emoji
    case link
    case url
    case image
    case video
    case imageAndVideo
    /// 代码块
    case code
    case anchor
    /// 套件Id
    case entityNum
}
