//
//  MessengerCryptoChatKeyboardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/20.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkOpenChat
import LarkOpenIM
import LarkFeatureGating
import LarkContainer
import RustPB
import LarkModel
import EENavigator
import LarkNavigation
import LarkUIKit
import LarkMessengerInterface
import LarkSDKInterface
import LarkCore
import LarkAlertController
import LarkRichTextCore
import LarkBaseKeyboard
import EditTextView
import LarkMessageCore
import LarkChatOpenKeyboard

public final class MessengerCryptoChatKeyboardSubModule: CryptoChatKeyboardSubModule {
    // MARK: - 「+」号菜单
    public override var moreItems: [ChatKeyboardMoreItem] {
        return _moreItems
    }
    private var _moreItems: [ChatKeyboardMoreItem] = []
    private var metaModel: ChatKeyboardMetaModel?

    public override class func canInitialize(context: ChatKeyboardContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatKeyboardMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatKeyboardMetaModel) -> [Module<ChatKeyboardContext, ChatKeyboardMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatKeyboardMetaModel) {
        self.metaModel = model
    }

    public override func createMoreItems(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
        self._moreItems = self.buildMoreItems(metaModel: metaModel)
    }

    private func buildMoreItems(metaModel: ChatKeyboardMetaModel) -> [ChatKeyboardMoreItem] {
        var items: [ChatKeyboardMoreItem] = [file, sendLocation, shareUserCard].compactMap { $0 }
        return items
    }

