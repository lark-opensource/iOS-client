//
//  AccountDependencyImpl.swift
//  LarkByteView
//
//  Created by chentao on 2020/9/21.
//

import Foundation
import ByteViewNetwork
import LarkAccountInterface
import LarkContainer

final class LarkAccountInfo: AccountInfo {
    private let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private var user: LarkAccountInterface.User? {
        userService?.user
    }

    var userId: String {
        userResolver.userID
    }

    var deviceId: String {
        passportService?.deviceID ?? ""
    }

    var userName: String {
        user?.localizedName ?? ""
    }

    var tenantTag: ByteViewNetwork.TenantTag? {
        user?.tenant.tenantTag?.vcType
    }

    var tenantId: String {
        user?.tenant.tenantID ?? ""
    }

    var accessToken: String {
        user?.sessionKey ?? ""
    }

    var isGuest: Bool {
        user?.isGuestUser ?? false
    }

    var isForegroundUser: Bool {
        user?.userID == self.userId
    }

    var isFeishuBrand: Bool {
        user?.tenant.isFeishuBrand ?? true
    }

    var isChinaMainlandGeo: Bool {
        user?.isChinaMainlandGeo ?? true
    }

    private var userService: PassportUserService? {
        try? userResolver.resolve(assert: PassportUserService.self)
    }

    private var passportService: PassportService? {
        try? userResolver.resolve(assert: PassportService.self)
    }
}

private extension LarkAccountInterface.TenantTag {
    var vcType: ByteViewNetwork.TenantTag? {
        switch self {
        case .standard:
            return .standard
        case .simple:
            return .simple
        case .undefined:
            return .undefined
        default:
            return nil
        }
    }
}
