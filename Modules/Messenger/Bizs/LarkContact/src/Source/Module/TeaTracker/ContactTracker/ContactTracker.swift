//
//  ContactTracker.swift
//  LarkContact
//
//  Created by 夏汝震 on 2021/5/18.
//

import Foundation
import LarkAccountInterface
import LarkMessengerInterface
import LarkContainer

/// 新埋点
public struct ContactTracker {
    struct Base {
        private var inviteStorageService: InviteStorageService?
        let userResolver: UserResolver

        init(resolver: UserResolver) {
            self.userResolver = resolver
            self.inviteStorageService = try? resolver.resolve(assert: InviteStorageService.self)
        }
        // 是否是管理员
        mutating func isAdmin() -> Bool {
            return self.inviteStorageService?.getInviteInfo(key: InviteStorage.isAdministratorKey) ?? false
        }

        mutating func userType() -> LarkAccountInterface.Account.UserType {
            guard let passportUserService = try? userResolver.resolve(assert: PassportUserService.self) else { return .undefined }
            return Account.userTypeFromPassportUserType(passportUserService.user.type)
        }

        public static func UserType(_ type: LarkAccountInterface.Account.UserType) -> String {
            switch type {
            case .c:
                return "c_user"
            case .standard:
                return "member"
            case .simple:
                return "simple_user"
            case .undefined:
                return "undefined"
            @unknown default:
                return "unknow type"
            }
        }
    }

    public struct Parms {
        public static func MemberType(resolver: UserResolver) -> [AnyHashable: Any] {
            var base = ContactTracker.Base(resolver: resolver)
            return ContactTracker.Parms.MemberType(userType: base.userType(), isAdmin: base.isAdmin())
        }

        public static func MemberType(userType: LarkAccountInterface.Account.UserType, isAdmin: Bool) -> [AnyHashable: Any] {
            var params: [AnyHashable: Any] = [:]
            let type: String
            if isAdmin {
                type = "admin"
            } else {
                type = ContactTracker.Base.UserType(userType)
            }
            params["member_type"] = type
            return params
        }
    }
}
