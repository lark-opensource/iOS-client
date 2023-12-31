//
//  OPAppMetaResponseSerialization.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/16.
//

// 该文件定义从后端统一meta接口返回的response的解析，利用codeable来做字段处理，属于内部处理，
// https://bytedance.feishu.cn/docs/doccnHm0MuEVB75B17SaRpYudlb

import Foundation

/// OPAppMetaResponse code 错误码定义
public enum OPAppMetaResponseCode: Int {
    /// 成功
    case success = 0
    /// 预览 Token 已失效
    case preview_token_has_expired = 10_251
}

struct OPAppMetaResponse: Codable {
    let code: Int
    let msg: String
    let data: OPAppMetas?
}

struct OPAppMetas: Codable {
    let appMetas: [OPAppMetaInfo]?

    enum CodingKeys: String, CodingKey {
        case appMetas = "app_metas"
    }
}

struct OPAppMetaInfo: Codable {
    let appBaseInfo: OPAppBaseInfo
    let extensionMetas: [OPAppExtensionMeta]

    enum CodingKeys: String, CodingKey {
        case appBaseInfo = "app_base_info"
        case extensionMetas = "extension_metas"
    }
}
private let OPAppSchemeaHostKey = "host"
private let OPAppSchemeaSchemaKey = "schema"

/// 白名单的结构
/// 包含 host 和 schema
public struct OPAppSchema: Codable, Equatable {
    public let host: String
    public let schema: String

    public func toDictionary() -> [String: String] {
        [
            OPAppSchemeaHostKey: host,
            OPAppSchemeaSchemaKey: schema
        ]
    }

    public init?(dictionary: [String: String]?) {
        guard let dic = dictionary else {
            return nil
        }
        guard let host = dic[OPAppSchemeaHostKey], let schema = dic[OPAppSchemeaSchemaKey] else {
            return nil
        }
        self.host = host
        self.schema = schema
    }

    public init(schema: String, host: String) {
        self.schema = schema
        self.host = host
    }
    
}

public struct OPAppBaseInfo: Codable {
    public let appID: String
    public let icon: String
    public let name: String
    public let version: String
    public let openSchemas: [OPAppSchema]?
    public let useOpenSchemas: Bool?
    enum CodingKeys: String, CodingKey {
        case appID = "app_id"
        case icon = "icon"
        case name = "name"
        case version = "version"
        case openSchemas = "openSchemaWhiteList"
        case useOpenSchemas = "useOpenSchemaWhiteList"
    }
}

public enum OPAppExtensionMetaUpdateType: Int, Codable {
    case `default`
    case bug
    case feature
}

public struct OPAppExtensionMeta: Codable {
    public let extensionType: String
    public let extensionID: String
    public let meta: String
    public let version: String
    public let basicLibVersion: String?
    public let extConfig: String?
    public let updateType: OPAppExtensionMetaUpdateType?
    public let updateDescription: String?
	public let devtoolSocketAddress: String?
    enum CodingKeys: String, CodingKey {
        case extensionType = "extension_type"
        case extensionID = "extension_id"
        case meta = "meta"
        case version = "version"
        case basicLibVersion = "basic_lib_version"
        case extConfig = "ext_config"
        case updateType = "update_type"
        case updateDescription = "update_description"
		case devtoolSocketAddress = "socket_address"
    }
}

