//
//  PickerNavigationBarTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/6/8.
//

import XCTest
import LarkModel
@testable import LarkSearchCore

final class PickerNavigationBarTest: XCTestCase {
    func testSingleSelect() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .sure)
    }

    func testMultiSelectCanSwitch() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .multi)
    }

    func testMultiSelectCantSwitch() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: true, canSwitchToSingle: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .sure)
    }

    func testMultiSelectAndSingleDefault() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .multi)
    }

    func testSwitchToMulti() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: false, canSwitchToSingle: true))
        let store = PickerNavigationBarStore(featureConfig: config)
        store.switchToMulti()
        XCTAssertEqual(store.state.left.style, .cancle)
        XCTAssertEqual(store.state.right.style, .sure)
    }

    func testSwitchToSingle() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: true, canSwitchToSingle: true))
        let store = PickerNavigationBarStore(featureConfig: config)
        store.switchToSingle()
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .multi)
    }

    func testCantSwitchToMulti() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: false, canSwitchToMulti: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        store.switchToMulti()
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .sure)
    }

    func testCantSwitchToSingle() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: true, canSwitchToSingle: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        store.switchToSingle()
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .sure)
    }

    func testSwitchToMultiAndCantSwitchToSingle() {
        let config = PickerFeatureConfig(multiSelection: .init(isOpen: true, isDefaultMulti: false, canSwitchToSingle: false))
        let store = PickerNavigationBarStore(featureConfig: config)
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .multi)
        store.switchToMulti()
        XCTAssertEqual(store.state.left.style, .close)
        XCTAssertEqual(store.state.right.style, .sure)
    }
}
