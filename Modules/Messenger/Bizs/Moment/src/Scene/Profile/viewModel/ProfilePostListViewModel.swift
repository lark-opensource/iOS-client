//
//  ProfilePostListViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/8/11.
//

import Foundation
import UIKit
import LarkContainer
import LarkMessageCore

final class ProfilePostListViewModel: UserPostListViewModel {

    override init(userResolver: UserResolver, userId: String, context: BaseMomentContext, userPushCenter: PushNotificationCenter) {
        super.init(userResolver: userResolver, userId: userId, context: context, userPushCenter: userPushCenter)
    }

    func getCurrentCircle(_ finish: ((RawData.UserCircleConfig) -> Void)?) {
        configService?.getUserCircleConfigWithFinsih({[weak self] config in
            self?.circleId = config.circleID
            finish?(config)
        }, onError: nil)
    }

    override func getTrackValueForKey(_ key: MomentsTrackParamKey) -> Any? {
        switch key {
        case .isFollow:
            if let getIsFollowCallBack = getIsFollowCallBack {
                return getIsFollowCallBack()
            }
            return nil
        case .profileUserId:
            return userId
        default:
            return nil
        }
    }

    var getIsFollowCallBack: (() -> Bool?)?
}
