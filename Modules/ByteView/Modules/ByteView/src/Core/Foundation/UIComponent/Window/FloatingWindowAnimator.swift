//
//  FloatingWindowAnimator.swift
//  ByteView
//
//  Created by kiri on 2021/3/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor
import ByteViewCommon
import ByteViewUI

/// 为FloatingWindow的floating动画提供外部输入，可继承DefaultFloatingWindowAnimator以简化实现
protocol FloatingWindowAnimator {
    /// 浮窗可移动的范围
    func floatingRegion(for window: FloatingWindow) -> CGRect
    /// 浮窗的大小
    func floatingSize(for window: FloatingWindow) -> CGSize
    /// 准备动画
    func prepareAnimation(for window: FloatingWindow, to frame: CGRect)
    /// 获取frame
    /// - returns: 返回动画后期望达到的frame
    func animationEndFrame(for window: FloatingWindow) -> CGRect
    /// 切换isFloating时的动画
    /// - parameters:
    ///     - window: 做动画的window
    ///     - animated: 是否需要动画
    ///     - frame: 动画后期望达到的frame
    ///     - alongsideAnimation: 跟随动画的回调
    ///     - completion: 动画完成后的回调
    func animate(for window: FloatingWindow, animated: Bool, to frame: CGRect, alongsideAnimation: (() -> Void)?, completion: ((Bool) -> Void)?)

    /// 小窗的时候调用该方法
    func updateSupportedInterfaceOrientations()
}

/// FloatingWindowAnimator的默认实现
class DefaultFloatingWindowAnimator: FloatingWindowAnimator {
    func updateSupportedInterfaceOrientations() {}

    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
        logger.info("init DefaultFloatingWindowAnimator")
    }

    deinit {
        logger.info("deinit DefaultFloatingWindowAnimator")
    }

    func floatingRegion(for window: FloatingWindow) -> CGRect {
        // nolint-next-line: magic number
        VCScene.bounds.insetBy(dx: 12, dy: 12)
    }

    func floatingSize(for window: FloatingWindow) -> CGSize {
        let size: CGSize
        if Display.pad {
            if #available(iOS 13.0, *), let ws = window.windowScene, ws.interfaceOrientation.isLandscape {
                size = CGSize(width: 240, height: 135)
            } else if UIApplication.shared.statusBarOrientation.isLandscape {
                size = CGSize(width: 240, height: 135)
            } else {
                size = CGSize(width: 160, height: 160)
            }
        } else {
            size = CGSize(width: 90, height: 90)
        }
        return size
    }

    func animate(for window: FloatingWindow, animated: Bool, to frame: CGRect, alongsideAnimation: (() -> Void)?, completion: ((Bool) -> Void)?) {
        if animated {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: {
                self.animations(for: window, animated: animated, to: frame)
                alongsideAnimation?()
                window.layoutIfNeeded()
            }, completion: { isFinished in
                self.completeAnimation(for: window, animated: animated, to: frame)
                completion?(isFinished)
            })
        } else {
            self.animations(for: window, animated: animated, to: frame)
            alongsideAnimation?()
            self.completeAnimation(for: window, animated: animated, to: frame)
            completion?(true)
        }
    }

    func prepareAnimation(for window: FloatingWindow, to frame: CGRect) {}

    func animationEndFrame(for window: FloatingWindow) -> CGRect {
        if window.isFloating {
            let validRegion = floatingRegion(for: window)
            let size = floatingSize(for: window)
            let origin = CGPoint(x: validRegion.maxX - size.width, y: validRegion.minY + VCScene.safeAreaInsets.top + 100.0)
            return CGRect(origin: origin, size: size)
        } else {
            return VCScene.bounds
        }
    }

    func animations(for window: FloatingWindow, animated: Bool, to frame: CGRect) {
        window.frame = frame
    }

    func completeAnimation(for window: FloatingWindow, animated: Bool, to frame: CGRect) { }
}

extension FloatingWindow {
    func updateFloatStyle() {
        // 自定义的window在floating下需要配置阴影
        if isFloating {
            self.applyFloatingShadow()
        } else {
            layer.shadowColor = nil
            layer.shadowOffset = .zero
            layer.shadowRadius = 0
            layer.shadowOpacity = 0
        }
    }
}
