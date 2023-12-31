//
//  MessageDynamicAuthorityServiceImpl.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/2/16.
//

import Foundation
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface
import ThreadSafeDataStructure
import LarkModel
import LarkSetting
import LKCommonsLogging

class MessageDynamicAuthorityServiceImpl: MessageDynamicAuthorityService, UserResolverWrapper {
    private static let logger = Logger.log(MessageDynamicAuthorityServiceImpl.self, category: "Module.chat.Security")
    private let chatSecurityControlService: ChatSecurityControlService
    public let userResolver: UserResolver

    init(chatSecurityControlService: ChatSecurityControlService, userResolver: UserResolver) {
        self.chatSecurityControlService = chatSecurityControlService
        self.userResolver = userResolver
    }

    private var _requestingDynamicAuthority: SafeAtomic<Bool> = false + .semaphore
    private var requestingDynamicAuthority: Bool {
        get {
            return _requestingDynamicAuthority.value
        }
        set {
            _requestingDynamicAuthority.value = newValue
        }
    }
    private weak var _delegate: MessageDynamicAuthorityDelegate?
    var delegate: MessageDynamicAuthorityDelegate? {
        get {
            assert(_delegate != nil, "_delegate must be set just after init")
            return _delegate
        }
        set {
            assert(_delegate == nil, "_delegate should be set only once")
            _delegate = newValue
            requestDynamicAuthorityIfNeed()
        }
    }

    private var dynamicAuthority: SecurityDynamicResult? {
        didSet {
            guard dynamicAuthority.dynamicAuthorityEnum != oldValue.dynamicAuthorityEnum else {
                return
            }
            if dynamicAuthority.dynamicAuthorityEnum.authorityAllowed {
                self.performActionCache()
            }
            self.delegate?.updateUIWhenAuthorityChanged()
        }
    }

    private var needAuthority: Bool {
        guard self.userResolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "messenger.permission.share")) else { return false }
        guard let delegate = delegate else { return true }
        guard delegate.needAuthority else { return false }
        if authorityMessage.isMeSend(userId: self.userResolver.userID) {
            return false //自己发的消息不鉴权
        }
        return true
    }

    private var authorityMessage: Message {
        guard let message = self.delegate?.authorityMessage else {
            assert(needAuthority == false, "needAuthority but no authorityMessage")
            return Message.transform(pb: .init())
        }
        return message
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        guard let delegate = self.delegate else { return .loading }
        guard needAuthority else { return .allow }
        return dynamicAuthority.dynamicAuthorityEnum
    }

    private func requestDynamicAuthorityIfNeed() {
        guard let delegate = delegate else { return }
        guard needAuthority else {
            return
        }
        guard !requestingDynamicAuthority else { return }
        guard let senderUserId = Int64(authorityMessage.fromId),
              let senderTenantId = Int64(authorityMessage.fromChatter?.tenantId ?? "") else {
            Self.logger.error("requestDynamicAuthority trans ID fail", additionalData: ["messageID": authorityMessage.id,
                                                                                        "channelID": authorityMessage.channel.id,
                                                                                        "channelType": authorityMessage.channel.type.rawValue.description,
                                                                                        "fromID": authorityMessage.fromId,
                                                                                        "fromChatterIsNil": authorityMessage.fromChatter == nil ? "true" : "false",
                                                                                        "fromTenantID": authorityMessage.fromChatter?.tenantId ?? ""])
            return
        }
        requestingDynamicAuthority = true
        self.chatSecurityControlService.checkDynamicAuthority(params: .init(event: .receive,
                                                                            messageID: authorityMessage.id,
                                                                            senderUserId: senderUserId,
                                                                            senderTenantId: senderTenantId,
                                                                            onComplete: { [weak self] result in
            self?.dynamicAuthority = result
            self?.requestingDynamicAuthority = false
        }))
    }

    private var actionCacheMap: SafeDictionary<String, () -> Void> = [:] + .readWriteLock

    func performAfterAuthorityAllow(identify: String, action: @escaping (() -> Void)) {
        if self.dynamicAuthorityEnum.authorityAllowed {
            action()
        } else {
            //没有权限时先把block存起来，等到有权限时再执行
            actionCacheMap.updateValue(action, forKey: identify)
        }
    }

    //拿到权限后执行actionCacheMap中的所有block
    private func performActionCache() {
        guard self.dynamicAuthorityEnum.authorityAllowed else {
            assertionFailure("this function should be called only when authorityAllowed")
            return
        }
        let tempMap = actionCacheMap
        actionCacheMap.removeAll()
        tempMap.forEach { _, action in
            action()
        }
    }

    func reGetAuthorityIfNeed() {
        if self.dynamicAuthority.isDowngradeResult {
            //如果当前权限是降级方案，则尝试再次请求
            requestDynamicAuthorityIfNeed()
        }
    }
}
