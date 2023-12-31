//
//  DeviceOrientation.swift
//  LarkOrientation
//
//  Created by 李晨 on 2020/2/27.
//

import UIKit
import Foundation

extension UIDeviceOrientation {
    var toInterfaceOrientation: UIInterfaceOrientationMask {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .faceUp:
            return .portrait
        case .faceDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

extension UIInterfaceOrientationMask {
    var anyOrientation: UIDeviceOrientation {
        if self.contains(.portrait) {
            return UIDeviceOrientation.portrait
        }
        else if self.contains(.landscapeLeft) {
            return UIDeviceOrientation.landscapeLeft
        }
        else if self.contains(.landscapeRight) {
            return UIDeviceOrientation.landscapeRight
        }
        return UIDeviceOrientation.portrait
    }
}
