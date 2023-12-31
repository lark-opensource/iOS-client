//
//  NormalChatInputKeyboard+AI.swift
//  LarkChat
//
//  Created by Hayden on 27/6/2023.
//

import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAIInfra
import ServerPB
import EditTextView
import LarkOpenChat
import LarkBaseKeyboard
import LarkMessengerInterface

// MARK: MyAIQuickActionSendService

extension NormalChatInputKeyboard: MyAIQuickActionSendService {

    /// 实现 MyAIQuickActionSendService 协议方法
    public func handleAIQuickAction(_ quickAction: ServerPB_Office_ai_QuickAction, sendTracker: QuickActionSendTracker) {
        currentSendTracker = sendTracker
        // 处理 query 类型的快捷指令
        if quickAction.typeIsQuery {
            Self.logger.info("[MyAI.QuickAction][Handle][\(#function)] handle quick action query, enter editing")
            // 7.1 版本需求：Query 类型快捷指令改为直接发送
            sendQuery(quickAction)
            return
        }
        // 处理 promptTask 和 api 类型的快捷指令
        if quickAction.needUserInput {
            // 带参数的快捷指令进入到输入框编辑
            Self.logger.info("[MyAI.QuickAction][Handle][\(#function)] has unconfirmed params, enter editing")
            editQuickAction(quickAction)
        } else {
            // 没有参数的快捷指令直接发送
            Self.logger.info("[MyAI.QuickAction][Handle][\(#function)] no params, send directly")
            sendQuickAction(quickAction)
        }
    }
}

// MARK: - Handle QuickAction

extension NormalChatInputKeyboard {

    private struct AssociatedKeys {
        static var queryKey = "MyAIQueryKey"
        static var quickActionKey = "MyAIQuickActionKey"
        static var sendCallbackKey = "MyAIQuickActionSendCallbackKey"
    }

