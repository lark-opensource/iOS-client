//
//  Token.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/7.
//

import Foundation

enum TokenId: Equatable {
    case literal(name: String)
    case ordinal(index: Int)
}

enum Token: Equatable {
    case simple(token: String)
    case complex(tokenId: TokenId, prefix: String, delimeter: String, optional: Bool, repeating: Bool, pattern: String)
}
