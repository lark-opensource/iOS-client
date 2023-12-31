//
//  AppReciableTrack.swift
//  LarkContact
//
//  Created by qihongye on 2020/9/3.
//

import UIKit
import Foundation
import AppReciableSDK
import LarkSDKInterface
import LKCommonsLogging
import ThreadSafeDataStructure

struct AppReciableTrack {
    static let logger = Logger.log(AppReciableTrack.self, category: "Module.IM.AppReciableTrack")

    enum ProfileType: Int {
        case user = 2
    }

    static let ProfilePageName = "PersonalCardViewController"

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

    struct AddExternalContactPageContext {
        /// 开始时间
        var startTime: CFTimeInterval
        /// 初始化耗时
        var initViewCost: Int
        /// FirstRender耗时
        var firstRenderViewCost: Int
        /// 链接加载耗时
        var linkCost: Int
        /// 二维码加载耗时
        var qrCodeCost: Int

        init(startTime: CFTimeInterval = CACurrentMediaTime(),
             initViewCost: Int = 0,
             firstRenderViewCost: Int = 0,
             linkCost: Int = 0,
             qrCodeCost: Int = 0) {
            self.startTime = startTime
            self.initViewCost = initViewCost
            self.firstRenderViewCost = firstRenderViewCost
            self.linkCost = linkCost
            self.qrCodeCost = qrCodeCost
        }
    }

    class ApprecibleTrackContext {
        // 开始时间
        var startTime: CFTimeInterval
        // 初始化耗时
        var initViewCost: Int
        // FirstRender耗时
        var firstRenderViewCost: Int
        // sdk加载耗时
        var sdkCost: Int
        // 成员数量
        var memberCount: Int

        init(startTime: CFTimeInterval = CACurrentMediaTime(),
             initViewCost: Int = 0,
             firstRenderViewCost: Int = 0,
             linkCost: Int = 0,
             sdkCost: Int = 0,
             memberCount: Int = 0) {
            self.startTime = startTime
            self.initViewCost = initViewCost
            self.firstRenderViewCost = firstRenderViewCost
            self.sdkCost = sdkCost
            self.memberCount = memberCount
        }
    }

    // profile打点相关配置
    private static var userProfileKey: DisposedKey?
    private static var userProfileTrackMap: [DisposedKey: UserProfileContext] = [:]
    private static var userProfileRefreshEndKey = "refreshEnd"
    private static var userProfileAvatarEndKey = "avatarEnd"

    // profile打点相关函数

