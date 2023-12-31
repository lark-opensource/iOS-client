//
//  Parameter.swift
//  LarkPolicyEngine
//
//  Created by Bytedance on 2022/8/2.
//

import Foundation

public struct Parameter {

    public init(key: String, value: @escaping () -> Any) {
        self.key = key
        self.value = value
    }

    let key: String
    let value: () -> Any
}
