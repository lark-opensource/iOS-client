//
//  EditStatus.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/6/24.
//

import Foundation

public enum EditStatusDenyType: String, ModelEnum {
    public static var fallbackValue: EditStatusDenyType = .inEditing

    case success = "0"
    case inEditing = "1"
    case lowversion = "2"
}

public struct EditStatus: Codable {
    public let editorName: String
    public let canEdit: String
    public let denyType: EditStatusDenyType
    public let objectVersion: Int
    public let lastEditVersion: Int

    private enum CodingKeys: String, CodingKey {
        case editorName = "editor_name"
        case canEdit = "can_edit"
        case denyType = "deny_type"
        case objectVersion = "object_version"
        case lastEditVersion = "last_edit_version"
    }
}

public enum KeepEditExitReason: Int, ModelEnum {
    public static var fallbackValue: KeepEditExitReason = .keep

    case keep = 0
    case otherDevice = 1
    case expired = 2
}

public struct KeepEditStatus: Codable {
    public let reason: KeepEditExitReason

    private enum CodingKeys: String, CodingKey {
        case reason = "exit_edit"
    }
}
