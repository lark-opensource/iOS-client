//
//  KaSettings.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/16.
//
//
//   let kaSettings = try? newJSONDecoder().decode(KaSettings.self, from: jsonData)

import Foundation

// MARK: - KaSettings
struct KaSettings: Codable {
    let defaultIdpType: String

    enum CodingKeys: String, CodingKey {
        case defaultIdpType = "default_idp_type"
    }
}
