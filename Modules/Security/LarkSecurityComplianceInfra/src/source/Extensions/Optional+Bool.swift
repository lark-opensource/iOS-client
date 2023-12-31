//
//  Optional+Bool.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2022/12/30.
//

import Foundation

public extension Optional where Wrapped == Bool {

    var isTrue: Bool { self == true }

    var isFalse: Bool { self == false }

    var isNil: Bool { self == nil }
}