    static func userProfileLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Profile,
                                              event: .enterProfile,
                                              page: ProfilePageName)
        userProfileTrackMap.removeAll()
        var context = UserProfileContext()
        context.userProfileStratTime = CACurrentMediaTime()
        userProfileTrackMap[key] = context
        self.userProfileKey = key
        AppReciableTrack.logger.info("Key: \(key), UserProfile StratTime At: \(context.userProfileStratTime)")
    }

    static func getUserProfileKey() -> DisposedKey? {
        return self.userProfileKey
    }

    private static func getUserProfileEventCost() -> Int {
        guard let disposedKey = userProfileKey,
            let startTime = userProfileTrackMap[disposedKey]?.userProfileStratTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        AppReciableTrack.logger.info("Key: \(disposedKey), UserProfileEvent Cost: \(cost)")
        return cost
    }

    static func updateUserProfileSDKLocalCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            userProfileTrackMap[disposedKey]?.userProfileSDKLocalCost = Int(cost * 1000)
            AppReciableTrack.logger.info("Key: \(disposedKey), Update UserProfile SDK Local Cost: \(Int(cost * 1000))")
        }
    }

    static func updateUserProfileSDKNetworkCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            userProfileTrackMap[disposedKey]?.userProfileSDKNetworkCost = Int(cost * 1000)
            AppReciableTrack.logger.info("Key: \(disposedKey), Update UserProfile SDK Network Cost: \(Int(cost * 1000))")
        }
    }

    static func updateUserProfileAvatarCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            userProfileTrackMap[disposedKey]?.userProfileAvatarCost = Int(cost * 1000)
            AppReciableTrack.logger.info("Key: \(disposedKey), Update UserProfile Avatar Cost: \(Int(cost * 1000))")
        }
    }

    static func userProfileFirstRenderViewCostTrack() {
        guard let disposedKey = userProfileKey else {
            return
        }
        let cost = getUserProfileEventCost()
        userProfileTrackMap[disposedKey]?.userProfileFirstRenderViewCost = cost
        AppReciableTrack.logger.info("Key: \(disposedKey), UserProfile First Render View Cost: \(cost)")
    }

    static func userProfileInitViewCostTrack() {
        guard let disposedKey = userProfileKey else {
            return
        }
        let cost = getUserProfileEventCost()
        userProfileTrackMap[disposedKey]?.userProfileInitViewCost = cost
        AppReciableTrack.logger.info("Key: \(disposedKey), UserProfile Init View Cost: \(cost)")
    }

    static func trackUserProfileEndCostOnRefresh(key: DisposedKey?) {
        guard let disposedKey = userProfileKey else {
            return
        }
        let cost = getUserProfileEventCost()
        userProfileTrackMap[disposedKey]?.userProfileEndCostDic[userProfileRefreshEndKey] = cost
        tryTotrackUserProfileEndCost(key: key)
        AppReciableTrack.logger.info("Key: \(disposedKey), UserProfile End Cost On Refresh: \(cost)")
    }

    static func trackUserProfileEndCostOnAvatar(key: DisposedKey?) {
        mainThreadExecuteTask {
            guard let disposedKey = userProfileKey else {
                return
            }
            let cost = getUserProfileEventCost()
            userProfileTrackMap[disposedKey]?.userProfileEndCostDic[userProfileAvatarEndKey] = cost
            tryTotrackUserProfileEndCost(key: key)
            AppReciableTrack.logger.info("Key: \(disposedKey), UserProfile End Cost On Avatar: \(cost)")
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

    static func userProfileLoadTimeEnd(key: DisposedKey?) {
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
        AppReciableTrack.logger.info("Key: \(key), UserProfile Init View End")
    }

    static func userProfileLoadNetworkError(errorCode: Int,
                                            errorMessage: String) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Profile,
                                                        event: .enterProfile,
                                                        errorType: .Network,
                                                        errorLevel: .Fatal,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: ProfilePageName,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
        guard let key = self.getUserProfileKey() else { return }
        AppReciableTrack.logger.info("Key: \(key), UserProfile Init Load Network Error")
    }
    // 添加外部联系人打点相关配置
    private static let addExternalContactPage = "ExternalContactsInvitationViewController"
    private static var addExternalContactPageKey: DisposedKey?
    private static var addExternalPageTrackMap: SafeDictionary<DisposedKey, AddExternalContactPageContext> = [:] + .readWriteLock
}

