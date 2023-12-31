//
//  TokenTests.swift
//  EENavigatorDevEEUnitTest
//
//  Created by xiongmin on 2021/10/19.
//

import Foundation
import XCTest
@testable import EENavigator

class TokenTests: XCTestCase {

    func testTokenId() {
        let tokenId1 = TokenId.literal(name: "name1")
        let tokenId2 = TokenId.ordinal(index: 0)
        XCTAssert(tokenId1 != tokenId2)
    }
    
    func testToken() {
        let token1 = Token.simple(token: "token1")
        let tokenId2 = TokenId.ordinal(index: 0)
        let token2 = Token.complex(tokenId: tokenId2, prefix: "", delimeter: "", optional: true, repeating: false, pattern: "")
        XCTAssert(token1 != token2)
    }

}
