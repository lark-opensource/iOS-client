//
//  MomentsFeedContainerViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/4/19.
//

import Foundation
import UIKit
import RxSwift
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import LarkMessengerInterface
import RxCocoa

final class MomentsFeedContainerViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    static let logger = Logger.log(MomentsFeedContainerViewModel.self, category: "Module.Moments.MomentsFeedContainerViewModel")
    var postCreating: Bool = false
    var hasCategories: Bool = false
    var manageMode: RawData.ManageMode?
    @ScopedInjectedLazy var badgeNoti: MomentBadgePushNotification?
    @ScopedInjectedLazy var tabService: UserTabApiService?
    @ScopedInjectedLazy var createPostService: CreatePostApiService?
    @ScopedInjectedLazy private var postApi: PostApiService?
    @ScopedInjectedLazy private var configNot: MomentsUserGlobalConfigAndSettingNotification?
    @ScopedInjectedLazy private var postStatusNoti: PostStatusChangedNotification?
    @ScopedInjectedLazy var userCircleConfigService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var securityAuditService: MomentsSecurityAuditService?
    @ScopedInjectedLazy private var momentsAccountService: MomentsAccountService?
    var userSwitchAccountCallBack: (() -> Void)? //用户主动切换官方号身份的callBack

    var tabs: [RawData.PostTab] = []
    var circleID: String?
    var myOfficialUsers: [MomentUser]? {
        return momentsAccountService?.getMyOfficialUsers()
    }
    var currentOperatorUserInfo: (userID: String, isOfficialUser: Bool)? {
        guard let momentsAccountService else { return nil }
        return (userID: momentsAccountService.getCurrentUserId(), isOfficialUser: momentsAccountService.getCurrentUserIsOfficialUser())
    }
    let disposeBag = DisposeBag()

    func addObserverForPostStatus(_ complete: ((Bool, [String]?) -> Void)?) {
        /// 帖子状态的ID
        postStatusNoti?.rxPostStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (postStatus) in
                func auditEvent(succeed: Bool) {
                    let imageKeys = postStatus.successPost.post.postContent.imageSetList.map {
                        $0.origin.key
                    }
                    let officialUserId = self?.momentsAccountService?.getCurrentOfficialUser()?.userID
                    let videoKeys = [postStatus.successPost.post.postContent.media.driveURL]
                    self?.securityAuditService?.auditEvent(.momentsCreatePost(postId: postStatus.successPost.postId,
                                                                             imageKeys: imageKeys,
                                                                             videoKeys: videoKeys,
                                                                              officialUserId: officialUserId),
                                                          status: succeed ? .success : .fail)
                }
                let status = postStatus.createStatus
                if status == .success {
                    auditEvent(succeed: true)
                    complete?(true, postStatus.successPost.post.categoryIds)
                } else if status == .error || status == .failed {
                    auditEvent(succeed: false)
                    complete?(false, nil)
                }
            }).disposed(by: disposeBag)
    }

    func getUserGlobalConfigAndSettingsWithFinish(_ finish: (() -> Void)?, onError: ((Error) -> Void)?) {
        /// 这个接口SDK会兜底
        MomentsFeedFristScreenItem.shared.startSdkConfigAndSettingsCost()
        userCircleConfigService?.getUserCircleConfigWithFinsih({ [weak self] (userCircleConfig) in
            MomentsFeedFristScreenItem.shared.endSdkConfigAndSettingsCost()
            self?.tabs = userCircleConfig.tabs
            self?.hasCategories = userCircleConfig.hasCategories_p
            self?.circleID = userCircleConfig.circleID
            self?.manageMode = userCircleConfig.manageMode
            finish?()
        }, onError: onError)
    }

    func getTabTitles() -> [String] {
        return self.tabs.map { $0.name }
    }

    func addObserverForConfigNotWithRefresh(_ refresh: (([Int]) -> Void)?) {
        self.configNot?.rxConfig
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (nof) in
                var indexArr: [Int] = []
                nof.userCircleConfig.tabs.forEach { (tab) in
                    if let idx = self?.updateTabNameIfNeedForTab(tab) {
                        indexArr.append(idx)
                    }
                }
                refresh?(indexArr)
            }, onError: { (error) in
                Self.logger.error("configNot.rxConfig \(error)")
            }).disposed(by: disposeBag)
    }
    /// 名字更新了 更新UI
    private func updateTabNameIfNeedForTab(_ tab: RawData.PostTab) -> Int? {
        if let idx = self.tabs.firstIndex(where: { $0.id == tab.id }),
           self.tabs[idx].name != tab.name {
            self.tabs[idx] = tab
            return idx
        }
        return nil
    }

    func getOfficialAccountInto() {
        self.momentsAccountService?.fetchMyOfficialUsers(forceRemote: true) { _ in
        }
        self.momentsAccountService?.fetchCurrentOperatorUserId { _ in
        }
    }

    func getCurrentOfficialUser() -> MomentUser? {
        guard let currentOperatorUserInfo = currentOperatorUserInfo else { return nil }
        if currentOperatorUserInfo.isOfficialUser {
            guard let myOfficialUsers = myOfficialUsers else { return nil }
            for user in myOfficialUsers where user.userID == currentOperatorUserInfo.userID {
                return user
            }
            return nil
        } else {
            return nil
        }
    }

    func updateCurrentMomentUser(userID: String) {
        var isOfficialUser = userID != (userResolver.userID)
        self.momentsAccountService?.setCurrentOperatorUserId(userID: userID, isOfficialUser: isOfficialUser, from: nil) { [weak self] success in
            if success {
                self?.userSwitchAccountCallBack?()
            }
        }
    }
}
