//
//  ChatOpenKeyboardDelegate.swift
//  LarkChatOpenKeyboard
//
//  Created by liluobin on 2023/5/15.
//

import LarkUIKit
import LarkKeyboardView
import LarkModel
import EditTextView
import LarkChatOpenKeyboard
import LarkMessengerInterface
import RustPB
import LarkSendMessage

public enum KeyboardAppearTriggerType {
    case inputTextView
    case keyboardItem(KeyboardItemKey) // KeyboardItemKey
}

public protocol ChatOpenKeyboardSendService {
    /// 发送普通文本消息 -> 设置定时发送
    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  position: Int32,
                  scheduleTime: Int64?,
                  quasiMsgCreateByNative: Bool,
                  callback: ((SendMessageState) -> Void)?)
    /// 发送Post的消息
    func sendPost(title: String,
                  content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  scheduleTime: Int64?,
                  stateHandler: ((SendMessageState) -> Void)?)
}

public protocol ChatOpenKeyboardDelegate: AnyObject {
    func getKeyboardStartupState() -> KeyboardStartupState
    func handleKeyboardAppear(triggerType: KeyboardAppearTriggerType)
    func keyboardFrameChanged(frame: CGRect)
    func inputTextViewFrameChanged(frame: CGRect)
    /// 插入图片，返回值是 是否应该继续向输入框插入图片，默认为 返回 false 的空实现
    func inputTextViewWillInput(image: UIImage) -> Bool
    func rootViewController() -> UIViewController
    func baseViewController() -> UIViewController
    func keyboardWillExpand()
    func textChange(text: String, textView: LarkEditTextView)
    func keyboardContentHeightWillChange(_ isFold: Bool)
}
