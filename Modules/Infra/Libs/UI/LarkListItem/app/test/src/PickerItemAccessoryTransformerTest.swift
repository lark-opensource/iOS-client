//
//  PickerItemAccessoryTransformerTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/10/11.
//

import XCTest
import LarkModel
@testable import LarkListItem

// swiftlint:disable all
final class PickerItemAccessoryTransformerTest: XCTestCase {

    var transformer: PickerItemAccessoryTransformer!

    override func setUp() {
        transformer = PickerItemAccessoryTransformer(isOpen: true)
    }

    func testCloseTargetPreview() {
        transformer = PickerItemAccessoryTransformer(isOpen: false)
        let chatter = ChatterMetaMocker.mockChatter()
        let item = PickerItemMocker.mockChatter(meta: chatter)
        let accessories = transformer.transform(item: item)
        XCTAssertEqual(accessories, [])
    }

    func testCryptoChatter() {
        var chatter = ChatterMetaMocker.mockChatter()
        chatter.isCrypto = true
        let item = PickerItemMocker.mockChatter(meta: chatter)
        let accessories = transformer.transform(item: item)
        XCTAssertEqual(accessories, [])
    }

    func testNormalUser() {
        let chatter = ChatterMetaMocker.mockChatter()
        let item = PickerItemMocker.mockChatter(meta: chatter)
        let accessories = transformer.transform(item: item)
        XCTAssertEqual(accessories?.first, .targetPreview)
    }

}
// swiftlint:enable all
