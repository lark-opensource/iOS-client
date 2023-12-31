//
//  SCLoggerAdditionalDataConvertable.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2023/9/8.
//

import UIKit

public protocol SCLoggerAdditionalDataConvertable {
    var logData: [String: String] { get }
}

extension Dictionary: SCLoggerAdditionalDataConvertable where Key == String, Value == String {
    public var logData: [String: String] {
        self
    }
}
