//
//  MessagePinCardSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import LarkOpenChat
import RustPB
import LarkModel
import LarkMessageBase
import LarkMessageCore
import RxSwift
import RxCocoa
import LarkSDKInterface

public final class MessagePinCardSubModule: ChatPinCardSubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .messagePin
    }

    public override func canHandle(model: ChatPinCardMetaModel) -> Bool {
        return true
    }

    public override class func canInitialize(context: ChatPinCardContext) -> Bool {
        return true
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinCardContext) -> ChatPinPayload? {
        guard case .messagePin(let messagePinData) = pb else {
            return nil
        }
        let messageID = String(messagePinData.messageID)
        var messagePayload = MessageChatPinPayload(messageID: messagePinData.messageID)
        messagePayload.message = try? Message.transform(entity: extras.entity, id: messageID, currentChatterID: context.userResolver.userID)
        return messagePayload
    }

    private let disposeBag = DisposeBag()
    private var pageContext: PageContext?
    private var metaModel: ChatPinCardMetaModel?
    public override func modelDidChange(model: ChatPinCardMetaModel) {
        if let chat = self.metaModel?.chat,
           chat.firstMessagePostion != model.chat.firstMessagePostion {
            self.context.update(doUpdate: { return $0 as? MessageChatPinPayload }, completion: nil)
        }
        self.metaModel = model
    }

    public override func setup() {
        guard let chatID = self.metaModel?.chat.id else { return }
        let dragManager = DragInteractionManager()
        dragManager.viewTagBlock = { return $0.getASComponentKey() ?? "" }
        let pageContext = PageContext(
            resolver: self.context.userResolver,
            dragManager: dragManager,
            defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: self.context.userResolver)
        )
        self.pageContext = pageContext
        pageContext.dataSourceAPI = self
        pageContext.pageAPI = self.context.targetViewController as? PageAPI
        pageContext.pageContainer.register(ColorConfigService.self) {
            return ChatColorConfig()
        }

        self.context.container.register(MessageEngineCellViewModelFactory.self) { [unowned pageContext] _ -> MessageEngineCellViewModelFactory in
            return MessageEngineCellViewModelFactory(
                context: pageContext,
                registery: ChatPinMessageEngineSubFactoryRegistery(
                    context: pageContext, defaultFactory: MessageEngineUnknownContentFactory(context: pageContext)
                ),
                initBinder: { [unowned pageContext] contentComponent in
                    return ChatPinMessageEngineCellBinder<PageContext>(
                        contentComponent: contentComponent,
                        context: pageContext
                    )
                }
            )
        }

        self.context.pushCenter.observable(for: PushChannelMessages.self)
            .map { push -> [Message] in
                return push.messages.filter { message -> Bool in
                    return message.channel.id == chatID
                }
            }
            .filter { messages -> Bool in
                return !messages.isEmpty
            }
            .subscribe(onNext: { [weak self] messages in
                guard let self = self else { return }
                self.context.update(doUpdate: { payload in
                    guard var messagePayload = payload as? MessageChatPinPayload else { return nil }
                    if let updateMessage = messages.first(where: { $0.id == "\(messagePayload.messageID)" }) {
                        messagePayload.message = updateMessage
                        return messagePayload
                    }
                    return nil
                }, completion: nil)
            }).disposed(by: self.disposeBag)
    }
}

extension MessagePinCardSubModule: DataSourceAPI {
    /// UI 上对齐会话页
    public var scene: ContextScene { return .newChat }
    public func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>
    (_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return []
    }
    public func pauseDataQueue(_ pause: Bool) {}

    public func reloadTable() {
        self.context.refresh()
    }

    public func reloadRow(by messageId: String, animation: UITableView.RowAnimation) {
        self.context.calculateSizeAndUpateView { _, payload in
            guard let messagePayload = payload as? MessageChatPinPayload else { return false }
            return messageId == "\(messagePayload.messageID)"
        }
    }

    public func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {
        self.context.update(doUpdate: { payload in
            guard var messagePayload = payload as? MessageChatPinPayload else { return nil }
            if let oldMessage = messagePayload.message,
               let updateMessage = doUpdate(oldMessage) {
                messagePayload.message = updateMessage
                return messagePayload
            }
            return nil
        }, completion: nil)
    }

    public func deleteRow(by messageId: String) {}
    public func processMessageSelectedEnable(message: Message) -> Bool {
        return false
    }
    public func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
    public var hostUIConfig: HostUIConfig { return HostUIConfig(size: .zero, safeAreaInsets: .zero) }
    public var traitCollection: UITraitCollection? { return nil }
    public var supportAvatarLeftRightLayout: Bool { return false }
}
