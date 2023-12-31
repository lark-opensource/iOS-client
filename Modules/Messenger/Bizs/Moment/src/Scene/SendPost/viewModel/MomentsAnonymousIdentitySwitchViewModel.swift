//
//  MomentsIdentitySwitchViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/5/26.
//

import Foundation
import UIKit
import LarkMessageCore
import LarkContainer
import LarkSDKInterface
import LarkFeatureGating

final class MomentsAnonymousIdentitySwitchViewModel: MomentsIdentityInfoViewModel {
    override var anonymousAvatarKey: String {
        var avatarKey: String?
        if type == .nickname {
            avatarKey = user?.nicknameUser?.avatarKey
        } else {
            avatarKey = user?.anonymousUser?.anonymousAvatarKey
        }
        return avatarKey ?? ""
    }

    override var anonymousEntityID: String {
        if type == .nickname {
            return user?.nicknameUser?.userID ?? ""
        }
        return "0"
    }

    override var anonymousName: String {
        var name: String?
        if type == .nickname {
            name = user?.nicknameUser?.name
        } else {
            name = user?.anonymousUser?.anonymousName
        }
        return name ?? ""
    }

    var user: RawData.AnonymousAndNicknameUserInfo?
    var type: RawData.AnonymityPolicy.AnonymousType

    init(userResolver: UserResolver,
         anonymousUser: RawData.AnonymousAndNicknameUserInfo?,
         type: RawData.AnonymityPolicy.AnonymousType) {
        self.user = anonymousUser
        self.type = type
        super.init(userResolver: userResolver)
    }
}

class MomentsIdentityInfoViewModel: IdentitySwitchViewModel {
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?

    /// 当前用户头像
    override var currAvatarKey: String {
        return momentsAccountService?.getCurrentUserAvatarKey() ?? ""
    }

    /// 当前用户ID
    override var currUserID: String {
        return momentsAccountService?.getCurrentUserId() ?? ""
    }

    /// 当前用户名称
    override var currName: String {
        return momentsAccountService?.getCurrentUserDisplayName() ?? ""
    }

    override var anonymousAvatarKey: String {
        return ""
    }

    override var anonymousEntityID: String {
        return "0"
    }

    override var anonymousName: String {
        return ""
    }
}
