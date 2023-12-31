//
//  Orientations.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/22.
//

import Foundation
import UIKit

// swiftlint:disable all
extension RootNaviController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.topViewController?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return self.topViewController?.shouldAutorotate ?? true
    }

}

extension TabbarController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.viewControllers?.first?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return self.viewControllers?.first?.shouldAutorotate ?? true
    }
}

extension FeedVC {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override var shouldAutorotate: Bool {
        return false
    }

}


extension FocusVC {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    open override var shouldAutorotate: Bool {
        return false
    }
}

extension MeetingVC {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if isShowDoc {
            return .allButUpsideDown
        } else {
            return .portrait
        }
    }

    open override var shouldAutorotate: Bool {
        return true
    }
}

extension UIDevice {
    func updateDeviceOrientation(_ orientation: UIInterfaceOrientation? = nil, animated: Bool = true) {
        if !animated {
            UIView.setAnimationsEnabled(false)
        }
        guard let orientation = orientation else { return }

        let value = (orientation ?? UIApplication.shared.statusBarOrientation).rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        UINavigationController.attemptRotationToDeviceOrientation()
        UITabBarController.attemptRotationToDeviceOrientation()
        UIViewController.attemptRotationToDeviceOrientation()

        if !animated {
            UIView.setAnimationsEnabled(true)
        }
    }
}

extension UIInterfaceOrientationMask: CustomStringConvertible {
    public var description: String {
        switch String(self.rawValue, radix: 2) {
        case "10", "100":
            return "portrait"
        case "10000", "1000", "11000":
            return "landscape"
        case "11110":
            return "all"
        case "11010":
            return "allButUpsideDown"
        default:
            return "unKnown"
        }
    }
}


extension UIDeviceOrientation: CustomStringConvertible {
    public var description: String {
        switch self.rawValue {
        case 1,2: return "portrait"
        case 3,4: return "landscape"
        default:
            return "unKnown"
        }
    }
}
