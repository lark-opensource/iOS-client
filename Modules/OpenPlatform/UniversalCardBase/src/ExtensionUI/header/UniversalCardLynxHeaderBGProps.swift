//
//  MsgCardLynxHeaderBGProps.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/14.
//

import Foundation

struct HeaderBGProps: Decodable {
    let tintColor: String?
    let gradientColors: [String]?
    let template: String?
    let bgColorToken: String?
    
    static func from(dict: [String: Any?]) throws -> Self {
        return try JSONDecoder().decode(
            HeaderBGProps.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
}
