//
//  PickerContentViewTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/4/7.
//

import XCTest
import SnapKit
@testable import LarkSearchCore
// swiftlint:disable all
final class PickerContentViewTest: ViewTestCase {
    var context: PickerContext!
    override func setUp() {
        super.setUp()
        self.context = PickerContext()
    }

    func testSearchStyleContentView() {
        context.style = .search
        let contentView = buildView(context: context)
        verify(contentView)
    }

    func testPickerStyleContentView() {
        context.style = .picker
        let contentView = buildView(context: context)
        verify(contentView)
    }

    private func buildView(context: PickerContext) -> PickerContentView {
        let searchBar = UIView()
        searchBar.backgroundColor = .lightGray
        let nav = PickerSearchBar(context: context, searchBar: searchBar)
        nav.snp.makeConstraints { $0.height.equalTo(52) }
        let headerView = UIView()
        headerView.backgroundColor = .red
        headerView.snp.makeConstraints { $0.height.equalTo(40) }
        let selectedView = UIView()
        selectedView.backgroundColor = .blue
        selectedView.snp.makeConstraints { $0.height.equalTo(40) }
        let topView = UIView()
        topView.backgroundColor = .green
        topView.snp.makeConstraints { $0.height.equalTo(40) }
        headerView.snp.makeConstraints { $0.height.equalTo(40) }
        let contentView = PickerContentView(navigationBar: nav, headerView: headerView,
                                            selectionView: selectedView, topView: topView,
                                            defaultView: UIView(), listView: UIView())
        contentView.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        contentView.backgroundColor = .white
        return contentView
    }
}
// swiftlint:disable all
