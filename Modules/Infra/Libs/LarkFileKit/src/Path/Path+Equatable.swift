//
//  Path+Equatable.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/10.
//

import Foundation

extension Path: Equatable {
    public static func == (lhs: Path, rhs: Path) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
