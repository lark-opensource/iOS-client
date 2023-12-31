//
//  PickerContactViewConfig.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/5.
//

import Foundation

public protocol PickerContactEntry: Codable {}

public struct PickerContactViewConfig: Codable {

    typealias Entry = PickerContactEntry

    // 我管理的群里相关配置，如果传空则不打开该入口
    public struct OwnedGroup: Entry, Codable {
        public init() {}
    }
    // 组织架构相关配置，如果传空则不打开该入口
    public struct Organization: Entry, Codable {
        // 是否拉取企业邮箱，注意，开启情况下，没有企业邮箱的将不能选中
        public var preferEnterpriseEmail: Bool
        public init(preferEnterpriseEmail: Bool = false) {
            self.preferEnterpriseEmail = preferEnterpriseEmail
        }
    }
    // 外部联系人相关配置，如果传空则不打开该入口
    public struct External: Entry, Codable {
        public init() {}
    }
    // 关联组织相关配置，如果传空则不打开该入口
    public struct RelatedOrganization: Entry, Codable {
        public init() {}
    }
    // 邮箱联系人相关配置，如果传空则不打开该入口
    public struct EmailContact: Entry, Codable {
        public init() {}
    }
    // 用户组相关配置，如果传空则不打开该入口
    public struct UserGroup: Entry, Codable {
        public init() {}
    }

    public var entries: [PickerContactEntry] = []

    public init(entries: [PickerContactEntry]) {
        self.entries = entries
    }

    public enum CodingKeys: String, CodingKey {
        case entries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PickerContactViewConfig.CodingKeys.self)
        let wrapper = try container.decode(PickerContactViewConfigWrapper.self, forKey: .entries)
        self.entries = wrapper.entries
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy:CodingKeys.self)
        let wrapper = PickerContactViewConfigWrapper(entries: self.entries)
        try container.encode(wrapper, forKey: .entries)
    }
}

struct PickerContactViewConfigWrapper: Codable {
    var ownedGroup: [PickerContactViewConfig.OwnedGroup]? = []
    var external: [PickerContactViewConfig.External]? = []
    var organization: [PickerContactViewConfig.Organization]? = []
    var relatedOrganization: [PickerContactViewConfig.RelatedOrganization]? = []
    var emailContact: [PickerContactViewConfig.EmailContact]? = []
    var userGroup: [PickerContactViewConfig.UserGroup]? = []

    init(entries: [PickerContactEntry]) {
        for entry in entries {
            if let e = entry as? PickerContactViewConfig.OwnedGroup {
                ownedGroup = [e]
            } else if let e = entry as? PickerContactViewConfig.External {
                external = [e]
            } else if let e = entry as? PickerContactViewConfig.Organization {
                organization = [e]
            } else if let e = entry as? PickerContactViewConfig.RelatedOrganization {
                relatedOrganization = [e]
            } else if let e = entry as? PickerContactViewConfig.EmailContact {
                emailContact = [e]
            } else if let e = entry as? PickerContactViewConfig.UserGroup {
                userGroup = [e]
            }
        }
    }

    var entries: [PickerContactEntry] {
        var result = [PickerContactEntry]()
        result.append(contentsOf: ownedGroup ?? [])
        result.append(contentsOf: external ?? [])
        result.append(contentsOf: organization ?? [])
        result.append(contentsOf: relatedOrganization ?? [])
        result.append(contentsOf: emailContact ?? [])
        result.append(contentsOf: userGroup ?? [])
        return result
    }
}
