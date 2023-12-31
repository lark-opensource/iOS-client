//
//  CCMUserSettingsModel.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/12/7.
//

import Foundation
import SwiftyJSON
import SKFoundation

// MARK: - User Properties
// 对应接口 https://bytedance.larkoffice.com/wiki/wikcnbq5LqiIaH6vMHCPqJDK2if
public extension CCMUserProperties {
    // 链接分享的默认值
    enum LinkSharePermissionType: Int, Codable {
        case close = 1
        case tenantCanRead = 2
    }
}

public struct CCMUserProperties {

    public var linkSharePermissionType: LinkSharePermissionType

    private init(linkSharePermissionType: CCMUserProperties.LinkSharePermissionType) {
        self.linkSharePermissionType = linkSharePermissionType
    }

    public static var `default`: CCMUserProperties {
        CCMUserProperties(linkSharePermissionType: .close)
    }

    mutating func apply(patch: CCMUserProperties.Patch) {
        if let linkSharePermissionType = patch.linkSharePermissionType {
            self.linkSharePermissionType = linkSharePermissionType
        }
    }
}

extension CCMUserProperties: Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case linkSharePermissionType = "permission_type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        linkSharePermissionType = try container.decodeIfPresent(LinkSharePermissionType.self, forKey: .linkSharePermissionType) ?? .close
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(linkSharePermissionType, forKey: .linkSharePermissionType)
    }
}

// 需要更新 UserProperties 时，需要构造一个 patch 写入需要更新的值
public extension CCMUserProperties {

    struct Patch {

        public var linkSharePermissionType: LinkSharePermissionType?

        public init() {}

        var paramsRepresentation: [String: Any] {
            var params = [String: Any]()
            // 必须要带上的参数，不然后端会报错，不知道为啥
            var properties: [String: Any] = [
                "initial_setting": true,
                "allow_share_outside": false
            ]
            if let linkSharePermissionType {
                params[CodingKeys.linkSharePermissionType.rawValue] = linkSharePermissionType.rawValue
            }

            params["properties"] = properties
            return params
        }
    }
}

// MARK: - CCM Common Settings

public enum CCMCommonSettingsScene: String {

    public typealias Value = CCMCommonSettingsValue

    // 默认创建位置
    case nodeDefaultCreatePosition = "node_default_create_position"
    /// 是否允许上级查看下级文档
    case allowLeaderView = "allow_leader_view"
    /// 文档默认分享给上级
    case imShareLeader = "im_share_leader"

    var valueParser: (JSON) -> Value? {
        switch self {
        case .nodeDefaultCreatePosition:
            Self.parseNodeDefaultCreatePosition(json:)
        case .allowLeaderView:
            Self.parseAllowLeaderView(json:)
        case .imShareLeader:
            Self.parseIMShareLeader(json:)
        }
    }

    private static func parseNodeDefaultCreatePosition(json: JSON) -> Value? {
        guard let locationValue = json.string else { return nil }
        guard let location = CCMCommonSettingsValue.DefaultCreateLocation(rawValue: locationValue) else {
            DocsLogger.error("unknown node default create position: \(locationValue)")
            spaceAssertionFailure("unknown node default create position: \(locationValue)")
            return .nodeDefaultCreatePosition(location: .none)
        }
        return .nodeDefaultCreatePosition(location: location)
    }

    private static func parseAllowLeaderView(json: JSON) -> Value? {
        let enableValue = json.string ?? ""
        let enable = ["true", "none"].contains(enableValue)
        return .allowLeaderView(enable: enable)
    }

    private static func parseIMShareLeader(json: JSON) -> Value? {
        guard let stateValue = json.string else { return nil }
        guard let state = CCMCommonSettingsValue.IMShareLeaderState(rawValue: stateValue) else {
            DocsLogger.error("unknown im share leader state: \(stateValue)")
            spaceAssertionFailure("unknown im share leader state: \(stateValue)")
            return nil
        }
        return .imShareLeader(state: state)
    }
}

public enum CCMCommonSettingsValue: Codable, Equatable {
    public enum DefaultCreateLocation: String, Codable, Equatable {
        case myLibrary = "my_document_library"
        case mySpace = "my_space"
        case none
    }
    // 默认创建位置
    case nodeDefaultCreatePosition(location: DefaultCreateLocation)
    /// 是否允许上级查看下级文档
    case allowLeaderView(enable: Bool)

    public enum IMShareLeaderState: String, Codable, Equatable {
        case auto // 开启自动授权
        case close // 关闭自动授权
        case none // 未设置，按关闭处理
    }
    /// 文档默认分享给上级
    case imShareLeader(state: IMShareLeaderState)

    var updateParameterRepresentation: Any? {
        switch self {
        case let .nodeDefaultCreatePosition(location):
            location.rawValue
        case let .allowLeaderView(enable):
            enable
        case let .imShareLeader(state):
            state.rawValue
        }
    }
}
