//
//  UserAnonymousConfigServiceIMP.swift
//  Moment
//
//  Created by liluobin on 2021/5/27.
//

import Foundation
import UIKit
import LarkContainer
import RxCocoa
import RxSwift
import LKCommonsLogging
enum MomentsAnonymousUserScene {
    case post
    case comment
}
protocol UserAnonymousConfigService: AnyObject {
    var userCircleConfig: RawData.UserCircleConfig? { get set }
    var anonymityPolicyEnable: Bool { get }
    /// 是否需要配置匿名 外界在需要的地方调用 不用关系实名 匿名这些
    func needConfigNickName() -> Bool
    /// 当前用户的匿名身份
    func anonymousAndNicknameUserInfoWithScene(_ scene: MomentsAnonymousUserScene) -> RawData.AnonymousAndNicknameUserInfo?
    /// 查询当前是否还有匿名次数
    func getAnonymousQuotaWithPostID(postID: String?, finish: ((Bool) -> Void)?)
    /// 当前板块是可以匿名
    func canAnonymousForCategory(_ category: RawData.PostCategory?) -> Bool
}

final class UserAnonymousConfigServiceIMP: UserAnonymousConfigService, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var anonymityPolicyEnable: Bool {
        guard let config = userCircleConfig else {
            return false
        }
        return config.anonymityPolicy.enabled
    }
    static let logger = Logger.log(UserAnonymousConfigServiceIMP.self, category: "Module.Moments.UserAnonymousConfigServiceIMP")
    var userCircleConfig: RawData.UserCircleConfig?
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy var anonymousApi: NickNameAndAnonymousService?
    func needConfigNickName() -> Bool {
        guard let config = userCircleConfig, config.anonymityPolicy.enabled else {
            return false
        }
        return config.anonymityPolicy.type == .nickname && config.nicknameUser.userID.isEmpty
    }
    /// 匿名关闭的情况下 没有匿名身份
    func anonymousAndNicknameUserInfoWithScene(_ scene: MomentsAnonymousUserScene) -> RawData.AnonymousAndNicknameUserInfo? {
        guard let config = userCircleConfig, config.anonymityPolicy.enabled else {
            return nil
        }
        var anonymousName = ""
        switch scene {
        case .post, .comment:
            anonymousName = BundleI18n.Moment.Lark_Community_AnonymousUser
        }
        let anonymousUser = RawData.AnonymousUser(anonymousAvatarKey: config.anonymousAvatarKey, anonymousName: anonymousName)
        return RawData.AnonymousAndNicknameUserInfo(nicknameUser: config.nicknameUser, anonymousUser: anonymousUser)
    }
    /// 获取是否有匿名次数
    func getAnonymousQuotaWithPostID(postID: String?, finish: ((Bool) -> Void)?) {
        guard let config = userCircleConfig, config.anonymityPolicy.enabled else {
            finish?(false)
            return
        }
        if config.anonymityPolicy.limitation.type == .noLimitation {
            finish?(true)
            return
        }
        anonymousApi?.getAnonymousQuota(postId: postID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {(hasQuota) in
                finish?(hasQuota)
            }, onError: {(error) in
                finish?(false)
                Self.logger.error("getAnonymousQuota-------error: \(error)")
            }).disposed(by: disposeBag)
    }

    func canAnonymousForCategory(_ category: RawData.PostCategory?) -> Bool {
        guard let config = userCircleConfig, config.anonymityPolicy.enabled else {
            return false
        }

        if config.anonymityPolicy.scope == .global {
            return true
        }

        if config.anonymityPolicy.scope == .category, category?.category.canAnonymous ?? false {
            return true
        }
        return false
    }
}