// 添加外部联系人打点相关函数
extension AppReciableTrack {
    static func addExternalContactPageLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .addContacts,
                                              page: addExternalContactPage)
        addExternalPageTrackMap.removeAll()
        var context = AddExternalContactPageContext()
        context.startTime = CACurrentMediaTime()
        addExternalPageTrackMap[key] = context
        self.addExternalContactPageKey = key
    }

    static func getExternalContactPageTrackKey() -> DisposedKey? {
        return addExternalContactPageKey
    }

    private static func getAddExternalContactPageEventCost() -> Int {
        guard let disposedKey = addExternalContactPageKey,
            let startTime = addExternalPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func addExternalContactPageLinkCostTrack() {
        guard let disposedKey = addExternalContactPageKey else {
            return
        }
        let cost = getAddExternalContactPageEventCost()
        addExternalPageTrackMap[disposedKey]?.linkCost = cost
    }

    static func addExternalContactPageQRCodeCostTrack() {
        guard let disposedKey = addExternalContactPageKey else {
            return
        }
        let cost = getAddExternalContactPageEventCost()
        addExternalPageTrackMap[disposedKey]?.qrCodeCost = cost
    }

    static func addExternalContactPageFirstRenderCostTrack() {
        guard let disposedKey = addExternalContactPageKey else {
            return
        }
        let cost = getAddExternalContactPageEventCost()
        addExternalPageTrackMap[disposedKey]?.firstRenderViewCost = cost
    }

    static func addExternalContactPageInitViewCostTrack() {
        guard let disposedKey = addExternalContactPageKey else {
            return
        }
        let cost = getAddExternalContactPageEventCost()
        addExternalPageTrackMap[disposedKey]?.initViewCost = cost
    }

    static func addExternalContactPageLoadingTimeEnd(key: DisposedKey?) {
        guard let key = key,
            let addExternalContactPageContext = addExternalPageTrackMap.removeValue(forKey: key) else {
            return
        }
        var latencyDetail: [String: Any] = [:]
        latencyDetail["link_cost"] = addExternalContactPageContext.linkCost
        latencyDetail["qrcode_cost"] = addExternalContactPageContext.qrCodeCost
        latencyDetail["init_view_cost"] = addExternalContactPageContext.initViewCost
        latencyDetail["first_render"] = addExternalContactPageContext.firstRenderViewCost

        let extra = Extra(isNeedNet: true,
                          latencyDetail: latencyDetail)
        AppReciableSDK.shared.end(key: key, extra: extra)
    }

    static func addExternalContactPageError(errorCode: Int, errorMessage: String? = nil) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Contact,
                                                        event: .addContacts,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: addExternalContactPage,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
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

// 服务台列表打点
struct OncallContactsApprecibleTrack {
    final class OncallContactsContext: AppReciableTrack.ApprecibleTrackContext {}

    // 服务台列表打点相关配置
    private static let oncallContactsPage = "OnCallViewController"
    private static var oncallContactsPageKey: DisposedKey?
    private static var oncallContactsPageTrackMap: [DisposedKey: OncallContactsContext] = [:]

    static func oncallContactsPageLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .showOncallContacts,
                                              page: oncallContactsPage)
        oncallContactsPageTrackMap.removeAll()
        let context = OncallContactsContext()
        context.startTime = CACurrentMediaTime()
        oncallContactsPageTrackMap[key] = context
        self.oncallContactsPageKey = key
    }

    private static func getOncallContactsPageEventCost() -> Int {
        guard let disposedKey = oncallContactsPageKey,
            let startTime = oncallContactsPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func updateOncallContactsTrackData(sdkCost: CFTimeInterval, memberCount: Int) {
        mainThreadExecuteTask {
            guard let disposedKey = oncallContactsPageKey else {
                return
            }
            oncallContactsPageTrackMap[disposedKey]?.sdkCost = Int(sdkCost * 1000)
            oncallContactsPageTrackMap[disposedKey]?.memberCount = memberCount
        }
    }

    static func oncallContactsPageFirstRenderCostTrack() {
        guard let disposedKey = oncallContactsPageKey else {
            return
        }
        let cost = getOncallContactsPageEventCost()
        oncallContactsPageTrackMap[disposedKey]?.firstRenderViewCost = cost
        // 会有一些时候loadingTimeEnd早于firstRender, 因此这里将loadingTimeEnd放在firstRender后执行
        let isDoneLoadingTimeEnd = oncallContactsPageTrackMap[disposedKey]?.sdkCost != 0
        if isDoneLoadingTimeEnd {
            oncallContactsPageLoadingTimeEnd()
        }
    }

    static func oncallContactsPageInitViewCostTrack() {
        guard let disposedKey = oncallContactsPageKey else {
            return
        }
        let cost = getOncallContactsPageEventCost()
        oncallContactsPageTrackMap[disposedKey]?.initViewCost = cost
    }

    static func oncallContactsPageLoadingTimeEnd() {
        mainThreadExecuteTask {
            guard let key = oncallContactsPageKey,
                oncallContactsPageTrackMap[key]?.firstRenderViewCost != 0,
                let context = oncallContactsPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = context.sdkCost
            latencyDetail["init_view_cost"] = context.initViewCost
            latencyDetail["first_render"] = context.firstRenderViewCost
            var metric: [String: Any] = [:]
            metric["member_count"] = context.memberCount

            let extra = Extra(isNeedNet: true,
                              latencyDetail: latencyDetail,
                              metric: metric)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }

    static func oncallContactsPageError(errorCode: Int, errorMessage: String? = nil) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Contact,
                                                        event: .showOncallContacts,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: oncallContactsPage,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
    }
}

// 我的群组列表打点
struct MyGroupAppReciableTrack {
    final class MyGroupContext: AppReciableTrack.ApprecibleTrackContext {}
    // 我的群组列表打点相关配置
    private static let myGroupPage = "GroupsViewController"
    private static var myGroupPageKey: DisposedKey?
    private static var myGroupPageTrackMap: [DisposedKey: MyGroupContext] = [:]

