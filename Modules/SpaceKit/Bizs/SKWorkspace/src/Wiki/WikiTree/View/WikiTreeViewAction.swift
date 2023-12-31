//
//  WikiTreeViewAction.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/5/23.
//

import Foundation
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit

public enum WikiTreeViewAction {
    case scrollTo(indexPath: IndexPath)
    case reloadSectionHeader(section: Int, node: TreeNode)
    case present(provider: (UIView) -> UIViewController, popoverConfig: ((UIViewController) -> Void)? = nil)
    case dismiss(controller: UIViewController?)
    case push(controller: UIViewController)
    case pushURL(_ url: URL)

    // 从 view 层模拟一次完整的 toggle state 点击事件，包括展示 cell loading 等效果
    case simulateClickState(nodeUID: WikiTreeNodeUID)

    case showLoading
    case showErrorPage(UIView)

    case showHUD(_ action: HUDAction)
    case hideHUD
    // 仅供需要fromVC的其他业务方使用
    case customAction(compeletion: ((UIViewController?) -> Void))
    public enum HUDAction {
        case customLoading(_ content: String)
        case failure(_ content: String)
        case success(_ content: String)
        case tips(_ content: String)
        case custom(config: UDToastConfig, operationCallback: ((String?) -> Void)?)
        public static let loading: HUDAction = .customLoading(BundleI18n.SKResource.Doc_Facade_Loading)
    }
}

public struct TreeSwipeAction {
    
    static var normalMoreImage: UIImage {
        UDIcon.moreOutlined.ud.withTintColor(UDColor.staticWhite)
    }
    static var normalAddImage: UIImage {
        UDIcon.addOutlined.ud.withTintColor(UDColor.staticWhite)
    }
    static var disabledMoreImage: UIImage {
        UDIcon.moreOutlined.ud.withTintColor(UDColor.staticWhite.withAlphaComponent(0.5))
    }
    static var disabledAddImage: UIImage {
        UDIcon.addOutlined.ud.withTintColor(UDColor.staticWhite.withAlphaComponent(0.5))
    }
    
    public let normalImage: UIImage
    public let normalBackgroundColor: UIColor
    public let disabledImage: UIImage
    public let disabledBackgroundColor: UIColor
    public let action: (UIView, @escaping (Bool) -> Void, TreeNode, IndexPath) -> Void

    public func getSlideItem(isEnable: Bool, node: TreeNode) -> SKCustomSlideItem {
        SKCustomSlideItem(icon: isEnable ? normalImage : disabledImage,
                          backgroundColor: isEnable ? normalBackgroundColor : disabledBackgroundColor) { _, view in
            action(view, { _ in }, node, IndexPath())
        }
    }
    
    public func getHoverItem(node: TreeNode) -> HomeHoverItem {
        HomeHoverItem(icon: normalImage,
                      hoverBackgroundColor: UDColor.fillHover) { _, view in
            action(view, { _ in }, node, IndexPath())
        }
    }
}

struct SwipeActionSheetTarget {
    let title: String
    let titleColor: UIColor?
    let isEnable: Bool
    let action: (IndexPath, TreeNode) -> Void
}
