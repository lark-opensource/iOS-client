//
//  NavigationEntity.swift
//  LarkNavigation
//
//  Created by 夏汝震 on 2021/6/21.
//

import Foundation
import AnimatedTabBar
import RustPB
import LarkTab
import ThreadSafeDataStructure
import LarkUIKit

public typealias NavigationAppInfoBatchResponse = RustPB.Settings_V1_GetNavigationAppInfoBatchResponse

public typealias NavigationAppInfoResponse = RustPB.Settings_V1_GetNavigationAppInfoResponse

// 仅用来兼容4.5版本及之前的本地缓存的v2数据，作为v2过度到v3用，以后可以删除
public typealias NavigationInfoV2 = RustPB.Basic_V1_NavigationInfo

public struct AllNavigationInfoResponse {
    public let bottom: NavigationInfoResponse
    public let edge: NavigationInfoResponse
    // iPad CRMode数据统一：GA后上面的可以删除，只保留下面的两个属性
    public let iPhone: NavigationInfoResponse
    public let iPad: NavigationInfoResponse
    // 仅用来序列化进行缓存
    public let response: NavigationAppInfoBatchResponse

    public init(response: NavigationAppInfoBatchResponse) {
        self.response = response
        var map = [Settings_V1_NavigationPlatform: NavigationAppInfoResponse]()
        response.responses.forEach({ map[$0.platform] = $0 })
        let iPhone = map[.navMobile] ?? NavigationAppInfoResponse()
        self.bottom = NavigationInfoResponse(response: iPhone)
        self.iPhone = NavigationInfoResponse(response: iPhone)
        let iPad = map[.navIpad] ?? NavigationAppInfoResponse()
        self.edge = NavigationInfoResponse(response: iPad)
        self.iPad = NavigationInfoResponse(response: iPad)
    }
}

public struct NavigationInfoResponse {
    // 主导航列表数据
    public let main: [Basic_V1_NavigationAppInfo]
    // 快捷导航列表数据
    public let quick: [Basic_V1_NavigationAppInfo]
    /// 应用总数
    public let totalCount: Int32
    /// 有多少个主导航应用
    public let primaryCount: Int32
    public let platform: Settings_V1_NavigationPlatform

    // 仅用来序列化进行缓存
    public let response: NavigationAppInfoResponse

    // 管理员添加的应用
    public let addList: [String]
    // 管理员删除的应用
    public let deleteList: [String]

    init(response: NavigationAppInfoResponse) {
        self.response = response
        let mainTabs = response.appInfo.prefix(Int(response.primaryCount))
        self.main = Array(mainTabs)
        let startIndexForQuick = response.appInfo.count - Int(response.primaryCount)
        if startIndexForQuick > 0 {
            self.quick = response.appInfo.suffix(startIndexForQuick)
        } else {
            self.quick = []
        }
        self.totalCount = response.totalCount
        self.primaryCount = response.primaryCount
        self.platform = response.platform
        //TODO: @lizijie,临时兼容下
        self.addList = response.addList.map({ String($0) })
        self.deleteList = response.deleteList.map({ String($0) })
    }
}

// 当前数据
public final class AllTabs {
    let iPhone: Tabs
    let iPad: Tabs
    // iPad CRMode数据统一：GA后上面的可以删除，只保留下面的两个属性
    let bottom: Tabs
    let edge: Tabs
    let crmodeDataUnifiedDisable: Bool
    var all: [Tab] {
        let tabs: [Tab]
        if !crmodeDataUnifiedDisable {
            // iPad设备CRMode数据源统一以后逻辑
            if Display.pad {
                tabs = iPad.main + iPad.quick
            } else {
                tabs = iPhone.main + iPhone.quick
            }
        } else {
            // iPad设备CRMode数据源不统一情况，所有的Tab应该包含底部栏和侧边栏
            tabs = bottom.main + bottom.quick + edge.main + edge.quick
        }
        // 这里需要根据key去重下，因为iPad设备C、R模式数据源里面会有重复的数据，不去重的话在计算SpringBoard总的红点数时就会有问题
        // CRMode数据统一GA后，下面的去重逻辑可以删除
        let uniqueTabs = tabs.reduce(into: [String: Tab]()) { (result, tab) in
            result[tab.key] = tab
        }.map { $0.value }
        return uniqueTabs
    }
    init(iPhone: Tabs, iPad: Tabs, crmodeDataUnifiedDisable: Bool) {
        self.bottom = iPhone
        self.edge = iPad
        self.iPhone = iPhone
        self.iPad = iPad
        self.crmodeDataUnifiedDisable = crmodeDataUnifiedDisable
    }
    // 获取默认数据
    static func defaultTabs() -> AllTabs {
        return AllTabs.init(iPhone: Tabs(), iPad: Tabs(), crmodeDataUnifiedDisable: true)
    }
}

public final class Tabs {
    var main = [Tab]()
    var quick = [Tab]()
    init() {}
}

extension AllNavigationInfoResponse {
    var description: [String: String] {
        return [
            "bottomAppInfo": "\(bottom.description)",
            "edgeAppInfo": "\(edge.description)",
            "iPhoneAppInfo": "\(iPhone.description)",
            "iPadAppInfo": "\(iPad.description)"]
    }

