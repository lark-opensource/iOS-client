//
//  TabBarItem.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2020/12/7.
//

import Foundation
import UIKit
import LarkBadge
import LarkTab
import RustPB
import LarkLocalizations

public protocol TabBarItemDelegate: AnyObject {

    func tabBarItemDidUpdateBadge(type: LarkBadge.BadgeType, style: LarkBadge.BadgeStyle)
    func tabBarItemDidAddCustomView(_ item: AbstractTabBarItem)
    func tabBarItemDidChangeAppearance(_ item: AbstractTabBarItem)

    func selectedUserEvent(_ item: AbstractTabBarItem, itemState: ItemStateProtocol)
    func selectedState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol)
    func deselectState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol)
}

public extension TabBarItemDelegate {
    func selectedUserEvent(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {}
    func selectedState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {}
    func deselectState(_ item: AbstractTabBarItem, itemState: ItemStateProtocol) {}
}

public final class AllTabBarItems {
    public var bottom = TabBarGroupItems()
    public var edge = TabBarGroupItems()
    // iPad CRMode数据统一：GA后上面的可以删除，只保留下面的两个属性
    public var iPhone = TabBarGroupItems()
    public var iPad = TabBarGroupItems()
    init() {}
}

public final class TabBarGroupItems {
    public var main = [AbstractTabBarItem]()
    public var quick = [AbstractTabBarItem]()
    init() {}
}

public protocol AbstractTabBarItem: AnyObject {

    var tab: Tab { get  set }
    var title: String { get set }
    var customView: UIView? { get set }
    var quickCustomView: UIView? { get set }
    var stateConfig: ItemStateConfig { get set }
    var isSelected: Bool { get set }
    var itemState: ItemStateProtocol { get set }
    var accessoryIdentifier: String? { get set }

    // Badge
    // https://bytedance.feishu.cn/docs/doccnlKJ5tvCA8EBjDU67Y2TpQg
    var badgeType: LarkBadge.BadgeType { get }
    var badgeStyle: LarkBadge.BadgeStyle { get }
    func updateBadge(type: LarkBadge.BadgeType, style: LarkBadge.BadgeStyle)

    // Delegation
    func add(delegate: TabBarItemDelegate)
    func remove(delegate: TabBarItemDelegate)

    // Selection State
    func selectedUserEvent()
    func selectedState()
    func deselectedState()
}

public class TabBarItem: AbstractTabBarItem {

    private var delegates = NSHashTable<AnyObject>.weakObjects()

    public var tab: Tab {
        didSet { self.delegate { $0.tabBarItemDidChangeAppearance(self) }}
    }

    public var title: String {
        didSet { self.delegate { $0.tabBarItemDidChangeAppearance(self) }}
    }

    public var stateConfig: ItemStateConfig {
        didSet { self.delegate { $0.tabBarItemDidChangeAppearance(self) }}
    }

    public var isSelected: Bool = false
    public var itemState: ItemStateProtocol = DefaultItemState()

    public var customView: UIView? {
        didSet {
            if customView !== oldValue {
                oldValue?.removeFromSuperview()
            }
            self.delegate { $0.tabBarItemDidAddCustomView(self) }
        }
    }

    public var quickCustomView: UIView? {
        didSet {
            if quickCustomView !== oldValue {
                oldValue?.removeFromSuperview()
            }
            self.delegate { $0.tabBarItemDidAddCustomView(self) }
        }
    }

    public var accessoryIdentifier: String? {
        didSet { self.delegate { $0.tabBarItemDidChangeAppearance(self) }}
    }

    public private(set) var badgeType: LarkBadge.BadgeType = .none
    public private(set) var badgeStyle: LarkBadge.BadgeStyle = .strong

    public init(tab: Tab, title: String, stateConfig: ItemStateConfig) {
        self.title = title
        self.tab = tab
        self.stateConfig = stateConfig
    }

    public func updateBadge(type: LarkBadge.BadgeType, style: LarkBadge.BadgeStyle) {
        self.badgeType = type
        self.badgeStyle = style
        self.delegate { $0.tabBarItemDidUpdateBadge(type: type, style: style) }
    }

    public func add(delegate: TabBarItemDelegate) {
        if self.delegates.contains(delegate) {
            return
        }
        self.delegates.add(delegate)
    }

