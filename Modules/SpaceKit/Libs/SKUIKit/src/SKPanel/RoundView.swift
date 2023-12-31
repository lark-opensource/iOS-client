//
//  RoundView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/8/31.
//

import Foundation

public extension UIRectCorner {
    static var top: UIRectCorner { [.topLeft, .topRight] }
    static var left: UIRectCorner { [.topLeft, .bottomLeft] }
    static var right: UIRectCorner { [.topRight, .bottomRight] }
    static var bottom: UIRectCorner { [.bottomLeft, .bottomRight] }
    static var all: UIRectCorner { [.topLeft, .topRight, .bottomLeft, .bottomRight] }
}

public extension CACornerMask {
    static var top: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner] }
    static var left: CACornerMask { [.layerMinXMinYCorner, .layerMinXMaxYCorner] }
    static var right: CACornerMask { [.layerMaxXMinYCorner, .layerMaxXMaxYCorner] }
    static var bottom: CACornerMask { [.layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
    static var all: CACornerMask { [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner] }
}
