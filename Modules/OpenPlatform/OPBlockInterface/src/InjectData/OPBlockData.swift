//
//  OPBlockData.swift
//  OPBlockInterface
//
//  Created by xiangyuanyuan on 2022/7/17.
//

import Foundation
import OPSDK

public enum BlockDataSourceType: String {
    case entity
    case guideInfo
    case unknown
}

public struct OPBlockGuideInfo: BaseBlockInfo, Codable {
    public var blockExtension: BlockExtension
    public var blockExtensionTip: BlockExtensionTip

    enum CodingKeys: String, CodingKey {
        case blockExtension = "block_extension"
        case blockExtensionTip = "block_extension_tip"
    }
}

public struct BlockExtension: Codable {
    public let status: Int
}

public struct BlockExtensionTip: Codable {
    public var content: [String: String]? = nil
    public var buttons: [GuideInfoButton]? = nil
}

public struct GuideInfoButton: Codable {
    public var content: [String: String]? = nil
    public var schema: String? = nil
}
