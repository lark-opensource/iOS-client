//
//  ShareGroupLinkViewModel.swift
//  LarkChatSetting
//
//  Created by 姜凯文 on 2020/4/20.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import LarkReleaseConfig
import LarkExtensions
import LarkMessengerInterface
import LarkContainer
import ServerPB
import LarkAccountInterface
import LarkStorage

final class ShareGroupLinkViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    public let chat: Chat
    var chatId: String {
        chat.id
    }
    private let chatAPI: ChatAPI
    let isFromChatShare: Bool

    private(set) var inAppShareService: InAppShareService

    private(set) var name: String?
    private(set) var avatarKey: String?
    private(set) var entityId: String?
    private(set) var description: String?
    private(set) var tenantName: String
    private(set) var currentChatterID: String
    private(set) var groupLinkText: String?
    private(set) var shareLink: String?
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
            return "" // PM确认，外部群不需要此处文案
        }
        return BundleI18n.LarkChatSetting.Lark_Group_OnlyInternalMembersCanJoin
    }()

    // 判断当前包是feishu or lark
    let isLark: Bool = (ReleaseConfig.releaseChannel == "Oversea")

    private lazy var globalStore = KVStores.ChatSetting.global()
    private var expireTimeKey: KVKey<Int> {
        return .init("GroupLink_ExpireTime_\(chat.id)", default: 0)
    }
    var expireTime: ExpireTime = .sevenDays {
        didSet {
            if expireTime != oldValue {
                globalStore[expireTimeKey] = expireTime.rawValue
            }
        }
    }

    init(
        resolver: UserResolver,
        chat: Chat,
        chatAPI: ChatAPI,
        tenantName: String,
        currentChatterID: String,
        isFromChatShare: Bool,
        inAppShareService: InAppShareService
    ) {
        self.chat = chat
        self.chatAPI = chatAPI
        self.tenantName = tenantName
        self.currentChatterID = currentChatterID
        self.isFromChatShare = isFromChatShare
        self.inAppShareService = inAppShareService
        self.userResolver = resolver
        loadData(chat)
    }

    private func loadData(_ chat: Chat) {
        name = chat.name
        avatarKey = chat.avatarKey
        entityId = chat.id
        description = chat.description
        let value = globalStore[expireTimeKey]
        self.expireTime = ExpireTime(rawValue: value) ?? .sevenDays
    }

    func loadGroupLinkString() -> Observable<(String, String)> {
        let appName = isLark ? "Lark" : "Feishu"
        return chatAPI
            .getChatShareLink(chatId: chat.id, expiredDay: expireTime.transform(), appName: appName)
            .map { [weak self] (token) -> (String, String) in
                guard let self = self else { return ("", "") }
                self.groupLinkText = token.pasteText
                self.shareLink = token.sharedURL
                let expireTime = BundleI18n.LarkChatSetting.Lark_Group_LinkValidity(self.expireTime.timeString())
                return (token.pasteText, expireTime)
            }
    }
}
