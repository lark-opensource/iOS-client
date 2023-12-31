//
//  AuthenticationMessageSubViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/2/6.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkContainer
import LarkMessageBase
import LarkMessengerInterface
import LarkModel
import LarkSetting

open class NewAuthenticationMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: NewMessageSubViewModel<M, D, C>, MessageDynamicAuthorityDelegate {

    lazy var messageDynamicAuthorityService: MessageDynamicAuthorityService? = {
        return try? self.context.resolver.resolve(assert: MessageDynamicAuthorityService.self)
    }()

    public var needAuthority: Bool {
        let chat = self.metaModel.getChat()
        if chat.isCrypto || chat.anonymousId == message.fromId {
            return false //密聊不鉴权;自己发的不鉴权
        }
        return true
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        return messageDynamicAuthorityService?.dynamicAuthorityEnum ?? .allow
    }

    //用于被鉴权的message。通常返回自身的message即可，但也有例外。
    //例如:对于回复ReplyComponent，就需要返回parentMessage
    open var authorityMessage: Message? {
        return self.message
    }

    open override func initialize() {
        super.initialize()
        messageDynamicAuthorityService?.delegate = self
    }

    public func updateUIWhenAuthorityChanged() {
        self.binderAbility?.syncToBinder()
        self.binderAbility?.updateComponent(animation: .none)
    }

    open override func willDisplay() {
        super.willDisplay()
        messageDynamicAuthorityService?.reGetAuthorityIfNeed()
    }
}

open class AuthenticationMessageSubViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: MessageSubViewModel<M, D, C>, MessageDynamicAuthorityDelegate {
    lazy var messageDynamicAuthorityService: MessageDynamicAuthorityService? = {
        return try? self.context.resolver.resolve(assert: MessageDynamicAuthorityService.self)
    }()

    public var needAuthority: Bool {
        let chat = self.metaModel.getChat()
        if chat.isCrypto || chat.anonymousId == message.fromId {
            return false //密聊不鉴权;自己发的不鉴权
        }
        return true
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        return messageDynamicAuthorityService?.dynamicAuthorityEnum ?? .allow
    }

    //用于被鉴权的message。通常返回自身的message即可，但也有例外。
    //例如:对于回复ReplyComponent，就需要返回parentMessage
    open var authorityMessage: Message? {
        return self.message
    }

    open override func initialize() {
        super.initialize()
        messageDynamicAuthorityService?.delegate = self
    }

    public func updateUIWhenAuthorityChanged() {
        self.binder.update(with: self)
        self.update(component: self.binder.component, animation: .none)
    }

    open override func willDisplay() {
        super.willDisplay()
        messageDynamicAuthorityService?.reGetAuthorityIfNeed()
    }
}
