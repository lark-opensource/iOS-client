//
//  ChatOpenKeyboardService.swift
//  LarkChatOpenKeyboard
//
//  Created by liluobin on 2023/5/11.
//

import UIKit
import LarkKeyboardView
import LarkModel
import Swinject
import EditTextView
import RustPB
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkChatOpenKeyboard
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface

public struct ChatOpenKeyboardConfig {
    public struct AbilityConfig {
        public let supportRichTextEdit: Bool
        public let supportRealTimeTranslate: Bool
        public let disableReplyBar: Bool
        public let supportAfterMessagesRender: Bool
        public let forbidDraft: Bool
        public let supportAtMyAI: Bool
        public let unsupportPasteType: [KeyboardSupportPasteType]

        public init(supportRichTextEdit: Bool,
                    supportRealTimeTranslate: Bool,
                    disableReplyBar: Bool = false,
                    supportAfterMessagesRender: Bool = false,
                    forbidDraft: Bool = false,
                    supportAtMyAI: Bool = false,
                    unsupportPasteType: [KeyboardSupportPasteType] = []) {
            self.supportRichTextEdit = supportRichTextEdit
            self.supportRealTimeTranslate = supportRealTimeTranslate
            self.disableReplyBar = disableReplyBar
            self.supportAfterMessagesRender = supportAfterMessagesRender
            self.forbidDraft = forbidDraft
            self.unsupportPasteType = unsupportPasteType
            self.supportAtMyAI = supportAtMyAI
        }
    }

    public struct DataConfig {
        public let chat: Chat
        public let context: ChatKeyboardContext
        public let userResolver: UserResolver
        /// 剪切板复制粘贴token 安全需求需要
        public let copyPasteToken: String
        /// 配置支持配置的按钮
        public var items: [ChatKeyboardItemTypeProtocol]
        /// 常见的回调方法
        public weak var delegate: ChatOpenKeyboardDelegate?

        public let sendService: ChatOpenKeyboardSendService
        public let rootMessage: Message?
        public let keyboardViewDidInitCallBack: ((IMKeyBoardView) -> Void)?

        public init(chat: Chat,
                    context: ChatKeyboardContext,
                    userResolver: UserResolver,
                    copyPasteToken: String,
                    delegate: ChatOpenKeyboardDelegate?,
                    sendService: ChatOpenKeyboardSendService,
                    items: [ChatKeyboardItemTypeProtocol],
                    rootMessage: Message? = nil,
                    keyboardViewDidInitCallBack: ((IMKeyBoardView) -> Void)? = nil) {
            self.chat = chat
            self.context = context
            self.userResolver = userResolver
            self.copyPasteToken = copyPasteToken
            self.delegate = delegate
            self.sendService = sendService
            self.items = items
            self.rootMessage = rootMessage
            self.keyboardViewDidInitCallBack = keyboardViewDidInitCallBack
        }
    }

    public let abilityConfig: AbilityConfig
    public let dataConfig: DataConfig

    public init(dataConfig: DataConfig,
                abilityConfig: AbilityConfig) {
        self.dataConfig = dataConfig
        self.abilityConfig = abilityConfig
    }
}

/// 打包IMChat的键盘 供外界使用
/// 外界可以不感知具体实现 低成本的使用IM的键盘
/// 根据对应的接口配置功能
public protocol ChatOpenKeyboardService: AnyObject {

    ///loadChatKeyboardViewWithConfig 之后才会创建
    var chatKeyboardView: IMKeyBoardView? { get }

    ///loadChatKeyboardViewWithConfig 之后才会创建
    var keyboardStatusManager: KeyboardStatusManager? { get }

    /// 加载Chat的键盘，返回一个IMKeyBoardView的实例
    /// 没有加载调用任何都是无用的
    func loadChatKeyboardViewWithConfig(_ config: ChatOpenKeyboardConfig) -> IMKeyBoardView?

    /// 是否支持展示展开按钮 default = true
    func showExpandButton(_ show: Bool)

    /// 设置支持Panel Menu items
    /// - Parameter order: 按钮的展示顺序，不在order中的按钮 不会展示
    /// 不设置 默认使用chat的顺序
    func setSupportItemOrder(_ order: [KeyboardItemKey])

    /// 设置支持的Panel Menu items
    /// - Parameter whiteList: 支持按钮，默认按照Chat规则的展示
    func setSupportItemWhiteList(_ whiteLis: [KeyboardItemKey])

    /// 弹出键盘
    func showKeyboard()

    /// 收起键盘
    func foldKeyboard()

    /// 设置键盘的状态
    func setupStartupKeyboardState()

    /// 清空回复信息
    func clearReplyMessage()

    /// 获取回复的消息
    func getReplyMessage() -> Message?

    /// 更新attributedText图片&视频的尺寸
    func updateAttachmentSizeFor(attributedText: NSAttributedString)

    /// 如果一些操作需要在键盘初始化草稿之后完成，调用该方法
    /// 禁止草稿后不会调用
    func actionAfterKeyboardInitDraftFinish(_ action: @escaping () -> Void)

    /// 存储草稿操作 forbidDraft = true 这个接口将失效
    func saveInputViewDraft(callback: DraftCallback?)

    /// 自定义输入框占位文字
    /// - Parameter attributedPlaceholder: 占位文字
    func setAttributedPlaceholder(_ attributedPlaceholder: NSAttributedString)
}
