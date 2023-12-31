//
//  QuickTabBarInterface.swift
//  AnimatedTabBar
//
//  Created by 夏汝震 on 2021/6/4.
//

import UIKit
import Foundation
import SnapKit
import LarkTab

// 对外提供的接口
public protocol QuickTabBarInterface: UIView {
    func show(contentView: UIView, delegate: QuickTabBarDelegate)
    func dismiss()
    func layout()
}

public protocol QuickTabBarDelegate: AnyObject {
    func quickTabBarDidShow(_ quickTabBar: QuickTabBarInterface, isSlide: Bool)
    func quickTabBarDidDismiss(_ quickTabBar: QuickTabBarInterface, isSlider: Bool)
}

protocol QuickTabBarContentViewInterface: UIView {
    var maxHeight: CGFloat { get }
    var delegate: QuickTabBarContentViewDelegate? { get set }
    func updateToProgress(_ progress: CGFloat)
    func updateData(_ dataSource: [AbstractTabBarItem])
    func reload()
}

protocol QuickTabBarContentViewDelegate: AnyObject {
    func quickTabBar(_ contentView: QuickTabBarContentViewInterface, didSelectItem tab: Tab)
    func quickTabBarDidTapEditButton(_ contentView: QuickTabBarContentViewInterface)
}
