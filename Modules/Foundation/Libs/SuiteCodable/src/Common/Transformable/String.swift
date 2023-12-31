//
//  String.swift
//  SuiteCodable
//
//  Created by liuwanlin on 2019/5/4.
//

import Foundation

extension String: Transformable, HasDefault {
    static func transform(from object: Any) -> String? {
        switch object {
        case let str as String:
            return str
        default:
            return "\(object)"
        }
    }

    public static func `default`() -> String {
        return ""
    }
}
