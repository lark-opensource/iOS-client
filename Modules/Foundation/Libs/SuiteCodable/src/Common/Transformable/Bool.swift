//
//  Bool.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation

extension Bool: Transformable, HasDefault {
    static func transform(from object: Any) -> Bool? {
        switch object {
        case let bool as Bool:
            return bool
        case let str as String:
            let lowerCase = str.lowercased()
            if ["0", "false"].contains(lowerCase) {
                return false
            }
            if ["1", "true"].contains(lowerCase) {
                return true
            }
            return nil
        default:
            return nil
        }
    }

    public static func `default`() -> Bool {
        return false
    }
}
