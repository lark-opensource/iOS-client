//
//  SuspendConfig.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/20.
//

import Foundation
import UIKit

// MARK: - 基本配置
enum SuspendConfig {

    /// 悬浮窗大小
    static let bubbleSize = CGSize(width: 52, height: 52)
    /// 悬浮窗默认位置
    static var defaultBubbleRect: CGRect {
        let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let screenHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return CGRect(
            x: screenWidth - bubbleSize.width,
            y: screenHeight / 2 + 44,
            width: bubbleSize.width,
            height: bubbleSize.height
        )
    }

    /// 扇形篮筐大小
    static let basketSize = CGSize(width: 140, height: 140)
    static let basketScale: CGFloat = 168 / 140

    /// 篮筐默认位置
    static var defaultBasketRect: CGRect {
        return CGRect(
            x: UIScreen.main.bounds.width - basketSize.width * 0.29,
            y: UIScreen.main.bounds.height - basketSize.height * 0.29,
            width: basketSize.width,
            height: basketSize.height
        )
    }

    /// 动画时间
    static let animateDuration: TimeInterval = 0.2

    static let maxDockLimit: Int = Int.max

    static var safeZone = UIEdgeInsets(
        top: Helper.statusBarHeight,
        left: 0,
        bottom: Helper.homeIndicatorHeight + 10,
        right: 0
    )

    /// 禁止气泡移动到此区域
    static let restrictedZone: UIEdgeInsets = {
        return UIEdgeInsets(
            top: Helper.statusBarHeight,
            left: 10,
            bottom: Helper.homeIndicatorHeight,
            right: 10
        )
    }()

    static let protectedMargin: CGFloat = 20
}
