//
//  UIView+Extensions.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/6/12.
//

import Foundation
import UIKit

extension UIView {

    var screenFrame: CGRect {
        if let window = window {
            let windowFrame = convert(bounds, to: nil)
            return window.convert(windowFrame, to: nil)
        } else {
            TroubleKiller.logger.warn("view \(self) has no window.", tag: LogTag.log)
            return .zero
        }
    }

    var visible: Bool {
        return !isHidden && window != nil && alpha > 0.0
    }
}
