//
//  CustomTopContainerContext.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/4.
//  https://bytedance.feishu.cn/docs/doccn42935xT0vODjS7MOaxcLsg

import Foundation
import SKUIKit
import UniverseDesignIcon
import SKFoundation

public typealias CustomTCManagerProxy = CustomTCManagerInfoProxy & CustomTCManagerActionProxy

/// 定制化TopContainer时所需信息
public protocol CustomTCManagerInfoProxy: AnyObject {
    var hostView: UIView { get }
    var enableFullscreenScrolling: Bool { get set }
    func obtainHostVCInteractivePopGestureRecognizer() -> UIGestureRecognizer?

    // Flags
    var isInVideoConference: Bool { get }
    var statusBarStyle: UIStatusBarStyle { get }
    var navBarSizeType: SKNavigationBar.SizeType { get }
    var disableCustomNavBarBackground: Bool { get }
}

/// 定制化TopContainer时相关配置
public protocol CustomTCManagerActionProxy: AnyObject {
    func customTCMangerDidShow(_: CustomTopContainerManager)
    func customTCMangerDidHidden(_: CustomTopContainerManager)
    func customTCManger(_: CustomTopContainerManager, updateStatusBarStyle: UIStatusBarStyle)
    func customTCManger(_: CustomTopContainerManager, shouldShowIndicator: Bool)
    func customTCMangerForceTopContainer(state: TopContainerState)
}

/// frontend control custom top container pattern parameters
public struct CustomTopContainerData: Codable {
    let titleConfig: TitleConfig?
    let sidesMenuConfig: SidesMenuConfig? // 左右两侧按钮
    let callback: String? // 回调
    let shouldShowDivider: Bool? // header 与正文中间的分割线
    let themeColor: String? // 主题色
    let historySceneLogic: HistorySceneLogic? // 历史记录特化逻辑
    let bitableCatalog: SKBitableCatalogData?
    let hideCustomHeaderInLandscape: Bool?
    let key: String? //用于标识业务

    private enum CodingKeys: String, CodingKey {
        case titleConfig = "titleConfig"
        case sidesMenuConfig = "items"
        case callback = "callback"
        case shouldShowDivider = "shouldShowDivider"
        case themeColor = "themeColor"
        case historySceneLogic = "historySceneLogic"
        case bitableCatalog = "bitableCatalog"
        case hideCustomHeaderInLandscape = "hideCustomHeaderInLandscape"
        case key = "key"
    }
}

public struct HistorySceneLogic: Codable {
    let id: String?
    let text: String?
    let shouldShow: Bool
    let restoreEnable: Bool
}

public struct TitleConfig: Codable {
    let title: String // 标题文字
    let position: String // 标题位置
    let isLoading: Bool // 标题是否处于isLoading态
    let titleIcon: String? //翻译icon
    let id: String?       // 标题id
    let clickable: Bool?  // 是否可点击
    let showFoldBtn: Bool? //是否展示折叠按钮
}

public struct SidesMenuConfig: Codable {
    let leftMenuConfigs: [MenuConfig]?
    let rightMenuConfigs: [MenuConfig]?

    private enum CodingKeys: String, CodingKey {
        case leftMenuConfigs = "left"
        case rightMenuConfigs = "right"
    }
}

public struct MenuConfig: Codable {
    let id: String
    var enable: Bool? = true
    let extraId: String?
    var style: String? = "icon"
    var text: String?
    var customColor: [String]?
}

//public enum SKBitableBlockType: String, Codable {
//    case dashboard = "DASHBOARD"
//    case bitableTable = "BITABLE_TABLE"
//    case linkedDocx = "LINKED_DOCX"
//}

public struct SKBitableCatalogData: Codable {
    public let baseId: String?
    public let tableName: String?
    public let tableId: String?
    public let viewName: String?
    public let viewId: String?
    public let blockType: String?
    public let viewType: String?
    // 灰度阶段为optional，且只有任务视图使用，灰度完成改为require
    var icon: String?
    public var iconUrl: String?
    public var needShowBadge: Bool?
    public let callback: String?
    public var viewTypeImage: UIImage? {
        var image: UIImage?
        if let udIconKey = bitableRealUDKey(icon), let key = UDIcon.getIconTypeByName(udIconKey) {
            image = UDIcon.getIconByKey(key)
        } else {
            guard let type = viewType else {
                return nil
            }
            switch type {
            case "notSupport": image = nil
            case "grid": image = UDIcon.bitablegridOutlined
            case "kanban": image = UDIcon.bitablekanbanOutlined
            case "gallery": image = UDIcon.bitablegalleryOutlined
            case "gantt": image = UDIcon.bitableganttOutlined
            case "form": image = UDIcon.bitableformOutlined
            case "task": image = UDIcon.bitableTaskviewOutlined
            case "calendar": image = UDIcon.calendarLineOutlined
            default:
                // 不应该走到这里
                let msg = "use viewType error"
                DocsLogger.error(msg)
                assertionFailure(msg)
            }
        }
        return image
    }
}
// ud-design key 转换工具
public func bitableRealUDKey(_ string: String?) -> String? {
    guard let string = string else {
        return nil
    }
    var finalStr = ""
    var str = string.replacingOccurrences(of: "-", with: "_")
    if str.starts(with: "icon_") {
        str.removeFirst(5) // 移除icon_
    } else {
        DocsLogger.error("ud key not start with icon_")
    }
    var flag = false
    // 按照UD规则做映射
    for item in str {
        if item == "_" {
            flag = true
        } else {
            if flag {
                finalStr.append(item.uppercased())
            } else {
                finalStr.append(item)
            }
            flag = false
        }
    }
    DocsLogger.info("bitableRealUDKey from \(string) to \(finalStr)")
    return finalStr
}
