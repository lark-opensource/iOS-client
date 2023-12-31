//
//  SearchEntityGeneratorWikiSpaceTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/23.
//
// swiftlint:disable all
import XCTest
import RustPB
import LarkModel
@testable import LarkSearchCore

final class SearchEntityGeneratorWikiSpaceTest: XCTestCase {
    typealias Config = PickerConfig.WikiSpaceEntityConfig

    /// 测试生成Doc entity
    func testGenerateEntity() {
        let wikiSpace = Config()
        let config = PickerSearchConfig(entities: [wikiSpace])
        let entities = SearchEntityGenerator.generatorEntities(configs: config.entities)
        XCTAssertEqual(entities.count, 1)
        XCTAssertEqual(entities[0].type, .wikiSpace)
    }

}
// swiftlint:enable all
