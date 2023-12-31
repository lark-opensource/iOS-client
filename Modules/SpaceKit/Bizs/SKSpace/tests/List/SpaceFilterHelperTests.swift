//
//  SpaceFilterHelper+Test.swift
//  SKSpace-Unit-Tests
//
//  Created by Weston Wu on 2022/3/21.
//

import XCTest
@testable import SKSpace
import SKCommon

class MockSpaceListConfigCache: SpaceListConfigCache {

    var content: [String: Data] = [:]

    init() {}

    func set(data: Data, for key: String) {
        content[key] = data
    }

    func data(by key: String) -> Data? {
        content[key]
    }
}

class SpaceFilterHelperTests: XCTestCase {

    func testChanged() {
        let options = SpaceFilterHelper.FilterOption.allCases
        var filterHelper = SpaceFilterHelper(listIdentifier: "unit-test", options: options, configCache: MockSpaceListConfigCache())
        XCTAssertFalse(filterHelper.changed)

        filterHelper.update(filterIndex: 1)
        XCTAssertTrue(filterHelper.changed)

        filterHelper.update(filterIndex: 0)
        XCTAssertFalse(filterHelper.changed)
    }

    func testSelection() {
        let options = SpaceFilterHelper.FilterOption.allCases
        var filterHelper = SpaceFilterHelper(listIdentifier: "unit-test", options: options, configCache: MockSpaceListConfigCache())

        for index in 0..<options.count {
            filterHelper.update(filterIndex: index)
            XCTAssertEqual(filterHelper.selectedIndex, index)
            XCTAssertEqual(filterHelper.selectedOption, options[index])
        }
    }

    func testStoreRestore() {
        let options = SpaceFilterHelper.FilterOption.allCases
        var cache = MockSpaceListConfigCache()
        var filterHelper = SpaceFilterHelper(listIdentifier: "unit-test", options: options, configCache: cache)
        filterHelper.update(filterIndex: 5)

        do {
            let data = try JSONEncoder().encode(filterHelper.selectedOption)
            cache.set(data: data, for: "space.filter.unit-test")
            // 正常恢复
            filterHelper.update(filterIndex: 0)
            filterHelper.restore()
            XCTAssertEqual(filterHelper.selectedIndex, 5)
        } catch {
            XCTFail("encode option data failed")
        }

        // cache 里 index 不合法
        filterHelper = SpaceFilterHelper(listIdentifier: "unit-test", options: [.all, .wiki], configCache: cache)
        filterHelper.update(filterIndex: 1)
        filterHelper.restore()
        XCTAssertEqual(filterHelper.selectedIndex, 1)

        // cache 不存在
        filterHelper = SpaceFilterHelper(listIdentifier: "unit-test-no-exist", options: [.all, .wiki], configCache: MockSpaceListConfigCache())
        filterHelper.update(filterIndex: 1)
        filterHelper.restore()
        XCTAssertEqual(filterHelper.selectedIndex, 1)

        // cache 数据不合法
        cache = MockSpaceListConfigCache()
        cache.set(data: Data(), for: "space.filter.unit-test-invalid-data")
        filterHelper = SpaceFilterHelper(listIdentifier: "unit-test-invalid-data", options: [.all, .wiki], configCache: cache)
        filterHelper.update(filterIndex: 1)
        filterHelper.restore()
        XCTAssertEqual(filterHelper.selectedIndex, 1)
    }

    func testUpdate() {
        var filterHelper = SpaceFilterHelper(listIdentifier: "unit-test-no-exist", options: [.all, .wiki], configCache: MockSpaceListConfigCache())
        XCTAssertEqual(filterHelper.selectedIndex, 0)
        // 正常更新
        filterHelper.update(filterIndex: 1)
        XCTAssertEqual(filterHelper.selectedIndex, 1)
        // 非法 index，重置为0
        filterHelper.update(filterIndex: 2)
        XCTAssertEqual(filterHelper.selectedIndex, 0)

        filterHelper.update(selectedOption: .wiki)
        XCTAssertEqual(filterHelper.selectedOption, SpaceFilterHelper.FilterOption.wiki)
        // 选择不存在的选项，不发生变化
        filterHelper.update(selectedOption: .bitable)
        XCTAssertEqual(filterHelper.selectedOption, SpaceFilterHelper.FilterOption.wiki)
    }

    func testLegacyFilterType() {
        SpaceFilterHelper.FilterOption.allCases.forEach { option in
            let legacyType = option.legacyType
            let legacyItem = FilterItem(isSelected: false, filterType: legacyType)
            XCTAssertEqual(option.reportName, legacyType.reportName)
            XCTAssertEqual(option.reportNameV2, legacyType.reportNameV2)
            XCTAssertEqual(option.objTypes ?? [], legacyItem.currentObjTypes)
            XCTAssertEqual(option.displayName, legacyItem.displayName)
        }
    }
}
