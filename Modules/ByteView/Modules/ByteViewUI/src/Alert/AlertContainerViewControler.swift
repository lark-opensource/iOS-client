//
//  AlertContainerViewControler.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/18.
//

import Foundation
import ByteViewCommon

class AlertContainerViewControler: UIViewController {
    private var customShouldAutorotate: Bool?
    private var customOrientations: UIInterfaceOrientationMask?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.view.isUserInteractionEnabled = true
        self.modalPresentationStyle = .overFullScreen

        if #available(iOS 13, *) {
            return
        }
        if Display.phone && UIApplication.shared.statusBarOrientation.isLandscape {
            // iOS12手机横屏弹窗时，alert大概率会保持竖屏，因此临时写死supportedInterfaceOrientations，didAppear后再恢复
            self.customShouldAutorotate = false
            self.customOrientations = UIApplication.shared.statusBarOrientation.interfaceOrientationMask
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.customOrientations = nil
        self.customShouldAutorotate = nil
    }

    override var shouldAutorotate: Bool {
        return customShouldAutorotate ?? true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let customOrientations = self.customOrientations {
            return customOrientations
        }
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
        guard let kw = UIApplication.shared.windows.first(where: { $0.isKeyWindow }), let root = kw.rootViewController,
              root != self, kw != self.view.window else {
            return nil
        }
        return root.vc.topMost
    }
}

private extension UIInterfaceOrientation {
    var interfaceOrientationMask: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return .allButUpsideDown
        }
    }
}
