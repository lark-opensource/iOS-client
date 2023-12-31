//
//  ProfileHeaderViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/8/3.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import LarkRustClient
import UniverseDesignEmpty
import UniverseDesignToast

final class MomentsProfileHeaderContext {
    weak var pageVC: UIViewController?
    var circleId: String?
}

final class MomentsProfileHeaderViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentsProfileHeaderViewModel.self, category: "Module.Moments.ProfileHeaderViewModel")
    var followRequesting = false
    @ScopedInjectedLazy private var userAPI: UserApiService?
    @ScopedInjectedLazy private var profileApi: ProfileApiService?
    @ScopedInjectedLazy private var followingChangedNoti: FollowingChangedNotification?

    let context: MomentsProfileHeaderContext
    let userID: String
    let tracker: MomentsCommonTracker
    let disposeBag = DisposeBag()
    var profileEntity: RawData.UserProfileEntity?
    var postCount: Int32?
    /// 是否是一次加载数据
    var isFirstRefreshData = true
    /// 是不是当前用户
    var isCurrentUser: Bool {
        return userResolver.userID == userID
    }
    var refreshDataCallBack: ((RawData.UserProfileEntity) -> Void)?
    var showTipCallBack: ((String, UIImage) -> Void)?
    var refreshPostCountCallBack: ((Int32) -> Void)?
    var followingChangedNotiCallBack: ((Bool) -> Void)?

    init(userResolver: UserResolver, userID: String, context: MomentsProfileHeaderContext, tracker: MomentsCommonTracker) {
        self.userResolver = userResolver
        self.context = context
        self.userID = userID
        self.tracker = tracker
        addObserver()
    }
    func addObserver() {
        followingChangedNoti?
            .rxFollowingInfo
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (followingInfo) in
                guard let self = self else { return }
                if self.userID == followingInfo.targetUserID {
                    Self.logger.info("moment trace Profile header loadData")
                    self.followingChangedNotiCallBack?(followingInfo.isCurrentUserFollowing)
                }
            }).disposed(by: self.disposeBag)
    }
    func getUserProfileWith(userId: String, useLocal: Bool) -> ProfileApi.RxProfileResponse {
        return profileApi?.getUserProfile(userId: userID, useLocal: useLocal).observeOn(MainScheduler.instance) ?? .empty()
    }
    /// 加载首屏数据
    func loadDataWithLocalPriority() {
        let item = self.tracker.getItemWithEvent(.momentsShowProfile) as? MomentsProfileItem
        getUserProfileWith(userId: userID, useLocal: true)
            .subscribe(onNext: { [weak self] (info) in
                item?.sdkProfileInfoLocalCost = info.trackerInfo.timeCost
                item?.startLocalProfileListRenderCost()
                self?.refreshDataWith(profile: info.profile)
                item?.endLocalProfileListRenderCost()
                self?.loadReomtelData()
            }, onError: { [weak self] (error) in
                Self.logger.error("getUserProfile local fail --\(error)")
                self?.loadReomtelData()
            }).disposed(by: disposeBag)
    }
    /// 加载远端数据
    func loadReomtelData() {
        let item = self.tracker.getItemWithEvent(.momentsShowProfile) as? MomentsProfileItem
        getUserProfileWith(userId: userID, useLocal: false)
            .subscribe(onNext: { [weak self] (info) in
                item?.updateRemoteDataRenderTimeAndSdkProfileInfoCost(info.trackerInfo.timeCost)
                self?.refreshDataWith(profile: info.profile)
                if self?.isFirstRefreshData ?? false {
                    self?.isFirstRefreshData = false
                    MomentsTracer.trackFeedPageView(circleId: self?.context.circleId,
                                                    type: .moments_profile,
                                                    detail: nil,
                                                    porfileInfo: MomentsTracer.ProfileInfo(profileUserId: self?.userID ?? "",
                                                                                           isFollow: info.profile.user?.isCurrentUserFollowing ?? false,
                                                                                           isNickName: false,
                                                                                           isNickNameInfoTab: false))
                }
                item?.endRemoteProfileInfoRenderCost()
            }, onError: { [weak self] (error) in
                Self.logger.error("getUserProfile remote fail --\(error)")
                if let error = error as? RCError, let self = self {
                    let tip: String
                    let image: UIImage
                    if case .businessFailure(errorInfo: let info) = error, (info.code == 330_300 || info.code == 330_503) {
                        // 无权限，单独处理
                        tip = BundleI18n.Moment.Lark_Community_FeatureDisabledContactAdministratorCustomized(MomentTab.tabTitle())
                        image = Resources.postDetailNoPermission
                    } else {
                        tip = BundleI18n.Moment.Lark_Community_LoadingFailed
                        image = UDEmptyType.loadingFailure.defaultImage()
                    }
                    self.showTipCallBack?(tip, image)
                }
            }).disposed(by: disposeBag)
    }

    /// 这里收到删帖的推送 需要内存把计数-1
    func modifyPostCount() {
        guard let postCount = self.postCount, postCount - 1 >= 0 else {
            return
        }
        self.refreshPostCountCallBack?(postCount - 1)
        self.postCount = postCount - 1
    }

    /// 数据加载完成 刷新UI
    private func refreshDataWith(profile: RawData.UserProfileEntity) {
        self.profileEntity = profile
        self.postCount = profile.userProfile.postsCount
        self.refreshDataCallBack?(profile)
    }

    /// 关注/取消关注
    func followerUserWithFinish(isCurrentUserFollowing: Bool, finish: @escaping ((Bool) -> Void)) {
        guard followRequesting == false else {
            return
        }
        followRequesting = true
        Tracer.trackCommunityTabFollow(source: .profile, action: !isCurrentUserFollowing, followId: userID)
        if isCurrentUserFollowing {
            self.userAPI?.unfollowUser(byId: userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.followRequesting = false
                    finish(false)
                }, onError: { [weak self] (error) in
                    Self.logger.error("unfollowUser fail, error: \(error)")
                    finish(true)
                    self?.followRequesting = false
                    if let vc = self?.context.pageVC {
                        UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FailedToUnfollow, on: vc.view)
                    }
                }).disposed(by: self.disposeBag)
        } else {
            self.userAPI?.followUser(byId: userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    self?.followRequesting = false
                    finish(true)
                }, onError: { [weak self] (error) in
                    Self.logger.error("followUser fail, error: \(error)")
                    self?.followRequesting = false
                    finish(false)
                    if let vc = self?.context.pageVC {
                        UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_FollowFailed, on: vc.view)
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    /// 跳转关注列表
    func jumpToFollowVCWithType(_ type: FollowListType) {
        let followContext = UserFollowListContext()
        followContext.circleId = context.circleId
        let vm = UserFollowListViewModel(userResolver: userResolver, type: type, userID: userID, context: followContext)
        let vc = UserFollowListViewController(viewModel: vm) { [weak self] in
            /// 查看别人的关注列表，不会改变的人数  这里别人的不做刷新
            if self?.isCurrentUser ?? false {
                self?.loadReomtelData()
            }
        }
        followContext.pageVC = vc
        self.context.pageVC?.navigationController?.pushViewController(vc, animated: true)
    }
}
