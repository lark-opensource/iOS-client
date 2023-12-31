//
//  DisplayTagInfo.swift
//  SKCommon
//
//  Created by majie.7 on 2022/11/21.
//

import Foundation
import SwiftyJSON
import LarkLocalizations
import SpaceInterface

public struct DisplayTagSimpleInfo: Codable {
    public let type: String
    public let tagValue: String?
    private enum CodingKeys: String, CodingKey {
        case type
        case tagValue = "tag_value"
    }
    
    public init(type: String, tagValue: String?) {
        self.type = type
        self.tagValue = tagValue
    }
    
    public init(json: JSON) {
        type = json["type"].string ?? "0"
        tagValue = json["tag_value"].string
    }
    
    public init(data: [String: Any]) {
        type = data["type"] as? String ?? "0"
        tagValue = data["tag_value"] as? String
    }
}

public typealias TagValue = UserAliasInfo
public struct DisplayTagInfo: Codable, Equatable {
    public let type: String
    public let tagValue: TagValue?
    
    public var displayName: String? {
        if let tag = tagValue {
            return tag.currentLanguageDisplayName
        }
        return nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case tagValue = "tag_value"
    }
    
    public init(type: String, tagValue: TagValue?) {
        self.type = type
        self.tagValue = tagValue
    }
    
    public init(json: JSON) {
        type = json["type"].string ?? "0"
        tagValue = TagValue(json: json["tag_value"])
    }
    
    public init(data: [String: Any]) {
        type = data["type"] as? String ?? "0"
        if let tagValueData = data["tag_value"] as? [String: Any] {
            tagValue = TagValue(data: tagValueData)
        } else {
            tagValue = nil
        }
    }
}
