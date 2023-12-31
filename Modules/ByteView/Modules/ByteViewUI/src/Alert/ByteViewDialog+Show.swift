//
//  ByteViewDialog+Show.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/14.
//

import Foundation
import ByteViewCommon

extension ByteViewDialog {
    public func show(animated: Bool, in vc: UIViewController?, completion: ((ByteViewDialog) -> Void)?) {
        let manager = ByteViewDialogManager.shared
        Util.runInMainThread {
            if let showingId = self.showConfig.id {
                guard !manager.isShowing(showingId) else { return }
                manager.showingIds.insert(showingId)
                manager.showingAlerts.append(WeakRef(self))
                Logger.ui.info("show alert \(showingId)")
            }
            // 消除键盘
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
            let showInVC: UIViewController
            if let vc = vc {
                showInVC = vc
            } else {
                let window: UIWindow
                if self.showConfig.inVcScene {
                    window = VCScene.createWindow(FollowVcWindow.self, tag: .alert)
                } else {
                    window = VCScene.createWindow(UIWindow.self, tag: .alert)
                }
                self.alertWindow = window
                let root = AlertContainerViewControler()
                window.rootViewController = root
                window.windowLevel = UIWindow.Level.alert + self.showConfig.level
                window.isHidden = false
                showInVC = root
            }
            showInVC.present(self, animated: true) {
                completion?(self)
            }

            if self.showConfig.needAutoDismiss {
                // 是否在会议结束后自动消失
                manager.autoDismissAlerts.append(.init(self))
            }
        }
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        Util.runInMainThread {
            self.alertWindow?.isHidden = true
            self.dismiss(animated: true) { [weak self] in
                self?.alertWindow?.rootViewController = nil
                self?.alertWindow = nil
                if let showingId = self?.showConfig.id {
                    ByteViewDialogManager.shared.showingIds.remove(showingId)
                    ByteViewDialogManager.shared.showingAlerts.removeAll {
                        $0.ref == nil || $0.ref === self
                    }
                }
            }

        }
    }
}
