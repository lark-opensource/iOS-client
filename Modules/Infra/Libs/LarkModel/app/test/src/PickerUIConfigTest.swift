//
//  PickerUIConfigTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/4/19.
//

import XCTest
import LarkModel
// swiftlint:disable all
final class PickerUIConfigTest: XCTestCase {
    var config: PickerFeatureConfig!

    override func setUp() {
        config = PickerFeatureConfig(navigationBar: .init(title: "", sureText: ""),
                                     searchBar: .init(placeholder: ""))
    }

    func testToJson() {
        let json = try! JSONEncoder().encode(config)
        let jsonString = String(data: json, encoding: .utf8)!
        XCTAssertFalse(jsonString.isEmpty)
    }

    func testToConfig() {
        do {
            let json = try JSONEncoder().encode(config)
            let config = try JSONDecoder().decode(PickerFeatureConfig.self, from: json)
            XCTAssertNotNil(config)
        } catch {
//            XCTFail()
            NSLog(" \(error.localizedDescription)")
        }
    }
}
// swiftlint:enable all
