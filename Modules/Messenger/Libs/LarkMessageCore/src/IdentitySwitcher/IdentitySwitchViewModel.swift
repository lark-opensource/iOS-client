//
//  IdentitySwitchViewModel.swift
//  LarkThread
//
//  Created by 李勇 on 2020/11/10.
//

import Foundation
import LarkAccountInterface
import LarkContainer

open class IdentitySwitchViewModel: UserResolverWrapper {
    @ScopedInjectedLazy var passportUserService: PassportUserService?

    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 当前用户头像
    open var currAvatarKey: String {
        return passportUserService?.user.avatarKey ?? ""
    }

    /// 当前用户ID
    open var currUserID: String {
        return self.userResolver.userID
    }

    /// 当前用户名称
    open var currName: String {
        return passportUserService?.user.name ?? ""
    }

    /// 匿名的头像 Key
    open var anonymousAvatarKey: String {
        assertionFailure("子类必须重写")
        return ""
    }
    /// 匿名的头像 EntityID
    open var anonymousEntityID: String {
        assertionFailure("子类必须重写")
        return ""
    }
    /// 匿名的称呼
    open var anonymousName: String {
        assertionFailure("子类必须重写")
        return ""
    }
}
