//
//  FollowCellViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/3/9.
//
import Foundation
import LarkMessengerInterface
import EENavigator
import RxSwift
import UniverseDesignToast
import LarkContainer
import Swinject
import LarkUIKit
import LarkAccountInterface

final class FollowCellViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    let user: MomentUser
    let context: UserFollowListContext
    private var followRequesting: Bool = false
    var isCurrentUserFollowing: Bool
    var followListType: FollowListType

    let disposeBag: DisposeBag = DisposeBag()
    @ScopedInjectedLazy private var userAPI: UserApiService?
    @ScopedInjectedLazy var momentsAccountService: MomentsAccountService?

    var isCurrentUser: Bool {
        return userResolver.userID == user.userID
    }

    init(userResolver: UserResolver, user: MomentUser, context: UserFollowListContext, followListType: FollowListType) {
        self.userResolver = userResolver
        self.user = user
        self.isCurrentUserFollowing = user.isCurrentUserFollowing
        self.context = context
        self.followListType = followListType
    }

    func didSelected() {
        guard let targetVC = self.context.pageVC else { return }
        let body = MomentUserProfileByIdBody(userId: self.user.userID)
        userResolver.navigator.push(body: body, from: targetVC)
        MomentsTracer.trackMomentsFollowPageClickWith(circleId: context.circleId, isFollowUsers: followListType == .followings, type: .momentsProfile)
    }

    func avatarViewTapped() {
        guard let targetVC = self.context.pageVC else { return }
        MomentsNavigator.pushAvatarWith(userResolver: userResolver, user: user, from: targetVC, source: .profile, trackInfo: nil)
        MomentsTracer.trackMomentsFollowPageClickWith(circleId: context.circleId, isFollowUsers: followListType == .followings, type: .otherProfile)
    }

    func followUserWith(finish: ( @escaping (_ isFollowed: Bool) -> Void)) {
        guard let targetVC = self.context.pageVC, !followRequesting else { return }
        followRequesting = true
        trackCommunityTabFollow()
        let clickType: MomentsTracer.FollowPageClickType
        if isCurrentUserFollowing {
            clickType = .followCancel(user.userID)
            self.userAPI?.unfollowUser(byId: user.userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.followRequesting = false
                    finish(false)
                    self?.isCurrentUserFollowing = false
                }, onError: { [weak self] (_) in
                    finish(true)
                    self?.followRequesting = false
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToUnfollow, on: targetVC.view)
                }).disposed(by: self.disposeBag)
        } else {
            clickType = .follow(user.userID)
            self.userAPI?.followUser(byId: user.userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.followRequesting = false
                    finish(true)
                    self?.isCurrentUserFollowing = true
                }, onError: { [weak self] (_) in
                    self?.followRequesting = false
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FollowFailed, on: targetVC.view)
                    finish(false)
                }).disposed(by: self.disposeBag)
        }
        MomentsTracer.trackMomentsFollowPageClickWith(circleId: context.circleId, isFollowUsers: followListType == .followings, type: clickType)
    }

    func trackCommunityTabFollow() {
        let source: Tracer.FollowSource
        switch self.followListType {
        case .followers:
            source = .follwer
        case .followings:
            source = .following
        }
        Tracer.trackCommunityTabFollow(source: source, action: !isCurrentUserFollowing, followId: user.userID)
    }
}
