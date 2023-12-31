//
//  SearchEntityGeneratorDocTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/17.
//

import XCTest
// swiftlint:disable all
import RustPB
import LarkModel
@testable import LarkSearchCore

final class SearchEntityGeneratorDocTest: XCTestCase {
    typealias Config = PickerConfig.DocEntityConfig

    /// 测试生成Doc entity
    func testGenerateEntity() {
        let doc = PickerConfig.DocEntityConfig()
        let config = PickerSearchConfig(entities: [doc])
        let entities = SearchEntityGenerator.generatorEntities(configs: config.entities)
        XCTAssertEqual(entities.count, 1)
        XCTAssertEqual(entities[0].type, .doc)
    }

    /// 设置文档创建者
    func testBelongUser() {
        let entity = config {
            $0.belongUser = .belong(["123"])
        }
        XCTAssertEqual(entity.entityFilter.docFilter.creatorIds, ["123"])
    }

    /// 设置文档所属群
    func testBelongChat() {
        let entity = config {
            $0.belongChat = .belong(["123"])
        }
        XCTAssertEqual(entity.entityFilter.docFilter.chatIds, ["123"])
    }

    /// 设置文档类型
    func testDocTypes() {
        let entity = config {
            $0.types = [.doc, .wiki]
        }
        XCTAssertEqual(entity.entityFilter.docFilter.types.count, 2)
        XCTAssertEqual(entity.entityFilter.docFilter.types[0], .doc)
        XCTAssertEqual(entity.entityFilter.docFilter.types[1], .wiki)
    }

    /// 设置文档搜索时间范围
    func testReviewTimeRange() {
        let entity = config {
            $0.reviewTimeRange = .range(1, 2)
        }
        let range = entity.entityFilter.docFilter.reviewTimeRange
        XCTAssertEqual(range.startTime, 1)
        XCTAssertEqual(range.endTime, 2)
    }

    /// 设置文档内容类型
    func testSearchContentTypes() {
        let entity = config {
            $0.searchContentTypes = [.onlyTitle]
        }
        XCTAssertEqual(entity.entityFilter.docFilter.searchContentTypes.count, 1)
        XCTAssertEqual(entity.entityFilter.docFilter.searchContentTypes[0], .onlyTitle)
    }
    /// 设置文档分享者IDs
    func testSharerIds() {
        let entity = config {
            $0.sharerIds = ["1"]
        }
        XCTAssertEqual(entity.entityFilter.docFilter.sharerIds.first, "1")
    }
    /// 设置文档所有者 + 分享者
    func testFromIds() {
        let entity = config {
            $0.fromIds = ["1"]
        }
        XCTAssertEqual(entity.entityFilter.docFilter.fromIds.first, "1")
    }
    /// 设置文档排序方式
    func testSortType() {
        let entity = config {
            $0.sortType = .createTime
        }
        XCTAssertEqual(entity.entityFilter.docFilter.sortType, .createTime)
    }
    /// 设置文档跨语言搜索
    func testCrossLanguage() {
        let entity = config {
            $0.crossLanguage = true
        }
        XCTAssertEqual(entity.entityFilter.docFilter.crossLanguage, true)
    }
    /// 设置文档文件夹内的文档
    func testFolderTokens() {
        let entity = config {
            $0.folderTokens = ["1"]
        }
        XCTAssertEqual(entity.entityFilter.docFilter.folderTokens.first, "1")
    }
    /// 设置文档扩召回：包括纠错，同义词，向量召回
    func testEnableExtendedSearch() {
        let entity = config {
            $0.enableExtendedSearch = true
        }
        XCTAssertEqual(entity.entityFilter.docFilter.enableExtendedSearch, true)
    }
    /// 设置文档使用V2版本的扩召回词表
    func testUseExtendedSearchV2() {
        let entity = config {
            $0.useExtendedSearchV2 = true
        }
        XCTAssertEqual(entity.entityFilter.docFilter.useExtendedSearchV2, true)
    }
    // MARK: - Field
    /// 设置relationTag
    func testRelationTag() {
        let entity = config {
            $0.field = PickerConfig.DocField(relationTag: true)
        }
        XCTAssertEqual(entity.entitySelector.docSelector.relationTag, true)
    }
    // MARK: - Private
    private func config(transform: (inout Config) -> Void) -> Search_V2_BaseEntity.EntityItem {
        var config = Config()
        transform(&config)
        let entity = SearchEntityGenerator.getDocEntity(by: [config])
        return entity
    }
}
// swiftlint:enable all
