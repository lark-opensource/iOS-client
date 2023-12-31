//
//  ECOFoundationTestCase.swift
//  ECOInfraDevEEUnitTest
//
//  Created by Meng on 2021/3/1.
//

import XCTest
@testable import ECOInfra

// swiftlint:disable all
class ECOFoundationTestCase: XCTestCase {
    func testStringMask() {
        XCTAssertEqual("", "".mask())
        XCTAssertEqual("*", "a".mask())
        XCTAssertEqual("*", "a".mask(padding: 1))
        XCTAssertEqual("**", "ab".mask())
        XCTAssertEqual("a*", "ab".mask(padding: 1))
        XCTAssertEqual("***", "abc".mask())
        XCTAssertEqual("a**", "abc".mask(padding: 1))
        XCTAssertEqual("a**d", "abcd".mask())
        XCTAssertEqual("a***e", "abcde".mask())
        XCTAssertEqual("*****", "abcde".mask(padding: 5))
        XCTAssertEqual("ab***f", "abcdef".mask())
        XCTAssertEqual("ab****g", "abcdefg".mask())
        XCTAssertEqual("ab*******************************fg", "abcdefgabcdefgabcdefgabcdefgabcdefg".mask())
        XCTAssertEqual("_", "_".mask())
        XCTAssertEqual("*_*", "a_b".mask())
        XCTAssertEqual("***_", "abc_".mask())
        XCTAssertEqual("_***", "_abc".mask())
        XCTAssertEqual("_***_", "_abc_".mask())
        XCTAssertEqual("___*", "___a".mask())
        XCTAssertEqual("*___", "a___".mask())
        XCTAssertEqual("*___*", "a___b".mask())
        XCTAssertEqual("*_*_*", "a_b_c".mask())
        XCTAssertEqual("ab*_***_*hi", "abc_def_ghi".mask())
        XCTAssertEqual("__ab*_***_*hi__", "__abc_def_ghi__".mask())
        XCTAssertEqual("ab*_***_***_***_***_***_*tu_", "abc_def_ghi_jkl_mno_pqr_stu_".mask())
        XCTAssertEqual("abc_d0000h000k0000000q0_stu_", "abc_def_ghi_jkl_mno_pqr_stu_".mask(padding: 5, pad: "0", except: ["h", "k", "q"]))
        XCTAssertEqual("***", "abc".mask(padding: -1))
        XCTAssertEqual("mi*****_***en", "mission_token".mask())
        XCTAssertEqual("_ss*_*******ne", "_ssa_userphone".mask())
        XCTAssertEqual("MO*****_***_ID", "MONITOR_WEB_ID".mask())
        XCTAssertEqual("se****_*id", "server_sid".mask())
        XCTAssertEqual("_hj*****st", "_hjTLDTest".mask())
        XCTAssertEqual("_ss*_******me", "_ssa_username".mask())
        XCTAssertEqual("_**", "_ga".mask())
        XCTAssertEqual("MO*****_***_ID", "MONITOR_WEB_ID".mask())
        XCTAssertEqual("_***", "_gid".mask())
        XCTAssertEqual("MO*****_***_ID", "MONITOR_WEB_ID".mask())
        XCTAssertEqual("SL*****_***_ID", "SLARDAR_WEB_ID".mask())
        XCTAssertEqual("_h**d", "_hjid".mask())
        XCTAssertEqual("_**", "_ga".mask())
        XCTAssertEqual("_ne**********on", "_netarchsession".mask())
        XCTAssertEqual("_h**d", "_hjid".mask())
        XCTAssertEqual("G_E******_**PS", "G_ENABLED_IDPS".mask())
        XCTAssertEqual("ru*****-*****on", "rutland-session".mask())
        XCTAssertEqual("by****_*****on", "byteio_version".mask())
        XCTAssertEqual("di***t", "digest".mask())
    }
}
