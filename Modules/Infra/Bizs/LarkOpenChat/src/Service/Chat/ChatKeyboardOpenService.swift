//
//  ChatKeyboardOpenService.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2021/12/27.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import RxSwift

public protocol ChatKeyboardOpenService: AnyObject {
    /// 是否有根消息
    var hasRootMessage: Bool { get }
    /// 是否有回复消息
    var hasReplyMessage: Bool { get }
    /// 获取定时消息草稿
    var getScheduleDraft: Observable<RustPB.Basic_V1_Draft?> { get }
    /// 收起键盘
    func foldKeyboard()
    /// 刷新「+」号更多菜单区域
    func refreshMoreItems()
    /// 键盘所属的页面
    func baseViewController() -> UIViewController
    /// 获取根消息
    func getRootMessage() -> Message?
    /// 获取回复消息
    func getReplyMessage() -> Message?
    /// 清除回复消息
    func clearReplyMessage()
    /// 获取输入框内容
    func getInputRichText() -> RustPB.Basic_V1_RichText?
    /// 发送位置消息
    func sendLocation(parentMessage: Message?,
                      screenShot: UIImage,
                      location: LocationContent)
    /// 发送个人名片消息
    func sendUserCard(shareChatterId: String)
    /// 发送文件消息
    func sendFile(path: String,
                  name: String,
                  parentMessage: Message?)
    /// 发送 Text 消息
    func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?)
    /// 发送当前输入框的内容
    func sendInputContentAsMessage()
    /// 向输入框插入 At 人名
    /// - Parameters:
    ///   - name: 要插入的名字
    ///   - actualName: 用户实际的名字，可以使用chatter.localizedName
    ///   - id: user id
    ///   - isOuter: 是否为外部用户
    func insertAtChatter(name: String, actualName: String, id: String, isOuter: Bool)
    func insertUrl(urlString: String)
    func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum)
    func onMessengerKeyboardPanelSendLongPress()
    func onMessengerKeyboardPanelScheduleSendTaped(draft: RustPB.Basic_V1_Draft?)
}

public final class DefaultChatKeyboardOpenService: ChatKeyboardOpenService {
    public init() {}
    public var hasRootMessage: Bool { return false }
    public var hasReplyMessage: Bool { return false }
    // 需要拉取草稿拿到，因此是异步接口
    public var getScheduleDraft: Observable<RustPB.Basic_V1_Draft?> { return .empty() }
    
    public func foldKeyboard() {}
    public func refreshMoreItems() {}
    public func baseViewController() -> UIViewController { return UIViewController() }
    public func getRootMessage() -> Message? { return nil }
    public func getReplyMessage() -> Message? { return nil }
    public func clearReplyMessage() {}
    public func getInputRichText() -> RustPB.Basic_V1_RichText? { return nil }
    public func sendLocation(parentMessage: Message?,
                             screenShot: UIImage,
                             location: LocationContent) {}
    public func sendUserCard(shareChatterId: String) {}
    public func sendFile(path: String,
                         name: String,
                         parentMessage: Message?) {}
    public func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?) {}
    public func sendInputContentAsMessage() {}
    public func insertAtChatter(name: String, actualName: String, id: String, isOuter: Bool) {}
    public func insertUrl(urlString: String) {}
    public func insertUrl(title: String, url: URL, type: RustPB.Basic_V1_Doc.TypeEnum) {}
    public func onMessengerKeyboardPanelSendLongPress() {}
    public func onMessengerKeyboardPanelScheduleSendTaped(draft: RustPB.Basic_V1_Draft?) {}
}
