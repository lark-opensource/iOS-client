//
//  SearchEntityGeneratorTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/9.
//

// swiftlint:disable all
import XCTest
import LarkModel
@testable import LarkSearchCore

final class SearchEntityGeneratorTest: XCTestCase {
    func testGenerateUser() {
        let config = PickerSearchConfig(entities: [
            PickerConfig.ChatterEntityConfig(talk: .all, resign: .all),
        ])
        let entities = SearchEntityGenerator.generatorEntities(configs: config.entities)
        XCTAssertEqual(entities.count, 1)
    }

    func testGenerate() {
        let config = PickerSearchConfig(entities: [
            PickerConfig.ChatterEntityConfig(talk: .all, resign: .all),
            PickerConfig.ChatEntityConfig(tenant: .inner)
        ])
        let entities = SearchEntityGenerator.generatorEntities(configs: config.entities)
        XCTAssertEqual(entities.count, 2)
    }

}
// swiftlint:enable all