    static func myGroupPageLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .showMyGroup,
                                              page: myGroupPage)
        myGroupPageTrackMap.removeAll()
        let context = MyGroupContext()
        context.startTime = CACurrentMediaTime()
        myGroupPageTrackMap[key] = context
        self.myGroupPageKey = key
    }

    private static func getMyGroupPageEventCost() -> Int {
        guard let disposedKey = myGroupPageKey,
            let startTime = myGroupPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func updateMyGroupPageTrackData(sdkCost: CFTimeInterval, memberCount: Int) {
        mainThreadExecuteTask {
            guard let disposedKey = myGroupPageKey else {
                return
            }
            myGroupPageTrackMap[disposedKey]?.sdkCost = Int(sdkCost * 1000)
            myGroupPageTrackMap[disposedKey]?.memberCount = memberCount
        }
    }

    static func myGroupPageFirstRenderCostTrack() {
        guard let disposedKey = myGroupPageKey else {
            return
        }
        let cost = getMyGroupPageEventCost()
        myGroupPageTrackMap[disposedKey]?.firstRenderViewCost = cost
        // 会有一些时候loadingTimeEnd早于firstRender, 因此这里将loadingTimeEnd放在firstRender后执行
        let isDoneLoadingTimeEnd = myGroupPageTrackMap[disposedKey]?.sdkCost != 0
        if isDoneLoadingTimeEnd {
            myGroupPageLoadingTimeEnd()
        }
    }

    static func myGroupPageInitViewCostTrack() {
        guard let disposedKey = myGroupPageKey else {
            return
        }
        let cost = getMyGroupPageEventCost()
        myGroupPageTrackMap[disposedKey]?.initViewCost = cost
    }

    static func myGroupPageLoadingTimeEnd() {
        mainThreadExecuteTask {
            guard let key = myGroupPageKey,
                myGroupPageTrackMap[key]?.firstRenderViewCost != 0,
                let context = myGroupPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = context.sdkCost
            latencyDetail["init_view_cost"] = context.initViewCost
            latencyDetail["first_render"] = context.firstRenderViewCost
            var metric: [String: Any] = [:]
            metric["member_count"] = context.memberCount

            let extra = Extra(isNeedNet: true,
                              latencyDetail: latencyDetail,
                              metric: metric)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }

    static func myGroupPageError(errorCode: Int, errorMessage: String? = nil) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Contact,
                                                        event: .showMyGroup,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: myGroupPage,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
    }
}

// 外部联系人列表打
struct ExternalContactsAppReciableTrack {
    final class ExternalContactsContext: AppReciableTrack.ApprecibleTrackContext {}

    // 外部联系人列表打点相关配置
    private static let newExternalContactsPage = "NewExternalContactsViewController"
    private static let oldExternalContactsPage = "ExternalContactsViewController"
    private static var externalContactsPageKey: DisposedKey?
    private static var externalContactsPageTrackMap: [DisposedKey: ExternalContactsContext] = [:]

