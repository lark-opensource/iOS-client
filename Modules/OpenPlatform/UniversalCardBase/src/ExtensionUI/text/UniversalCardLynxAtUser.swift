//
//  MsgCardLynxAtUser.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/7.
//

import Foundation
struct UniversalCardLynxAtUser: Decodable {
    let userID: String
    let content: String
    private let isOuter: Int
    private let isAnonymous: Int
    
    func getIsOuter() -> Bool {
        return isOuter != 0
    }
    
    func getIsAnonymous() -> Bool {
        return isAnonymous != 0
    }
    
    static func from(dict: [String: Any?]) throws -> Self {
        return try JSONDecoder().decode(
            UniversalCardLynxAtUser.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
    
    
}
