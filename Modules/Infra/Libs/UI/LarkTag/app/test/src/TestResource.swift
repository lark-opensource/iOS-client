//
//  TestResource.swift
//  LarkTagDevEEUnitTest
//
//  Created by Aslan on 2021/5/17.
//

import Foundation
import UIKit
import XCTest
@testable import LarkTag

// 为了保证单侧覆盖率
class TestResource: XCTestCase {
    func testResource() {
        XCTAssertNotNil(BundleResources.LarkTag.crypto_do_not_disturb)
        XCTAssertNotNil(BundleResources.LarkTag.do_not_disturb)
        XCTAssertNotNil(Resources.LarkTag.newVersion)
    }
}
