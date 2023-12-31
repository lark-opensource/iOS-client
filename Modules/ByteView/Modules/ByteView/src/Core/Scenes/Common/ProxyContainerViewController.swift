//
//  ProxyContainerViewController.swift
//  ByteView
//
//  Created by chentao on 2020/11/23.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewUI

//只是简单作为window的root vc，目前在preview页面作为了window的root vc
final class ZombieViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }
}

/*
 * 透明window的设备方向应该由底层window实现，该VC可以作为透明window的root vc
 * 作为toast、alert弹框的底部容器，代理一些实际的转向等
 */
final class PuppetWindowRootViewController: UIViewController {

    private let allowsToInteraction: Bool
    // 默认不允许用户进行交互
    init(allowsToInteraction: Bool = false) {
        self.allowsToInteraction = allowsToInteraction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = allowsToInteraction
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard !Display.pad else {
            return .all
        }
        if let responder = getReallyResponderViewController() {
            return responder.supportedInterfaceOrientations
        }
        return .allButUpsideDown
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if let responder = getReallyResponderViewController() {
            return responder.preferredStatusBarStyle
        }
        return super.preferredStatusBarStyle
    }

    override var childForStatusBarStyle: UIViewController? {
        if let responder = getReallyResponderViewController() {
            return responder
        }
        return nil
    }

    //取底层window的top most作为实际代理者
    private func getReallyResponderViewController() -> UIViewController? {
        guard let kw = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              kw.rootViewController != self, kw != self.view.window else {
            return nil
        }
        return kw.rootViewController?.vc.topMost
    }
}

/*
 *presented的viewController如果不想管横竖屏事件可以使用, 比如ActionSheet
 */
class PuppetPresentedViewController: BaseViewController {

    private var shouldAutorotateRunning = false
    override var shouldAutorotate: Bool {
        if shouldAutorotateRunning { return false }
        shouldAutorotateRunning = true
        defer { shouldAutorotateRunning = false }
        return presentedViewControllerForProxy?.shouldAutorotate ?? false
    }

    private var supportedInterfaceOrientationsRunning = false
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if supportedInterfaceOrientationsRunning { return .allButUpsideDown }
        supportedInterfaceOrientationsRunning = true
        defer { supportedInterfaceOrientationsRunning = false }
        return presentedViewControllerForProxy?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    private var presentedViewControllerForProxy: UIViewController? {
        // return nil if no presentingViewController
        guard let presentingVC = presentingViewController else {
            return nil
        }
        return presentingVC
    }
}

// 小窗后FloatingWindow会被隐藏，但是只要是window && 有rootViewController就可以影响设备转向
// 如果window有过root，
class AlwaysPortraitViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
