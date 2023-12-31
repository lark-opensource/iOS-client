//
//  LarkDebugTest.swift
//  LarkDebugDevEEUnitTest
//
//  Created by SuPeng on 2/14/20.
//

import UIKit
import Foundation
import XCTest
@testable import LarkDebug
import LarkDebugExtensionPoint
import Swinject
import EENavigator
import AppContainer
import LarkFoundation
#if canImport(FLEX)
import FLEX
#endif

class LarkDebugTest: XCTestCase {

    var item: TestDebugItem!
    var cell: DebugTableViewCell!

    override func setUp() {
        item = TestDebugItem()
        cell = DebugTableViewCell()
        cell.setItem(item)
    }

    override func tearDown() {
        self.item = nil
        self.cell = nil
    }

    func testAccessoryViewIsSwitchButton() {
        let switchButton = cell.accessoryView as? UISwitch
        XCTAssertNotNil(switchButton)
    }

    func testSwitchValueChangeDidInvoked() {
        var invoked: Bool = false
        item.switchValueDidChange = { _ in
            invoked = true
        }
        let switchButton = cell.accessoryView as? UISwitch
        switchButton?.sendActions(for: .valueChanged)
        XCTAssertTrue(invoked)
    }

#if canImport(FLEX)
    func testDebugRegistryCanRegister() {
        DebugCellItemRegistries = [:]
        DebugRegistry.registerDebugItem(FlexDebugItem(), to: .debugTool)

        let vc = DebugViewController()
        XCTAssertEqual(vc.data.first!.0, .debugTool)
        XCTAssertEqual(vc.data.first!.1.count, 1)
    }
#endif

    func testDebugBody() {
        let container = Container()
        let assembly = DebugAssembly()
        assembly.assemble(container: container)
        let vc = Navigator.shared.response(for: DebugBody()).resource as? DebugViewController

        XCTAssertNotNil(vc)
    }

    func testSectionTypeNameNotEmtpy() {
        let allTypeNameNotEmpty = SectionType
            .allCases
            .map { $0.name }
            .allSatisfy { !$0.isEmpty }
        XCTAssertTrue(allTypeNameNotEmpty)
    }

    func testCanDebug() {
        XCTAssertTrue(appCanDebug())
    }
}
