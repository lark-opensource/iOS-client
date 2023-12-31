//
//  RustNavigationAPI.swift
//  LarkSDK
//
//  Created by Meng on 2019/10/20.
//

import UIKit
import Foundation
import LarkAccountInterface
import RxSwift
import LKCommonsLogging
import RustPB
import LarkRustClient
import AnimatedTabBar
import LarkTab
import LarkUIKit
import LarkSetting
import SuiteAppConfig
import LarkContainer

final class NavigationAPIImpl: NavigationAPI, UserResolverWrapper {
    public var userResolver: UserResolver

    static private let logger = Logger.log(NavigationAPIImpl.self, category: "LarkNavigation.NavigationAPIImpl")

    @ScopedInjectedLazy var client: RustService?

    @ScopedInjectedLazy var fgService: FeatureGatingService?

    // 新导航FG
    private let isNewNavigation = !AppConfigManager.shared.leanModeIsOn

    // FG：CRMode数据统一
    public lazy var crmodeUnifiedDataDisable: Bool = {
        return fgService?.staticFeatureGatingValue(with: "lark.navigation.disable.crmode") ?? false
    }()

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func noticeRustSwitchTab(tabKey: String) -> Observable<Void> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Behavior_V1_TabActivatedRequest()
        request.tabKey = tabKey
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    func getNavigationInfo(firstPage: Int?, fullData: Bool) -> Observable<AllNavigationInfoResponse> {
        guard let client = self.client else { return .empty() }
        var requests = [Settings_V1_GetNavigationAppInfoRequest]()
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            if Display.pad {
                var iPadRequest = Settings_V1_GetNavigationAppInfoRequest()
                iPadRequest.platform = .navIpad
                iPadRequest.isNewTabContainer = isNewNavigation
                requests.append(iPadRequest)
                // 这段逻辑其实是多余的，但是C、R模式数据统一是有FG控制的
                // 所以这边必须两个平台的数据都请求并保存下来，否则FG打开冷启动会有问题
                // https://meego.feishu.cn/larksuite/issue/detail/17033374
                // 记得GA以后下面的逻辑删除！！！！
                var iPhoneRequest = Settings_V1_GetNavigationAppInfoRequest()
                iPhoneRequest.platform = .navMobile
                iPhoneRequest.isNewTabContainer = isNewNavigation
                requests.append(iPhoneRequest)
            } else {
                var iPhoneRequest = Settings_V1_GetNavigationAppInfoRequest()
                iPhoneRequest.platform = .navMobile
                iPhoneRequest.isNewTabContainer = isNewNavigation
                requests.append(iPhoneRequest)
            }
        } else {
            var bottomRequest = Settings_V1_GetNavigationAppInfoRequest()
            bottomRequest.platform = .navMobile
            bottomRequest.isNewTabContainer = isNewNavigation
            requests.append(bottomRequest)
            if UIDevice.current.userInterfaceIdiom == .pad {
                var edgeRequest = Settings_V1_GetNavigationAppInfoRequest()
                edgeRequest.platform = .navIpad
                edgeRequest.isNewTabContainer = isNewNavigation
                requests.append(edgeRequest)
            }
        }
        var request = Settings_V1_GetNavigationAppInfoBatchRequest()
        request.isNewTabContainer = isNewNavigation
        request.requests = requests
        return client.sendAsyncRequest(request) { (res: NavigationAppInfoBatchResponse) in
            if requests.count != res.responses.count {
                NavigationAPIImpl.logger.error("<NAVIGATION_BAR> Get navigationInfo request is different from response")
            } else {
                NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Get navigationInfo success")
            }
            let allNavigationInfoResponse = AllNavigationInfoResponse(response: res)
            if !crmodeDisable {
                if Display.pad {
                    NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Get navigationInfo iPad main: \(allNavigationInfoResponse.iPad.main.map({$0.uniqueID})), iPad quick: \(allNavigationInfoResponse.iPad.quick.map({$0.uniqueID}))")
                } else {
                    NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Get navigationInfo iPhone main: \(allNavigationInfoResponse.iPhone.main.map({$0.uniqueID})), iPhone quick: \(allNavigationInfoResponse.iPhone.quick.map({$0.uniqueID}))")
                }
            } else {
                NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Get navigationInfo bottom main: \(allNavigationInfoResponse.bottom.main.map({$0.uniqueID})), quick: \(allNavigationInfoResponse.bottom.quick.map({$0.uniqueID}))")
            }
            return allNavigationInfoResponse
        }.subscribeOn(scheduler).do(onError: { error in
            NavigationAPIImpl.logger.error("<NAVIGATION_BAR> Get navigationInfo failed.", error: error)
        })
    }

    // 修改导航栏顺序（新版）
    func modifyNavigationOrder(tabbarStyle: TabbarStyle, mainTabItems: [AbstractTabBarItem], quickTabItems: [AbstractTabBarItem]) -> Observable<NavigationInfoResponse> {
        guard let client = self.client else { return .empty() }
        var request = Settings_V1_ModifyNavigationOrderRequest()
        request.isNewTabContainer = true
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            // 根据设备来区分，C、R模式现在数据已经统一了
            if Display.pad {
                request.platform = .navIpad
            } else {
                request.platform = .navMobile
            }
        } else {
            if tabbarStyle == .bottom {
                request.platform = .navMobile
            } else if tabbarStyle == .edge {
                request.platform = .navIpad
            }
        }
        request.isNewTabContainer = isNewNavigation
        let main = mainTabItems.map { item -> Basic_V1_NavigationUniqueId in
            var uniqueID = Basic_V1_NavigationUniqueId()
            // 自定义应用一定会有uniqueId，这是新加的属性，但是之前的本地应用是没有这个值的，虽然拉导航的时候都对数据处理过（没有会赋正确的值）
            // 但是还是需要兜底下，防止意外情况发生导致顺序不正确
            if let uniqueId = item.tab.uniqueId {
                uniqueID.id = uniqueId
            } else {
                // 走到兜底逻辑，说明有问题，打个日志
                NavigationAPIImpl.logger.error("<NAVIGATION_BAR> uniqueId is nil, key = \(item.tab.key)")
                // 尝试从keyToUniqueIdMap中取值
                if let keyToId = Tab.keyToUniqueIdMap[item.tab.key] {
                    // 兜底兜住了
                    uniqueID.id = keyToId
                } else {
                    // 还没有兜住，一定是有问题的，打个日志
                    NavigationAPIImpl.logger.error("<NAVIGATION_BAR> finally uniqueId is nil, key = \(item.tab.key)")
                    // 最后再兜底下
                    uniqueID.id = item.tab.key
                }
            }
            uniqueID.appType = transform(type: item.tab.appType)
            return uniqueID
        }
        let quick = quickTabItems.map { item -> Basic_V1_NavigationUniqueId in
            var uniqueID = Basic_V1_NavigationUniqueId()
            if let uniqueId = item.tab.uniqueId {
                uniqueID.id = uniqueId
            } else {
                uniqueID.id = item.tab.key
            }
            uniqueID.appType = transform(type: item.tab.appType)
            return uniqueID
        }
        if !crmodeDisable {
            NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Modify navigation order isIPad = \(Display.pad), tabBarStyle = \(tabbarStyle), mainItem: \(main), quickItem: \(quick)")
        } else {
            NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Modify navigation order mainItem: \(main), quickItem: \(quick)")
        }
        request.mainNavigation = main
        request.shortcutNavigation = quick
        return client.sendAsyncRequest(request) { (res: Settings_V1_ModifyNavigationOrderResponse) in
            NavigationAPIImpl.logger.info("<NAVIGATION_BAR> modifyNavigationOrder success")
            var result = Settings_V1_GetNavigationAppInfoResponse()
            result.appInfo = res.appInfo
            result.primaryCount = res.primaryCount
            result.totalCount = res.totalCount
            result.platform = res.platform
            return NavigationInfoResponse(response: result)
        }.subscribeOn(scheduler).do(onError: { error in
            NavigationAPIImpl.logger.error("<NAVIGATION_BAR> modifyNavigationOrder failed", error: error)
        })
    }

    // 修改导航栏顺序（旧版）
    func modifyNavigationOrder(tabbarStyle: TabbarStyle, mainItems: [AbstractRankItem], quickItems: [AbstractRankItem]) -> Observable<NavigationInfoResponse> {
        guard let client = self.client else { return .empty() }
        var request = Settings_V1_ModifyNavigationOrderRequest()
        request.isNewTabContainer = true
        if tabbarStyle == .bottom {
            request.platform = .navMobile
        } else if tabbarStyle == .edge {
            request.platform = .navIpad
        }
        request.isNewTabContainer = isNewNavigation
        let main = mainItems.map { item -> Basic_V1_NavigationUniqueId in
            var uniqueID = Basic_V1_NavigationUniqueId()
            uniqueID.id = item.uniqueID
            uniqueID.appType = transform(type: item.tab.appType)
            return uniqueID
        }
        let quick = quickItems.map { item -> Basic_V1_NavigationUniqueId in
            var uniqueID = Basic_V1_NavigationUniqueId()
            uniqueID.id = item.uniqueID
            uniqueID.appType = transform(type: item.tab.appType)
            return uniqueID
        }
        NavigationAPIImpl.logger.info("<NAVIGATION_BAR> Modify navigation order mainItem: \(main), quickItem: \(quick)")
        request.mainNavigation = main
        request.shortcutNavigation = quick
        return client.sendAsyncRequest(request) { (res: Settings_V1_ModifyNavigationOrderResponse) in
            NavigationAPIImpl.logger.info("NAVIGATION_BAR> modifyNavigationOrder success")
            var result = Settings_V1_GetNavigationAppInfoResponse()
            result.appInfo = res.appInfo
            result.primaryCount = res.primaryCount
            result.totalCount = res.totalCount
            result.platform = res.platform
            return NavigationInfoResponse(response: result)
        }.subscribeOn(scheduler).do(onError: { error in
            NavigationAPIImpl.logger.error("NAVIGATION_BAR> modifyNavigationOrder failed", error: error)
        })
    }

    /// 创建最近访问记录
    func createRecentVisitRecord(appInfo: RustPB.Basic_V1_NavigationAppInfo) -> Observable<Void> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_CreateRecentVisitRecordRequest()
        request.appInfo = [appInfo]
        if Display.pad {
            request.platform = .navIpad
        } else {
            request.platform = .navMobile
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 拉取最近访问列表
    func getRecentVisitRecords() -> Observable<Settings_V1_GetRecentVisitListResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_GetRecentVisitListRequest()
        if Display.pad {
            request.platform = .navIpad
        } else {
            request.platform = .navMobile
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 新增最近使用记录
    func createRecentUsedRecord(appInfo: RustPB.Basic_V1_NavigationAppInfo) -> Observable<Void> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_CreateRecentUsedRecordRequest()
        request.recordAppInfo = appInfo
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 删除最近使用记录
    func deleteRecentUsedRecord(uniqueId: String) -> Observable<Void> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_DeleteRecentUsedRecordRequest()
        request.uniqueID = uniqueId
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 拉取最近使用记录
    func getRecentUsedRecord(cursor: Int, count: Int) -> Observable<Settings_V1_GetRecentUsedRecordResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_GetRecentUsedRecordRequest()
        request.cursor = Int64(cursor)
        request.count = Int32(count)
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// Pin应用到主导航
    func pinAppToNavigation(appInfo: RustPB.Basic_V1_NavigationAppInfo, style: TabbarStyle) -> Observable<Settings_V1_PinNavigationAppResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_PinNavigationAppRequest()
        request.appInfo = appInfo
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            // iPad设备不再区分C、R模式
            request.platform = Display.pad ? .navIpad : .navMobile
        } else {
            // 哎...这逻辑我也是毙了dog，这绝对是需求变更了~~~
            var platform: Settings_V1_NavigationPlatform = .navMobile
            // 如果设备是iPad并且当前在R模式下，platform才是.navIpad（C模式使用底部栏platform是.navMobile）
            if Display.pad && style == .edge {
                platform = .navIpad
            }
            request.platform = platform
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 删除导航应用
    func unpinNavigationApp(appId: String, bizType: NavigationAppBizType, style: TabbarStyle) -> Observable<Settings_V1_UnPinNavigationAppResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_UnPinNavigationAppRequest()
        request.appID = appId
        request.bizType = bizType
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            // iPad设备不再区分C、R模式
            request.platform = Display.pad ? .navIpad : .navMobile
        } else {
            // 哎...这逻辑我也是毙了dog，这绝对是需求变更了~~~
            var platform: Settings_V1_NavigationPlatform = .navMobile
            // 如果设备是iPad并且当前在R模式下，platform才是.navIpad（C模式使用底部栏platform是.navMobile）
            if Display.pad && style == .edge {
                platform = .navIpad
            }
            request.platform = platform
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 查询应用是否存在于导航
    // nolint: duplicated_code - 非重复代码
    func findAppExistInNavigation(appId: String, bizType: NavigationAppBizType, style: TabbarStyle) -> Observable<Bool> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_FindNavigationAppRequest()
        request.appID = appId
        request.bizType = bizType
        let crmodeDisable = self.crmodeUnifiedDataDisable
        if !crmodeDisable {
            request.platform = Display.pad ? .navIpad : .navMobile
        } else {
            var platform: Settings_V1_NavigationPlatform = .navMobile
            if Display.pad && style == .edge {
                platform = .navIpad
            }
            request.platform = platform
        }
        return client.sendAsyncRequest(request).subscribeOn(scheduler).map({ (resp: RustPB.Settings_V1_FindNavigationAppResponse) -> Bool in
            return resp.isAppExist
        })
    }

    /// 获取全量导航
    func getNavigationApps() -> Observable<Settings_V1_GetNavigationAppsResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_GetNavigationAppsRequest()
        request.platform = Display.pad ? .navIpad : .navMobile
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 新增临时区域记录
    func createTemporaryRecord(appInfo: RustPB.Basic_V1_NavigationAppInfo) -> Observable<String> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_CreateTemporaryRecordRequest()
        request.recordAppInfo = appInfo
        return client.sendAsyncRequest(request) { (res: RustPB.Settings_V1_CreateTemporaryRecordResponse) -> String in
            return res.uniqueID
        }
    }
    /// 删除临时区域记录
    func deleteTemporaryRecord(uniqueIds: [String]) -> Observable<Void> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_DeleteTemporaryRecordRequest()
        request.uniqueIds = uniqueIds
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 拉取临时区域记录
    func getTemporaryRecord(cursor: Int, count: Int) -> Observable<Settings_V1_GetTemporaryRecordResponse> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_GetTemporaryRecordRequest()
        request.cursor = Int64(cursor)
        request.count = Int32(count)
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    /// 更新临时区域记录
    func modifyTemporaryRecord(appInfos: [RustPB.Basic_V1_NavigationAppInfo]) -> Observable<[String]> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_ModifyTemporaryRecordRequest()
        request.appInfos = appInfos
        return client.sendAsyncRequest(request) { (res: RustPB.Settings_V1_ModifyTemporaryRecordResponse) -> [String] in
            return res.uniqueIDList
        }
    }

    /// 更新应用的信息
    func updateNavigationInfos(appInfos: [RustPB.Basic_V1_NavigationAppInfo]) -> Observable<Void> {
        guard let client = self.client else { return .empty() }
        var request = RustPB.Settings_V1_UpdateNaviAppInfoRequest()
        request.appInfos = appInfos
        return client.sendAsyncRequest(request).subscribeOn(scheduler)
    }

    private func transform(type: AppType) -> Basic_V1_NavigationAppType {
        switch type {
        case .native: return .appTypeLarkNative
        case .gadget: return .appTypeMini
        case .webapp: return .appTypeWeb
        case .appTypeOpenApp: return .appTypeOpenApp
        case .appTypeURL: return .appTypeURL
        case .appTypeCustomNative: return .appTypeCustomNative
        }
    }
}