    /// 记录当前正在处理的快捷指令（Query 类型）
    fileprivate var currentQuery: AIQuickActionModel? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.queryKey) as? AIQuickActionModel
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.queryKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 记录当前正在处理的快捷指令（API、PrompTask 类型）
    fileprivate var currentQuickAction: AIQuickAction? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.quickActionKey) as? AIQuickAction
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.quickActionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// 保存快捷指令埋点回调。闭包由 LarkAI 传入，闭包内执行埋点逻辑。
    fileprivate var currentSendTracker: QuickActionSendTracker? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.sendCallbackKey) as? QuickActionSendTracker
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sendCallbackKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: Query QuickAction

    /// 理 Query 快捷指令：直接上屏发送（7.1 需求：Query 直接发送）
    func sendQuery(_ quickAction: AIQuickAction) {
        var contentAttr = NSAttributedString(string: quickAction.realDisplayName)
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        guard var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) else { return }
        richText.richTextVersion = 1
        self.viewModel.messageSender?.sendAIQuery(
            content: richText,
            chatId: viewModel.chatModel.id,
            position: viewModel.chatModel.lastMessagePosition,
            quickActionBody: quickAction,
            callback: nil
        )
        Self.logger.warn("[MyAI.QuickAction][Send][\(#function)] send (query) quick action directly: \(contentAttr.string)")
        currentSendTracker?.reportSendEvent(isEdited: false, chat: self.viewModel.chatModel)
        currentSendTracker = nil
    }

    /// 处理 Query 快捷指令：添加到输入框的最后（7.1 需求：Query 添加到输入框最后，由用户发送）
    func appendQuery(_ quickAction: AIQuickActionModel) {
        if case .quickAction = keyboardView.keyboardStatusManager.currentKeyboardJob {
            exitQuickActionEditingState()
        }
        // 将 Query 填进输入框
        let currentText = NSMutableAttributedString(attributedString: keyboardView.attributedString)
        let queryText = NSAttributedString(string: quickAction.realDisplayName, attributes: chatKeyboardView?.inputTextView.defaultTypingAttributes ?? [:])
        currentText.append(queryText)
        keyboardView.attributedString = currentText
        Self.logger.info("[MyAI.QuickAction][Send][\(#function)] append query to current editing text: \(quickAction.realDisplayName)")
        // 弹起键盘
        keyboardView.inputTextView.becomeFirstResponder()
        currentQuery = quickAction
    }

    /// 输入框中的内容被发送出去时执行，进行 Query 快捷指令的埋点
    /// - Parameter richText: 当前输入框的 richText
    func trackQuerySendingEventIfNeeded(_ richText: RustPB.Basic_V1_RichText) {
        guard let quickAction = currentQuery,
              let currentInputString = RichTextTransformKit.transformRichTexToText(richText) else {
            return
        }
        let isEdited = quickAction.realDisplayName != currentInputString
        currentSendTracker?.reportSendEvent(isEdited: isEdited, chat: self.viewModel.chatModel)
        currentSendTracker = nil
        currentQuery = nil
    }

    // MARK: Non-Param QuickAction

    /// 不需要确认参数的快捷指令，直接通过 Keyboard 调用 MessageSender，将快捷指令作为消息发送出去
    func sendQuickAction(_ quickAction: AIQuickAction) {
        var contentAttr = NSAttributedString(string: quickAction.displayName)
        contentAttr = RichTextTransformKit.preproccessSendAttributedStr(contentAttr)
        guard var richText = RichTextTransformKit.transformStringToRichText(string: contentAttr) else { return }
        richText.richTextVersion = 1
        // 直接发送不带参数的快捷指令
        let unconfirmableParams = quickAction.unconfirmableParams
        self.viewModel.messageSender?.sendAIQuickAction(
            content: richText,
            chatId: viewModel.chatModel.id,
            position: viewModel.chatModel.lastMessagePosition,
            quickActionID: quickAction.id,
            quickActionParams: unconfirmableParams,
            quickActionBody: quickAction,
            callback: nil
        )
        Self.logger.info("[MyAI.QuickAction][Send][\(#function)] send (no params) quick action directly: \(contentAttr.string), unconfirmableParams: \(unconfirmableParams)")
        currentSendTracker?.reportSendEvent(isEdited: false, chat: self.viewModel.chatModel)
        currentSendTracker = nil
    }

    // MARK: Param QuickAction

    /// 带参数的快捷指令，进入到 Keyboard，等待用户编辑
    func editQuickAction(_ quickAction: AIQuickAction) {
        enterQuickActionEditingState(quickAction)
    }

    /// 操作 Keyboard，进入 QuickAction 编辑态，并弹起键盘
    func enterQuickActionEditingState(_ quickAction: AIQuickAction) {
        // 将键盘状态调整为 QuickAction
        keyboardView.switchJob(.quickAction)
        keyboardView.inputTextView.smartInsertDeleteType = .no
        // 根据 QuickAction 结构，构建 NSAttributedString，并放入键盘中
        let defaultAttributes = chatKeyboardView?.inputTextView.defaultTypingAttributes
        let attributedContent = QuickActionAttributeUtils.transformContentToString(quickAction, attributes: defaultAttributes)
        keyboardView.titleEditView?.textView.text = nil
        keyboardView.attributedString = attributedContent
        // 弹起键盘
        keyboardView.inputTextView.becomeFirstResponder()
        // 将光标移动到第一个参数的位置（因为参数不一定有 placeholder，因此设为 paramTitle 的最后一位）
        // TODO: 下沉到 QuickActionTransformer
        let paramPlaceholderKey = NSAttributedString.Key(rawValue: "ai.quickAction.paramPlaceholderKey")
        if let firstPlaceholderRange = attributedContent.getRanges(ofKey: paramPlaceholderKey).first {
            keyboardView.inputTextView.selectedRange = firstPlaceholderRange.firstPlace
        }
        currentQuickAction = quickAction
    }

    /// 操作 Keyboard，退出 QuickAction 编辑态，并清空输入
    func exitQuickActionEditingState() {
        keyboardView.richText = nil
        keyboardView.switchToDefaultJob()
        keyboardView.inputTextView.smartInsertDeleteType = .default
        currentQuickAction = nil
        currentSendTracker = nil
    }

    /// 从 Keyboard 用户输入区读取文字，解析出 QuickAction 参数并发送
    func sendQuickActionFromCurrentEditing() {
        // 假上屏的消息要删除没有填写的 Placeholder
        guard let richText = keyboardView.richText else {
            Self.logger.error("[MyAI.QuickAction][Send][\(#function)] can not get rich text from keyboard view")
            return
        }
        let content = keyboardView.attributedString
        var contentByRemovingPlaceholder = QuickActionAttributeUtils.clipEmptyPlaceholders(from: content)
        contentByRemovingPlaceholder = RichTextTransformKit.preproccessSendAttributedStr(contentByRemovingPlaceholder)
        var quickActionText = RichTextTransformKit.transformStringToRichText(string: contentByRemovingPlaceholder) ?? richText
        quickActionText.richTextVersion = 1
        Self.logger.info("[MyAI.QuickAction][Send][\(#function)] get user input from keyboard: \(contentByRemovingPlaceholder.string.desensitized())")

        // 解析 QuickAction 的必要参数
        guard let (actionID, params) = QuickActionAttributeUtils.parseQuickAction(from: content) else {
            // 如果无法解析到 ID，降级为普通消息
            self.viewModel.messageSender?.sendText(
                content: quickActionText,
                lingoInfo: nil,
                parentMessage: nil,
                chatId: viewModel.chatModel.id,
                position: viewModel.chatModel.lastMessagePosition,
                quasiMsgCreateByNative: quasiMsgCreateByNative,
                callback: nil
            )
            Self.logger.warn("[MyAI.QuickAction][Send][\(#function)] invalid quick action: no id, send plain text from current editing: \(contentByRemovingPlaceholder.string.desensitized())")
            currentSendTracker?.reportSendEvent(isEdited: true, chat: self.viewModel.chatModel)
            exitQuickActionEditingState()
            return
        }
        if !QuickActionAttributeUtils.checkQuickActionValidity(from: content) {
            // 如果 QuickAction 结构被破坏，降级为普通消息
            self.viewModel.messageSender?.sendText(
                content: quickActionText,
                lingoInfo: nil,
                parentMessage: nil,
                chatId: viewModel.chatModel.id,
                position: viewModel.chatModel.lastMessagePosition,
                quasiMsgCreateByNative: quasiMsgCreateByNative,
                callback: nil
            )
            Self.logger.warn("[MyAI.QuickAction][Send][\(#function)] invalid quick action: invalid param input, send plain text from current editing: \(contentByRemovingPlaceholder.string)")
            currentSendTracker?.reportSendEvent(isEdited: true, chat: self.viewModel.chatModel)
            exitQuickActionEditingState()
            return
        }

        // richTag 的快捷指令参数
        let richTagParams = QuickActionAttributeUtils.parseQuickActionRichTagParams(from: content, with: currentQuickAction?.needUserInputParamNames ?? [])
        let userParams = richTagParams.merging(params, uniquingKeysWith: { (_, new) in new })
        // 发送快捷指令（发送前要合并不需确认的参数）
        // let defaultParams = currentQuickAction?.unconfirmableParams ?? [:]
        let defaultParams = currentQuickAction?.allParamsMap ?? [:]
        let fullParams = defaultParams.merging(userParams, uniquingKeysWith: { (_, new) in new })
        self.viewModel.messageSender?.sendAIQuickAction(
            content: quickActionText,
            chatId: viewModel.chatModel.id,
            position: viewModel.chatModel.lastMessagePosition,
            quickActionID: actionID,
            quickActionParams: fullParams,
            quickActionBody: currentQuickAction,
            callback: nil
        )
        Self.logger.info("[MyAI.QuickAction][Send][\(#function)] send quick action from current editing. id: \(actionID), userParams: \(params.desensitized()), fullParams: \(fullParams.desensitized())")
        // 检查是否填充了所有必填参数，如果没有，不影响发送，但是给出提示
        if let currentQuickAction = currentQuickAction {
            var missingParams: [String] = []
            for paramDetail in currentQuickAction.paramDetails where !paramDetail.isOptional {
                if fullParams[paramDetail.name] == nil {
                    missingParams.append(paramDetail.name)
                }
            }
            if !missingParams.isEmpty {
                Self.logger.error("[MyAI.QuickAction][Send][\(#function)] quick action missing required param: \(missingParams)")
            }
            // let isEdited = currentQuickAction.allParamsMap != fullParams
            // 按埋点要求，这里采用简单的方式：只要字符有改变，都算作 Edited
            let isEdited = QuickActionAttributeUtils.transformContentToString(currentQuickAction).string != content.string
            // 上报埋点，回调到 LarkAI 模块处理
            currentSendTracker?.reportSendEvent(isEdited: isEdited, chat: self.viewModel.chatModel)
        }
        exitQuickActionEditingState()
    }
}

// MARK: - Desensitized

fileprivate extension Dictionary where Value == String {

    /// 日志中的参数列表内容脱敏
    func desensitized() -> Self {
        self.mapValues { $0.desensitized() }
    }
}

fileprivate extension String {

    /// 日志中的文字内容脱敏
    func desensitized() -> Self {
        var desensitizedString = self
        let stringLength = desensitizedString.count
        if desensitizedString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return self
        }
        if stringLength <= 4 {
            desensitizedString = String(repeating: "*", count: stringLength)
        } else {
            let startIndex = desensitizedString.index(desensitizedString.startIndex, offsetBy: 2)
            let endIndex = desensitizedString.index(desensitizedString.endIndex, offsetBy: -2)
            desensitizedString.replaceSubrange(startIndex..<endIndex, with: "**(\(stringLength))**")
        }
        return desensitizedString
    }
}
