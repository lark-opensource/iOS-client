//
//  TestNavigationController.swift
//  LarkCameraDev
//
//  Created by Crazy凡 on 2019/8/12.
//

import Foundation
import UIKit

class TestNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var shouldAutorotate: Bool {
        print("# # # # # # # TestNavigationController shouldAutorotate",
              self.topViewController?.shouldAutorotate ?? false)

        return self.topViewController?.shouldAutorotate ?? false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.topViewController?.supportedInterfaceOrientations ?? .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return self.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }
}
