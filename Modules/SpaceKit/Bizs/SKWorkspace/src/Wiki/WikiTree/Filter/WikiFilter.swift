//
//  WikiFilter.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/12/12.
//

import Foundation


public struct WikiFilter: Codable {
    public let classId: String
    public let className: String
    
    enum CodingKeys: String, CodingKey {
        case classId = "space_class_id"
        case className = "space_class_name"
    }
}

public struct WikiFilterList {
    public let filters: [WikiFilter]
}

