//
//  GroupQRCodeViewModel.swift
//  LarkChat
//
//  Created by K3 on 2018/9/17.
//

import Foundation
import LarkModel
import RxCocoa
import RxSwift
import EENavigator
import LarkStorage
import LarkSDKInterface
import LarkMessengerInterface
import LarkFeatureGating
import LarkReleaseConfig
import LarkExtensions
import LarkContainer
import ServerPB
import RustPB

final class GroupQRCodeViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private var chatAPI: ChatAPI
    private var tokenInfo: RustPB.Im_V1_GetChatQRCodeTokenResponse?

    private(set) var inAppShareService: InAppShareService

    private(set) var chatID: String
    private(set) var chat: Chat
    private(set) var name: String?
    private(set) var avatarKey: String?
    private(set) var description: String?
    private(set) var tenantName: String
    private(set) var currentChatterID: String
    var isOwner: Bool {
        currentChatterID == chat.ownerId
    }
    var isExternal: Bool {
        return chat.isCrossTenant
    }
    var isPublic: Bool {
        return chat.isPublic
    }

    lazy var ownership: String = {
        if isExternal {
            return BundleI18n.LarkChatSetting.Lark_Chat_ExternalGroupQRCodeImageContent
        } else if isThread {
            return BundleI18n.LarkChatSetting.Lark_Groups_CircleQRCodeOrLinkInternalOnly(tenantName)
        }
        return BundleI18n.LarkChatSetting.Lark_Group_OnlyInternalMembersCanJoin

    }()

    let isThread: Bool

    // 埋点判断二维码来源
    var isFormQRcodeEntrance: Bool
    var isFromShare: Bool

    private lazy var globalStore = KVStores.ChatSetting.global()
    private var expireTimeKey: String {
        return "QRCode_ExpireTime_\(chatID)"
    }
    var expireTime: ExpireTime = .sevenDays {
        didSet {
            if expireTime != oldValue {
                globalStore[expireTimeKey] = expireTime.rawValue
            }
        }
    }

    init(resolver: UserResolver,
         chat: Chat,
         chatAPI: ChatAPI,
         tenantName: String,
         currentChatterID: String,
         inAppShareService: InAppShareService,
         isFormQRcodeEntrance: Bool,
         isFromShare: Bool
    ) {
        self.chat = chat
        self.chatAPI = chatAPI
        self.chatID = chat.id
        self.tenantName = tenantName
        self.currentChatterID = currentChatterID
        self.isThread = (chat.chatMode == .threadV2)
        self.inAppShareService = inAppShareService
        self.isFormQRcodeEntrance = isFormQRcodeEntrance
        self.isFromShare = isFromShare
        self.userResolver = resolver
        let value = globalStore.integer(forKey: expireTimeKey)
        self.expireTime = ExpireTime(rawValue: value) ?? .sevenDays

        loadData(chat)
    }

    private func loadData(_ chat: Chat) {
        name = chat.name
        avatarKey = chat.avatarKey
        description = chat.description
    }

    func loadQRCodeURLString() -> Observable<(String, String)> {
        return chatAPI
            .getChatQRCodeToken(chatId: chatID, expiredDay: expireTime.transform())
            .map { [weak self] (info) -> (String, String) in
                guard let self = self else { return ("", "") }
                self.tokenInfo = info
                let expireTime = BundleI18n.LarkChatSetting.Lark_Group_QRcodeValidity(self.expireTime.timeString())
                return (info.url, expireTime)
            }
    }
}
