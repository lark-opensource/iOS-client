//
//  File.swift
//  LarkPushTokenUploader
//
//  Created by aslan on 2023/11/14.
//

import Foundation
import LKCommonsLogging
import LarkContainer

final class LarkBackgroundUserResetTokenServiceImp: LarkBackgroundUserResetTokenService, UserResolverWrapper {
    let logger = Logger.log(LarkCouldPushUserListService.self, category: "LarkPushTokenUploader")

    let userResolver: LarkContainer.UserResolver

    private lazy var uploadRequest = PushTokenUploadRequest()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    /// 后台用户因为数量限制导致下线或者其他非session失效等原因下线，需要在下线前重置token
    public func backgroundUserWillOffline(userId: String, completion: @escaping (() -> Void)) {
        self.uploadRequest.uploadApnsToken("", userResolver: self.userResolver) {
            completion()
        }
    }
}
