//
//  ChatServiceImpl.swift
//  Lark
//
//  Created by zc09v on 2018/6/12.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkContainer
import RxSwift
import LarkSDKInterface
import LKCommonsLogging
import LarkAccountInterface
import RustPB
import LarkStorage
import LarkSetting

final class ChatServiceImpl: ChatService {
    static let logger = Logger.log(ChatServiceImpl.self, category: "ChatServiceImpl")
    let chatAPI: ChatAPI
    let chatterAPI: ChatterAPI
    let userID: String
    let userPushCenter: PushNotificationCenter
    private let disposeBag = DisposeBag()
    private lazy var userStore = KVStores.udkv(
        space: .user(id: userID),
        domain: Domain.biz.messenger.child("Chat")
    )

    init(
        chatAPI: ChatAPI,
        chatterAPI: ChatterAPI,
        userID: String,
        userPushCenter: PushNotificationCenter
    ) {
        self.chatAPI = chatAPI
        self.chatterAPI = chatterAPI
        self.userID = userID
        self.userPushCenter = userPushCenter
    }

    func createP2PChat(userId: String, isCrypto: Bool, chatSource: CreateChatSource?) -> Observable<Chat> {
        return self.createP2PChat(userId: userId, isCrypto: isCrypto, isPrivateMode: false, chatSource: nil)
    }

    func createP2PChat(userId: String, isCrypto: Bool, isPrivateMode: Bool, chatSource: CreateChatSource?) -> Observable<Chat> {
        // NOTES: 密聊/密盾群直接调用创建chat的接口, sdk 未提供获取本地密聊的接口且做了判重, 普通会话需要先调用本地接口防止重复创建.
        if !isCrypto, !isPrivateMode {
            return chatAPI.fetchLocalP2PChat(by: userId)
                .catchErrorJustReturn(nil)
                .flatMap({ [weak self] (chat) -> Observable<Chat> in
                    guard let self = self else {
                        return Observable.empty()
                    }
                    // 如果没有chat，说明本地不存在，需要调用创建接口
                    guard let chat = chat else {
                        var param = CreateGroupParam(type: .p2P)
                        param.chatterIds = [userId]
                        param.isCrypto = isCrypto
                        param.createChatSource = chatSource
                        return self.chatAPI.createChat(param: param).map { $0.chat }
                    }

                    return self.chatAPI.fetchChat(by: chat.id, forceRemote: false)
                        .catchError({ (error) -> Observable<Chat?> in
                            ChatServiceImpl.logger.error("fetchChat error", additionalData: ["chatId": chat.id], error: error)
                            return .just(chat)
                        })
                        .compactMap({ $0 })
                })
        } else {
            var param = CreateGroupParam(type: .p2P)
            param.chatterIds = [userId]
            param.isCrypto = isCrypto
            param.isPrivateMode = isPrivateMode
            return self.chatAPI.createChat(param: param).map { $0.chat }
        }
    }

    // swiftlint:disable function_parameter_count
    func createGroupChat(name: String,
                         desc: String,
                         chatIds: [String],
                         departmentIds: [String],
                         userIds: [String],
                         fromChatId: String,
                         messageIds: [String],
                         messageId2Permissions: [String: RustPB.Im_V1_CreateChatRequest.DocPermissions],
                         linkPageURL: String?,
                         isCrypto: Bool,
                         isPublic: Bool,
                         isPrivateMode: Bool,
                         chatMode: Chat.ChatMode) -> Observable<CreateChatResult> {
        DispatchQueue.global().async {
            messageId2Permissions.forEach({ (messageId2Permission) in
                messageId2Permission.value.perms.forEach({ (perm) in
                    SDKTracker.trackDocsSync(perm.value.rawValue)
                })
            })
        }
        var param = CreateGroupParam(type: .group)
        param.name = name
        param.desc = desc
        param.chatterIds = userIds
        param.fromChatId = fromChatId
        param.isPublic = isPublic
        param.isCrypto = isCrypto
        param.isPrivateMode = isPrivateMode
        param.messageId2Permissions = messageId2Permissions
        param.chatMode = chatMode
        param.messageIds = messageIds
        param.linkPageURL = linkPageURL
        if !chatIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .chat
            pickEntity.pickIds = chatIds
            param.pickEntities.append(pickEntity)
        }
        if !departmentIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .dept
            pickEntity.pickIds = departmentIds
            param.pickEntities.append(pickEntity)
        }
        if !userIds.isEmpty {
            var pickEntity = Basic_V1_PickEntities()
            pickEntity.pickType = .user
            pickEntity.pickIds = userIds
            param.pickEntities.append(pickEntity)
        }

        return self.chatAPI.createChat(param: param)
    }
    // swiftlint:enable function_parameter_count

    func createDepartmentGroupChat(departmentId: String) -> Observable<Chat> {
        return self.chatAPI.createDepartmentChat(departmentId: departmentId)
    }

    func getCustomerServiceChat() -> Observable<Chat?> {
        var kvConf = KVConfig<String?>(
            key: "custom_service_chat_id",
            store: KVStores.udkv(
                space: .user(id: userID),
                domain: Domain.biz.messenger.child("Chat")
            )
        )
        if let chatId = kvConf.value {
            return chatAPI.fetchChat(by: chatId, forceRemote: false)
        }

        return self.chatterAPI.fetchServiceChatId()
            .flatMap { [weak self] (chatId) -> Observable<[String: Chat]> in
                guard let `self` = self else {
                    return .empty()
                }
                kvConf.value = chatId
                return self.chatAPI.fetchChats(by: [chatId], forceRemote: false)
            }
            .map { (chatsMap) in
                return chatsMap.first?.value
            }
        }

    func disbandGroup(chatId: String) -> Observable<Chat> {
        self.userPushCenter.post(PushLocalLeaveGroupChannnel(channelId: chatId, status: .start))
        return self.chatAPI.disbandGroup(chatId: chatId).do(onNext: { [weak self] (chat) in
            self?.userPushCenter.post(PushLocalLeaveGroupChannnel(channelId: chatId, status: .success))
            self?.userPushCenter.post(PushLocalLeaveGroupChannnel(channelId: chatId, status: .completed))
            if chat.chatMode == .threadV2, !chat.isPublic {
                self?.userPushCenter.post(PushRemoveMeForRecommendList(channelId: chatId))
            }
        }, onError: { [weak self] (_) in
            self?.userPushCenter.post(PushLocalLeaveGroupChannnel(channelId: chatId, status: .error))
        })
    }
}
