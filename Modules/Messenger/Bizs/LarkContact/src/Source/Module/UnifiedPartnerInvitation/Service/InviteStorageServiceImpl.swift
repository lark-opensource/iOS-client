//
//  InviteStorageServiceImpl.swift
//  LarkContact
//
//  Created by zhenning on 2020/4/21.
//
import Foundation
import LarkMessengerInterface
import LKCommonsLogging
import LarkAccountInterface
import LarkContainer
import ThreadSafeDataStructure
import LarkStorage

final class InviteStorageServiceImpl: InviteStorageService {
    static let logger = Logger.log(InviteStorageServiceImpl.self, category: "Module.LarkContact")
    private(set) var inviteInfoCache: [String: InviteInfo] = [:]

    private lazy var userStore = userResolver.udkv(domain: contactDomain)

    private let passportUserService: PassportUserService
    public var userResolver: LarkContainer.UserResolver

    public init(resolver: LarkContainer.UserResolver) throws {
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
    }
    public func setInviteInfo<V: KVValue>(value: V, key: KVKey<V>) {
        userStore.set(value, forKey: key)
    }
    public func getInviteInfo<V: KVValue>(key: KVKey<V>) -> V {
        let value = userStore.value(forKey: key)
        InviteStorageServiceImpl.logger.info("getInviteInfo",
                                             additionalData: ["value": "\(String(describing: value))",
                                                              "key": "\(key.raw))"])
        return value
    }
}
