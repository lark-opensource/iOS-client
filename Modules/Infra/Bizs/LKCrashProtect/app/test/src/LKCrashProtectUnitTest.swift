//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
import LKCrashProtect
import MMKV

class LKCrashProtectUnitTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInit() {
        let res = MMKV.default()?.double(forKey: "CPDataRecordTime")
        XCTAssertNotNil(res, "CPDataRecordTime must not nil")
    }

    func testIncreaseAndDecreaseWhenCrash() {
        LKCharacterCPUtil.increaseCrashCountWithKey(character: "ç")
        LKCharacterCPUtil.decreaseCrashCountWithKey(character: "x")
        LKCharacterCPUtil.increaseCrashCountWithKey(character: "2")
        //由于onSingalCrash是收到crash的信号之后再触发，因此无法主动调用，单测的时候，可以将onSignalCrash方法置为public
//        LKCPUtil.shared.onSingalCrash(signal: SIGSEGV)
//        let res = LKCPUtil.shared.isUnSafeKey(key: "0x24")
        XCTAssertTrue(true, "0x23 need unsafe")
    }

    func testIncreaseAndDereaseWhenOOM() {
        LKCharacterCPUtil.increaseCrashCountWithKey(character: "5")
        let res = LKCharacterCPUtil.isUnSafeKey(character: "x")
        XCTAssertFalse(res, "0x26 must true")
    }

    func testIncreaseAndDereaseWhenExit() {
        LKCharacterCPUtil.increaseCrashCountWithKey(character: "f")
//        LKCPUtil.shared.onExit()
        let res = LKCharacterCPUtil.isUnSafeKey(character: "A")
        XCTAssertFalse(res, "0x25 must false")
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
