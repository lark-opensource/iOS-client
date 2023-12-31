//
//  FlagMessageCellViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel
import LarkExtensions
import RustPB
import LarkContainer
import LarkMessengerInterface
import LarkSDKInterface

public struct MessageFlagContent: FlagContent {

    public var source: String {
        guard let chat = self.chat else { return message.fromChatter?.localizedName ?? "" }
        let name = chat.localizedName
        if chat.type != .p2P {
            return name
        }
        return BundleI18n.LarkFlag.Lark_IM_Marked_FromUserChat_Text(" " + name + " ")
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

    public let chat: Chat?
    public let message: Message
    public var messageTime: String {
        return self.message.createTime.lf.cacheFormat("fav", formater: { $0.lf.formatedTime_v2() })
    }

    public init(chat: Chat?, message: Message) {
        self.message = message
        self.chat = chat
    }
}

public class FlagMessageCellViewModel: BaseFlagTableCellViewModel, MessageDynamicAuthorityDelegate {

    @ScopedInjectedLazy var chatSecurity: ChatSecurityControlService?
    @ScopedInjectedLazy var messageDynamicAuthorityService: MessageDynamicAuthorityService?
    @ScopedInjectedLazy var userSetting: UserGeneralSettings?

    lazy var permissionPreview: (Bool, ValidateResult?) = {
        return self.checkPermissionPreview()
    }()

    override public class var identifier: String {
        return String(describing: FlagMessageCellViewModel.self)
    }
    override public var identifier: String {
        return FlagMessageCellViewModel.identifier
    }
    override public var content: FlagContent {
        didSet {
            self.updateContent(content)
        }
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

    var chat: Chat?

    public init(userResolver: UserResolver, flag: RustPB.Feed_V1_FlagItem, content: MessageFlagContent, dataDependency: FlagDataDependency) {
        self.message = content.message
        self.chat = content.chat
        super.init(flag: flag, content: content, dataDependency: dataDependency)
        if let messageDynamicAuthorityService = messageDynamicAuthorityService {
            messageDynamicAuthorityService.delegate = self
        }
        self.updateContent(content)
        self.setupMessage()
    }

    public func updateContent(_ content: FlagContent) {
        guard let content = content as? MessageFlagContent else {
            return
        }
        self.message = content.message
    }

    public func updateChat(_ chat: Chat?) {
        self.chat = chat
        let content = MessageFlagContent(chat: chat, message: self.message)
        self.content = content
    }

    public func updateFromChatter(_ chatter: Chatter) {
        self.message.fromChatter = chatter
    }

    public func setupMessage() {}

    public func checkPermissionPreview() -> (Bool, ValidateResult?) {
        guard let chat = chat else {
            return chatSecurity?.checkPermissionPreview(anonymousId: "", message: message) ?? (false, nil)
        }
        return chatSecurity?.checkPermissionPreview(anonymousId: chat.anonymousId, message: message) ?? (false, nil)
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
        self.dataDependency.refreshObserver.onNext(())
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        return messageDynamicAuthorityService?.dynamicAuthorityEnum ?? .loading
    }
}
