//
//  BDDriveAESTest.swift
//  DocsTests
//
//  Created by zenghao on 2019/5/23.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import XCTest
@testable import SpaceKit
@testable import Docs

class BDDriveAESTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLongMsg() {
        let msg = "demo:657960321@qq.com:747ddf3d0119fac9235e7dc145eba5e04fbe76bbe999d4d08a"

        let rightEncryptedMsg = "mHcowwObyiKEfLXnamrnCnjmGCoxo8dSe7N5TTpQcxE/bivsZEsqoNDxFGfOYMhGzopzZWB+xNhNoJ3otiHAmNkOIkG7yMJZzMh71EHBULE="

        let encryptedMsg = AESUtil.encrypt_AES_ECB(msg: msg)
        print("加密后：\(encryptedMsg)")

        let decryptedMsg = AESUtil.decrypt_AES_ECB(base64String: encryptedMsg)
        print("解密后：\(decryptedMsg)")

        XCTAssert(rightEncryptedMsg == encryptedMsg, "wrong encryptedMsg")
        XCTAssert(msg == decryptedMsg, "wrong decryptedMsg")
    }

    func testShortMsg() {
        let msg = "abc"

        let rightEncryptedMsg = "eMrbJ4KxDfu2z9R8hSVYLw=="

        let encryptedMsg = AESUtil.encrypt_AES_ECB(msg: msg)
        print("加密后：\(encryptedMsg)")

        let decryptedMsg = AESUtil.decrypt_AES_ECB(base64String: encryptedMsg)
        print("解密后：\(decryptedMsg)")

        XCTAssert(rightEncryptedMsg == encryptedMsg, "wrong encryptedMsg")
        XCTAssert(msg == decryptedMsg, "wrong decryptedMsg")
    }

    func testEmptyMsg() {
        let msg = ""

        let rightEncryptedMsg = "yvjCpoRgCA1SV2mvVOnepg=="

        let encryptedMsg = AESUtil.encrypt_AES_ECB(msg: msg)
        print("加密后：\(encryptedMsg)")

        let decryptedMsg = AESUtil.decrypt_AES_ECB(base64String: encryptedMsg)
        print("解密后：\(decryptedMsg)")

        XCTAssert(rightEncryptedMsg == encryptedMsg, "wrong encryptedMsg")
        XCTAssert(msg == decryptedMsg, "wrong decryptedMsg")
    }

}
