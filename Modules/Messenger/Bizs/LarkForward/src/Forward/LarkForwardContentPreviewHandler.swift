//
//  LarkForwardContentPreviewHandle.swift
//  LarkForward
//
//  Created by ByteDance on 2022/8/2.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import LarkModel
import RxSwift
import LarkContainer
import RustPB

struct P2pChatterInfo {
    var p2PCreatorName: String = ""
    var p2PCreatorID: Int64 = 0
    var p2PPartnerName: String = ""
    var p2PPartnerID: Int64 = 0
}

public struct ForwardContentPreviewBodyInfo {
    var messages: [Message]
    var chat: Chat
    var chatterInfo: P2pChatterInfo
}

public extension ForwardContentPreviewBodyInfo {
    var title: String {
        switch self.chat.type {
        case .group, .topicGroup:
            return BundleI18n.LarkForward.Lark_Legacy_GroupChatHistory
        case .p2P:
            if self.chatterInfo.p2PPartnerName.isEmpty {
                return String(format: BundleI18n.LarkForward.Lark_Legacy_MergeforwardTitleOneside, self.chatterInfo.p2PCreatorName)
            } else {
                return String(format: BundleI18n.LarkForward.Lark_Legacy_MergeforwardTitleTwoside, self.chatterInfo.p2PCreatorName, self.chatterInfo.p2PPartnerName)
            }
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkForward.Lark_Legacy_Detail
        }
    }
}

final class LarkForwardContentPreviewHandler {
    typealias MessageReactionsInfo = [String: RustPB.Basic_V1_MergeForwardContent.MessageReaction]
    typealias Chatters = [String: LarkModel.Chatter]
    var chatAPI: ChatAPI
    var messageAPI: MessageAPI
    var chatterAPI: ChatterAPI
    let userResolver: UserResolver
    private var disposeBag = DisposeBag()

    init(chatAPI: ChatAPI, messageAPI: MessageAPI, chatterAPI: ChatterAPI, userResolver: UserResolver) {
        self.chatAPI = chatAPI
        self.messageAPI = messageAPI
        self.chatterAPI = chatterAPI
        self.userResolver = userResolver
    }

