//
//  NoPermissionRustActionModel.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/8.
//

import Foundation
import SwiftyJSON
import LarkSecurityComplianceInfra

struct NoPermissionRustActionModel: Codable {

    enum Action: Int {
        case unknown = 0
        case network = 100
        case deviceCredibility = 101
        case deviceOwnership = 102
        case mfa = 103
        case fileblock = 104
        case dlp = 105
        case pointDowngrade = 106
        case universalFallback = 107
        case ttBlock = 108
    }

    struct ActionModel: Codable {

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case name
            case params
        }

        let name: String
        let params: [String: JSON]?
    }

    enum CodingKeys: String, CodingKey {
        case actions
        case code
    }

    let actions: [ActionModel]
    private(set) var logId: String = ""
    private(set) var code: Int32 = 0

    var model: ActionModel? { return actions.first }

    init(_ message: PushReqRegulateResponse) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(type(of: self), from: message.xLscDecision)
        self.logId = message.xTtLogid
        self.code = message.xLscCode
    }

    init(actions: [ActionModel]) {
        self.actions = actions
    }

    init(action: ActionModel) {
        self.actions = [action]
        self.code = Int32(noPermissionCode)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actions = try container.decode([ActionModel].self, forKey: .actions)
        code = try container.decodeIfPresent(Int32.self, forKey: .code) ?? 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(actions, forKey: .actions)
        try container.encode(code, forKey: .code)
    }
    
}

extension NoPermissionRustActionModel {
    var action: NoPermissionRustActionModel.Action {
        switch self.actions.first?.name {
        case "BLOCKED_BY_DEVICE_OWNERSHIP":
            return .deviceOwnership
        case "BLOCKED_BY_IP_RULE":
            return .network
        case "BLOCKED_BY_DEVICE_CREDIBILITY":
            return .deviceCredibility
        case "ACCESS_MFA":
            return .mfa
        case "FILE_BLOCK_COMMON":
            return .fileblock
        case "DLP_CONTENT_DETECTING", "DLP_CONTENT_SENSITIVE":
            return .dlp
        case "FALLBACK_COMMON":
            return .pointDowngrade
        case "UNIVERSAL_FALLBACK_COMMON":
            return .universalFallback
        case "TT_BLOCK":
            return .ttBlock
        default:
            return .unknown
        }
    }
}
