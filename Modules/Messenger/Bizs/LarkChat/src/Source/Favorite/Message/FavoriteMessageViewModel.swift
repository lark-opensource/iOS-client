//
//  FavoriteMessageViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkExtensions
import RustPB
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface

public struct MessageFavoriteContent: FavoriteContent {
    public var source: String {

        if type == .favoritesMergeFavorite {
            if let chat = self.chat {
                if chat.type == .group {
                    return "\(chat.name)"
                } else if let chatter = chat.chatter {
                    return chatter.displayName
                }
            }
            return ""
        }

        let name = message.fromChatter?.displayName ?? ""
        if let chat = self.chat, chat.type == .group {
            return "\(name)\(BundleI18n.LarkChat.Lark_Legacy_FavoriteFrom)\(chat.name)"
        }
        return name
    }

    public var detailLocation: String {
        if let chat = self.chat, chat.type == .group {
            return chat.name
        }
        return ""
    }

    public var detailTime: String {
        return self.messageTime
    }

    public let type: RustPB.Basic_V1_FavoritesType
    public let chat: Chat?
    public let message: Message
    public var messageTime: String {
        return self.message.createTime.lf.cacheFormat("fav", formater: { $0.lf.formatedTime_v2() })
    }

    public init(type: RustPB.Basic_V1_FavoritesType, chat: Chat?, message: Message) {
        self.type = type
        self.message = message
        self.chat = chat
    }
}

public class FavoriteMessageViewModel: FavoriteCellViewModel, MessageDynamicAuthorityDelegate {
    @ScopedInjectedLazy var chatSecurity: ChatSecurityControlService?
    @ScopedInjectedLazy var messageDynamicAuthorityService: MessageDynamicAuthorityService?
    @ScopedInjectedLazy var userSetting: UserGeneralSettings?
    override public class var identifier: String {
        assertionFailure("need override in subclass")
        return String(describing: FavoriteMessageViewModel.self)
    }
    public override var identifier: String {
        assertionFailure("need override in subclass")
        return FavoriteMessageViewModel.identifier
    }

    override public var content: FavoriteContent {
        didSet {
            self.updateContent(content)
        }
    }

    public func checkPermissionPreview() -> (Bool, ValidateResult?) {
        guard let chatSecurity else { return (false, nil) }
        guard let chat = chat else {
            return chatSecurity.checkPermissionPreview(anonymousId: "", message: message)
        }
        return chatSecurity.checkPermissionPreview(anonymousId: chat.anonymousId, message: message)
    }

    public var message: Message {
        didSet {
            self.setupMessage()
        }
    }

    public var fromChatter: Chatter? {
        return self.message.fromChatter
    }

    public var fromChatterDisplayName: String {
        let displayName = self.message.fromChatter?.displayName ?? ""
        return displayName
    }

    let chat: Chat?

    public init(userResolver: UserResolver, favorite: RustPB.Basic_V1_FavoritesObject, content: MessageFavoriteContent, dataProvider: FavoriteDataProvider) {
        self.message = content.message
        self.chat = content.chat
        super.init(userResolver: userResolver, favorite: favorite, content: content, dataProvider: dataProvider)
        if let messageDynamicAuthorityService { messageDynamicAuthorityService.delegate = self }

        self.updateContent(content)

        self.setupMessage()
    }

    public func updateContent(_ content: FavoriteContent) {
        guard let content = content as? MessageFavoriteContent else {
            return
        }

        self.message = content.message
    }

    public func setupMessage() {}

    override public func supportForward() -> Bool {
        guard self.message.type != .audio else { return false }
        guard self.dynamicAuthorityEnum.authorityAllowed else { return false }
        return super.supportForward()
    }

    public override func willDisplay() {
        super.willDisplay()
        messageDynamicAuthorityService?.reGetAuthorityIfNeed()
    }

    // MARK: MessageDynamicAuthorityDelegate
    public var needAuthority: Bool {
        assertionFailure("need to be overrided")
        return true
    }

    public var authorityMessage: Message? {
        return self.message
    }

    public func updateUIWhenAuthorityChanged() {
        self.dataProvider
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        return messageDynamicAuthorityService?.dynamicAuthorityEnum ?? .allow
    }
}
