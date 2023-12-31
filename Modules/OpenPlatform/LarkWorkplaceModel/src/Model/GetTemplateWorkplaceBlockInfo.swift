//
//  GetTemplateWorkplaceBlockInfo.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/27.
//

import Foundation

/// ['lark/workplace/api/GetTemplateWorkplaceBlockInfo'] - request parameters
/// request parameters for block model prefetch
struct WPPrefetchBlockRequestParams: Codable {
    /// lark version number, eg: "5.27.0"
    let larkVersion: String
    /// locale for response data
    let lang: String
    /// the blockTypeId of blocks that need to be prefetched
    let blockTypeIds: [String]
    /// the blockId of blocks that need to be prefetched
    let blockIds: [String]
    /// source business, should be "workplace"
    let host: String

    enum CodingKeys: String, CodingKey {
        case larkVersion = "lark_version"
        case lang
        case blockTypeIds = "block_type_ids"
        case blockIds = "block_ids"
        case host
    }
}

/// ['lark/workplace/api/GetTemplateWorkplaceBlockInfo'] - response data
/// block model wrapper, for block model prefetch in workplace
/// generic type T should be OPBlockGuideInfo
struct WPBlockModelPrefetchWrapper<T: Codable>: Codable {
    // block model
    let data: WPBlockModelPrefetch<T>
}

/// block model, for block model prefetch in workplace
struct WPBlockModelPrefetch<T: Codable>: Codable {
    /// block entities
    let blockEntities: WPBlockEntities?
    /// block guide info
    let blockGuideInfo: WPBlockGuide<T>?

    enum CodingKeys: String, CodingKey {
        case blockEntities = "MGetBlockEntityV2"
        case blockGuideInfo = "GetBlockGuideInfo"
    }
}

/// block entities
struct WPBlockEntities: Codable {
    /// error code
    let code: Int
    /// error message
    let msg: String
    /// block entity dictionary
    /// key: block identifier
    /// value: block entity
    let blocks: [String: WPBlockEntityWrapper]?
}

/// block entity wrapper, contains extra status and error message
struct WPBlockEntityWrapper: Codable {
    /// error code
    let status: Int
    /// error message
    let errMessage: String
    /// block entity
    let entity: WPBlockEntity?
}

/// correspond to blockit OPBlockInfo structure
/// you don't need to pay attention to the meaning of the internal fields
struct WPBlockEntity: Codable {
    let tenantId: Int?
    let blockId: String
    let status: Int?
    let sourceData: String?
    let sourceLink: String
    let appIdStr: String?
    let summary: String
    let appId: Int?
    let owner: String?
    let title: String?
    let blockTypeId: String
    let preview: String?
    let sourceMeta: String

    enum CodingKeys: String, CodingKey {
        case tenantId = "tenantID"
        case blockId = "blockID"
        case status
        case sourceData
        case sourceLink
        case appIdStr = "appIDStr"
        case summary
        case appId = "appID"
        case owner
        case title
        case blockTypeId = "blockTypeID"
        case preview
        case sourceMeta
    }
}

/// block guide model wrapper
struct WPBlockGuide<T: Codable>: Codable {
    /// error code
    let code: Int
    /// error message
    let msg: String
    /// pass to blockit
    /// key: blockTypeId
    /// value: should be OPBlockGuideInfo
    let blockExtensions: [String: T]?

    enum CodingKeys: String, CodingKey {
        case code
        case msg
        case blockExtensions = "block_extensions"
    }
}
