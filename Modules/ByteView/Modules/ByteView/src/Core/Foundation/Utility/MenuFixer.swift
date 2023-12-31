//
//  MenuFixer.swift
//  ByteView
//
//  Created by kiri on 2020/6/9.
//

import UIKit

/// Fix the problem that UIMenuController is not visible on a window which is not original keyWindow on iOS 13.0+.
/// Just hold an instance of MenuFixer in the viewController:
///
///     class SomeViewController: UIViewController {
///         private var menuFixer: MenuFixer?
///
///         override func viewDidLoad() {
///             super.viewDidLoad()
///
///             menuFixer = MenuFixer(viewController: self)
///         }
///     }
///
final class MenuFixer {
    private var targetWindowProvider: () -> UIWindow?
    private var windowLevelChanged: Bool = false
    private var originWindowLevel: UIWindow.Level = .init(0.0)

    init(targetWindowProvider: @escaping () -> UIWindow?) {
        self.targetWindowProvider = targetWindowProvider
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(willShowMenu(_:)),
                                                   name: UIMenuController.willShowMenuNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(willHideMenu(_:)),
                                                   name: UIMenuController.willHideMenuNotification, object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(updateOrientation),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        updateOrientation()
    }

    convenience init(viewController: UIViewController) {
        self.init(targetWindowProvider: { [weak viewController] in return viewController?.view.window })
    }

    private lazy var menuWindow: UIWindow? = {
        if #available(iOS 13.0, *) {
            if let scene = targetWindowProvider()?.windowScene {
                return scene.windows.first { (w) -> Bool in
                    String(describing: type(of: w)) == "UITextEffectsWindow"
                }
            }
        }
        return UIApplication.shared.windows.first { (w) -> Bool in
            String(describing: type(of: w)) == "UITextEffectsWindow"
        }
    }()

    /// fix UIMenuController's orientation
    @objc
    private func updateOrientation() {
        if #available(iOS 13, *) {
            if let scene = targetWindowProvider()?.windowScene {
                let value = scene.interfaceOrientation.rawValue
                UIDevice.current.setValue(value, forKey: "orientation")
            }
        } else {
            let value = UIApplication.shared.statusBarOrientation.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
    }

    @objc
    private func willShowMenu(_ sender: NSNotification) {
        guard let w = menuWindow, let target = targetWindowProvider(), w != target else {
            return
        }

        if w.windowLevel > target.windowLevel {
            return
        }

        windowLevelChanged = true
        originWindowLevel = w.windowLevel
        w.windowLevel = target.windowLevel + 1
        Logger.ui.info("will show menu, update window level to: \(w.windowLevel)")
    }

    @objc
    private func willHideMenu(_ sender: NSNotification) {
        guard let w = menuWindow, windowLevelChanged else {
            return
        }

        windowLevelChanged = false
        w.windowLevel = originWindowLevel
        Logger.ui.info("will hide menu, retrieve window level to: \(w.windowLevel)")
    }

    deinit {
        if #available(iOS 13.0, *) {
            NotificationCenter.default
                .removeObserver(self, name: UIMenuController.willShowMenuNotification, object: nil)
            NotificationCenter.default
                .removeObserver(self, name: UIMenuController.willHideMenuNotification, object: nil)
        }
    }
}
