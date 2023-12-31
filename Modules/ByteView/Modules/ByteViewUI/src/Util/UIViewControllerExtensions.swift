//
//  UIViewControllerExtensions.swift
//  ByteViewUI
//
//  Created by kiri on 2023/2/21.
//

import Foundation
import ByteViewCommon

extension VCExtension where BaseType: UIViewController {
    public var topMost: UIViewController {
        UIDependencyManager.dependency?.topMost(of: base) ?? base
    }

    /// 防止多scene转场时present，导致crash。
    ///
    /// 辅助窗口关闭时，present preview会crash。
    /// - https://t.wtturl.cn/hwBoCdg/
    /// - https://meego.feishu.cn/larksuite/issue/detail/8384399
    /// - 复现路径：主scene和辅助窗口同时在前台，并且主scene为compact模式。此时再次点击加入会议，会结束掉辅助窗口，并在主scene上present preview，这时会crash。
    /// - crash原因：present preview时，会经历pageSheet(initial) -> fullScreen(compact) -> formSheet(regular)的变化，其中fullScreen短暂的出现在scene的转场过程中， 并且在动画结束前就变到了formSheet，导致`_UIFullscreenPresentationController`抛出异常：_computeToEndFrameForCurrentTransition block is nil inside the _transitionViewForCurrentTransition block。
    public func safePresent(_ vc: UIViewController, animated: Bool, completion: (() -> Void)? = nil) {
        WindowSceneTransitionCoordinator.shared.appendAction(key: "presenting") { [weak base] in
            // vc不能weak，否则就释放了。
            base?.present(vc, animated: animated, completion: completion)
        }
    }
}

/// 检查是否在多scene转场（销毁辅助窗口或改变分屏），转场过程中提供方法delay必要的action，以防止crash（比如present vc）
/// - https://t.wtturl.cn/kLoghRn/
private final class WindowSceneTransitionCoordinator {
    static let shared = WindowSceneTransitionCoordinator()

    private let isMultisceneEnabled: Bool
    private var isTransitioning = false
    private var actions: [SceneTransitionAction] = []
    /// - start后500ms，手动检查一次是否需要结束transition
    /// - start后5s，强制结束transition
    private var timeoutItems: [DispatchWorkItem] = []

    init() {
        assertMain()
        if #available(iOS 13.0, *), Display.pad {
            isMultisceneEnabled = true
            startMonitor()
        } else {
            isMultisceneEnabled = false
        }
    }

    /// 添加需要避免scene转场的操作，必须在主线程调用
    func appendAction(key: String, action: @escaping () -> Void) {
        assertMain()
        if isMultisceneEnabled, isTransitioning {
            Logger.ui.info("[WindowSceneTransitionCoordinator] append blocked action: \(key)")
            actions.removeAll(where: { $0.key == key })
            actions.append(SceneTransitionAction(key: key, action: action))
        } else {
            action()
        }
    }

    private struct SceneTransitionAction {
        let key: String
        let action: () -> Void
    }
}

@available(iOS 13.0, *)
private extension WindowSceneTransitionCoordinator {
    func startMonitor() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTransitionBeganNotification(_:)),
                                               name: UIScene.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTransitionBeganNotification(_:)),
                                               name: UIScene.willDeactivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTransitionEndedNotification(_:)),
                                               name: UIScene.didActivateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveTransitionEndedNotification(_:)),
                                               name: UIScene.didEnterBackgroundNotification, object: nil)
        if !VCScene.isSceneTransitionFinished {
            startTransitioning("hasInactive on initialize")
        }
    }

    @objc func didReceiveTransitionBeganNotification(_ notification: Notification) {
        startTransitioning(notification.name.rawValue)
    }

    @objc func didReceiveTransitionEndedNotification(_ notification: Notification) {
        finishTransitioning(notification.name.rawValue)
    }

    func startTransitioning(_ reason: String) {
        if isTransitioning { return }
        Logger.ui.info("[WindowSceneTransitionCoordinator] start transitioning, reason: \(reason)")

        clearTimeoutItems()
        isTransitioning = true
        let checkTimeoutItem = DispatchWorkItem {
            self.finishTransitioning("timeout(500ms)")
        }
        let forceTimeoutItem = DispatchWorkItem {
            self.finishTransitioning("timeout(5s)", force: true)
        }
        self.timeoutItems = [checkTimeoutItem, forceTimeoutItem]
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: checkTimeoutItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: forceTimeoutItem)
    }

    func finishTransitioning(_ reason: String, force: Bool = false) {
        guard isTransitioning, force || VCScene.isSceneTransitionFinished else { return }
        Logger.ui.info("[WindowSceneTransitionCoordinator] finish transitioning, reason: \(reason)")

        clearTimeoutItems()
        isTransitioning = false
        actions.forEach { action in
            Logger.ui.info("[WindowSceneTransitionCoordinator] running blocked action: \(action.key)")
            action.action()
        }
        self.actions = []
    }

    func clearTimeoutItems() {
        self.timeoutItems.forEach { $0.cancel() }
        self.timeoutItems = []
    }
}
