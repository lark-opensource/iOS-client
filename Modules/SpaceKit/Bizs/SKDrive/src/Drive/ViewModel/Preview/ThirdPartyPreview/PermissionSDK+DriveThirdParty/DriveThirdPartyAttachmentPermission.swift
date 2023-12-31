//
//  DriveThirdPartyAttachmentPermission.swift
//  SKDrive
//
//  Created by Weston Wu on 2023/8/23.
//

import Foundation
import SKFoundation
import SpaceInterface

struct DriveThirdPartyAttachmentPermission {

    typealias DenyReason = PermissionResponse.DenyType.UserPermissionDenyReason

    let actions: [Action: Status]

    // 对应 perm_v2 字段，Drive 需要使用回报给业务方
    let bizExtraInfo: [String: Any]?

    func check(action: Action) -> Bool {
        guard let status = actions[action] else { return false }
        return status == .allow
    }

    func denyReason(for action: Action) -> DenyReason? {
        guard let status = actions[action] else {
            return .unknown
        }
        switch status {
        case .allow:
            return nil
        case let .forbidden(code):
            if let code {
                return .blockByServer(code: code)
            } else {
                return .unknown
            }
        case .blockByCAC:
            return .blockByCAC
        case .blockByAudit:
            return .blockByAudit
        }
    }
}

extension DriveThirdPartyAttachmentPermission: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.actions = try container.decode([Action: Status].self)
        self.bizExtraInfo = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(actions)
    }
}

extension DriveThirdPartyAttachmentPermission {
    enum Status: Equatable, Hashable, Codable {
        case allow
        case forbidden(code: Int?)
        case blockByCAC
        case blockByAudit
    }

    enum Action: String, Equatable, Hashable, CaseIterable, Codable {
        case view
        case edit
        case export
        case copy
    }

    /// 受 CAC 管控无权限时点位的值
    static let blockByCACCode = 2002
    /// 受审计管控时点位的值
    static let blockByAudit = 202
}

struct DriveThirdPartyAttachmentPermissionContainer: UserPermissionContainer {

    let userPermission: DriveThirdPartyAttachmentPermission
    // 第三方附件没有 statusCode，都按 normal 处理
    var statusCode: UserPermissionResponse.StatusCode { .normal }

    var isOwner: Bool { false }

    var grantedViewPermissionByLeader: Bool { false }

    var shareControlByCAC: Bool { false }

    var previewControlByCAC: Bool {
        userPermission.denyReason(for: .view) == .blockByCAC
    }

    var previewBlockByAdmin: Bool {
        false
    }

    var viewBlockByAudit: Bool {
        userPermission.denyReason(for: .view) == .blockByAudit
    }
}