    static func externalContactsPageLoadTimeStart(isNewPage: Bool) {
        let page = isNewPage ? newExternalContactsPage : oldExternalContactsPage
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .showExternalContacts,
                                              page: page)
        externalContactsPageTrackMap.removeAll()
        let context = ExternalContactsContext()
        context.startTime = CACurrentMediaTime()
        externalContactsPageTrackMap[key] = context
        self.externalContactsPageKey = key
    }

    private static func getExternalContactsPageEventCost() -> Int {
        guard let disposedKey = externalContactsPageKey,
            let startTime = externalContactsPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func updateExternalContactsPageTrackData(sdkCost: CFTimeInterval, memberCount: Int) {
        guard let disposedKey = externalContactsPageKey else {
            return
        }
        externalContactsPageTrackMap[disposedKey]?.sdkCost = Int(sdkCost * 1000)
        externalContactsPageTrackMap[disposedKey]?.memberCount = memberCount
    }

    static func externalContactsPageFirstRenderCostTrack() {
        guard let disposedKey = externalContactsPageKey else {
            return
        }
        let cost = getExternalContactsPageEventCost()
        externalContactsPageTrackMap[disposedKey]?.firstRenderViewCost = cost
        // 会有一些时候loadingTimeEnd早于firstRender, 因此这里将loadingTimeEnd放在firstRender后执行
        let isDoneLoadingTimeEnd = externalContactsPageTrackMap[disposedKey]?.sdkCost != 0
        if isDoneLoadingTimeEnd {
            externalContactsPageLoadingTimeEnd()
        }
    }

    static func externalContactsPageInitViewCostTrack() {
        guard let disposedKey = externalContactsPageKey else {
            return
        }
        let cost = getExternalContactsPageEventCost()
        externalContactsPageTrackMap[disposedKey]?.initViewCost = cost
    }

    static func externalContactsPageLoadingTimeEnd() {
        mainThreadExecuteTask {
            guard let key = externalContactsPageKey,
                externalContactsPageTrackMap[key]?.firstRenderViewCost != 0,
                let context = externalContactsPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = context.sdkCost
            latencyDetail["init_view_cost"] = context.initViewCost
            latencyDetail["first_render"] = context.firstRenderViewCost
            var metric: [String: Any] = [:]
            metric["member_count"] = context.memberCount

            let extra = Extra(isNeedNet: true,
                              latencyDetail: latencyDetail,
                              metric: metric)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }

    static func externalContactsPageError(isNewPage: Bool, errorCode: Int, errorMessage: String? = nil) {
        let page = isNewPage ? newExternalContactsPage : oldExternalContactsPage
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Contact,
                                                        event: .showExternalContacts,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: page,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
    }
}

// 邀请团队成员打点
struct InviteMemberApprecibleTrack {
    final class InviteMemberContext: AppReciableTrack.ApprecibleTrackContext {}

    // 邀请团队成员打点相关配置
    private static let inviteMemberPage = "MemberInviteSplitViewController"
    private static var inviteMemberPageKey: DisposedKey?
    private static var inviteMemberPageTrackMap: [DisposedKey: InviteMemberContext] = [:]

    static func inviteMemberPageLoadTimeStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .showInviteMember,
                                              page: inviteMemberPage)
        inviteMemberPageTrackMap.removeAll()
        let context = InviteMemberContext()
        context.startTime = CACurrentMediaTime()
        inviteMemberPageTrackMap[key] = context
        self.inviteMemberPageKey = key
    }

    private static func getInviteMemberPageeEventCost() -> Int {
        guard let disposedKey = inviteMemberPageKey,
            let startTime = inviteMemberPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func updateInviteMemberPageSDKCostTrack(cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = inviteMemberPageKey else {
                return
            }
            inviteMemberPageTrackMap[disposedKey]?.sdkCost = Int(cost * 1000)
        }
    }

    static func inviteMemberPageFirstRenderCostTrack() {
        guard let disposedKey = inviteMemberPageKey else {
            return
        }
        let cost = getInviteMemberPageeEventCost()
        inviteMemberPageTrackMap[disposedKey]?.firstRenderViewCost = cost
        // 会有一些时候loadingTimeEnd早于firstRender, 因此这里将loadingTimeEnd放在firstRender后执行
        let isDoneLoadingTimeEnd = inviteMemberPageTrackMap[disposedKey]?.sdkCost != 0
        if isDoneLoadingTimeEnd {
            inviteMemberPageLoadingTimeEnd()
        }
    }

    static func inviteMemberPageInitViewCostTrack() {
        guard let disposedKey = inviteMemberPageKey else {
            return
        }
        let cost = getInviteMemberPageeEventCost()
        inviteMemberPageTrackMap[disposedKey]?.initViewCost = cost
    }

    static func inviteMemberPageLoadingTimeEnd() {
        mainThreadExecuteTask {
            guard let key = inviteMemberPageKey,
                inviteMemberPageTrackMap[key]?.firstRenderViewCost != 0,
                let context = inviteMemberPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = context.sdkCost
            latencyDetail["init_view_cost"] = context.initViewCost
            latencyDetail["first_render"] = context.firstRenderViewCost

            let extra = Extra(isNeedNet: true,
                              latencyDetail: latencyDetail)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }

    static func inviteMemberPageError(errorCode: Int, errorMessage: String? = nil) {
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Contact,
                                                        event: .showInviteMember,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: inviteMemberPage,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
    }
}

// 通讯录页面打点
struct AddressBookAppReciableTrack {
    final class AddressBookContext: AppReciableTrack.ApprecibleTrackContext {
        var source: AddressBookSourceType = .unknow
    }

    enum AddressBookSourceType: Int {
      case unknow = 0
      case addExternal = 1 // 添加外部联系人
      case addMember = 2 // 添加成员
    }

