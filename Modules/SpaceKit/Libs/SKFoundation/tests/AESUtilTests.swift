//
//  AESUtilTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by CJ on 2022/3/11.
//

import XCTest
@testable import SKFoundation

class AESUtilTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    func testEncrypt_AES_ECB() {
        let msg = "hello"
        let res = AESUtil.encrypt_AES_ECB(msg: msg)
        XCTAssertTrue(!res.isEmpty)
    }

    func testDecrypt_AES_ECB() {
        let msg = "hello"
        let encryptRes = AESUtil.encrypt_AES_ECB(msg: msg)
        let res = AESUtil.decrypt_AES_ECB(base64String: encryptRes)
        XCTAssertEqual(res, msg)
    }
}
