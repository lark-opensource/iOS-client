//
//  LarkEnterSafeModeTask.swift
//  LarkSafeMode
//
//  Created by luyz on 2022/11/4.
//

import UIKit
import Foundation
import BootManager
import Heimdallr
import LarkDebugExtensionPoint
import LarkReleaseConfig

public final class LarkEnterSafeModeTask: AsyncBootTask, Identifiable {
    public static var identify = "LarkEnterSafeModeTask"
    public override var runOnlyOnce: Bool { return true }
    public override func execute(_ context: BootContext) {
        makeOccupationVC(context.window)
        if LarkSafeMode.safeModeForemostEnable {
            LarkSafeMode.processExceptionForemost { (isNeedEnterSafeMode, clear) in
                if isNeedEnterSafeMode {
                    context.window?.rootViewController = UINavigationController(rootViewController: SafeModeViewController(clear: clear))
                } else {
                    self.flowCheckout(.didFinishLaunchFlow)
                }
            }
        } else {
            LarkSafeMode.processException { (isNeedEnterSafeMode, clear) in
                if isNeedEnterSafeMode {
                    context.window?.rootViewController = UINavigationController(rootViewController: SafeModeViewController(clear: clear))
                } else {
                    self.flowCheckout(.didFinishLaunchFlow)
                }
            }
        }
    }

    private func makeOccupationVC(_ window: UIWindow?) {
        let occupationView = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view
        let occupationVC = UIViewController()
        if let view = occupationView {
            occupationVC.view.addSubview(view)
            window?.rootViewController = occupationVC
        }
    }
}