    // MARK: file
    private lazy var file: ChatKeyboardMoreItem? = {
        if self.context.hasRootMessage { return nil }
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Legacy_FileLabel,
            icon: Resources.cloud_file,
            type: .file,
            tapped: { [weak self] in
                self?.clickFile()
            })
        return item
    }()

    private func clickFile() {
        guard let generalSettings = try? self.context.resolver.resolve(assert: UserGeneralSettings.self) else { return }
        ChatTracker.trackSendAttachedFileIconClicked()
        if let chat = self.metaModel?.chat {
            IMTracker.Chat.InputPlus.Click.localFile(chat)
        }

        let chooseFileBlock: ([LocalAttachFile]) -> Void = { [weak self] (files) in
            guard let self = self else { return }
            files.forEach {
                self.context.sendFile(path: $0.fileURL.path, name: $0.name, parentMessage: nil)
            }
        }

        let from = self.context.baseViewController()
        var body = LocalFileBody()
        // 获取settings下发的文件大小发送限制
        body.maxSingleFileSize = generalSettings.fileUploadSizeLimit.value.maxSingleFileSize
        body.maxTotalFileSize = generalSettings.fileUploadSizeLimit.value.maxTotalFileSize
        body.requestFrom = .im
        body.chooseLocalFiles = chooseFileBlock
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
    }

    // MARK: sendLocation
    private lazy var sendLocation: ChatKeyboardMoreItem? = {
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Chat_InputwindowExpansionLocation,
            icon: Resources.location_keyboard,
            type: .location,
            tapped: { [weak self] in
                self?.clickSendLocation()
            })
        return item
    }()

    private func clickSendLocation() {
        let from = self.context.baseViewController()
        var body = SendLocationBody(psdaToken: "")
        body.sendAction = self.sendCurrentLocation
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepare: {
                $0.modalPresentationStyle = .formSheet
            })
        self.context.foldKeyboard()
        ChatTracker.trackLocationEnter()
        IMTracker.Chat.InputPlus.Click.location(self.metaModel?.chat)
    }

    private func sendCurrentLocation(model: LocationContent, image: UIImage, mapType: String, selectedType: String) {
        guard let chatModel = self.metaModel?.chat else { return }
        /// 打点需求https://bytedance.feishu.cn/space/sheet/shtcnTF0isNVyxTNpfC4PaHLBff#dd8e91
        var chatType = ""
        switch chatModel.type {
        case .p2P:
            chatType = "single"
        case .group:
            chatType = "group"
        case .topicGroup:
            chatType = "topicGroup"
        @unknown default:
            assert(false, "new value")
            chatType = "unknown"
        }
        if chatModel.chatMode == .threadV2 {
            chatType = "group_topic"
        } else if chatType == "single", let chatterType = chatModel.chatter?.type, chatterType == .bot {
            chatType = "single_bot"
        }

        var nameType = "none"
        if !model.location.name.isEmpty {
            nameType = "building"
        } else if !model.location.description_p.isEmpty {
            nameType = "full_address"
        }

        ChatTracker.trackLocationSent(nameType: nameType, chatType: chatType, resultType: selectedType)
        ChatTracker.trackLocationMapType(type: mapType)

        self.context.sendLocation(
            parentMessage: self.context.getRootMessage(),
            screenShot: image,
            location: model
        )
    }

    // MARK: shareUserCard
    private lazy var shareUserCard: ChatKeyboardMoreItem? = {
        if self.context.hasRootMessage { return nil }
        let item = ChatKeyboardMoreItemConfig(
            text: BundleI18n.LarkChat.Lark_Legacy_SendUserCard,
            icon: Resources.profile_card,
            type: .userCard,
            tapped: { [weak self] in
                self?.clickShareUserCard()
            })
        return item
    }()

    private func clickShareUserCard() {
        guard let chatModel = self.metaModel?.chat else { return }
        IMTracker.Chat.InputPlus.Click.PersonalCard(chatModel)
        ChatTracker.trackSendUserCardIconClicked()

        let chooseUserCardBlock: (String) -> Void = { [weak self] shareChatterId in
            guard let self = self else { return }
            self.context.sendUserCard(shareChatterId: shareChatterId)
        }

        let from = self.context.baseViewController()
        var body = ChatterPickerBody()
        body.selectStyle = .single(style: .callbackWithReset)
        body.title = BundleI18n.LarkChat.Lark_Legacy_SelectUserCard
        body.dataOptions = [.external]
        body.cancelCallback = {
            ChatTracker.trackSendUserCardCancel()
        }
        body.enableRelatedOrganizations = false
        body.selectedCallback = { [userResolver]controler, contactPickerResult in
            guard let controller = controler else {
                return
            }

            let alertController = LarkAlertController()
            alertController.setContent(text: BundleI18n.LarkChat.Lark_Legacy_UserCardConfirm, font: UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium))
            alertController.addCancelButton()
            alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_Send, dismissCompletion: { [weak controller] in
                let chatterIDs = contactPickerResult.chatterInfos.map { $0.ID }
                if let shareChatterId = chatterIDs.first, !shareChatterId.isEmpty {
                    chooseUserCardBlock(shareChatterId)
                    if let channel = contactPickerResult.extra as? String {
                        ChatTracker.trackChooseUserCardSuccess(channel: channel)
                    }
                } else {
                    ChatRouterImpl.logger.error("选人时获取不到 chatterId")
                }
                controller?.dismiss(animated: true, completion: nil)
            })
            userResolver.navigator.present(alertController, from: controller)
        }
        navigator.present(
            body: body,
            from: from,
            prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() }
        )
        self.context.foldKeyboard()
    }

    // MARK: - input handler
    public override var inputHandlers: [ChatKeyboardInputOpenProtocol] {
        return _inputHandlers
    }
    private var _inputHandlers: [ChatKeyboardInputOpenProtocol] = []

    public override func createInputHandlers(metaModel: ChatKeyboardMetaModel) {
        self.metaModel = metaModel
        self._inputHandlers = [returnInputHandler,
                               atPickerInputHandler,
                               atUserInputHandler,
                               emojiInputHandler]
    }

    private lazy var keyboardNewStyleEnable: Bool = {
        return KeyboardDisplayStyleManager.isNewKeyboadStyle()
    }()

    private lazy var atPickerInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = AtPickerInputHandler { [weak self] (textView, range, _) in
            textView.resignFirstResponder()
            guard let self = self,
                  let chatModel = self.metaModel?.chat,
                  let textView = textView as? LarkEditTextView else { return }

            let defaultTypingAttributes = textView.defaultTypingAttributes
            let from = self.context.baseViewController()
            var body = AtPickerBody(chatID: chatModel.id)
            body.cancel = {
                textView.becomeFirstResponder()
            }
            body.completion = { [weak self] (selectItems) in
                guard let self = self else { return }
                // 删除已经插入的at
                textView.selectedRange = NSRange(location: range.location + 1, length: range.length)
                textView.deleteBackward()

                // 插入at标签
                selectItems.forEach { item in
                    self.context.insertAtChatter(name: item.name,
                                                 actualName: item.actualName,
                                                 id: item.id,
                                                 isOuter: item.isOuter)
                }
                textView.defaultTypingAttributes = defaultTypingAttributes
            }
            self.navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepare: { $0.modalPresentationStyle = LarkCoreUtils.autoAdaptStyle() }
            )
            IMTracker.Chat.Main.Click.AtMention(chatModel, isFullScreen: false, self.context.store.getValue(for: IMTracker.Chat.Main.ChatFromWhereKey))
        }
        return CryptoChatKeyboardInputOpenHandler(
            type: .atPicker,
            handler: handler
        )
    }()

    private lazy var returnInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = ReturnInputHandler { [weak self] (_) -> Bool in
            if self?.keyboardNewStyleEnable ?? false {
                return true
            } else {
                self?.context.sendInputContentAsMessage()
                return false
            }
        }
        handler.newlineFunc = { (textView) -> Bool in
            // 搜狗换行会 先输入 \r\r 然后删除一个字符 所以这里需要输入两个 \n
            textView.insertText("\n\n")
            return false
        }
        return CryptoChatKeyboardInputOpenHandler(
            type: .return,
            handler: handler
        )
    }()

    private lazy var atUserInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = AtUserInputHandler()
        return CryptoChatKeyboardInputOpenHandler(
            type: .atUser,
            handler: handler
        )
    }()

    private lazy var emojiInputHandler: ChatKeyboardInputOpenProtocol = {
        let handler = EmojiInputHandler(supportFontStyle: false)
        return CryptoChatKeyboardInputOpenHandler(
            type: .emoji,
            handler: handler
        )
    }()
}

final class CryptoChatKeyboardInputOpenHandler: ChatKeyboardInputOpenProtocol {
    let type: ChatKeyboardInputOpenType
    private let handler: TextViewInputProtocol

    init(type: ChatKeyboardInputOpenType, handler: TextViewInputProtocol) {
        self.type = type
        self.handler = handler
    }

    func register(textView: UITextView) {
        handler.register(textView: textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        handler.textViewDidChange(textView)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return handler.textView(textView, shouldChangeTextIn: range, replacementText: text)
    }
}
