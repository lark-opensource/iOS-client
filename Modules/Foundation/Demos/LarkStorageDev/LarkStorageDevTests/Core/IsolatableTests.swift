//
//  IsolatableTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
import LarkFileKit
@testable import LarkStorageCore
@testable import LarkStorage

typealias LfkPath = LarkFileKit.Path

class IsolatableTests: XCTestCase {

    // 测试 Domain & DomainType 的 APIs
    func testDomainApis() throws {
        let root = Domain("Root")
        XCTAssertTrue(root.isRoot)

        let sub1 = root.child("Sub1")
        XCTAssertFalse(sub1.isRoot)

        let sub2 = sub1.child("Sub2")
        XCTAssertFalse(sub2.isRoot)

        XCTAssertTrue(sub1.parent?.isolationId == root.isolationId)
        XCTAssertTrue(sub1.root.isolationId == root.isolationId)

        XCTAssertTrue(sub2.parent?.isolationId == sub1.isolationId)
        XCTAssertTrue(sub2.root.isolationId == root.isolationId)

        XCTAssert(sub2.asComponents().map(\.isolationId) == [
            root.isolationId,
            sub1.isolationId,
            sub2.isolationId
        ])
    }

    func testDomainAncestor() {
        let d1 = Domain("d1")
        let d2 = d1.child("d2")
        let d3_1 = d2.child("d3_1")
        let d3_2 = d2.child("d3_2")
        XCTAssert(!d1.isAncestor(of: d1))
        XCTAssert(!d2.isAncestor(of: d1))
        XCTAssert(!d3_1.isAncestor(of: d3_1))
        XCTAssert(!d3_2.isAncestor(of: d3_2))

        XCTAssert(d1.isAncestor(of: d2))
        XCTAssert(d1.isAncestor(of: d3_1))
        XCTAssert(d1.isAncestor(of: d3_2))

        XCTAssert(d2.isAncestor(of: d3_1))
        XCTAssert(d2.isAncestor(of: d3_2))

        XCTAssert(!d3_1.isAncestor(of: d3_2))
    }

    func testDomainDescendant() {
        let d1 = Domain("d1")
        let d2 = d1.child("d2")
        let d3_1 = d2.child("d3_1")
        let d3_2 = d2.child("d3_2")
        XCTAssert(!d1.isDescendant(of: d1))
        XCTAssert(!d2.isDescendant(of: d2))
        XCTAssert(!d3_1.isDescendant(of: d3_1))
        XCTAssert(!d3_2.isDescendant(of: d3_2))

        XCTAssert(d2.isDescendant(of: d1))
        XCTAssert(d3_1.isDescendant(of: d1))
        XCTAssert(d3_2.isDescendant(of: d1))

        XCTAssert(d3_1.isDescendant(of: d2))
        XCTAssert(d3_2.isDescendant(of: d2))

        XCTAssert(!d3_2.isDescendant(of: d3_1))
    }

    func testDomainSame() {
        let d1 = Domain("d1")
        let d2 = d1.child("d2")
        XCTAssert(d2.isSame(as: d1.child("d2")))
        XCTAssert(d2.child("d3").isSame(as: d1.child("d2").child("d3")))
    }

    func testDomainValid() {
        let valid = "valid"
        let invalid1 = "invalid."
        let invalid2 = ".invalid"
        Domain.disableCheckValid = true
        defer { Domain.disableCheckValid = false }
        XCTAssertTrue(Domain(valid).checkValid(includesAncestor: false))
        XCTAssertTrue(Domain(valid).checkValid(includesAncestor: true))

        XCTAssertFalse(Domain(invalid1).checkValid(includesAncestor: false))
        XCTAssertFalse(Domain(invalid1).checkValid(includesAncestor: true))

        XCTAssertFalse(Domain(invalid2).checkValid(includesAncestor: false))
        XCTAssertFalse(Domain(invalid2).checkValid(includesAncestor: true))

        XCTAssertTrue(Domain(invalid1).child(valid).checkValid(includesAncestor: false))
        XCTAssertFalse(Domain(invalid1).child(valid).checkValid(includesAncestor: true))

        XCTAssertTrue(Domain(invalid2).child(valid).checkValid(includesAncestor: false))
        XCTAssertFalse(Domain(invalid2).child(valid).checkValid(includesAncestor: true))

        do {
            var tester = Domain(invalid1)
            (0..<100).forEach { _ in tester = tester.child(valid) }
            XCTAssertTrue(tester.checkValid(includesAncestor: false))
            XCTAssertFalse(tester.checkValid(includesAncestor: true))
        }

        do {
            var tester = Domain(invalid2)
            (0..<100).forEach {_ in tester = tester.child(valid) }
            XCTAssertTrue(tester.checkValid(includesAncestor: false))
            XCTAssertFalse(tester.checkValid(includesAncestor: true))
        }

        do {
            var tester = Domain(valid)
            (0..<100).forEach {_ in tester = tester.child(valid) }
            XCTAssertTrue(tester.checkValid(includesAncestor: false))
            XCTAssertTrue(tester.checkValid(includesAncestor: true))
        }
    }
}
