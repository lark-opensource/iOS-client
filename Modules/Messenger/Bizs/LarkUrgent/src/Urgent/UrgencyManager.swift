//
//  UrgentManager.swift
//  LarkUrgent
//
//  Created by 白镜吾 on 2022/10/11.
//

import UIKit
import Foundation
import EENavigator
import LarkPushCard
import LarkSuspendable
import LKWindowManager

final class UrgencyManager: NSObject {
    static let zombieZoneKey = "LarkUrgent_ZombieZone"
    /// 加急弹窗
    var window: UrgencyWindow?

    override init() {
        super.init()
        addKeyBoardObserver()
        LKWindowManager.shared.registerWindow(UrgencyWindow.self)
    }

    /// 加急归档数组
    var archiveCards: [Cardable] {
        return self.window?.urgencyViewController.floatingBox.cardArchives ?? []
    }

    /// 新增浮窗中的加急卡片
    ///
    /// - parameter model: Push 卡片模型
    /// - parameter animated: 是否显示浮窗动画
    func post(_ model: Cardable, animated: Bool) {
        self.execInMainThread {
            self.post([model], animated: animated)
        }
    }

    /// 新增浮窗中的加急卡片
    ///
    /// - parameter model: Push 卡片模型组
    /// - parameter animated: 是否显示浮窗动画
    func post(_ models: [Cardable], animated: Bool) {
        guard !models.isEmpty else { return }

        self.execInMainThread {
            self.createWindowAndVisible()
            self.window?.urgencyViewController.post(models, animated: animated)
        }
    }

    /// 移除浮窗中的加急卡片
    ///
    /// - parameter id: 加急卡片标识符
    /// - parameter animated: 是否显示浮窗动画
    func remove(with id: String, animated: Bool) {
        guard !id.isEmpty else { return }

        self.execInMainThread {
            guard !self.archiveCards.isEmpty else { return }
            self.createWindowAndVisible()
            self.window?.urgencyViewController.remove(with: id, animated: animated, completion: { [weak self] in
                if self?.archiveCards.isEmpty ?? true {
                    self?.window?.isHidden = true
                    self?.window?.removeFromSuperview()
                    self?.window = nil
                }
            })
        }
    }

    /// 确保闭包在主线程执行
    private func execInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    /// 检查window是否存在，不存在创建并 makeKeyAndVisible
    private func createWindowAndVisible() {
        if self.window == nil {
            if #available(iOS 13.0, *) {
                self.setupUrgencyWindowByConnectScene()
            } else {
                self.setupUrgencyWindowByApplicationDelegate()
            }
        }

        guard let window = self.window else { return }

        if window.isHidden {
            window.isHidden = false
        }
    }

    @available(iOS 13.0, *)
    private func setupUrgencyWindowByConnectScene() {
        if let windowScene = UIApplication.shared.windowApplicationScenes.first as? UIWindowScene,
           let rootWindow = Utility.rootWindowForScene(scene: windowScene) {
            self.window = self.createUrgencyWindow(window: rootWindow)
        }
    }

    private func setupUrgencyWindowByApplicationDelegate() {
        guard let delegate = UIApplication.shared.delegate,
              let weakWindow = delegate.window,
              let rootWindow = weakWindow else {
            return
        }
        self.window = self.createUrgencyWindow(window: rootWindow)
    }

    private func createUrgencyWindow(window: UIWindow) -> UrgencyWindow {
        guard let urgencyWindow = LKWindowManager.shared.createLKWindow(byID: .UrgencyWindow, isVirtual: true) as? UrgencyWindow else { return UrgencyWindow() }
        if #available(iOS 13.0, *) {
            urgencyWindow.windowScene = window.windowScene
        }
        return urgencyWindow
    }

    private func addKeyBoardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let floatingBox = window?.urgencyViewController.floatingBox else {
            return
        }

        if keyboardRect.intersects(floatingBox.frame) {
            let bottom: CGFloat = keyboardRect.height > 0 ? keyboardRect.height + UrgencyFloatingBox.Cons.keyboardOffset : UrgencyFloatingBox.Cons.cardFloatingBottom

            floatingBox.snp.updateConstraints { make in
                make.bottom.equalTo(-bottom)
            }
        }
        floatingBox.layoutIfNeeded()
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        guard let floatingBox = window?.urgencyViewController.floatingBox else {
            return
        }
        floatingBox.snp.updateConstraints { make in
            make.bottom.equalTo(-UrgencyFloatingBox.Cons.cardFloatingBottom)
        }
        floatingBox.layoutIfNeeded()
    }

    @objc
    private func keyboardDidShow(_ notification: Notification) {
        guard let floatingBox = window?.urgencyViewController.floatingBox else { return }
        UrgencyManager.urgentBoxToggled(urgencyBox: floatingBox, showed: true)
    }

    @objc
    private func keyboardDidHide(_ notification: Notification) {
        guard let floatingBox = window?.urgencyViewController.floatingBox else { return }
        UrgencyManager.urgentBoxToggled(urgencyBox: floatingBox, showed: true)
    }

    // 与多任务浮窗互斥：当加急出现时多任务浮窗不可与加急box重叠(新卡片逻辑)
    static func urgentBoxToggled(urgencyBox: UIView?, showed: Bool) {
        if showed, let box = urgencyBox {
            let rect = box.convert(box.bounds, to: nil)
            SuspendManager.shared.removeProtectedZone(forKey: UrgencyManager.zombieZoneKey)
            SuspendManager.shared.addProtectedZone(rect, forKey: UrgencyManager.zombieZoneKey)
        } else if !showed {
            SuspendManager.shared.removeProtectedZone(forKey: UrgencyManager.zombieZoneKey)
        }
    }
}
