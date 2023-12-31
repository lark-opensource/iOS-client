//
//  ChatPushWrapper.swift
//  LarkCore
//
//  Created by liuwanlin on 2019/2/25.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface

public protocol ChatPushWrapper {
    var chat: BehaviorRelay<Chat> { get }

    /*Rust目前存在订阅状态莫名丢失的bug,且无法定位问题，为了保证业务不受影响，端上暂时由会话页面
     通过Im_V1_GetChatMessagesRequest subscribChatEvent参数再次对会话进行订阅，
     暴露以下两个接口将操作告知ChatPushWrapperImpl，统一管理
     */
    //增加订阅引用计数
    func increaseSubscriber(chatId: String)
    //减少订阅引用计数
    func decreaseSubscriber(chatId: String)

    // MARK: - 确保当引用计数为0时，会话时区提示 Push 才会消失
    //进入会话引用计数
    func enterChat()
    //离开会话引用计数
    func exitChat()
}

final class ChatPushWrapperImpl: ChatPushWrapper, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(ChatPushWrapperImpl.self, category: "ChatPushWrapper")

    let chat: BehaviorRelay<Chat>

    private let disposeBag = DisposeBag()
    private let subCenter: SubscriptionCenter
    private let subscribeChatEventService: SubscribeChatEventService
    private let pushCenter: PushNotificationCenter
    private var chatterAPI: ChatterAPI
    private var chatAPI: ChatAPI

    init(userResolver: UserResolver, chat: Chat) throws {
        self.userResolver = userResolver
        self.pushCenter = try userResolver.userPushCenter
        self.subCenter = try userResolver.resolve(assert: SubscriptionCenter.self)
        self.subscribeChatEventService = try userResolver.resolve(assert: SubscribeChatEventService.self)
        self.chatterAPI = try userResolver.resolve(assert: ChatterAPI.self)
        self.chatAPI = try userResolver.resolve(assert: ChatAPI.self)

        let chatId = chat.id
        self.chat = BehaviorRelay<Chat>(value: chat)

        pushCenter.observable(for: PushChat.self).filter({ [weak self] (push) -> Bool in
            guard let `self` = self else { return  false }
            let currentChat = self.chat.value
            return push.chat.id == chatId && (push.chat.lastMessagePosition >= currentChat.lastMessagePosition && push.chat.lastThreadPosition >= currentChat.lastThreadPosition)
        }).subscribe(onNext: { [weak self] (push) in
            guard let `self` = self else { return }
            let newChat = push.chat
            if self.chat.value.type == .p2P, newChat.chatter == nil {
                newChat.chatter = self.chat.value.chatter
            }
            self.chat.accept(newChat)
        })
        .disposed(by: disposeBag)

        self.increaseSubscriber(chatId: chatId)
    }

    private var updateEventName: String {
        return "UpdateEventName_" + chat.value.id
    }

    private var timezoneName: String {
        return "ChatTimezone_" + chat.value.id
    }

    func increaseSubscriber(chatId: String) {
        subscribeChatEventService.increaseSubscriber(chatID: chatId)
        subCenter.increaseSubscriber(eventName: updateEventName) {
            //ChatPushWrapperImpl是多实例的，将挂载和数据更新等逻辑写在这里，避免逻辑冗余执行
            let chat = chat.value
            if chat.type == .p2P {
                let fetchChatterOb: Observable<Chatter?> = chatterAPI.getChatter(id: chat.chatterId)
                let chatterOb: Observable<Chatter?> = pushCenter.observable(for: PushChatters.self)
                    .map { (pushChatters) -> Chatter? in
                        return pushChatters.chatters.first(where: { (chatter) -> Bool in
                            return chatter.id == chat.chatterId
                        })
                    }
                let chatterChangeOb: Observable<Chatter?>
                if chat.chatter == nil {
                    chatterChangeOb = Observable.merge([fetchChatterOb, chatterOb])
                } else {
                    chatterChangeOb = chatterOb
                }
                chatterChangeOb.subscribe(onNext: { [weak self] (chatter) in
                    if let chatter = chatter, let chat = self?.chat.value {
                        let copyChat = chat.copy()
                        copyChat.chatter = chatter
                        self?.pushCenter.post(PushChat(chat: copyChat))
                    }
                }).disposed(by: disposeBag)
            }

            if chat.isSuper {
                //超大群chat同步不会太及时，主动拉取一下，手动做更新，这个要通过pushcenter发信号，ChatPushWrapperImpl是多实例的，要保证一致更新
                let chatId = chat.id
                chatAPI.fetchChat(by: chatId, forceRemote: true).subscribe { [weak self] chat in
                    if let chat = chat {
                        self?.pushCenter.post(PushChat(chat: chat))
                    } else {
                        Self.logger.error("chatTrace superChat fetchChat nil \(chatId)")
                    }
                } onError: { error in
                    Self.logger.error("chatTrace superChat fetchChat fail \(chatId)", error: error)
                }.disposed(by: disposeBag)
            }
        }
    }

    func decreaseSubscriber(chatId: String) {
        subscribeChatEventService.decreaseSubscriber(chatID: chatId)
        subCenter.decreaseSubscriber(eventName: updateEventName) {}
    }

    func enterChat() {
        let chatId = self.chat.value.id
        subCenter.increaseSubscriber(eventName: timezoneName) { [weak self] in
            guard let self = self else { return }
            self.chatAPI.enterChat(chatId: chatId).subscribe().disposed(by: self.disposeBag)
        }
    }

    func exitChat() {
        let chatId = self.chat.value.id
        subCenter.decreaseSubscriber(eventName: timezoneName) { [weak self] in
            guard let self = self else { return }
            self.chatAPI.exitChat(chatId: chatId).subscribe().disposed(by: self.disposeBag)
        }
    }

    deinit {
        let chatId = self.chat.value.id
        self.decreaseSubscriber(chatId: chatId)
    }
}

public final class SubscribeChatEventService {

    private let subCenter: SubscriptionCenter
    private let chatAPI: ChatAPI

    init(subCenter: SubscriptionCenter, chatAPI: ChatAPI) {
        self.subCenter = subCenter
        self.chatAPI = chatAPI
    }

    private var eventName: String {
        return "ChatEvent_"
    }

    public func increaseSubscriber(chatID: String) {
        subCenter.increaseSubscriber(eventName: eventName + chatID) {
            chatAPI.asyncSubscribeChatEvent(chatIds: [chatID], subscribe: true)
        }
    }

    public func decreaseSubscriber(chatID: String) {
        subCenter.decreaseSubscriber(eventName: eventName + chatID) {
            chatAPI.asyncSubscribeChatEvent(chatIds: [chatID], subscribe: false)
        }
    }
}
