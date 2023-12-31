//
//  PickerSearchBarTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/6/5.
//

import XCTest
import SnapKit
@testable import LarkSearchCore

// swiftlint:disable all
final class PickerSearchBarTest: ViewTestCase {
    var context: PickerContext!
    var searchBar: PickerSearchBar!
    override func setUp() {
        super.setUp()
        self.context = PickerContext()
        self.context.style = .search
        let textField = UITextField()
        textField.borderStyle = .roundedRect
//        textField.backgroundColor = .red
        self.searchBar = PickerSearchBar(context: context, searchBar: textField)
        searchBar.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
        searchBar.backgroundColor = .white
    }

    func testSearchBar() {
        verify(searchBar)
    }

}
// swiftlint:enable all
