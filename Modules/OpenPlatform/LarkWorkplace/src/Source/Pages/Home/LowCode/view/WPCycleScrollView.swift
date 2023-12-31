//
//  WPCycleScrollView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/28.
//

import Foundation
import LarkContainer
import LarkAccountInterface

// MARK: Frame
extension UIView {
    // swiftlint:disable identifier_name
    /// WP_x
    var WP_x: CGFloat {
        get {
            return self.frame.origin.x
        }
        set(value) {
            self.frame = CGRect(x: value, y: self.WP_y, width: self.WP_w, height: self.WP_h)
        }
    }

    /// WP_y
    var WP_y: CGFloat {
        get {
            return self.frame.origin.y
        }
        set(value) {
            self.frame = CGRect(x: self.WP_x, y: value, width: self.WP_w, height: self.WP_h)
        }
    }

    /// WP_w
    var WP_w: CGFloat {
        get {
            return self.frame.size.width
        } set(value) {
            self.frame = CGRect(x: self.WP_x, y: self.WP_y, width: value, height: self.WP_h)
        }
    }

    /// WP_h
    var WP_h: CGFloat {
        get {
            return self.frame.size.height
        } set(value) {
            self.frame = CGRect(x: self.WP_x, y: self.WP_y, width: self.WP_w, height: value)
        }
    }
    // swiftlint:enable identifier_name
}
