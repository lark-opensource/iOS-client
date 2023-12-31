//
//  AccountTest.swift
//  LarkExtensionServicesDevEEUnitTest
//
//  Created by 王元洵 on 2021/4/19.
//

import Foundation
import XCTest
@testable import LarkExtensionServices

class AccountTest: XCTestCase {
    func testAccount() {
        XCTAssertFalse(AccountService.isLogin)
        XCTAssertNil(AccountService.currentAccountID)
        XCTAssertNil(AccountService.currentAccountSession)
        XCTAssertNil(AccountService.currentTenentID)
        XCTAssertNil(AccountService.currentDeviceID)

        do {
            try SecureUserDefaults.shared.set(key: .currentAccountID, value: "account.userID")
            try SecureUserDefaults.shared.set(key: .currentAccountSession, value: "account.sessionKey")
            try SecureUserDefaults.shared.set(key: .currentUserAgent, value: "LarkFoundation.Utils.userAgent")
            try SecureUserDefaults.shared.set(key: .currentDeviceID, value: "deviceService.deviceId")
            try SecureUserDefaults.shared.set(key: .currentTenentID, value: "account.tenant.tenantID")
        } catch { print(error) }

        XCTAssertEqual(AccountService.isLogin, true)
        XCTAssertEqual(AccountService.currentAccountID, "account.userID")
        XCTAssertEqual(AccountService.currentAccountSession, "account.sessionKey")
        XCTAssertEqual(AccountService.currentDeviceID, "deviceService.deviceId")
        XCTAssertEqual(AccountService.currentTenentID, "account.tenant.tenantID")
        XCTAssertEqual(AccountService.currentUserAgent, "LarkFoundation.Utils.userAgent")
    }
}
