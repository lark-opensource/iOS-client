//
//  UploadLog.swift
//  SuiteLogin
//
//  Created by quyiming on 2019/11/25.
//

import Foundation

struct AdditionalDataKey {
    static let defaultTenantCode: String = "default_tenant_code"
    static let tenantCode: String = "tenantCode"
    static let tenantId: String = "tenantId"
    static let url: String = "url"
    static let blackList: [String] = [AdditionalDataKey.defaultTenantCode, AdditionalDataKey.tenantCode, AdditionalDataKey.url]
}

class SuiteLoginLogFormat {
    public static func extractAdditionalData(additionalData: [String: String]) -> String {
        guard !additionalData.isEmpty else { return "" }
        let additions = additionalData.keys.compactMap { (k) -> String? in
            if AdditionalDataKey.blackList.contains(k) {
                return nil
            }
            return "\(k): \(additionalData[k] ?? "")"
        }.joined(separator: ", ")
        return "[\(additions)]"
    }

    static func template(message: String, error: Error?) -> String {
        var m = message
        if let error = error {
            m = "\(message) [Error|\(error)]"
        }
        return m
    }
}
