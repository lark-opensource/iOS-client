//
//  Error.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/9.
//

import Foundation

struct CustomStringError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}

struct ActionResolverError: Error, CustomStringConvertible {
    var description: String
    init(_ description: String) {
        self.description = description
    }
}
