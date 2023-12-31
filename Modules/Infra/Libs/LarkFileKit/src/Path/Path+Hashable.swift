//
//  Path+Hashable.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/10/10.
//

import Foundation

extension Path: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
