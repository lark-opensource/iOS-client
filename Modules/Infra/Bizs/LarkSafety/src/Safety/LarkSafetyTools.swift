//
//  LarkSafetyTools.swift
//  LarkApp
//
//  Created by KT on 2019/7/30.
//

import UIKit
import Foundation

/// Safety工具类
public final class LarkSafetyTools {

    /// 单例
    public static let shared = LarkSafetyTools()

    private var blurImageView: BlureImageView?

    /// 添加遮盖全屏的毛玻璃
    public func addWindowBlurView(in window: UIWindow?) {
        guard let window = window else { return }
        let image = LarkSafetyUtils.blurredImage(
            LarkSafetyTools.screenShot(for: window),
            withRadius: 15.0,
            iterations: 3,
            tintColor: .clear)

        let imageView = BlureImageView()
        imageView.tag = larkBlurImageTag
        imageView.image = image
        imageView.frame = window.frame
        window.addSubview(imageView)

        self.blurImageView?.removeFromSuperview()
        self.blurImageView = imageView
    }

    /// 移除遮盖全屏的毛玻璃
    public func removeWindowBlurView() {
        self.removeBlurViewIfPossible()
    }

    /// keyWindow截屏
    ///
    /// - Returns: UIImage
    public static func screenShot(for window: UIWindow) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(window.frame.size, false, UIScreen.main.scale)
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage ?? UIImage()
    }

    // MARK: - Private
    private init() {
    }

    private func removeBlurViewIfPossible() {
        guard let view = self.blurImageView else { return }
        view.removeFromSuperview()
        self.blurImageView = nil
    }

    private let larkBlurImageTag = 9_527
}

private final class BlureImageView: UIImageView { }
