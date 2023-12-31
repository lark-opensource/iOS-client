//
//  SecurityActionModel.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/4/20.
//

import Foundation
import SwiftyJSON

struct ActionModel: Codable {
    let name: String
    let params: [String: JSON]?
    var operation: SecurityPolicyActionOperation {
        guard let jsonString = params?[ActionParamsKey.operation]?.stringValue,
              let operation = SecurityPolicyActionOperation(rawValue: jsonString) else {
            return .unknown
        }
        return operation
    }

    var style: SecurityPolicyActionStyle {
        guard let jsonString = params?[ActionParamsKey.style]?.stringValue,
              let style = SecurityPolicyActionStyle(rawValue: jsonString) else {
            return .unknown
        }
        return style
    }

    enum CodingKeys: String, CodingKey {
        case name
        case params
    }
}
