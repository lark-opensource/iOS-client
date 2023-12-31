//
//  ChatNavigationBarTagsGenerator.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/3/15.
//

import Foundation
import LarkBizTag
import LarkModel
import LarkAccountInterface
import UniverseDesignColor
import RxSwift
import LarkSDKInterface
import LarkContainer

open class ChatNavigationBarTagsGenerator: UserResolverWrapper {
    public let userResolver: UserResolver

    public let forceShowAllStaffTag: Bool
    public var currentTenantId: String {
        return self.passportUserService?.userTenant.tenantID ?? ""
    }
    @ScopedInjectedLazy public var serverNTPTimeService: ServerNTPTimeService?
    @ScopedInjectedLazy public var passportUserService: PassportUserService?
    public let isDarkStyle: Bool

    func getTagDataItems(_ chat: Chat) -> [TagDataItem] {
        if let userType = self.passportUserService?.user.type {
            return self.getTitleTagTypes(chat: chat, userType: userType)
        }
        return []
    }

    public init(forceShowAllStaffTag: Bool, isDarkStyle: Bool, userResolver: UserResolver) {
        self.forceShowAllStaffTag = forceShowAllStaffTag
        self.isDarkStyle = isDarkStyle
        self.userResolver = userResolver
    }

    open func getTitleTagTypes(chat: Chat, userType: PassportUserType) -> [TagDataItem] {
        assertionFailure("must override")
        return []
    }
}