    public func remove(delegate: TabBarItemDelegate) {
        self.delegates.remove(delegate)
    }

    private func delegate(_ block: (TabBarItemDelegate) -> Void) {
        self.delegates.allObjects.compactMap { (object) -> TabBarItemDelegate? in
            return object as? TabBarItemDelegate
        }.forEach { (delegate) in
            block(delegate)
        }
    }

    public static func tranformBy(_ item: TabCandidate) -> TabBarItem {
        var tab = Tab(url: item.url, appType: item.appType, key: item.uniqueId, bizType: item.bizType, name: item.title, tabIcon: item.icon, openMode: .pushMode, source: .userSource)
        tab.extra[NavigationKeys.appid] = item.id
        tab.extra["tabBizID"] = item.bizId
        return TabBarItem(
            tab: tab,
            title: item.title,
            stateConfig: ItemStateConfig(
                defaultIcon: nil,
                selectedIcon: nil,
                quickBarIcon: nil
            )
        )
    }

    public func tranformTo() -> TabCandidate {
        return TabCandidate(id: tab.extra[NavigationKeys.appid] as? String ?? "",
                            icon: tab.tabIcon ?? .udToken(""),
                            title: title,
                            url: tab.urlString,
                            bizType: tab.bizType,
                            appType: tab.appType,
                            bizId: tab.extra["tabBizID"] as? String ?? "",
                            uniqueId: tab.key)
    }

    public func tranformToNavigationAppInfo() -> RustPB.Basic_V1_NavigationAppInfo {
        var appInfo = RustPB.Basic_V1_NavigationAppInfo()

        appInfo.key = self.tab.key
        if let uniqueId = self.tab.uniqueId {
            appInfo.uniqueID = uniqueId
        }
        if self.tab.appType == .native {
            appInfo.appType = .appTypeLarkNative
        } else if self.tab.appType == .gadget {
            appInfo.appType = .appTypeMini
        } else if self.tab.appType == .webapp {
            appInfo.appType = .appTypeWeb
        } else if self.tab.appType == .appTypeOpenApp {
            appInfo.appType = .appTypeOpenApp
        } else if self.tab.appType == .appTypeURL {
            appInfo.appType = .appTypeURL
        } else if self.tab.appType == .appTypeCustomNative {
            appInfo.appType = .appTypeCustomNative
        }
        if self.tab.openMode == .switchMode {
            appInfo.openMode = .switchMode
        } else {
            appInfo.openMode = .pushMode
        }
        if self.tab.source == .userSource {
            appInfo.source = .userSource
        } else {
            appInfo.source = .tenantSource
        }
        appInfo.primaryOnly = self.tab.primaryOnly
        appInfo.unmovable = self.tab.unmovable
        appInfo.erasable = self.tab.erasable
        for (key, value) in self.tab.extra {
            if let stringValue = value as? String {
                appInfo.extra[key] = stringValue
            }
        }
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        appInfo.name = [lang: self.tab.name ?? self.title]
        var appLogo = RustPB.Basic_V1_NavigationAppInfo.Logo()
        if let icon = self.tab.tabIcon {
            var logo = RustPB.Basic_V1_NavigationAppInfo.CustomNavigationAppLogo()
            logo.content = icon.content
            switch icon.type {
            case .udToken:
                logo.type = .appLogoTypeUdToken
            case .byteKey:
                logo.type = .appLogoTypeImageKey
            case .webURL:
                logo.type = .appLogoTypeURL
            case .iconInfo:
                logo.type = .appLogoTypeCcmIcon
            default:
                logo.type = .appLogoTypeUnknown
            }
            appLogo.customNavigationAppLogo = logo
        }
        appInfo.logo = appLogo
        
        return appInfo
    }
}

public extension TabBarItem {
    func selectedUserEvent() {
        self.delegate { $0.selectedUserEvent(self, itemState: itemState) }
    }

    func selectedState() {
        self.isSelected = true
        self.delegate { $0.selectedState(self, itemState: itemState) }
    }

