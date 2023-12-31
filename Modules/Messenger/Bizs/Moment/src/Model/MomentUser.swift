//
//  MomentUser.swift
//  Moment
//
//  Created by ByteDance on 2022/12/9.
//

import Foundation
import RustPB
import ServerPB
import LarkFeatureGating

public protocol MomentUser {
    var momentUserType: RustPB.Moments_V1_MomentUser.TypeEnum { get }
    var name: String { get }
    var nameWithAnotherName: String { get }
    var momentUserAnonymous: MomentAnonymousUser { get }
    var userID: String { get }
    var avatarKey: String { get }
    var isCurrentUserFollowing: Bool { get set }
    var momentLarkUser: MomentLarkUser { get }
    var department: String { get }
}

extension MomentUser {
    var displayName: String {
        if self.momentUserType == .anonymous {
            if self.momentUserAnonymous.idx == 0 {
                return BundleI18n.Moment.Lark_Community_AnonymousUser
            }
            return BundleI18n.Moment.Lark_Community_SpectatorNumber(self.momentUserAnonymous.idx)
        }
        if !self.nameWithAnotherName.isEmpty {
            return self.nameWithAnotherName
        }
        return self.name
    }
}

extension RustPB.Moments_V1_MomentUser: MomentUser {
    public var momentLarkUser: MomentLarkUser {
        return self.larkUser
    }

    public var momentUserType: RustPB.Moments_V1_MomentUser.TypeEnum {
        return self.type
    }

    public var momentUserAnonymous: MomentAnonymousUser {
        return self.anonymous
    }
}
extension ServerPB.ServerPB_Moments_entities_MomentUser: MomentUser {
    public var momentLarkUser: MomentLarkUser {
        return self.larkUser
    }

    public var isCurrentUserFollowing: Bool {
        get {
            return false
        }
        // swiftlint:disable unused_setter_value
        set {
            // 这个地方实现set方式只是为了实现协议 以兼容RustPB和ServerPB的MomentUser。这个set并不会被调用，这里disable掉了unused_setter_value规则
            assertionFailure("ServerPB_Moments_entities_MomentUser has no attribute isCurrentUserFollowing")
            return
        }
        // swiftlint:enable unused_setter_value
    }

    public var momentUserType: RustPB.Moments_V1_MomentUser.TypeEnum {
        switch self.type {
        case .unknown:
            return .unknown
        case .anonymous:
            return .anonymous
        case .nickname:
            return .nickname
        case .official:
            return .official
        case .user:
            return .user
        @unknown default:
            assertionFailure("unknown case")
            return .unknown
        }
    }

    public var nameWithAnotherName: String {
        return ""
    }

    public var momentUserAnonymous: MomentAnonymousUser {
        return self.anonymous
    }
}

public protocol MomentAnonymousUser {
    var idx: Int32 { get }
}
extension RustPB.Moments_V1_MomentUser.AnonymousUser: MomentAnonymousUser {}
extension ServerPB.ServerPB_Moments_entities_MomentUser.AnonymousUser: MomentAnonymousUser {}

public protocol MomentLarkUser {
    var fullDepartmentPath: String { get }
}
extension RustPB.Moments_V1_MomentUser.LarkUser: MomentLarkUser {}
extension ServerPB.ServerPB_Moments_entities_MomentUser.LarkUser: MomentLarkUser {}
