//
//  WikiSpaceIconInfo.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/8/28.
//

import Foundation
import SKFoundation
import LarkIcon

public struct WikiSpaceIconInfo: Codable {
    
    public let type: Int
    public let key: String
    
    public init(type: Int, key: String) {
        self.type = type
        self.key = key
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case key
    }
    
    public var iconType: IconType {
        IconType(rawValue: type)
    }
    
    public var infoString: String? {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch {
            DocsLogger.error("conver wiki space icon info to json string error: \(error)")
            return nil
        }
    }
}
