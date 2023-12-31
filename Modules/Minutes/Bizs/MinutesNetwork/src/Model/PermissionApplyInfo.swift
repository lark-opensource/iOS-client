//
//  PermissionApplyInfo.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/12.
//

import Foundation

public struct PermissionApplyInfo: Codable {
    public let owner: String
    public let allowApply: Bool
    public let tips: String
    public let ownerId: String

    private enum CodingKeys: String, CodingKey {
        case owner = "owner_name"
        case allowApply = "allow_apply"
        case tips = "not_allowed_tips"
        case ownerId = "owner_user_id"
    }
}
