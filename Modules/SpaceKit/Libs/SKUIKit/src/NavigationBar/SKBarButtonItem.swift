//
//  SKBarButtonItem.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/29.
//  


import Foundation
import UIKit
import UniverseDesignBadge
import UniverseDesignIcon

final public class SKBarButtonItem: UIBarButtonItem {

    public weak var associatedButton: SKBarButton?
    
    // 渲染原始色彩的image
    public var useOriginRenderedImage: Bool = false

    /// 前端用 biz.navigation.setMenu 传过来的 id
    public var id: SKNavigationBar.ButtonIdentifier = .unknown("UNKNOWN")

    public override var image: UIImage? {
        didSet {
            associatedButton?.update(image: image)
        }
    }

    /// 前端指定的自定义按钮状态颜色
    public var foregroundColorMapping: [UIControl.State: UIColor]? {
        didSet {
            associatedButton?.refreshColorMapping(foregroundColorMapping)
        }
    }

    /// 背景图片的状态颜色（目前只支持纯色背景）
    public var backgroundImageColorMapping: [UIControl.State: UIColor]?

    /// 按钮默认都应该是没有选中态的，只有 iPad 目录、评论按钮目前有 selected 状态
    public var isInSelection: Bool? {
        didSet {
            if let isInSelection = isInSelection {
                associatedButton?.isSelected = isInSelection
            }
        }
    }

    public override var isEnabled: Bool {
        didSet {
            associatedButton?.isEnabled = isEnabled
        }
    }

    /// 按钮右上角的小红点配置，目前没有写 didSet 绑定，
    /// 需要显式刷新一遍 navigationBar.trailingBarButtomItems 数组，在 didModifyTrailingItems 方法里更新小红点配置
    public var badgeStyle: UDBadgeConfig?
}
