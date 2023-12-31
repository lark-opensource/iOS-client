//
//  ExtensionsTests.swift
//  EENavigatorDevEEUnitTest
//
//  Created by liuwanlin on 2018/10/26.
//

import Foundation
import XCTest
@testable import EENavigator

class ExtensionsTests: XCTestCase {

    func testInsertionIndex() {
        var arr = [1, 2, 4, 5, 6]
        var index = arr.insertionIndex(of: 7, isOrderedBefore: <)
        XCTAssert(index == 5)

        index = arr.insertionIndex(of: 3, isOrderedBefore: <)
        XCTAssert(index == 2)

        index = arr.insertionIndex(of: 0, isOrderedBefore: <)
        XCTAssert(index == 0)

        arr = []
        index = arr.insertionIndex(of: 0, isOrderedBefore: <)
        XCTAssert(index == 0)
    }

    func testInsertionIndexReverse() {
        var arr = [6, 5, 4, 2, 1]
        var index = arr.insertionIndex(of: 7, isOrderedBefore: >)
        XCTAssert(index == 0)

        index = arr.insertionIndex(of: 3, isOrderedBefore: >)
        XCTAssert(index == 3)

        index = arr.insertionIndex(of: 0, isOrderedBefore: >)
        XCTAssert(index == 5)

        arr = []
        index = arr.insertionIndex(of: 0, isOrderedBefore: >)
        XCTAssert(index == 0)
    }

}
