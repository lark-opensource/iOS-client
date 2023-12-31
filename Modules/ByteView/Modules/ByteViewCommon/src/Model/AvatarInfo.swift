//
//  AvatarInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/7.
//

import Foundation

/// entityID: chatID(groupID)/chatterID(userID)/tenantID
/// https://bytedance.feishu.cn/docs/doccnhBQKl1cZeFOZVNXH8nM4wd#
@frozen public enum AvatarInfo: Equatable {
    case asset(UIImage?)
    case remote(key: String, entityId: String)

    public var isEmpty: Bool {
        switch self {
        case .asset(let image):
            return image == nil
        case let .remote(key: key, _):
            return key.isEmpty
        }
    }
}

public extension AvatarInfo {
    static let unknown = AvatarInfo.asset(BundleResources.ByteViewCommon.Avatar.unknown)
    static let sip = AvatarInfo.asset(BundleResources.ByteViewCommon.Avatar.sip)
    static let pstn = AvatarInfo.asset(BundleResources.ByteViewCommon.Avatar.pstn)
    static let guest = AvatarInfo.asset(BundleResources.ByteViewCommon.Avatar.guest)
    static let interviewer = AvatarInfo.asset(BundleResources.ByteViewCommon.Avatar.interviewer)
}

extension AvatarInfo: CustomDebugStringConvertible, CustomStringConvertible {
    public var debugDescription: String {
        description
    }

    public var description: String {
        switch self {
        case .asset(nil), .remote(key: "", entityId: _):
            return "empty"
        case .asset:
            return "asset"
        case .remote(key: _, entityId: let entityId):
            return "remote(\(entityId))"
        }
    }
}
