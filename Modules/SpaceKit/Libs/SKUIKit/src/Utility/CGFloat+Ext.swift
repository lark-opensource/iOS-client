//
//  CGFloat.swift
//  SpaceKit
//
//  Created by weidong fu on 18/3/2018.
//

import Foundation
import SKFoundation

extension CGFloat: PrivateFoundationExtensionCompatible {}

public extension CGFloat {
    static func fromString(_ string: String) -> CGFloat {

        guard let number = NumberFormatter().number(from: string) else {
            return 0.0
        }

        return CGFloat(number.floatValue)
    }

    func toString() -> String {
        return "\(self)"
    }
}


extension CGSize: PrivateFoundationExtensionCompatible {}

extension CGSize: Comparable {
    
    ///左宽和高都小于右
    public static func < (lhs: CGSize, rhs: CGSize) -> Bool {
        return (lhs.width < rhs.width && lhs.height <= rhs.height) ||
               (lhs.width <= rhs.width && lhs.height < rhs.height)
    }
    
    ///左宽和高都大于右
    public static func > (lhs: CGSize, rhs: CGSize) -> Bool {
        return (lhs.width > rhs.width && lhs.height >= rhs.height) ||
               (lhs.width >= rhs.width && lhs.height > rhs.height)
    }
}
