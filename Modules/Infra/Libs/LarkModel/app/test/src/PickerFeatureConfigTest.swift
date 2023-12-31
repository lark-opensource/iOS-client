//
//  PickerFeatureConfigTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/5/15.
//

import XCTest
import LarkModel
// swiftlint:disable all
final class PickerFeatureConfigTest: XCTestCase {
    func testCodable() {
        do {
            let item = PickerItem(meta: .chatter(.init(id: "123")))
            let config = PickerFeatureConfig(multiSelection: .init(preselectItems: [item], selectedViewStyle: .iconList),
                                             navigationBar: .init(title: "", closeColor: .blue, sureColor: .red))
            let data = try JSONEncoder().encode(config)
            XCTAssertFalse(data.isEmpty)
            let result = try JSONDecoder().decode(PickerFeatureConfig.self, from: data)
            XCTAssertEqual(result.multiSelection.preselectItems?.count, 1)
        } catch {
            XCTFail()
        }
    }
}
// swiftlint:enable all