    func deselectedState() {
        self.isSelected = false
        self.delegate { $0.deselectState(self, itemState: itemState) }
    }
}

public struct RecentRecordExtraKey {
    static public let url = "mobile_url"
    static public let appid = "app_id"
    static public let bizType = "biz_type"
    static public let tabBizId = "biz_id"
    static public let iconInfo = "iconInfo"
    static public let displayName = "displayName"
    static public let docSubType = "doc_sub_type"
}

private struct AssociatedKeys {
    static var tabContainableIdentifier = "tabContainableIdentifier"
}

public typealias NavigationAppBizType = RustPB.Basic_V1_NavigationAppInfo.BizType

public extension Basic_V1_NavigationAppInfo.CustomNavigationAppLogo {
    func toCustomTabIcon() -> TabCandidate.TabIcon {
        switch self.type {
        case .appLogoTypeUdToken:
            return TabCandidate.TabIcon.udToken(content)
        case .appLogoTypeImageKey:
            return TabCandidate.TabIcon.byteKey(content)
        case .appLogoTypeURL:
            return TabCandidate.TabIcon.webURL(content)
        case .appLogoTypeCcmIcon:
            return TabCandidate.TabIcon.iconInfo(content)
        case .appLogoTypeUnknown:
            return TabCandidate.TabIcon.webURL("")
        @unknown default:
            return TabCandidate.TabIcon.webURL("")
        }
    }
}

public extension Basic_V1_NavigationAppInfo {
    func transferToTabContainable() -> TabCandidate {
        let icon = self.logo.customNavigationAppLogo.toCustomTabIcon()
        let id = self.extra[RecentRecordExtraKey.appid] ?? ""
        let url = self.extra[RecentRecordExtraKey.url] ?? ""
        let typeValue = Int(self.extra[RecentRecordExtraKey.bizType] ?? "") ?? 0
        let bizType = (NavigationAppBizType(rawValue: typeValue) ?? .unknownType).toCustomBizType()
        let bizId = self.extra[RecentRecordExtraKey.tabBizId] ?? ""
        let appType = self.appType.transformToNativeApptype()
        let uniqueId = self.uniqueID
        var title = ""
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        if let name = self.name[lang], !name.isEmpty {
            title = name
        } else {
            title = self.name.values.first(where: { !$0.isEmpty }) ?? ""
        }
        return TabCandidate(id: id, icon: icon, title: title, url: url, bizType: bizType, appType: appType, bizId: bizId, uniqueId: uniqueId)
    }
}

public extension TabCandidate {
    func transferToNavigationAppInfo() -> RustPB.Basic_V1_NavigationAppInfo {
        var appInfo = RustPB.Basic_V1_NavigationAppInfo()
        let bizType = self.bizType.toAppBizType()
        appInfo.key = self.uniqueId
        if !self.uniqueId.isEmpty {
            appInfo.uniqueID = self.uniqueId
        }
        if bizType == .miniApp || bizType == .webApp {
            appInfo.appType = .appTypeOpenApp
        } else {
            appInfo.appType = .appTypeURL
        }
        appInfo.openMode = .pushMode
        appInfo.extra[RecentRecordExtraKey.url] = self.url
        appInfo.extra[RecentRecordExtraKey.appid] = self.id
        appInfo.extra[RecentRecordExtraKey.bizType] = String(bizType.rawValue)
        appInfo.extra[RecentRecordExtraKey.tabBizId] = self.bizId
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        appInfo.name = [lang: self.title]
        var logo = RustPB.Basic_V1_NavigationAppInfo.CustomNavigationAppLogo()
        logo.content = icon.content
        switch icon.type {
        case .udToken:
            logo.type = .appLogoTypeUdToken
        case .byteKey:
            logo.type = .appLogoTypeImageKey
        case .webURL:
            logo.type = .appLogoTypeURL
        case .iconInfo:
            logo.type = .appLogoTypeCcmIcon
        default:
            logo.type = .appLogoTypeUnknown
        }
        var appLogo = RustPB.Basic_V1_NavigationAppInfo.Logo()
        appLogo.customNavigationAppLogo = logo
        appInfo.logo = appLogo
        return appInfo
    }
}

public extension UIViewController {
    var tabContainer: UIViewController? {
        if self.parent is TemporaryTabContainer {
            return self.parent
        }
        return parent?.tabContainer
    }

    var isTemporaryChild: Bool {
        return tabContainer != nil
    }
}

public extension TabContainable {

