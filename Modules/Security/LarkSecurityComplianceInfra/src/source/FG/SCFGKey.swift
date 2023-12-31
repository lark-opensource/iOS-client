//
//  SCFGKey.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/7/28.
//

import Foundation

public struct SCFGKey {
    public let rawValue: String
    public let version: String
    public let owner: String

    public init(rawValue: String, version: String, owner: String) {
        self.rawValue = rawValue
        self.version = version
        self.owner = owner
        SCLogger.info("construct FG key \(rawValue), online version \(version), key owner: \(owner)")
    }
}
