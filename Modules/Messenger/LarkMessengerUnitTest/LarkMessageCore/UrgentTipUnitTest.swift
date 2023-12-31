//
//  UrgentTipUnitTest.swift
//  LarkMessengerUnitTest
//
//  Created by JackZhao on 2020/8/6.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import XCTest
@testable import LarkMessageCore

class UrgentTipUnitTest: XCTestCase {
    struct Chatter: UrgentTipChatter {
        var id: String
        var displayName: String
    }

    private let attributedStyle = UrgentTip.AttributedStyle(
            buzzReadColor: UIColor.red,
            buzzUnReadColor: UIColor.red,
            nameAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.red
            ],
            tipAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.red
            ]
    )

    private let maxWidth: CGFloat = 350

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // origin: “Buzzed a”
    // expect: “Buzzed a”
    func testSingleShortName() {
        let ackChatters: [Chatter] = [Chatter(id: "1", displayName: "a")]
        let unackChatter: [Chatter] = []
        let ackChatterIds = ackChatters.map({ $0.id })
        let unackChatterIds = unackChatter.map({ $0.id })
        let vm = UrgentTipViewModel(
            ackUrgentChatters: ackChatters,
            ackUrgentChatterIds: ackChatterIds,
            unackUrgentChatters: unackChatter,
            unackUrgentChatterIds: unackChatterIds,
            maxCellWidth: self.maxWidth,
            attributedStyle: self.attributedStyle)
        let str = vm.attributedString.string
        XCTAssert(vm.chatterIdToRange == ["1": NSRange(location: 7, length: 1)])
        XCTAssert(vm.tipMoreRange == NSRange(location: 0, length: 0))
        let ranges = [NSRange(location: 7, length: 1), NSRange(location: 0, length: 0)]
        XCTAssert(arrayIsAllEqual(arr1: vm.tapRanges, arr2: ranges))
        XCTAssert(str == "Buzzed a")
    }

    // origin: “Buzzed asdasdfwfwfwfwfwfwfwasdasdasdasdasdasd”
    // expect: “Buzzed asdasdasdasdas...”
    func testSingleLongName() {
        let ackChatters: [Chatter] = [Chatter(id: "1", displayName: "asdasdfwfwfwfwfwfwfwasdasdasdasdasdasd")]
        let unackChatter: [Chatter] = []
        let ackChatterIds = ackChatters.map({ $0.id })
        let unackChatterIds = unackChatter.map({ $0.id })
        let vm = UrgentTipViewModel(
            ackUrgentChatters: ackChatters,
            ackUrgentChatterIds: ackChatterIds,
            unackUrgentChatters: unackChatter,
            unackUrgentChatterIds: unackChatterIds,
            maxCellWidth: self.maxWidth,
            attributedStyle: self.attributedStyle)
        let str = vm.attributedString.string
        XCTAssert(vm.chatterIdToRange == ["1": NSRange(location: 7, length: 30)])
        XCTAssert(vm.tipMoreRange == NSRange(location: 37, length: 1))
        let ranges = [NSRange(location: 7, length: 30), NSRange(location: 37, length: 1)]
        XCTAssert(arrayIsAllEqual(arr1: vm.tapRanges, arr2: ranges))
        XCTAssert(str == "Buzzed asdasdfwfwfwfwfwfwfwasdasdasda…")
    }

    // origin: “Buzzed a, b, c”
    // expect: “Buzzed a, b, c”
    func testMoreShortNames() {
        let ackChatters: [Chatter] = [Chatter(id: "1", displayName: "a"),
                                      Chatter(id: "2", displayName: "b"),
                                      Chatter(id: "3", displayName: "c")]
        let unackChatter: [Chatter] = []
        let ackChatterIds = ackChatters.map({ $0.id })
        let unackChatterIds = unackChatter.map({ $0.id })
        let vm = UrgentTipViewModel(
            ackUrgentChatters: ackChatters,
            ackUrgentChatterIds: ackChatterIds,
            unackUrgentChatters: unackChatter,
            unackUrgentChatterIds: unackChatterIds,
            maxCellWidth: self.maxWidth,
            attributedStyle: self.attributedStyle)
        let str = vm.attributedString.string
        XCTAssert(vm.chatterIdToRange == ["2": NSRange(location: 10, length: 1),
                                       "1": NSRange(location: 7, length: 1),
                                       "3": NSRange(location: 13, length: 1)])
        XCTAssert(vm.tipMoreRange == NSRange(location: 0, length: 0))
        let ranges = [NSRange(location: 10, length: 1),
                      NSRange(location: 7, length: 1),
                      NSRange(location: 13, length: 1),
                      NSRange(location: 0, length: 0)]
        XCTAssert(arrayIsAllEqual(arr1: vm.tapRanges, arr2: ranges))
        XCTAssert(str == "Buzzed a, b, c")
    }

    // origin: “Buzzed asdasdfwfwfwfwfwfwfwasdasdasdasdasdasd, b, c”
    // expect: “Buzzed abcabcabcabccab...3 people”
    func testMoreLongNamesAndFistNeedCut() {
        let ackChatters: [Chatter] = [Chatter(id: "1", displayName: "asdasdfwfwfwfwfwfwfwasdasdasdasdasdasd"),
                                      Chatter(id: "2", displayName: "b"),
                                      Chatter(id: "3", displayName: "c")]
        let unackChatter: [Chatter] = []
        let ackChatterIds = ackChatters.map({ $0.id })
        let unackChatterIds = unackChatter.map({ $0.id })
        let vm = UrgentTipViewModel(
            ackUrgentChatters: ackChatters,
            ackUrgentChatterIds: ackChatterIds,
            unackUrgentChatters: unackChatter,
            unackUrgentChatterIds: unackChatterIds,
            maxCellWidth: self.maxWidth,
            attributedStyle: self.attributedStyle)
        let str = vm.attributedString.string
        XCTAssert(vm.chatterIdToRange == ["1": NSRange(location: 7, length: 22)])
        XCTAssert(vm.tipMoreRange == NSRange(location: 29, length: 9))
        let ranges = [NSRange(location: 7, length: 22), NSRange(location: 29, length: 9)]
        XCTAssert(arrayIsAllEqual(arr1: vm.tapRanges, arr2: ranges))
        XCTAssert(str == "Buzzed asdasdfwfwfwfwfwfwfwas…3 people")
    }

    // origin: “Buzzed a, asdasdfwfwfwfwfwfwfwasdasdasdasdasdasd, c”
    // expect: “Buzzed a...3 people”
    func testMoreLongNamesAndSecondNeedCut() {
        let ackChatters: [Chatter] = [Chatter(id: "1", displayName: "a"),
                                      Chatter(id: "2", displayName: "bsdasdfwfwfwfwfwfwfwasdasdasdasdasdasd"),
                                      Chatter(id: "3", displayName: "c")]
        let unackChatter: [Chatter] = []
        let ackChatterIds = ackChatters.map({ $0.id })
        let unackChatterIds = unackChatter.map({ $0.id })
        let vm = UrgentTipViewModel(
            ackUrgentChatters: ackChatters,
            ackUrgentChatterIds: ackChatterIds,
            unackUrgentChatters: unackChatter,
            unackUrgentChatterIds: unackChatterIds,
            maxCellWidth: self.maxWidth,
            attributedStyle: self.attributedStyle)
        let str = vm.attributedString.string
        XCTAssert(vm.chatterIdToRange == ["1": NSRange(location: 7, length: 1)])
        XCTAssert(vm.tipMoreRange == NSRange(location: 8, length: 9))
        let ranges = [NSRange(location: 7, length: 1), NSRange(location: 8, length: 9)]
        XCTAssert(arrayIsAllEqual(arr1: vm.tapRanges, arr2: ranges))
        XCTAssert(str == "Buzzed a…3 people")
    }

    // origin： “Buzzed a, b, csdasdfwfwfwfwfwfwfwasdasdasdasdasdasd”
    // expect： “Buzzed a, b...3 people”
    func testMoreLongNamesAndThirdNeedCut() {
        let ackChatters: [Chatter] = [Chatter(id: "1", displayName: "a"),
                                      Chatter(id: "2", displayName: "b"),
                                      Chatter(id: "3", displayName: "cbsdasdfwfwfwfwfwfwfwasdasdasdasdasdasd")]
        let unackChatter: [Chatter] = []
        let ackChatterIds = ackChatters.map({ $0.id })
        let unackChatterIds = unackChatter.map({ $0.id })
        let vm = UrgentTipViewModel(
            ackUrgentChatters: ackChatters,
            ackUrgentChatterIds: ackChatterIds,
            unackUrgentChatters: unackChatter,
            unackUrgentChatterIds: unackChatterIds,
            maxCellWidth: self.maxWidth,
            attributedStyle: self.attributedStyle)
        let str = vm.attributedString.string
        XCTAssert(vm.chatterIdToRange == ["1": NSRange(location: 7, length: 1), "2": NSRange(location: 10, length: 1)])
        XCTAssert(vm.tipMoreRange == NSRange(location: 11, length: 9))
        let ranges = [NSRange(location: 7, length: 1), NSRange(location: 10, length: 1), NSRange(location: 11, length: 9)]
        XCTAssert(arrayIsAllEqual(arr1: vm.tapRanges, arr2: ranges))
        XCTAssert(str == "Buzzed a, b…3 people")
    }

    // 判断两个数组是否元素全部相等, 不考虑顺序
    private func arrayIsAllEqual(arr1: [NSRange], arr2: [NSRange]) -> Bool {
        var arr2 = arr2
        guard arr1.count == arr2.count else { return false }
        for i in 0 ..< arr1.count {
            let range1 = arr1[i]
            if !arr2.contains(range1) {
                return false
            }
            arr2 = arr2.filter({ (range) -> Bool in
                return range != range1
            })
        }
        return true
    }
}
