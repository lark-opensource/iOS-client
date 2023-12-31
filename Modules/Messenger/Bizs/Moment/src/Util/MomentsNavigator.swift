//
//  MomentsNavigator.swift
//  Moment
//
//  Created by liluobin on 2021/3/14.
//

import UIKit
import Foundation
import EENavigator
import LarkUIKit
import LarkMessengerInterface
import LarkFeatureGating
import LarkContainer
import LarkSetting

final class MomentsNavigator {
    struct TrackInfo {
        let circleId: String?
        let postId: String?
        let categoryId: String?
        let scene: MomentContextScene?
        let pageIdInfo: MomentsTracer.PageIdInfo?
    }

    static func pushNickNameAvatarWith(userResolver: UserResolver,
                                       userID: String,
                                       userInfo: (name: String, avatarKey: String),
                                       from: UIViewController,
                                       selectPostTab: Bool = true) {
        /// 如果userId为空，不进行push
        if userID.isEmpty {
            assertionFailure("error to push empty user id")
            return
        }
        let body = MomentsUserNicknameProfileByIdBody(userId: userID,
                                                      userInfo: userInfo,
                                                      selectPostTab: selectPostTab)
        userResolver.navigator.presentOrPush(body: body,
                                       wrap: LkNavigationController.self,
                                       from: from,
                                       prepareForPresent: { (vc) in
            vc.modalPresentationStyle = .formSheet
        })
    }

    static func pushUserAvatarWith(userResolver: UserResolver,
                                   userID: String,
                                   from: UIViewController,
                                   source: Tracer.LarkPrfileSource?,
                                   trackInfo: TrackInfo?) {
        Tracer.trackCommunityEnterLarkProfile(source: source)
        if let trackInfo = trackInfo, let scene = trackInfo.scene {
            switch scene {
            case .feed(let postTab):
                MomentsTracer.trackFeedPageViewClick(.other_profile,
                                                     circleId: trackInfo.circleId,
                                                     postId: trackInfo.postId,
                                                     type: .tabInfo(postTab),
                                                     detail: nil)
            case .hashTagDetail(let index, let hashtagId):
                MomentsTracer.trackFeedPageViewClick(.other_profile,
                                                     circleId: trackInfo.circleId,
                                                     postId: trackInfo.postId,
                                                     type: .hashtag(hashtagId),
                                                     detail: index == 1 ? .hashtag_new : .hashtag_hot)
            case .categoryDetail(let index, let categoryId):
                MomentsTracer.trackFeedPageViewClick(.other_profile,
                                                     circleId: trackInfo.circleId,
                                                     postId: trackInfo.postId,
                                                     type: .category(categoryId),
                                                     detail: index == 1 ? .category_post : .category_comment)
            case .postDetail:
                MomentsTracer.trackDetailPageClick(.other_profile,
                                                   circleId: trackInfo.circleId,
                                                   postId: trackInfo.postId,
                                                   pageIdInfo: trackInfo.pageIdInfo)
            default:
                break
            }
        }
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false

        let tabId = !fgValue ? ProfilePostListViewController.tabId : MomentsPolybasicProfileViewController.tabId
        let body = PersonCardBody(chatterId: userID,
                                  source: .community,
                                  extraParams: ["tab": tabId])
        userResolver.navigator.presentOrPush(
            body: body,
            wrap: LkNavigationController.self,
            from: from,
            prepareForPresent: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    static func pushAvatarWith(userResolver: UserResolver,
                               user: MomentUser,
                               from: UIViewController,
                               source: Tracer.LarkPrfileSource?,
                               trackInfo: TrackInfo?) {
        if user.momentUserType == .nickname {
            pushNickNameAvatarWith(userResolver: userResolver,
                                   userID: user.userID,
                                   userInfo: (user.displayName, user.avatarKey),
                                    from: from)
            return
        }

        guard user.momentUserType == .user else {
            return
        }
        pushUserAvatarWith(userResolver: userResolver,
                           userID: user.userID,
                           from: from,
                           source: source,
                           trackInfo: trackInfo)
    }
}
