//
//  SearchEntityGeneratorWikiTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/17.
//

import XCTest
// swiftlint:disable all
import RustPB
import LarkModel
@testable import LarkSearchCore

final class SearchEntityGeneratorWikiTest: XCTestCase {
    typealias Config = PickerConfig.WikiEntityConfig

    /// 测试生成Doc entity
    func testGenerateEntity() {
        let wiki = Config()
        let config = PickerSearchConfig(entities: [wiki])
        let entities = SearchEntityGenerator.generatorEntities(configs: config.entities)
        XCTAssertEqual(entities.count, 1)
        XCTAssertEqual(entities[0].type, .wiki)
    }

    /// 设置wiki创建者
    func testBelongUser() {
        let entity = config {
            $0.belongUser = .belong(["123"])
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.creatorIds, ["123"])
    }

    func testBelongChat() {
        let entity = config {
            $0.belongChat = .belong(["123"])
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.chatIds, ["123"])
    }
    func testRepoIds() {
        let entity = config {
            $0.repoIds = ["123"]
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.repoIds, ["123"])
    }
    func testReviewTimeRange() {
        let entity = config {
            $0.reviewTimeRange = .range(1, 2)
        }
        let range = entity.entityFilter.wikiFilter.reviewTimeRange
        XCTAssertEqual(range.startTime, 1)
        XCTAssertEqual(range.endTime, 2)
    }
    func testTypes() {
        let entity = config {
            $0.types = [.doc, .wiki]
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.types, [.doc, .wiki])
    }
    func testSearchContentTypes() {
        let entity = config {
            $0.searchContentTypes = [.onlyTitle]
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.searchContentTypes, [.onlyTitle])
    }
    func testSharerIds() {
        let entity = config {
            $0.sharerIds = ["1", "2"]
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.sharerIds, ["1", "2"])
    }
    func testFromIds() {
        let entity = config {
            $0.fromIds = ["1", "2"]
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.fromIds, ["1", "2"])
    }
    func testSortType() {
        let entity = config {
            $0.sortType = .createTime
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.sortType, .createTime)
    }
    func testCrossLanguage() {
        let entity = config {
            $0.crossLanguage = true
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.crossLanguage, true)
    }
    func testSpaceIds() {
        let entity = config {
            $0.spaceIds = ["1", "2"]
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.spaceIds, ["1", "2"])
    }
    func testUseExtendedSearchV2() {
        let entity = config {
            $0.useExtendedSearchV2 = true
        }
        XCTAssertEqual(entity.entityFilter.wikiFilter.useExtendedSearchV2, true)
    }
    // MARK: - Field
    /// 设置relationTag
    func testRelationTag() {
        let entity = config {
            $0.field = PickerConfig.WikiField(relationTag: true)
        }
        XCTAssertEqual(entity.entitySelector.wikiSelector.relationTag, true)
    }

    // MARK: - Private
    private func config(transform: (inout Config) -> Void) -> Search_V2_BaseEntity.EntityItem {
        var config = Config()
        transform(&config)
        let entity = SearchEntityGenerator.getWikiEntity(by: [config])
        return entity
    }
}
// swiftlint:enable all