    public func generateForwardContentPreviewBodyInfo(messageIds: [String], chatId: String) -> Observable<ForwardContentPreviewBodyInfo?> {
        if !messageIds.isEmpty && !chatId.isEmpty {
            if userResolver.fg.staticFeatureGatingValue(with: "core.forward.preview_potential_crash_fix") {
                return self.chatAPI.fetchLocalChats([chatId]).flatMapLatest { [weak self] chatMaps -> Observable<ForwardContentPreviewBodyInfo?> in
                    guard let self, let chat = chatMaps[chatId] else { return .just(nil) }
                    let messageOb = self.messageAPI.fetchMessages(ids: messageIds)
                    let chatterOb = self.generateChatOfChatters(chat: chat)
                    return Observable.zip(messageOb, chatterOb).map { [weak self] (messages, chatterObject) -> ForwardContentPreviewBodyInfo? in
                        guard let self else { return nil }
                        var chatInfo = P2pChatterInfo()
                        if let chatterObject = chatterObject {
                            chatInfo = self.p2pChatterInfo(chat: chat, chatters: chatterObject)
                        }
                        let newMessages = messages.sorted(by: { $0.createTimeMs < $1.createTimeMs })
                        let previewBody = ForwardContentPreviewBodyInfo(messages: newMessages, chat: chat, chatterInfo: chatInfo)
                        return previewBody
                    }
                }
            }
            return Observable<ForwardContentPreviewBodyInfo?>.create({ [weak self] (observer) -> Disposable in
                guard let `self` = self,
                      let chat = self.chatAPI.getLocalChat(by: chatId) else {
                    observer.onNext((nil))
                    observer.onCompleted()
                    return Disposables.create()
                }
                let messageOb = self.messageAPI.fetchMessages(ids: messageIds)
                let chatterOb = self.generateChatOfChatters(chat: chat)
                Observable.zip(messageOb, chatterOb).subscribe(onNext: { [weak self] (messages, chatterObject) in
                    guard let `self` = self else { return }
                    var chatInfo = P2pChatterInfo()
                    if let chatterObject = chatterObject {
                        chatInfo = self.p2pChatterInfo(chat: chat, chatters: chatterObject)
                    }
                    let newMessages = messages.sorted(by: { $0.createTimeMs < $1.createTimeMs })
                    let previewBody = ForwardContentPreviewBodyInfo(messages: newMessages, chat: chat, chatterInfo: chatInfo)
                    observer.onNext(previewBody)
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
                return Disposables.create()
            })
        }
        return .just((nil))
    }

    public func generateForwardContentPreviewBodyInfo(message: Message) -> Observable<ForwardContentPreviewBodyInfo?> {
        if userResolver.fg.staticFeatureGatingValue(with: "core.forward.preview_potential_crash_fix") {
            return self.chatAPI.fetchLocalChats([message.channel.id]).flatMapLatest { [weak self] chatMaps -> Observable<ForwardContentPreviewBodyInfo?> in
                guard let self, let chat = chatMaps[message.channel.id] else { return .just(nil) }
                return self.generateChatOfChatters(chat: chat).map { [weak self] chatterObject -> ForwardContentPreviewBodyInfo? in
                    guard let self else { return nil }
                    var chatInfo = P2pChatterInfo()
                    if let chatterObject = chatterObject {
                        chatInfo = self.p2pChatterInfo(chat: chat, chatters: chatterObject)
                    }
                    let previewBody = ForwardContentPreviewBodyInfo(messages: [message], chat: chat, chatterInfo: chatInfo)
                    return previewBody
                }
            }
        }
        return Observable<ForwardContentPreviewBodyInfo?>.create({ [weak self] (observer) -> Disposable in
            guard let `self` = self,
                  let chat = self.chatAPI.getLocalChat(by: message.channel.id) else {
                observer.onNext((nil))
                observer.onCompleted()
                return Disposables.create()
            }
            self.generateChatOfChatters(chat: chat)
                .subscribe(onNext: { [weak self] (chatterObject) in
                    guard let `self` = self else { return }
                    var chatInfo = P2pChatterInfo()
                    if let chatterObject = chatterObject {
                        chatInfo = self.p2pChatterInfo(chat: chat, chatters: chatterObject)
                    }
                    let previewBody = ForwardContentPreviewBodyInfo(messages: [message], chat: chat, chatterInfo: chatInfo)
                    observer.onNext(previewBody)
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        })
    }

    func generateChatOfChatters(chat: Chat) -> Observable<Chatters?> {
        return Observable<Chatters?>.create({ [weak self] (observer) -> Disposable in
            guard let `self` = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            if chat.type == .p2P {
                 self.chatterAPI.getLocalChatChatters(chatId: chat.id, filter: nil, cursor: nil, limit: nil, condition: nil, offset: nil)
                    .flatMapLatest({ [weak self] (response) -> Observable<[String: Chatter]> in
                        guard let `self` = self else { return Observable.just([String: Chatter]()) }
                        var chatterIdList = [String]()
                        response.chatterIds.forEach({ chatterId in
                            if !chatterIdList.contains(chatterId) {
                                chatterIdList.append(chatterId)
                            }
                        })
                        return self.chatterAPI.fetchChatChatters(ids: chatterIdList, chatId: chat.id) })
                    .subscribe(onNext: { (result) in
                        guard let chatters = result as? Chatters else {
                            observer.onNext(nil)
                            observer.onCompleted()
                            return
                        }
                        observer.onNext(chatters)
                        observer.onCompleted()
                }).disposed(by: self.disposeBag)
            } else {
                observer.onNext(nil)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }

    private func p2pChatterInfo(chat: Chat, chatters: Chatters) -> (P2pChatterInfo) {
        var p2pChatterInfo = P2pChatterInfo()
        if chat.type == .p2P {
            chatters.keys.forEach({ chatterId in
                let chatter = chatters[chatterId]
                if chatterId != chat.chatterId {
                    p2pChatterInfo.p2PCreatorID = Int64(chatterId) ?? 0
                    p2pChatterInfo.p2PCreatorName = chatter?.name ?? ""
                } else {
                    p2pChatterInfo.p2PPartnerID = Int64(chatterId) ?? 0
                    p2pChatterInfo.p2PPartnerName = chatter?.name ?? ""
                }
            })
        }
        return p2pChatterInfo
    }
}
