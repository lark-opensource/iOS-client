//
//  ToolBarImageCache.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/12.
//

import Foundation
import UniverseDesignIcon

enum ToolBarImageLocation {
    /// iPad 更多列表页
    case padlist
    /// iPad 底部栏的左侧、中间部分
    case padbar
    /// iPhone 底部工具栏
    case phonebar
    /// iPhone 竖屏更多展开页面
    case phoneMore
    /// iPhone 横屏更多展开页面
    case landscapeMore
    /// iPhone 横屏工具栏
    case navbar

    var defaultIconColor: UIColor {
        switch self {
        case .phonebar, .phoneMore, .landscapeMore, .navbar:
            return UIColor.ud.iconN1.withAlphaComponent(0.8)
        case .padlist:
            return UIColor.ud.iconN1
        case .padbar:
            return UIColor.ud.iconN2
        }
    }

    var iconSize: CGSize {
        switch self {
        case .padlist:
            return ToolBarItemLayout.listIconSize
        case .padbar:
            return PadToolBarItemView.iconSize
        case .phonebar:
            return PhoneToolBarItemView.iconSize
        case .phoneMore:
            return ToolBarItemLayout.collectionIconSize
        case .landscapeMore:
            return ToolBarItemLayout.landscapeCollectionIconSize
        case .navbar:
            return NavigationBarItemView.iconSize
        }
    }
}

private struct CacheKey: Hashable {
    let location: ToolBarImageLocation
    let key: UDIconType
    let isEnabled: Bool
    let iconColor: UIColor
}

class ToolBarImageCache {
    private static var cache: [CacheKey: UIImage] = [:]

    static func image(for item: ToolBarItem, location: ToolBarImageLocation) -> UIImage? {
        let iconType: ToolBarIconType
        switch location {
        case .padlist, .navbar: iconType = item.outlinedIcon
        case .padbar, .phonebar, .phoneMore, .landscapeMore: iconType = item.filledIcon
        }

        let iconKey: UDIconType
        let iconColor: UIColor
        switch iconType {
        case .customColoredIcon(let key, let color):
            iconKey = key
            iconColor = item.isEnabled ? color : UIColor.ud.iconDisabled
        case .icon(let key):
            iconKey = key
            iconColor = item.isEnabled ? location.defaultIconColor : UIColor.ud.iconDisabled
        case .image(let image):
            return image
        case .none:
            return nil
        }

        let key = CacheKey(location: location, key: iconKey, isEnabled: item.isEnabled, iconColor: iconColor)
        if let image = cache[key] {
            return image
        }

        let image = UDIcon.getIconByKey(iconKey, iconColor: iconColor, size: location.iconSize)
        cache[key] = image
        return image
    }
}
