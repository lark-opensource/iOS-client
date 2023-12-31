//
//  MessagePinSummarySubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/31.
//

import Foundation
import LarkOpenChat
import RustPB
import LarkModel
import RxSwift
import RxCocoa
import LarkSDKInterface

public final class MessagePinSummarySubModule: ChatPinSummarySubModule {
    public override class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        return .messagePin
    }

    public override func canHandle(model: ChatPinSummaryMetaModel) -> Bool {
        return true
    }

    public override class func canInitialize(context: ChatPinSummaryContext) -> Bool {
        return true
    }

    private let disposeBag = DisposeBag()
    private var metaModel: ChatPinSummaryMetaModel?
    public override func modelDidChange(model: ChatPinSummaryMetaModel) {
        if let chat = self.metaModel?.chat,
           chat.firstMessagePostion != model.chat.firstMessagePostion {
            self.context.update(doUpdate: { return $0 as? MessageChatPinPayload }, completion: nil)
        }
        self.metaModel = model
    }

    public override class func parse(pindId: Int64, pb: UniversalChatPinPBModel, extras: UniversalChatPinsExtras, context: ChatPinSummaryContext) -> ChatPinPayload? {
        guard case .messagePin(let messagePinData) = pb else {
            return nil
        }
        let messageID = String(messagePinData.messageID)
        var messagePayload = MessageChatPinPayload(messageID: messagePinData.messageID)
        messagePayload.message = try? Message.transform(entity: extras.entity, id: messageID, currentChatterID: context.userResolver.userID)
        return messagePayload
    }

    public override func setup() {
        guard let chatID = self.metaModel?.chat.id else { return }
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
