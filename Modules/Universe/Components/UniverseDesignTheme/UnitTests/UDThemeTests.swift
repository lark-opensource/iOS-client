//
//  UDThemeTests.swift
//  UniverseDesignTheme-Unit-UnitTests
//
//  Created by 姚启灏 on 2020/11/17.
//

import Foundation
import XCTest
import UniverseDesignTheme

/// UniverseDesign Theme
struct UDTestTheme: UDResource {

    public struct Name: UDKey {
        public let key: String

        public init(_ key: String) {
            self.key = key
        }
    }

    static var current: Self = Self()

    var store: [UDTestTheme.Name: Int] = [:]

    init(store: [UDTestTheme.Name: Int] = [:]) {
        self.store = store
    }
}

extension UDTestTheme.Name {
    static let test1Key = UDTestTheme.Name("test1Key")
    static let test2Key = UDTestTheme.Name("test2Key")
    static let test3Key = UDTestTheme.Name("test3Key")
}

class UDThemeTests: XCTestCase {

    override class func tearDown() {
        super.tearDown()

        UDTestTheme.updateCurrent([:])
    }

    func testCurrentMap() {
        XCTAssertEqual(UDTestTheme.getCurrentStore().count, 0)
    }

    func testUpdateStore() {
        UDTestTheme.updateCurrent([.test1Key: 1])

        XCTAssert(UDTestTheme.getCurrentStore().count == 1)
        XCTAssert(UDTestTheme.getCurrentStore()[.test1Key] == 1)
        XCTAssert(UDTestTheme.getCurrentStore()[.test2Key] == nil)
    }

    func testUpdateTheme() {
        let testTheme = UDTestTheme(store: [.test1Key: 1])
        UDTestTheme.updateCurrent(testTheme)

        XCTAssert(UDTestTheme.getCurrentStore().count == 1)
        XCTAssert(UDTestTheme.getCurrentStore()[.test1Key] == 1)
        XCTAssert(UDTestTheme.getCurrentStore()[.test2Key] == nil)
    }

}
