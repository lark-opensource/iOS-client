//
//  UDBreadcrumbTests.swift
//  UniverseDesignBreadcrumb-Unit-UnitTests
//
//  Created by 姚启灏 on 2020/11/18.
//

import Foundation
import XCTest
@testable import UniverseDesignBreadcrumb
import UniverseDesignIcon

class UDBreadcrumbTests: XCTestCase {

    let breadcrumb = UDBreadcrumb()

    override func setUp() {
        super.setUp()

        breadcrumb.setItems(["test1"])
    }

    func testSetItem() {
        XCTAssert(breadcrumb.items.count == 1)
        XCTAssert(breadcrumb.items[0].title == "test1")
    }

    func testAddItem() {
        breadcrumb.addItems(["test2"])
        XCTAssert(breadcrumb.items.count == 2)
        XCTAssert(breadcrumb.items[1].title == "test2")
    }

    func testRemove() {
        breadcrumb.removeItems()
        XCTAssert(breadcrumb.items.isEmpty)
    }
}