    // 通讯录页面打点相关配置
    private static let newAddressBookPage = "AddrBookContactListController"
    private static let oldAddressBookPage = "SelectContactListController"
    private static var addressBookPageKey: DisposedKey?
    private static var addressBookPageTrackMap: [DisposedKey: AddressBookContext] = [:]

    static func addressBookPageLoadTimeStart(isNewPage: Bool, source: AddressBookSourceType) {
        let page = isNewPage ? newAddressBookPage : oldAddressBookPage
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              event: .showAddressBook,
                                              page: page)
        addressBookPageTrackMap.removeAll()
        let context = AddressBookContext()
        context.source = source
        context.startTime = CACurrentMediaTime()
        addressBookPageTrackMap[key] = context
        self.addressBookPageKey = key
    }

    private static func getAddressBookPageEventCost() -> Int {
        guard let disposedKey = addressBookPageKey,
            let startTime = addressBookPageTrackMap[disposedKey]?.startTime else {
            return 0
        }
        let cost = Int((CACurrentMediaTime() - startTime) * 1000)
        return cost
    }

    static func updateAddressBookPageTrackData(sdkCost: CFTimeInterval, memberCount: Int) {
        mainThreadExecuteTask {
            guard let disposedKey = addressBookPageKey else {
                return
            }
            addressBookPageTrackMap[disposedKey]?.sdkCost = Int(sdkCost * 1000)
            addressBookPageTrackMap[disposedKey]?.memberCount = memberCount
        }
    }

    static func addressBookPageFirstRenderCostTrack(isNeedNet: Bool) {
        guard let disposedKey = addressBookPageKey else {
            return
        }
        let cost = getAddressBookPageEventCost()
        addressBookPageTrackMap[disposedKey]?.firstRenderViewCost = cost
        // 会有一些时候loadingTimeEnd早于firstRender, 因此这里将loadingTimeEnd放在firstRender后执行
        let isDoneLoadingTimeEnd = addressBookPageTrackMap[disposedKey]?.sdkCost != 0
        if isDoneLoadingTimeEnd {
            addressBookPageLoadingTimeEnd(isNeedNet: isNeedNet)
        }
    }

    static func addressBookPageInitViewCostTrack() {
        guard let disposedKey = addressBookPageKey else {
            return
        }
        let cost = getAddressBookPageEventCost()
        addressBookPageTrackMap[disposedKey]?.initViewCost = cost
    }

    static func addressBookPageLoadingTimeEnd(isNeedNet: Bool) {
        mainThreadExecuteTask {
            guard let key = addressBookPageKey,
                addressBookPageTrackMap[key]?.firstRenderViewCost != 0,
                let context = addressBookPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = context.sdkCost
            latencyDetail["init_view_cost"] = context.initViewCost
            latencyDetail["first_render"] = context.firstRenderViewCost
            var category: [String: Any] = [:]
            category["source_type"] = context.source.rawValue
            var metric: [String: Any] = [:]
            metric["member_count"] = context.memberCount

            let extra = Extra(isNeedNet: isNeedNet,
                              latencyDetail: latencyDetail,
                              metric: metric,
                              category: category)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }

    static func addressBookPageError(isNewPage: Bool, errorCode: Int, errorType: ErrorType, errorMessage: String? = nil) {
        let page = isNewPage ? newAddressBookPage : oldAddressBookPage
        let extra = Extra(isNeedNet: true)
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Contact,
                                                        event: .showAddressBook,
                                                        errorType: errorType,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: page,
                                                        errorMessage: errorMessage,
                                                        extra: extra))
    }
}

final class PickerAppReciable {
    struct TrackerInfo {
        var startTime: CFTimeInterval = CACurrentMediaTime()
        var initViewCost: CFTimeInterval = 0
        var firstRenderCost: CFTimeInterval = 0
        var sdkCost: CFTimeInterval = 0
    }

    enum FromType: Int {
        case unknown = 0
        case createSingleChat
        case createGroupChat
        case mergeForward
        case forward
        case share
        case addGroupMember
        case urgent
        case vc
    }

    private var trackerInfo = TrackerInfo()
    private var pageName: String
    private var fromType: Int
    private var isEnd = false

    init(pageName: String, fromType: FromType) {
        self.pageName = pageName
        self.fromType = fromType.rawValue
    }

    func initViewStart() {
        if isEnd {
            return
        }
        trackerInfo.initViewCost = CACurrentMediaTime()
    }

