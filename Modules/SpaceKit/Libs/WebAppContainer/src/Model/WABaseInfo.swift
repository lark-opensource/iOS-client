//
//  WABaseInfo.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/29.
//

import Foundation


public protocol WABaseInfoProtocol {
    var lang: String { get }
    var timeZone: String { get }
    
    func toDic() -> [String : Any]
}

public struct WABaseInfo: WABaseInfoProtocol, Codable {
    public var lang: String
    
    public var timeZone: String
    
    public init(lang: String, timeZone: String) {
        self.lang = lang
        self.timeZone = timeZone
    }
    
    public func toDic() -> [String : Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
