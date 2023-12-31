//
//  String.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2023/9/11.
//

import Foundation

public extension String {
    public func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    public func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
