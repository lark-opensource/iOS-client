//
//  SpaceSortHelper+Test.swift
//  SKSpace-Unit-Tests
//
//  Created by Weston Wu on 2022/3/22.
//

import XCTest
@testable import SKSpace
import SKCommon
import SKResource

class SpaceSortHelperTests: XCTestCase {

    typealias SortType = SpaceSortHelper.SortType
    typealias SortOption = SpaceSortHelper.SortOption

    func testChanged() {
        let options = [
            SortOption(type: .allTime, descending: true, allowAscending: true),
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: true),
            SortOption(type: .lastOpenTime, descending: true, allowAscending: true),
            SortOption(type: .latestCreated, descending: true, allowAscending: true)
        ]
        var sortHelper = SpaceSortHelper(listIdentifier: "unit-test", options: options, configCache: MockSpaceListConfigCache())
        XCTAssertFalse(sortHelper.changed)

        sortHelper.update(sortIndex: 1, descending: true)
        XCTAssertTrue(sortHelper.changed)

        sortHelper.update(sortIndex: 0, descending: true)
        XCTAssertFalse(sortHelper.changed)

        sortHelper.update(sortIndex: 0, descending: false)
        XCTAssertTrue(sortHelper.changed)
    }

    func testSelection() {
        let options = [
            SortOption(type: .allTime, descending: true, allowAscending: true),
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: true),
            SortOption(type: .lastOpenTime, descending: true, allowAscending: true),
            SortOption(type: .latestCreated, descending: true, allowAscending: true)
        ]
        var sortHelper = SpaceSortHelper(listIdentifier: "unit-test", options: options, configCache: MockSpaceListConfigCache())

        for index in 0..<options.count {
            sortHelper.update(sortIndex: index, descending: true)
            XCTAssertEqual(sortHelper.selectedIndex, index)
            XCTAssertEqual(sortHelper.selectedOption, options[index])

            sortHelper.update(sortIndex: index, descending: false)
            XCTAssertEqual(sortHelper.selectedIndex, index)
            XCTAssertNotEqual(sortHelper.selectedOption, options[index])
        }
    }

    func testStoreRestore() {
        let options = [
            SortOption(type: .allTime, descending: true, allowAscending: true),
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: true),
            SortOption(type: .lastOpenTime, descending: true, allowAscending: true),
            SortOption(type: .latestCreated, descending: true, allowAscending: true)
        ]
        var cache = MockSpaceListConfigCache()
        var sortHelper = SpaceSortHelper(listIdentifier: "unit-test", options: options, configCache: cache)
        sortHelper.update(sortIndex: 2, descending: true)

        do {
            let data = try JSONEncoder().encode(sortHelper.selectedOption)
            cache.set(data: data, for: "space.sort.unit-test")
            // 正常恢复
            sortHelper.update(sortIndex: 0, descending: true)
            sortHelper.restore()
            XCTAssertEqual(sortHelper.selectedIndex, 2)
            XCTAssertEqual(sortHelper.selectedOption, options[2])
        } catch {
            XCTFail("encode option data failed")
        }

        let testOption = SortOption(type: .lastOpenTime, descending: false, allowAscending: true)
        sortHelper.update(selectedOption: testOption)
        do {
            let data = try JSONEncoder().encode(sortHelper.selectedOption)
            cache.set(data: data, for: "space.sort.unit-test")
            // 正常恢复
            sortHelper.update(sortIndex: 0, descending: true)
            sortHelper.restore()
            XCTAssertEqual(sortHelper.selectedIndex, 2)
            XCTAssertEqual(sortHelper.selectedOption, testOption)
        } catch {
            XCTFail("encode option data failed")
        }

        // cache 里 index 不合法
        sortHelper = SpaceSortHelper(listIdentifier: "unit-test", options: Array(options.prefix(2)), configCache: cache)
        sortHelper.update(sortIndex: 1, descending: true)
        sortHelper.restore()
        XCTAssertEqual(sortHelper.selectedIndex, 0)
        XCTAssertEqual(sortHelper.selectedOption, options[0])

        // cache 不存在
        sortHelper = SpaceSortHelper(listIdentifier: "unit-test-no-exist", options: options, configCache: MockSpaceListConfigCache())
        sortHelper.update(sortIndex: 1, descending: true)
        sortHelper.restore()
        XCTAssertEqual(sortHelper.selectedIndex, 1)
        XCTAssertEqual(sortHelper.selectedOption, options[1])

        // cache 数据不合法
        cache = MockSpaceListConfigCache()
        cache.set(data: Data(), for: "space.filter.unit-test-invalid-data")
        sortHelper = SpaceSortHelper(listIdentifier: "unit-test-no-exist", options: options, configCache: MockSpaceListConfigCache())
        sortHelper.update(sortIndex: 1, descending: true)
        sortHelper.restore()
        XCTAssertEqual(sortHelper.selectedIndex, 1)
        XCTAssertEqual(sortHelper.selectedOption, options[1])
    }

    func testUpdate() {
        let options = [
            SortOption(type: .allTime, descending: true, allowAscending: true),
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: true),
            SortOption(type: .lastOpenTime, descending: true, allowAscending: true),
            SortOption(type: .latestCreated, descending: true, allowAscending: true)
        ]
        let ascendingOptions = [
            SortOption(type: .allTime, descending: false, allowAscending: true),
            SortOption(type: .lastModifiedTime, descending: false, allowAscending: true),
            SortOption(type: .lastOpenTime, descending: false, allowAscending: true),
            SortOption(type: .latestCreated, descending: false, allowAscending: true)
        ]
        var sortHelper = SpaceSortHelper(listIdentifier: "unit-test-no-exist", options: options, configCache: MockSpaceListConfigCache())
        XCTAssertEqual(sortHelper.selectedIndex, 0)
        XCTAssertEqual(sortHelper.selectedOption, options[0])

        // 正常更新
        for index in 0 ..< options.count {
            sortHelper.update(sortIndex: index, descending: true)
            XCTAssertEqual(sortHelper.selectedIndex, index)
            XCTAssertEqual(sortHelper.selectedOption, options[index])

            sortHelper.update(sortIndex: index, descending: false)
            XCTAssertEqual(sortHelper.selectedIndex, index)
            XCTAssertEqual(sortHelper.selectedOption, ascendingOptions[index])
        }

        // 非法 index，重置为0
        sortHelper.update(sortIndex: 5, descending: true)
        XCTAssertEqual(sortHelper.selectedIndex, 0)
        XCTAssertEqual(sortHelper.selectedOption, options[0])


        options.forEach { option in
            sortHelper.update(selectedOption: option)
            XCTAssertEqual(sortHelper.selectedOption, option)
        }

        ascendingOptions.forEach { option in
            sortHelper.update(selectedOption: option)
            XCTAssertEqual(sortHelper.selectedOption, option)
        }

        sortHelper = SpaceSortHelper(listIdentifier: "unit-test-no-exist", options: options, configCache: MockSpaceListConfigCache())
        // 选择不存在的选项，不发生变化
        let invalidOption = SortOption(type: .addedManualOfflineTime, descending: true, allowAscending: false)
        sortHelper.update(selectedOption: invalidOption)
        XCTAssertEqual(sortHelper.selectedOption, options[0])

        let fixOrderOptions = [
            SortOption(type: .allTime, descending: true, allowAscending: false),
            SortOption(type: .lastModifiedTime, descending: true, allowAscending: false),
            SortOption(type: .lastOpenTime, descending: true, allowAscending: false),
            SortOption(type: .latestCreated, descending: true, allowAscending: false)
        ]
        sortHelper = SpaceSortHelper(listIdentifier: "unit-test-no-exist", options: fixOrderOptions, configCache: MockSpaceListConfigCache())
        sortHelper.update(sortIndex: 0, descending: false)
        XCTAssertEqual(sortHelper.selectedOption, fixOrderOptions[0])
    }

    func testLegacySortType() {
        SortType.allCases.forEach { sortType in
            let legacyType = sortType.legacyType
            var legacyItem = SortItem(isSelected: false, isUp: true, sortType: legacyType)
            if legacyType != .letestCreated {
                XCTAssertEqual(sortType.serverParamValue, legacyType.rawValue)
            } else {
                XCTAssertEqual(sortType.serverParamValue, SortItem.SortType.createTime.rawValue)
            }
            XCTAssertEqual(sortType.reportName, legacyType.reportName)
            XCTAssertEqual(sortType.displayName, legacyItem.displayNameV2)

            var sortOption = SortOption(type: sortType, descending: true, allowAscending: true)
            legacyItem = sortOption.legacyItem
            XCTAssertEqual(sortOption.allowAscending, legacyItem.needShowUpArrow)
            XCTAssertEqual(sortOption.descending, !legacyItem.isUp)
            sortOption.update(descending: false)
            legacyItem = sortOption.legacyItem
            XCTAssertEqual(sortOption.descending, !legacyItem.isUp)

            sortOption = SortOption(type: sortType, descending: true, allowAscending: false)
            legacyItem = sortOption.legacyItem
            XCTAssertEqual(sortOption.allowAscending, legacyItem.needShowUpArrow)
        }
    }
}
