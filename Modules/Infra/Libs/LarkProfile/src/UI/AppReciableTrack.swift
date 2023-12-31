//
//  ProfileReciableTrack.swift
//  ProfileReciableTrack
//
//  Created by 姚启灏 on 2021/9/1.
//

import UIKit
import Foundation
import AppReciableSDK
import LKCommonsLogging
import ThreadSafeDataStructure

public struct ProfileReciableTrack {
    static let logger = Logger.log(ProfileReciableTrack.self, category: "Module.Profile.ProfileReciableTrack")
    enum ProfileType: Int {
        case user = 2
    }

    struct UserProfileContext {
        /// userProfile开始时间
        var userProfileStratTime: CFTimeInterval
        /// userProfile本地请求耗时
        var userProfileSDKLocalCost: Int
        /// userProfile网络请求耗时
        var userProfileSDKNetworkCost: Int
        /// userProfile初始化耗时
        var userProfileInitViewCost: Int
        /// userProfileViewDidLoad耗时
        var userProfileFirstRenderViewCost: Int
        /// userProfile avatar耗时
        var userProfileAvatarCost: Int
        /// userProfile阶段耗时结束字典
        var userProfileEndCostDic: [String: Int] = [:]
        /// userProfile结束耗时
        var userProfileEndCost: Int

        init(userProfileStratTime: CFTimeInterval = CACurrentMediaTime(),
             userProfileSDKLocalCost: Int = 0,
             userProfileSDKNetworkCost: Int = 0,
             userProfileInitViewCost: Int = 0,
             userProfileFirstRenderViewCost: Int = 0,
             userProfileAvatarCost: Int = 0,
             userProfileEndCost: Int = 0) {
            self.userProfileStratTime = userProfileStratTime
            self.userProfileSDKLocalCost = userProfileSDKLocalCost
            self.userProfileSDKNetworkCost = userProfileSDKNetworkCost
            self.userProfileInitViewCost = userProfileInitViewCost
            self.userProfileFirstRenderViewCost = userProfileFirstRenderViewCost
            self.userProfileAvatarCost = userProfileAvatarCost
            self.userProfileEndCost = userProfileEndCost
        }
    }

    // profile打点相关配置
    private static var userProfileKey: DisposedKey?
    private static var userProfileTrackMap: SafeDictionary<DisposedKey, UserProfileContext> = [:] + .readWriteLock
    private static var userProfileRefreshEndKey = "refreshEnd"
    private static var userProfileAvatarEndKey = "avatarEnd"

    // profile打点相关函数

