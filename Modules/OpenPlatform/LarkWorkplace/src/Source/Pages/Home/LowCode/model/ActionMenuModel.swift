//
//  ActionMenuModel.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/12/9.
//

import Foundation
import UniverseDesignIcon
import RxSwift
import LarkWorkplaceModel

// MARK: 操作菜单相关
/// 菜单选项的事件类型
enum ActionMenuEventType {
    case cancelCommon
    case tip
    case link
    case callback
    case setting
    case console
    case blockShare
}

/// 交互菜单选项
final class ActionMenuItem {
    var name: String
    var iconUrl: String
    var schema: String?
    var key: String?
    /// 禁用时的弹窗文案
    var disableTip: String?
    /// 内置图标
    var iconResource: UIImage?
    /// 内置跳转逻辑
    var event: ActionMenuEventType = .link

    private var developerItem: TMPLMenuItem?
    private var developerAction: ((TMPLMenuItem) -> Void)?

    var shareTaskGenerator: (([WPMessageReceiver], String?) -> Observable<[String]>?)?

    init(name: String, iconUrl: String, key: String? = nil, schema: String? = nil) {
        self.name = name
        self.iconUrl = iconUrl
        self.key = key
        self.schema = schema
    }

    @discardableResult
    func updateDeveloperItem(with info: BlkAPIDataUpdateMenuItemInfo) -> Bool {
        guard key == info.key else {
            return false
        }
        guard let origin = developerItem else {
            return false
        }
        let newItem = TMPLMenuItem(
            name: info.name ?? origin.name,
            iconUrl: info.iconUrl ?? origin.iconUrl,
            schema: origin.schema,
            key: origin.key
        )
        developerItem = newItem
        name = newItem.i18nName
        iconUrl = newItem.iconUrl
        return true
    }

    /// 构造一个取消常用的选项
    static func cancelItem(disable: Bool) -> ActionMenuItem {
        let cancelCommon = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RemoveFrqBttn
        let item = ActionMenuItem(name: cancelCommon, iconUrl: "")
        item.iconResource = Resources.menu_cancel_common

        if disable {
            item.event = .tip
            item.disableTip = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_RecBlcRemovalNull
        } else {
            item.event = .cancelCommon
        }

        return item
    }

    static func blockShareItem(_ shareTaskGenerator: @escaping ([WPMessageReceiver], String?) -> Observable<[String]>?) -> ActionMenuItem {
        let shareCommon = BundleI18n.LarkWorkplace.OpenPlatform_BaseBlock_ShareBttn
        let item = ActionMenuItem(name: shareCommon, iconUrl: "")
        item.iconResource = Resources.menu_share
        item.event = .blockShare
        item.shareTaskGenerator = shareTaskGenerator
        return item
    }

    /// 构造一个设置跳转的选项
    static func settingItem(url: String) -> ActionMenuItem {
        let settingText = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_BlcSettings
        let item = ActionMenuItem(name: settingText, iconUrl: "", key: "", schema: url)
        item.iconResource = Resources.menu_setting
        item.event = .setting
        return item
    }

    /// 构造一个 Console 按钮
    static func consoleItem() -> ActionMenuItem {
        let title = BundleI18n.LarkWorkplace.OpenPlatform_Workplace_BlcConsole
        let item = ActionMenuItem(name: title, iconUrl: "")
        item.iconResource = UDIcon.platformOutlined
        item.event = .console
        return item
    }

    static func developerItem(origin: TMPLMenuItem, action: @escaping (TMPLMenuItem) -> Void) -> ActionMenuItem {
        let item = ActionMenuItem(
            name: origin.i18nName,
            iconUrl: origin.iconUrl,
            key: origin.key,
            schema: origin.schema
        )
        item.developerItem = origin
        item.developerAction = action
        item.event = .callback
        return item
    }

    func invokeCallbackEvent() {
        switch self.event {
        case .callback:
            if let item = developerItem, let action = developerAction {
                action(item)
            } else {
                assertionFailure()
            }
        default: break
        }
    }
}