    // NavigationInfo转换：V2 to V3。仅用来兼容4.5版本及之前的本地缓存的v2数据，作为v2过度到v3用，以后可以删除
    static func transformToV3FromV2(_ navigationInfoV2: NavigationInfoV2) -> NavigationAppInfoBatchResponse {
        var bottom = NavigationAppInfoResponse()
        bottom.platform = .navMobile
        let mainNavigation = navigationInfoV2.mainNavigation.map({ $0.transform() })
        let shortcutNavigation = navigationInfoV2.shortcutNavigation.map({ $0.transform() })
        bottom.appInfo = mainNavigation + shortcutNavigation
        bottom.totalCount = Int32(mainNavigation.count + shortcutNavigation.count)
        bottom.primaryCount = Int32(mainNavigation.count)
        var v3 = NavigationAppInfoBatchResponse()
        v3.responses = [bottom]
        return v3
    }
}

extension Basic_V1_AppInfo {
    // 仅用来兼容4.5版本及之前的本地缓存的v2数据，作为v2过度到v3用，以后可以删除
    func transform() -> Basic_V1_NavigationAppInfo {
        var appInfoV3 = Basic_V1_NavigationAppInfo()
        appInfoV3.uniqueID = id
        appInfoV3.key = key
        appInfoV3.name = name
        appInfoV3.extra = extra
        appInfoV3.primaryOnly = primaryOnly
        appInfoV3.unmovable = unmovable
        appInfoV3.appType = Basic_V1_NavigationAppType.transformToV3(appType)
        appInfoV3.logo = Basic_V1_NavigationAppInfo.Logo.transformToV3(logo)
        // platforms 和 desc 没用到，所以没有转换
        return appInfoV3
    }
}

extension NavigationInfoResponse {
    var description: [String: String] {
        return [
            "platform": "\(platform)",
            "addList": "\(addList)",
            "deleteList": "\(deleteList)",
            "mainAppInfo": "\(main.map { transform(info: $0) })",
            "quickAppInfo": "\(quick.map { transform(info: $0) })"]
    }

    private func transform(info: Basic_V1_NavigationAppInfo) -> String {
        return "\(info.key) -> \(info.uniqueID) -> \(info.appType) -> \(info.primaryOnly) -> \(info.unmovable) -> \(info.erasable) -> \(info.source) -> \(info.extra)"
    }
}

extension Basic_V1_NavigationAppInfo {
    var tabMeta: TabMeta {
        return TabMeta(key: key, appType: appType.transformToNativeApptype().rawValue, name: name, source: source.rawValue)
    }
    
    // 判断是否是自定义类型的Tab（用户和租户都可以添加，不管是谁添加交互方式都一样，只是租户添加的无法删除）产品定义这么复杂的逻辑>_<
    public func isCustomType() -> Bool {
        var result = false
        if (appType == .appTypeOpenApp || appType == .appTypeURL) {
            result = true
        }
        return result
    }
    
    // 判断是否是用户自己添加的Tab（有可能是租户添加的）产品定义这么复杂的逻辑>_<
    public func isUserPined() -> Bool {
        var result = false
        if source == .userSource {
            result = true
        }
        return result
    }
}

extension Basic_V1_NavigationAppInfo.NavigationSource {
    func transformToNativeSource() -> TabSource {
        switch self {
        case .tenantSource:
            return .tenantSource
        case .userSource:
            return .userSource
        default:
            return .tenantSource
        }
    }
}

extension Basic_V1_NavigationAppInfo.NavigationOpenMode {
    func transformToNativeOpenMode() -> TabOpenMode {
        switch self {
        case .pushMode:
            return .pushMode
        case .switchMode:
            return .switchMode
        default:
            return .switchMode
        }
    }
}

extension Basic_V1_NavigationAppInfo.Logo {
    func transformToNativeAppLogo() -> [String: String] {
        return [NavigationKeys.Logo.mainDefault: primaryDefault,
                NavigationKeys.Logo.mainSelected: primarySelected,
                NavigationKeys.Logo.mainSupportTintColor: primaryColorPng,
                NavigationKeys.Logo.mobileDefaultIcon: mobilePrimaryDefaultPng,
                NavigationKeys.Logo.mobileSelectedIcon: mobilePrimarySelectedPng,
                NavigationKeys.Logo.quickDefault: shortcutDefault,
                NavigationKeys.Logo.quickBackgroundColor: primaryDefaultSvg]
    }

    // 仅用来兼容4.5版本及之前的本地缓存的v2数据，作为v2过度到v3用，以后可以删除
    static func transformToV3(_ logo: [String: String]) -> Basic_V1_NavigationAppInfo.Logo {
        var logoV3 = Basic_V1_NavigationAppInfo.Logo()
        logoV3.primaryDefault = logo[NavigationKeys.Logo.mainDefault] ?? ""
        logoV3.primarySelected = logo[NavigationKeys.Logo.mainSelected] ?? ""
        logoV3.shortcutDefault = logo[NavigationKeys.Logo.quickDefault] ?? ""
        logoV3.primaryDefaultSvg = logo[NavigationKeys.Logo.quickBackgroundColor] ?? ""
        return logoV3
    }
}
