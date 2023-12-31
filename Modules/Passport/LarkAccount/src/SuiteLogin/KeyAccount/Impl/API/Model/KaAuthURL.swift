//
//  KaAuthURL.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/17.
//
//   let kaAuthURL = try? newJSONDecoder().decode(KaAuthURL.self, from: jsonData)

import Foundation
import AnyCodable

// MARK: - KaAuthURL
struct KaAuthURL: Codable {
    let preConfig: PreConfig
    let url: String

    enum CodingKeys: String, CodingKey {
        case preConfig = "pre_config"
        case url
    }
}

enum ExtKeyName: String, CodingKey {
    case apiId = "Api_ID"
    case appSubId = "App_Sub_ID"
    case apiVersion = "Api_Version"
    case appToken = "App_Token"
    case appKey = "App_key"
    case partnerID = "Partner_ID"
    case sign = "Sign"
    case sysID = "Sys_ID"
    case userToken = "User_Token"
    case businessEncryptKey = "businessEncryptKey"

    static func valueForKey(dict: [String: AnyCodable], key: String) -> String {
        let anyCodableValue = dict[key]
        if let anyCodableValue = anyCodableValue {
            let result = anyCodableValue.value as? String
            return result ?? ""
        }

        return ""
    }
}

// MARK: - PreConfig
struct PreConfig: Codable {
    let ext: [String: AnyCodable]
    let client: Client
    
    internal init(ext: [String : AnyCodable], client: Client) {
        self.ext = ext
        self.client = client
    }
}

// MARK: - Client
struct Client: Codable {
    let refreshAPIID, refreshAppID: String
    let refreshURL: String
    let mpwURL: String?

    enum CodingKeys: String, CodingKey {
        case refreshAPIID = "refresh_api_id"
        case refreshAppID = "refresh_app_id"
        case refreshURL = "refresh_url"
        case mpwURL = "mpw_url"
    }

    func hasPassword() -> Bool {
        if let url = mpwURL, URL(string: url) != nil {
            return true
        } else {
            return false
        }
    }
}