    func initViewEnd() {
        if isEnd {
            return
        }
        trackerInfo.initViewCost = CACurrentMediaTime() - trackerInfo.initViewCost
    }

    func firstRenderEnd() {
        if isEnd {
            return
        }
        trackerInfo.firstRenderCost = CACurrentMediaTime() - trackerInfo.startTime
    }

    func updateSDKCost(_ cost: CFTimeInterval) {
        if isEnd {
            return
        }
        trackerInfo.sdkCost = cost
    }

    func endLoadingTime() {
        if isEnd {
            return
        }
        isEnd = true
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger, scene: .Picker, event: .enterPicker,
            cost: Int((CACurrentMediaTime() - trackerInfo.startTime) * 1000), page: pageName,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: [
                    "init_view_cost": Int(trackerInfo.initViewCost * 1000),
                    "first_render_cost": Int(trackerInfo.firstRenderCost * 1000),
                    "sdk_cost": Int(trackerInfo.sdkCost * 1000)
                ],
                metric: nil,
                category: [
                    "from_type": fromType
                ])
        ))
    }

    func error(_ error: Error) {
        var errorCode = 0
        var errorMessage: String?

        if let error = error.underlyingError as? APIError {
            errorCode = Int(error.code)
            errorMessage = error.localizedDescription
        } else {
            let error = error as NSError
            errorCode = error.code
            errorMessage = error.localizedDescription
        }
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Picker, event: .enterPicker, errorType: .SDK, errorLevel: .Fatal,
            errorCode: errorCode, userAction: nil, page: pageName, errorMessage: errorMessage,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: nil,
                metric: nil,
                category: [
                    "from_type": fromType
                ]
            )
        ))
    }
}

private enum ContactEvent: ReciableEventable {
    /// 查看组织架构
    case enterContactOrganization
    /// 查看新的联系人
    case enterContactApplications
    /// 添加联系人申请
    case addContactRequest
    var eventKey: String {
        var key = ""
        switch self {
        case .enterContactOrganization:
            key = "enter_contact_organization"
        case .enterContactApplications:
            key = "enter_contact_applications"
        case .addContactRequest:
            key = "add_contact_request"
        }
        return key
    }
}

private func getErrorCode(error: Error) -> Int {
    var errorCode = 0
    if let error = error.underlyingError as? APIError {
        errorCode = Int(error.errorCode)
    } else {
        errorCode = (error as NSError).code
    }
    return errorCode
}

private func getErrorMessage(error: Error) -> String? {
    var errorMessage: String?
    if let error = error.underlyingError as? APIError {
        errorMessage = error.localizedDescription
    } else {
        errorMessage = (error as NSError).localizedDescription
    }
    return errorMessage
}

// 查看组织架构
struct OrganizationAppReciableTrack {
    final class OrganizationContext: AppReciableTrack.ApprecibleTrackContext {}
    private static var organizationPageKey: DisposedKey?
    private static var organizationPageTrackMap: [DisposedKey: OrganizationContext] = [:]

    /// 查看组织架构Start（手势点击）
    static func organizationPageLoadStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              eventable: ContactEvent.enterContactOrganization,
                                              page: nil)
        organizationPageTrackMap.removeAll()
        let context = OrganizationContext()
        context.startTime = CACurrentMediaTime()
        organizationPageTrackMap[key] = context
        self.organizationPageKey = key
    }
    /// 获取列表remote数据请求耗时
    static func updateOrganizationSdkCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = organizationPageKey else {
                return
            }
            organizationPageTrackMap[disposedKey]?.sdkCost = Int(cost * 1000)
            AppReciableTrack.logger.info("Key: \(disposedKey), Update Organization SDK Cost: \(Int(cost * 1000))")
        }
    }
    /// 查看组织架构End（渲染展示）
    static func organizationPageLoadEnd() {
        mainThreadExecuteTask {
            guard let key = organizationPageKey,
                organizationPageTrackMap[key]?.startTime != 0,
                let context = organizationPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = Int(context.sdkCost)
            latencyDetail["render_end_cost"] = Int((CACurrentMediaTime() - context.startTime) * 1000)

            let extra = Extra(isNeedNet: true,
                              latencyDetail: latencyDetail)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }
    /// 查看组织架构页面失败
    static func organizationPageLoadError(error: Error) {
        mainThreadExecuteTask {
            let extra = Extra(isNeedNet: true)
            AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                            scene: .Contact,
                                                            eventable: ContactEvent.enterContactOrganization,
                                                            errorType: .SDK,
                                                            errorLevel: .Exception,
                                                            errorCode: getErrorCode(error: error),
                                                            userAction: nil,
                                                            page: nil,
                                                            errorMessage: getErrorMessage(error: error),
                                                            extra: extra))
        }
    }
}