    var tabContainableIdentifier: String {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.tabContainableIdentifier, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.tabContainableIdentifier) as? String ?? ""
        }
    }

    func transferToNavigationAppInfo() -> RustPB.Basic_V1_NavigationAppInfo {
        var appInfo = RustPB.Basic_V1_NavigationAppInfo()
        let bizType = self.tabBizType.toAppBizType()
        appInfo.key = self.tabContainableIdentifier
        if !self.tabContainableIdentifier.isEmpty {
            appInfo.uniqueID = self.tabContainableIdentifier
        }
        if bizType == .miniApp || bizType == .webApp {
            appInfo.appType = .appTypeOpenApp
        } else {
            appInfo.appType = .appTypeURL
        }
        appInfo.openMode = .pushMode
        appInfo.extra[RecentRecordExtraKey.url] = self.tabURL
        appInfo.extra[RecentRecordExtraKey.appid] = self.tabID
        appInfo.extra[RecentRecordExtraKey.bizType] = String(bizType.rawValue)
        appInfo.extra[RecentRecordExtraKey.tabBizId] = self.tabBizID
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        appInfo.name = [lang: self.tabTitle]
        var logo = RustPB.Basic_V1_NavigationAppInfo.Logo()
        logo.customNavigationAppLogo = self.tabIcon.toCustomAppLogo()
        appInfo.logo = logo
        return appInfo
    }

    func transferToTabCandidate() -> TabCandidate {
        var appType: AppType = .appTypeURL
        if tabBizType == .MINI_APP || tabBizType == .WEB_APP {
            appType = .appTypeOpenApp
        }
        return TabCandidate(
            id: tabID,
            icon: tabIcon.toCodable(),
            title: tabTitle,
            url: tabURL,
            bizType: tabBizType,
            appType: appType,
            bizId: tabBizID,
            uniqueId: tabContainableIdentifier
        )
    }
}

public extension CustomBizType {
    func toAppBizType() -> NavigationAppBizType {
        switch self {
        case .UNKNOWN_TYPE:
            return .unknownType
        case .CCM:
            return .ccm
        case .MINI_APP:
            return .miniApp
        case .WEB_APP:
            return .webApp
        case .MEEGO:
            return .meego
        case .WEB:
            return .web
        @unknown default:
            return .unknownType
        }
    }
}

public extension NavigationAppBizType {
    func toCustomBizType() -> CustomBizType {
        switch self {
        case .unknownType:
            return .UNKNOWN_TYPE
        case .ccm:
            return .CCM
        case .miniApp:
            return .MINI_APP
        case .webApp:
            return .WEB_APP
        case .meego:
            return .MEEGO
        case .web:
            return .WEB
        @unknown default:
            return .UNKNOWN_TYPE
        }
    }
}

public extension CustomTabIcon {
    func toCustomAppLogo() -> RustPB.Basic_V1_NavigationAppInfo.CustomNavigationAppLogo {
        let icon  = self.toCodable()
        var logo = RustPB.Basic_V1_NavigationAppInfo.CustomNavigationAppLogo()
        logo.content = icon.content
        switch icon.type {
        case .udToken:
            logo.type = .appLogoTypeUdToken
        case .byteKey:
            logo.type = .appLogoTypeImageKey
        case .webURL:
            logo.type = .appLogoTypeURL
        case .iconInfo:
            logo.type = .appLogoTypeCcmIcon
        default:
            logo.type = .appLogoTypeUnknown
        }
        return logo
    }
}

public extension Basic_V1_NavigationAppType {
    func transformToNativeApptype() -> AppType {
        switch self {
        case .appTypeLarkNative:
            return .native
        case .appTypeMini:
            return .gadget
        case .appTypeWeb:
            return .webapp
        case .appTypeOpenApp:
            return .appTypeOpenApp
        case .appTypeURL:
            return .appTypeURL
        case .appTypeCustomNative:
            return .appTypeCustomNative
        default:
            return .native
        }
    }

    // 仅用来兼容4.5版本及之前的本地缓存的v2数据，作为v2过度到v3用，以后可以删除
    static func transformToV3(_ appType: String) -> Basic_V1_NavigationAppType {
        guard let type = AppType(rawValue: appType) else { return .appTypeLarkNative }
        switch type {
        case .native:
            return .appTypeLarkNative
        case .gadget:
            return .appTypeMini
        case .webapp:
            return .appTypeWeb
        default:
            return .appTypeLarkNative
        }
    }
}
