//
//  DocsIconInfo.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/6.
//

import Foundation
import SwiftyJSON
/*
/** The meta model of a single docs icon */
public struct DocsIconInfo: Equatable {
    
    public var id: Int
    
    public var key: String
    
    public var fsUnit: String
    
    public var type: SpaceEntry.IconType
    
    public var name: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case fsUnit = "fs_unit"
        case type
        case name
    }

    public init(_ json: JSON) {
        self.id = json["id"].intValue
        self.key = json["key"].stringValue
        self.fsUnit = json["fs_unit"].stringValue
        self.type = SpaceEntry.IconType(rawValue: json["type"].intValue) ?? .unknow
        self.name = json["name"].dictionaryObject as? [String: String] ?? [:]
    }

    private init(id: Int, key: String, type: SpaceEntry.IconType) {
        self.id = id
        self.key = key
        self.fsUnit = ""
        self.type = type
        self.name = [:]
    }

    public static var removeItem: DocsIconInfo {
        DocsIconInfo(id: -1, key: "remove", type: .remove)
    }
    
}
*/
