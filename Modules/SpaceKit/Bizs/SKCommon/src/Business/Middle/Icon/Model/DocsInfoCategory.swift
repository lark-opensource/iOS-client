//
//  DocsInfoCategory.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/6.
//

import Foundation
import SwiftyJSON

/*
/*
 
 The structure of category model
 
 - primary category (eg: Emoji)
    - secondary category (eg: Emoji-Face)
        - icon1
        - icon2
        - etc....
    - secondary category (eg: Emoji-National Flag)
        - icon3
        - icon4
 - primary category （eg: Image)
    - secondary category (eg: Image-Scenery)
        - icon5
    - secondary category (eg: Image-People)
        - icon6
        - icon7
 
 */

/** The primary category model of docs icon */
public struct DocsIconCategory {
    
    public var id: Int
    
    public var type: SpaceEntry.IconType
    
    public var title: [String: String]
    
    public var subCategories: [DocsIconSubCategory]

    public var iconSet: [DocsIconInfo]
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case subCategories = "data"
    }

    public init(_ json: JSON) {
        self.id = json["id"].intValue
        self.type = SpaceEntry.IconType(rawValue: json["type"].intValue) ?? .unknow
        self.title = json["title"].dictionaryObject as? [String: String] ?? [:]
        self.subCategories = json["data"].arrayValue.compactMap({ DocsIconSubCategory($0) })
        self.iconSet = subCategories.reduce([DocsIconInfo](), { $0 + $1.iconInfos })
    }
    
}

/** The secondary category model of docs icon */
public struct DocsIconSubCategory {
    
    public var id: Int
    
    public var subtitle: [String: String]
    
    public var iconInfos: [DocsIconInfo]
    
    enum CodingKeys: String, CodingKey {
        case id             = "category_id"
        case subtitle       = "sub_title"
        case iconInfos      = "data"
    }

    public init(_ json: JSON) {
        self.id = json["category_id"].intValue
        self.subtitle = json["sub_title"].dictionaryObject as? [String: String] ?? [:]
        self.iconInfos = json["data"].arrayValue.compactMap({ DocsIconInfo($0) })
    }
    
}
*/
