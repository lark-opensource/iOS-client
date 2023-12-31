//
//  Helper.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import LKWindowManager
import EENavigator

// swiftlint:disable all

enum Helper {

    /// The height of status bar in notch screen device.
    /// NOTE: The height of status bar various by devices, for maintainability,
    /// DONOT use 44 for all notch screen devices.
    public static var statusBarHeight: CGFloat {
        return keyWindow?.safeAreaInsets.top ?? 0
    }

    /// The height of home indicator in notch screen device.
    public static var homeIndicatorHeight: CGFloat {
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }

    public static var isFullScreen: Bool {
        return homeIndicatorHeight > 0
    }

    /// 导航栏高度
    public static let naviBarHeight: CGFloat = 44.0

    /// 工具栏高度
    public static let tabBarHeight: CGFloat = 52.0

    /// 获取屏幕宽度
    static let screenWidth = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)

    /// 获取屏幕高度
    static let screenHeight = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)

    /// Push 页面前，判断跳转的 VC 是否支持旋转
    static func rotateToPortraitIfNeeded(_ targetVC: UIViewController) {
        guard targetVC.supportedInterfaceOrientations == .portrait else { return }

        if let orientation = Utility.getCurrentInterfaceOrientation(), orientation.isLandscape {
            if #available(iOS 16.0, *),
               let window = Navigator.shared.mainSceneWindow,  //Global
               let windowScene = window.windowScene {
                Utility.focusRotateIfNeeded(to: .portrait, window: window, windowScene: windowScene)
            } else {
                Utility.focusRotateIfNeeded(to: .portrait)
            }
        }
    }
}

var keyWindow: UIWindow? {
    if #available(iOS 13.0, *) {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    } else {
        return UIApplication.shared.keyWindow
    }
}

/// 获取当前最上层VC
///
/// - Parameter rootVC: 底部VC
/// - Returns: 结果
func topViewController(_ rootVC: UIViewController? = keyWindow?.rootViewController) -> UIViewController? {
    if let tabbarVC = rootVC as? UITabBarController, let selectedVC = tabbarVC.selectedViewController {
        return topViewController(selectedVC)
    } else if let naviVC = rootVC as? UINavigationController, let visibleVC = naviVC.visibleViewController {
        return topViewController(visibleVC)
    } else if let presentedVC = rootVC?.presentedViewController {
        return topViewController(presentedVC)
    }
    return rootVC
}

extension DispatchQueue {

    private static var onceTokenTracker: [String] = []
    /// 保证整个生命周期只执行一次
    ///
    /// - Parameters:
    ///   - token: token
    ///   - block: 执行的代码块
    static func dispatchOnce(_ token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if onceTokenTracker.contains(token) {
            return
        }
        onceTokenTracker.append(token)
        block()
    }

}

extension UIView {

    /// 获取截图
    ///
    /// - Parameters:
    ///   - rect: 截图范围，默认为CGRect.zero
    ///   - scale: 图片缩放因子，默认为屏幕缩放因子
    /// - Returns: 截图
    func snapshot(_ rect: CGRect = .zero, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        // 获取整个区域图片
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, scale)
        defer {
            UIGraphicsEndImageContext()
        }
        drawHierarchy(in: frame, afterScreenUpdates: true)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        // 如果不裁剪图片，直接返回整张图片
        if rect.equalTo(.zero) || rect.equalTo(bounds) {
            return image
        }
        // 按照给定的矩形区域进行剪裁
        guard let sourceImageRef = image.cgImage else { return nil }
        let newRect = rect.applying(CGAffineTransform(scaleX: scale, y: scale))
        guard let newImageRef = sourceImageRef.cropping(to: newRect) else { return nil }
        // 将CGImageRef转换成UIImage
        let newImage = UIImage(cgImage: newImageRef, scale: scale, orientation: .up)
        return newImage
    }

}

extension UIColor {

    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }

    /// 16进制颜色
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255
        let green = CGFloat((hex & 0xFF00) >> 8) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension UIImage {

    /// 将图片染色，并返回新的图片
    /// - Parameter color: 替换颜色
    func tinted(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        let rect = CGRect(origin: CGPoint.zero, size: size)
        color.setFill()
        self.draw(in: rect)
        context.setBlendMode(.sourceIn)
        context.fill(rect)
        let resultImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return resultImage
    }
}

extension UINavigationController {

    func pushViewController(_ viewController: UIViewController,
                            animated: Bool,
                            completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }

    func replaceTopViewController(with viewController: UIViewController,
                                  animated: Bool,
                                  completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        defer { CATransaction.commit() }
        var vcs = viewControllers
        if vcs.contains(where: { $0 === viewController }) {
            vcs.removeAll(where: { $0 === viewController })
        }
        if vcs.isEmpty {
            vcs.append(viewController)
        } else {
            vcs[vcs.count - 1] = viewController
        }
        setViewControllers(vcs, animated: animated)
    }

    func pushOrPopViewController(_ viewController: UIViewController,
                                  animated: Bool,
                                  completion: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        defer { CATransaction.commit() }
        let vcs = viewControllers
        if vcs.contains(where: { $0 === viewController }) {
            // 如果栈内包含 VC，则 Pop 到该 VC，丢弃栈上层 VC
            var newVCs: [UIViewController] = []
            for vc in vcs {
                newVCs.append(vc)
                if vc === viewController { break }
            }
            setViewControllers(newVCs, animated: animated)
        } else {
            // 如果栈内不包含 VC，直接推入
            pushViewController(viewController, animated: true)
        }
    }
}

public extension UIView {

    /// 截屏
    var screenshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

struct CodableRect: Codable {
    private var originX: CGFloat
    private var originY: CGFloat
    private var width: CGFloat
    private var height: CGFloat

    init(cgRect: CGRect) {
        self.originX = cgRect.origin.x
        self.originY = cgRect.origin.y
        self.width = cgRect.width
        self.height = cgRect.height
    }

    var cgRect: CGRect {
        return CGRect(
            x: originX,
            y: originY,
            width: width,
            height: height
        )
    }
}

// swiftlint:enable all
