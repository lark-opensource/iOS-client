//
//  MenuViewModel.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/29.
//

import UIKit
import Foundation

/// MenuBarViewModel
public protocol MenuBarViewModel {
    /// menu
    var menu: MenuVCProtocol? { get set }
    /// type
    var type: String { get }
    /// identifier
    var identifier: String { get }
    /// menuView
    var menuView: UIView { get }
    /// menuSize
    var menuSize: CGSize { get }

    /// 修正 menu vc size
    func updateMenuVCSize(_ size: CGSize)

    /// 根据位置变化 更新 menu
    func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool)

}

extension MenuBarViewModel {
    /// updateMenuVCSize
    public func updateMenuVCSize(_ size: CGSize) {}
}

/// MenuLayoutInfo
public struct MenuLayoutInfo {

    /// menu size
    public let menuSize: CGSize

    /// 当前 menu frame， origin 为 nil 的时候代表 menu 第一次出现
    public let origin: CGRect?

    /// trigerView: 触发 menu 的 view, eg： cell
    public let trigerView: UIView

    /// trigerLocation: 触发 menu 的点击 相对 trigerView 的 point, eg：长按气泡位置
    public let trigerLocation: CGPoint?

    /// menu VC, 用于转化坐标系
    public let menuVC: UIViewController

    /// init
    public init(
        size: CGSize,
        origin: CGRect? = nil,
        vc menuVC: UIViewController,
        _ trigerView: UIView,
        _ trigerLocation: CGPoint? = nil) {
        self.menuSize = size
        self.origin = origin
        self.menuVC = menuVC
        self.trigerView = trigerView
        self.trigerLocation = trigerLocation
    }

    /// 把 trigerView rect 转化为 menuVc 上
    public func transformTrigerView() -> CGRect? {
        guard let menuWindow = self.menuVC.view.window,
            let trigerWindow = trigerView.window else {
            return nil
        }

        var rect = trigerView.convert(trigerView.bounds, to: trigerWindow)
        if trigerWindow != menuWindow {
            rect = trigerWindow.convert(rect, to: menuWindow)
        }
        return menuWindow.convert(rect, to: self.menuVC.view)
    }

    /// transformTrigerLocation
    public func transformTrigerLocation() -> CGPoint? {
        guard let trigerLocation = self.trigerLocation,
            let menuWindow = self.menuVC.view.window,
            let trigerWindow = trigerView.window else {
                return nil
        }
        var point = trigerView.convert(trigerLocation, to: trigerWindow)
        if trigerWindow != menuWindow {
            point = trigerWindow.convert(point, to: menuWindow)
        }
        return menuWindow.convert(point, to: self.menuVC.view)
    }

    /// transformView
    public func transformView(view: UIView) -> CGRect? {
        guard let menuWindow = self.menuVC.view.window,
            let viewWindow = view.window else {
            return nil
        }

        var rect = view.convert(view.bounds, to: viewWindow)
        if viewWindow != menuWindow {
            rect = viewWindow.convert(rect, to: menuWindow)
        }
        return menuWindow.convert(rect, to: self.menuVC.view)
    }
}

/// MenuBarLayout
public protocol MenuBarLayout {

    /// 计算 menu frame 方法
    ///
    /// - Parameters:
    ///   - menuSize: menu size
    ///   - origin: 当前 menu frame， origin 为 nil 的时候代表 menu 第一次出现
    ///   - info: layout 布局相关信息
    ///   - trigerLocation: 触发 menu 的点击 point, eg：长按气泡位置
    /// - Returns: menu frame

    /// 计算 menu 正常显示的 frame
    func calculate(info: MenuLayoutInfo) -> CGRect

    /// menu 从不显示到显示的 appear rect
    func calculateAppear(info: MenuLayoutInfo) -> CGRect

    /// menu 从显示到消失的 disappear rect
    func calculateDisappear(info: MenuLayoutInfo) -> CGRect

    /// menu 显示的时候 size 发生变化 重新计算 rect
    /// downward 为 true 时向下刷新, 否则向上刷新
    /// offset 为 偏移位置
    func calculateUpdate(info: MenuLayoutInfo, downward: Bool, offset: CGPoint) -> CGRect
}
