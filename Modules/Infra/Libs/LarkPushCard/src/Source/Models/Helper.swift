//
//  Helper.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/9/16.
//

import Foundation
import UIKit

// ignore magic number checking for UI
// disalbe-lint: magic number

// swiftlint:disable all
enum Helper {
    /// 获取 safeAre 高度
    static var safeAreaHeight: CGFloat { Helper.keyWindow?.safeAreaInsets.top ?? 0 }

    /// 获取 keyWindow 宽度
    static var windowWidth: CGFloat {
        guard let keyWindow = Helper.keyWindow else {
            return Helper.screenWidth
        }
        return keyWindow.bounds.width
    }

    /// 获取 keyWindow 高度
    static var windowHeight: CGFloat {
        guard let keyWindow = Helper.keyWindow else { return Helper.screenHeight }
        return keyWindow.bounds.width
    }

    /// 获取屏幕宽度
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }

    /// 获取屏幕高度
    static var screenHeight: CGFloat { UIScreen.main.bounds.height }

    /// 是否处于手机横屏状态
    static var isInPhoneLandscape: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone && (Helper.screenWidth > Helper.screenHeight)
    }

    /// 是否展示在屏幕中间
    static var isShowInWindowCenterX: Bool {

        guard UIDevice.current.userInterfaceIdiom == .pad else { return true }

        if Helper.isInCompact, Helper.windowWidth < 500 {
            return true
        } else {
            return false
        }
    }

    /// 卡片在不同设备下 X 的距离
    static var cardStackedX: CGFloat {
        if Helper.isInPhoneLandscape {
            return (Helper.windowWidth - Cons.cardWidth) / 2
        }

        if UIDevice.current.userInterfaceIdiom == .phone {
            return Cons.cardContainerPadding
        }

        if Helper.isInCompact, Helper.windowWidth < 500 {
            return Cons.cardContainerPadding
        }

        if Helper.isInCompact, Helper.windowWidth > 500 {
            return (Helper.windowWidth - Cons.cardWidth) / 2
        }

        if !Helper.isInCompact {
            return Helper.windowWidth - Cons.cardWidth - Cons.cardContainerPadding
        }

        return Cons.cardContainerPadding
    }

    /// 判断当前 window C / R 状态
    static var isInCompact: Bool {
        if let window = Helper.keyWindow {
            return window.traitCollection.horizontalSizeClass == .compact
        }
        return true
    }

    /// 获取当前 KeyWindow
    static var keyWindow: UIWindow? { PushCardManager.shared.window?.superWindow }
}
// swiftlint:enable all
