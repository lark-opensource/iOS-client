//
//  PopoverSource.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/8/5.
//

import UIKit
import Foundation

struct PopoverSource {
    let sourceView: UIView
    let sourceRect: CGRect
}

extension UIView {
    var defaultSource: PopoverSource {
        return PopoverSource(sourceView: self, sourceRect: bounds)
    }
}