    public static func userProfileLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Profile,
                                              event: .enterProfile,
                                              page: "ProfileViewController")
        userProfileTrackMap.removeAll()
        var context = UserProfileContext()
        context.userProfileStratTime = CACurrentMediaTime()
        userProfileTrackMap[key] = context
        self.userProfileKey = key
        ProfileReciableTrack.logger.info("Key: \(key), UserProfile StratTime At: \(context.userProfileStratTime)")
    }

    public static func getUserProfileKey() -> DisposedKey? {
        return self.userProfileKey
    }

    private static func getUserProfileEventCost() -> Int {
        guard let disposedKey = userProfileKey,
            let startTime = userProfileTrackMap[disposedKey]?.userProfileStratTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        ProfileReciableTrack.logger.info("Key: \(disposedKey), UserProfileEvent Cost: \(cost)")
        return cost
    }

    public static func updateUserProfileSDKLocalCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            userProfileTrackMap[disposedKey]?.userProfileSDKLocalCost = Int(cost * 1000)
            ProfileReciableTrack.logger.info("Key: \(disposedKey), Update UserProfile SDK Local Cost: \(Int(cost * 1000))")
        }
    }

    public static func updateUserProfileSDKNetworkCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            userProfileTrackMap[disposedKey]?.userProfileSDKNetworkCost = Int(cost * 1000)
            ProfileReciableTrack.logger.info("Key: \(disposedKey), Update UserProfile SDK Network Cost: \(Int(cost * 1000))")
        }
    }

    public static func updateUserProfileAvatarCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            userProfileTrackMap[disposedKey]?.userProfileAvatarCost = Int(cost * 1000)
            ProfileReciableTrack.logger.info("Key: \(disposedKey), Update UserProfile Avatar Cost: \(Int(cost * 1000))")
        }
    }

    public static func userProfileFirstRenderViewCostTrack() {
        guard let disposedKey = userProfileKey else {
            return
        }
        let cost = getUserProfileEventCost()
        userProfileTrackMap[disposedKey]?.userProfileFirstRenderViewCost = cost
        ProfileReciableTrack.logger.info("Key: \(disposedKey), UserProfile First Render View Cost: \(cost)")
    }

    public static func userProfileInitViewCostTrack() {
        guard let disposedKey = userProfileKey else {
            return
        }
        let cost = getUserProfileEventCost()
        userProfileTrackMap[disposedKey]?.userProfileInitViewCost = cost
        ProfileReciableTrack.logger.info("Key: \(disposedKey), UserProfile Init View Cost: \(cost)")
    }

    public static func trackUserProfileEndCostOnRefresh(key: DisposedKey?) {
        guard let disposedKey = userProfileKey else {
            return
        }
        let cost = getUserProfileEventCost()
        userProfileTrackMap[disposedKey]?.userProfileEndCostDic[userProfileRefreshEndKey] = cost
        tryTotrackUserProfileEndCost(key: key)
        ProfileReciableTrack.logger.info("Key: \(disposedKey), UserProfile End Cost On Refresh: \(cost)")
    }

    public static func trackUserProfileEndCostOnAvatar(key: DisposedKey?) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            let cost = getUserProfileEventCost()
            userProfileTrackMap[disposedKey]?.userProfileEndCostDic[userProfileAvatarEndKey] = cost
            tryTotrackUserProfileEndCost(key: key)
            ProfileReciableTrack.logger.info("Key: \(disposedKey), UserProfile End Cost On Avatar: \(cost)")
        }
    }

    private static func tryTotrackUserProfileEndCost(key: DisposedKey?) {
        guard let disposedKey = userProfileKey, let context = userProfileTrackMap[disposedKey] else {
            return
        }
        if let avatarCost = context.userProfileEndCostDic[userProfileAvatarEndKey],
           let refreshCost = context.userProfileEndCostDic[userProfileRefreshEndKey] {
            userProfileTrackMap[disposedKey]?.userProfileEndCost = max(avatarCost, refreshCost)
            userProfileLoadTimeEnd(key: key)
        }
    }

    public static func userProfileLoadTimeEnd(key: DisposedKey?) {
        guard let key = key,
            let context = userProfileTrackMap.removeValue(forKey: key) else {
            return
        }
        var latencyDetail: [String: Any] = [:]
        latencyDetail["sdk_cost_local"] = context.userProfileSDKLocalCost
        latencyDetail["sdk_cost_net"] = context.userProfileSDKNetworkCost
        latencyDetail["init_view_cost"] = context.userProfileInitViewCost
        latencyDetail["first_render"] = context.userProfileFirstRenderViewCost
        latencyDetail["avatar_cost"] = context.userProfileAvatarCost

        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail,
                          metric: nil,
                          category: ["profile_type": ProfileType.user.rawValue])
        AppReciableSDK.shared.end(key: key, extra: extra)
        ProfileReciableTrack.logger.info("Key: \(key), UserProfile Init View End")
    }

    public static func userProfileLoadLocalError(errorCode: Int,
                                          errorMessage: String) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Profile,
                                                        event: .enterProfile,
                                                        errorType: .SDK,
                                                        errorLevel: .Fatal,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: "ProfileViewController",
                                                        errorMessage: errorMessage,
                                                        extra: extra))
        guard let key = self.getUserProfileKey() else { return }
        ProfileReciableTrack.logger.info("Key: \(key), UserProfile Init Load Local Error")
    }

    public static func userProfileLoadNetworkError(errorCode: Int,
                                            errorMessage: String) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Profile,
                                                        event: .enterProfile,
                                                        errorType: .Network,
                                                        errorLevel: .Fatal,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: "ProfileViewController",
                                                        errorMessage: errorMessage,
                                                        extra: extra))
        guard let key = self.getUserProfileKey() else { return }
        ProfileReciableTrack.logger.info("Key: \(key), UserProfile Init Load Network Error")
    }
}

private func mainThreadExecuteTask(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async {
            task()
        }
    }
}