// 查看新的联系人
struct NewContactsAppReciableTrack {
    final class NewContactsContext: AppReciableTrack.ApprecibleTrackContext {}
    private static var newContactPageKey: DisposedKey?
    private static var newContactPageTrackMap: [DisposedKey: NewContactsContext] = [:]

    /// 查看新的联系人Start（手势点击）
    static func newContactPageLoadStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              eventable: ContactEvent.enterContactApplications,
                                              page: nil)
        newContactPageTrackMap.removeAll()
        let context = NewContactsContext()
        context.startTime = CACurrentMediaTime()
        newContactPageTrackMap[key] = context
        self.newContactPageKey = key
    }
    /// 获取列表remote数据请求耗时
    static func updateNewContactSdkCost(_ cost: CFTimeInterval) {
        mainThreadExecuteTask {
            guard let disposedKey = newContactPageKey else {
                return
            }
            newContactPageTrackMap[disposedKey]?.sdkCost = Int(cost * 1000)
            AppReciableTrack.logger.info("Key: \(disposedKey), Update newContact SDK Cost: \(Int(cost * 1000))")
        }
    }
    /// 查看组织架构End（渲染展示）
    static func newContactPageLoadEnd() {
        mainThreadExecuteTask {
            guard let key = newContactPageKey,
                newContactPageTrackMap[key]?.startTime != 0,
                let context = newContactPageTrackMap.removeValue(forKey: key) else {
                return
            }
            var latencyDetail: [String: Any] = [:]
            latencyDetail["sdk_cost"] = Int(context.sdkCost)
            let extra = Extra(isNeedNet: true,
                              latencyDetail: latencyDetail)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }
    static func newContactPageLoadError(error: Error) {
        mainThreadExecuteTask {
            let extra = Extra(isNeedNet: true)
            AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                            scene: .Contact,
                                                            eventable: ContactEvent.enterContactApplications,
                                                            errorType: .SDK,
                                                            errorLevel: .Exception,
                                                            errorCode: getErrorCode(error: error),
                                                            userAction: nil,
                                                            page: nil,
                                                            errorMessage: getErrorMessage(error: error),
                                                            extra: extra))
        }
    }
}

/// 发送添加联系人申请
struct AddContactRequestReciableTrack {
    final class AddContactRequestContext: AppReciableTrack.ApprecibleTrackContext {}
    private static var addContactRequestPageKey: DisposedKey?
    private static var addContactRequestPageTrackMap: [DisposedKey: AddContactRequestContext] = [:]

    /// 发送添加联系人申请Start（发请求）
    static func addContactRequestStart() {
        let key = AppReciableSDK.shared.start(biz: .Messenger,
                                              scene: .Contact,
                                              eventable: ContactEvent.addContactRequest,
                                              page: nil)
        addContactRequestPageTrackMap.removeAll()
        let context = AddContactRequestContext()
        context.startTime = CACurrentMediaTime()
        addContactRequestPageTrackMap[key] = context
        self.addContactRequestPageKey = key
    }
    /// 发送添加联系人申请End（返回结果）
    static func addContactRequstEnd() {
        mainThreadExecuteTask {
            guard let key = addContactRequestPageKey,
                  addContactRequestPageTrackMap[key]?.startTime != 0,
                  let context = addContactRequestPageTrackMap.removeValue(forKey: key) else {
                return
            }
            let extra = Extra(isNeedNet: true)
            AppReciableSDK.shared.end(key: key, extra: extra)
        }
    }
    static func addContactPageLoadError(error: Error) {
        mainThreadExecuteTask {
            let extra = Extra(isNeedNet: true)
            AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                            scene: .Contact,
                                                            eventable: ContactEvent.addContactRequest,
                                                            errorType: .SDK,
                                                            errorLevel: .Exception,
                                                            errorCode: getErrorCode(error: error),
                                                            userAction: nil,
                                                            page: nil,
                                                            errorMessage: getErrorMessage(error: error),
                                                            extra: extra))
        }
    }
}
