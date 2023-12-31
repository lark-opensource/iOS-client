//
//  LoginNaviController.swift
//  LarkLogin
//
//  Created by SuPeng on 1/9/19.
//

import UIKit

class LoginNaviController: UINavigationController {

    // 仅NaviController dismiss被调用时可用：兼容老版安全合规MFA，以解决他们无法感知页面被dismiss。
    public var dismissCallback: (() -> Void)?

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.isTranslucent = false
        self.navigationBar.tintColor = UIColor.ud.textTitle
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
        self.navigationBar.barTintColor = UIColor.ud.bgLogin
        if #available(iOS 13.0, *) {
            let appearance =  UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
            appearance.backgroundColor = UIColor.ud.bgLogin
            self.navigationBar.standardAppearance = appearance
            self.navigationBar.scrollEdgeAppearance = appearance
        }

        DispatchQueue.global().async {
            // fromColor在启动阶段调用可能会卡死，详见http://t.wtturl.cn/eyRaaVD/，因此异步调用
            let shadowImage = UIImage.lu.fromColor(UIColor.ud.lineDividerDefault)
            DispatchQueue.main.async {
                self.navigationBar.shadowImage = shadowImage
            }
        }

        self.delegate = self
    }

    public override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        } else {
            return false
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        } else {
            return .portrait
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        if viewControllers.count == 2, let _ = viewControllers.first as? SwitchUserLoadingViewController {
            self.dismiss(animated: true, completion: nil)
            return nil
        }
        
        if viewControllers.count > 1 {
            return super.popViewController(animated: animated)
        } else {
            if presentingViewController != nil {
                dismiss(animated: true)
                return viewControllers.first
            }
            assertionFailure("LoginNavi failed to pop view controller")
            return nil
        }
    }

    // 仅当此Navi Controller承载的VC调用self.navigationController.dismiss时可用
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if let stubVC = viewControllers.first as? SwitchUserLoadingViewController {
            stubVC.callback()
        }
        //dismiss callback
        dismissCallback?()
        //call super
        super.dismiss(animated: flag, completion: completion)
    }
}

extension LoginNaviController: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let from = fromVC as? BaseViewController, let to = toVC as? BaseViewController, from.useCustomNavAnimation, to.useCustomNavAnimation {
            switch operation {
            case .pop:
                return V3LoginNaviPopTransition()
            case .push:
                return V3LoginNaviPushTransition()
            case .none:
                break
            @unknown default:
                break
            }
        }
        return nil
    }
}
