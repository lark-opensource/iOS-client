//
//  MenuPanelSourceViewModel.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/3.
//

import Foundation
import UIKit

/// 菜单弹出时，表示从哪个视图上点击的类型，可以直接使用关联枚举，为了兼容OC，使用此种方式
@objc
public final class MenuPanelSourceViewModel: NSObject {

    let type: MenuPanelSourceViewType

    /// 通过UIView初始化
    /// - Parameter sourceView: 点击UIView类型弹出菜单
    @objc
    public init(sourceView: UIView) {
        self.type = .uiView(content: sourceView)
        super.init()
    }

    @objc
    public init(api: String) {
        self.type = .showMorePanelAPI
        super.init()
    }

    /// 通过UIBarButtonItem类型初始化
    /// - Parameter sourceButtonItem: 点击UIBarButtonItem类型弹出菜单
    @objc
    public init(sourceButtonItem: UIBarButtonItem) {
        self.type = .uiBarButtonItem(content: sourceButtonItem)
        super.init()
    }
}

extension MenuPanelSourceViewModel {
    /// 用于表示两种不同类型的视图
    enum MenuPanelSourceViewType {
        /// 表示UIView
        case uiView(content: UIView)
        /// 表示UIBarButtonItem
        case uiBarButtonItem(content: UIBarButtonItem)

        case showMorePanelAPI
    }
}
