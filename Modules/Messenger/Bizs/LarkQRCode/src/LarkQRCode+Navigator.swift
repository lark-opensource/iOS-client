//
//  LarkQRCode+Utils.swift
//  LarkQRCode
//
//  Created by Hayden on 2023/4/6.
//

import UIKit
import LarkUIKit
import EENavigator
import QRCode

enum LarkQRCodeNavigator {

    /// 打开扫一扫页面，如果当前屏幕被遮盖，则延后到当前屏幕重新展示时打开
    /// - Parameters:
    ///   - from: `EENavigator.NavigationFrom`，打开页面的层级
    ///   - params: `EENavigator.NaviParams`，路由参数
    static func showQRCodeViewControllerIfNeeded(from: NavigatorFrom, params: NaviParams? = nil) {
        // 如果主 Window 不是 KeyWindow，等待变成主 Window 再延迟打开扫一扫页面
        // NOTE: 这是正常主 Window 被顶部不可见 Window 遮盖的情况，此时可以直接打开 Window
        // NOTE2: 只有能够抢占 keyWindow 的 Window 才会影响此逻辑（多任务浮窗等非全屏 Window 不影响）
        if let fromWindow = from.fromViewController?.rootWindow(), !fromWindow.isKeyWindow {
            showQRCodeViewControllerWithDelay(from: from, params: params)
            return
        }
        // 如果主 Window 是 KeyWindow，但是当前被 AppLock 遮挡
        // NOTE: 这是一种特殊情况，是因为 AppLock Window 打开较慢，此时还没抢占主 Window，仍然需要延时执行
        // NOTE2: 这里使用字符串在运行时获取 LSCWindow 类，只是个临时解决方案，避免不必要的依赖
        if let appLockWindowClass = NSClassFromString("LarkSecurityCompliance.LSCWindow"),
           UIApplication.shared.windows.contains(where: { $0.isKind(of: appLockWindowClass) }) {
            showQRCodeViewControllerWithDelay(from: from, params: params)
            return
        }
        // 正常情况，主 Window 没有被遮挡，直接展示
        // NOTE: 大部分情况都会走到这个路径
        showQRCodeViewController(from: from, params: params)
    }

    private static func showQRCodeViewController(from: NavigatorFrom, params: NaviParams?) {
        let body = QRCodeControllerBody()
        if Display.pad {
            guard let vc = Navigator.shared.mainSceneTopMost else { return } //Global
            if !(vc is QRCode.ScanCodeViewControllerType) {
                Navigator.shared.present(body: body,  //Global
                                         naviParams: params,
                                         from: from,
                                         prepare: { vc in
                    vc.modalPresentationStyle = .fullScreen
                })
            }
        } else {
            Navigator.shared.push(body: body,  //Global
                                  naviParams: params,
                                  from: from)
        }
    }

    private static func showQRCodeViewControllerWithDelay(from: NavigatorFrom, params: NaviParams?) {
        guard let fromWindow = from.fromViewController?.rootWindow() else {
            showQRCodeViewController(from: from, params: params)
            return
        }
        fromWindow.addDidBecomeKeyBlock { [weak from, weak fromWindow] in
            guard let fromSource = from ?? fromWindow else { return }
            showQRCodeViewController(from: fromSource, params: params)
        }
    }
}

/*
 TODO:
 理想的情况是，所有 UIWindow 都给 LKWindowManager 管理，每个 Window 上的元素都能够拿到 `didBecomeActive` 回调，
 这样不需要依赖其他模块，只关注自己 Window 的回调，即可避免不同 Window 间的冲突。
 但是实际情况是，目前 LKWindowManager 还没有完全接入，各业务需要适配，且 WindowManager 需要改造以感知更多的生命周期。
 这里先给 UIWindow 做一个扩展，可以向 UIWindow 添加回调：如果当前 window 重新变为 keyWindow（多数情况下，可以看成是
 当前 window 重新展示在页面上方），则依次执行回调。
 此处留个 TODO，等 LKWindowManager 全业务接入后优化。
 */

extension UIWindow {

    private struct AssociatedKeys {
        static var didBecomeKeyBlocks = "didBecomeKeyBlocks"
        static var didAddObserver = "didAddObserver"
    }

    private var didBecomeKeyBlocks: [DispatchWorkItem] {
        get {
            if let blocks = objc_getAssociatedObject(self, &AssociatedKeys.didBecomeKeyBlocks) as? [DispatchWorkItem] {
                return blocks
            } else {
                let blocks = [DispatchWorkItem]()
                objc_setAssociatedObject(self, &AssociatedKeys.didBecomeKeyBlocks, blocks, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return blocks
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.didBecomeKeyBlocks, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            observeDidBecomeKeyNotification()
        }
    }

    private var didAddObserver: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.didAddObserver) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.didAddObserver, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private func observeDidBecomeKeyNotification() {
        if didAddObserver { return }
        didAddObserver = true
        let observeQueue = OperationQueue()
        observeQueue.name = "qrcode.window.become.active"
        NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification,
                                               object: self,
                                               queue: observeQueue,
                                               using: { [weak self] _ in
            guard let strongSelf = self else { return }
            for item in strongSelf.didBecomeKeyBlocks {
                DispatchQueue.main.async(execute: item)
            }
            strongSelf.didBecomeKeyBlocks.removeAll()
        })
    }

    /// 添加需要在当前 window 重获 keyWindow 时执行的回道，注意防护内存泄漏。
    func addDidBecomeKeyBlock(_ block: @escaping () -> Void) {
        let newItem = DispatchWorkItem {
            block()
        }
        var blocks = didBecomeKeyBlocks
        if let lastItem = blocks.last {
            newItem.notify(queue: DispatchQueue.main, execute: lastItem)
        }
        blocks.append(newItem)
        didBecomeKeyBlocks = blocks
    }
}
