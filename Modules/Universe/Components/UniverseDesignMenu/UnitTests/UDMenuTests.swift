//
//  UDMenuTests.swift
//  UniverseDesignMenu
//
//  Created by qsc on 2020/11/20.
//

import UIKit
import Foundation
import XCTest
@testable import UniverseDesignMenu

class UDMenuTests: XCTestCase {

    var udmenu: UDMenu?
    let titles = ["TestA", "Test 2"]
    var actions: [UDMenuAction] = []

    override func setUp() {
        super.setUp()
        let action1 = UDMenuAction(title: titles[0], icon: UIImage()) {
            print("did press TestA")
        }
        let action2 = UDMenuAction(title: titles[1], icon: UIImage()) {
            print("did press Test 2")
        }
        actions = [action1, action2]
        udmenu = UDMenu(actions: actions)
    }

    func testActionsCount() throws {
        udmenu?.showMenu(sourceRect: CGRect(x: 100, y: 100, width: 100, height: 100),
                         sourceVC: UIViewController()) { [unowned udmenu] success in
            XCTAssertEqual(udmenu?.menuVC?.actions.count, 2)

            print("show menu result: \(success)")
            XCTAssertEqual(success, false)
        }
    }

    // swiftlint:disable line_length
    func testActionsContent() throws {
        let titles = ["TestA", "Test 2"]

        let action1 = UDMenuAction(title: titles[0], icon: UIImage()) {
            print("did press TestA")
        }
        let action2 = UDMenuAction(title: titles[1], icon: UIImage()) {
            print("did press Test 2")
        }
        let udmenu = UDMenu(actions: [action1, action2])

        udmenu.showMenu(sourceRect: CGRect(x: 100, y: 100, width: 100, height: 100), sourceVC: UIViewController()) { [unowned udmenu, titles] _ in
            for index in 0...1 {
                if let cell = udmenu.menuVC?.menuTableView().cellForRow(at: IndexPath(item: index, section: 0)) as? UDMenuActionCell {
                    XCTAssertEqual(cell.titleLabel().text, titles[index])
                    XCTAssertEqual(cell.titleLabel().text, titles[index])
                }
            }
        }
    }

    func testActionsStyle() throws {

        var style = UDMenuStyleConfig()
        style.cornerRadius = 8
        style.marginToSource = 12
        style.maskColor = UIColor.green.withAlphaComponent(0.2)
        style.menuColor = UIColor.gray
        style.menuItemBackgroundColor = UIColor.darkGray
        style.menuItemHeight = 52

        style.menuItemIconTintColor = UIColor.red
        style.menuItemIconWidth = 24
        style.menuItemSelectedBackgroundColor = UIColor.blue.withAlphaComponent(0.5)
        style.menuItemTitleColor = UIColor.red
        style.menuItemTitleFont = UIFont.boldSystemFont(ofSize: 16)

        style.menuListInset = 12

        style.menuWidth = 144

        udmenu = UDMenu(actions: actions, style: style)
        guard let udmenu = udmenu else {
            return
        }
        udmenu.showMenu(sourceRect: CGRect(x: 100, y: 100, width: 100, height: 100), sourceVC: UIViewController()) { [unowned udmenu] _ in
            guard let menuVC = udmenu.menuVC else {
                XCTAssertNil(nil, "menuVC is nil!")
                return
            }
            XCTAssertEqual(menuVC.view.backgroundColor, UIColor.green.withAlphaComponent(0.2))

            for index in 0...1 {
                XCTAssertEqual(menuVC.menuTableView().layer.cornerRadius, 8)
                XCTAssertEqual(menuVC.menuTableView().backgroundColor, UIColor.gray)

                if let cell = menuVC.menuTableView().cellForRow(at: IndexPath(item: index, section: 0)) as? UDMenuActionCell {
                    XCTAssertEqual(cell.titleLabel().font, UIFont.boldSystemFont(ofSize: 16))
                    XCTAssertEqual(cell.titleLabel().textColor, UIColor.red)
                    XCTAssertEqual(cell.iconView().tintColor, UIColor.red)
                    XCTAssertEqual(cell.selectedBackgroundView().backgroundColor, UIColor.blue.withAlphaComponent(0.5))
                    XCTAssertEqual(cell.backgroundColor, UIColor.darkGray)

                }
            }
        }
    }
}
