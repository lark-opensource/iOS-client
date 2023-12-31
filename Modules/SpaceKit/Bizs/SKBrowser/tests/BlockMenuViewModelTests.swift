//
//  BlockMenuViewModelTests.swift
//  SKBrowser-Unit-Tests
//
//  Created by zoujie on 2022/3/24.
//  

import XCTest
import SKFoundation
import SKBrowser

class BlockMenuViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }


    //测试block菜单一行多少个
    func testBlockMeunPerLineItemNum() {
        let items = [BlockMenuItem(id: "1",
                                   panelId: "1",
                                   text: "1111"),
                     BlockMenuItem(id: "2",
                                   panelId: "1",
                                   text: "2222"),
                     BlockMenuItem(id: "3",
                                   panelId: "1",
                                   text: "3333"),
                     BlockMenuItem(id: "4",
                                   panelId: "1",
                                   text: "4444"),
                     BlockMenuItem(id: "5",
                                   panelId: "1",
                                   text: "5555"),
                     BlockMenuItem(id: "6",
                                   panelId: "1",
                                   text: "6666"),
                     BlockMenuItem(id: "7",
                                   panelId: "1",
                                   text: "7777")]
        let sixItems = [BlockMenuItem(id: "1",
                                      panelId: "1",
                                      text: "1111"),
                        BlockMenuItem(id: "2",
                                      panelId: "1",
                                      text: "2222"),
                        BlockMenuItem(id: "3",
                                      panelId: "1",
                                      text: "3333"),
                        BlockMenuItem(id: "4",
                                      panelId: "1",
                                      text: "4444"),
                        BlockMenuItem(id: "5",
                                      panelId: "1",
                                      text: "5555"),
                        BlockMenuItem(id: "6",
                                      panelId: "1",
                                      text: "6666")]

        var blockMenuModel = BlockMenuViewModel(isIPad: false,
                                                data: items)
        blockMenuModel.menuWidth = 422

        var perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(items.count == perLineItemNum)

        blockMenuModel = BlockMenuViewModel(isIPad: false,
                                            data: items)
        blockMenuModel.menuWidth = 375

        perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(5 == perLineItemNum)

        blockMenuModel = BlockMenuViewModel(isIPad: false,
                                            data: sixItems)
        blockMenuModel.menuWidth = 325

        perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(4 == perLineItemNum)


        blockMenuModel = BlockMenuViewModel(isIPad: true,
                                            data: items)
        blockMenuModel.menuWidth = 576

        perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(items.count == perLineItemNum)


        blockMenuModel = BlockMenuViewModel(isIPad: true,
                                            data: items)
        blockMenuModel.menuWidth = 375

        perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(5 == perLineItemNum)

        blockMenuModel = BlockMenuViewModel(isIPad: true,
                                            data: items)
        blockMenuModel.menuWidth = 315

        perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(3 == perLineItemNum)
        
        blockMenuModel = BlockMenuViewModel(isIPad: true,
                                            data: items)
        blockMenuModel.menuWidth = 304

        perLineItemNum = blockMenuModel.getPerLineItemNum()
        XCTAssertTrue(3 == perLineItemNum)

    }

    //测试block菜单需要显示几行
    func testBlockMeunLineNum() {
        let items = [BlockMenuItem(id: "1",
                                   panelId: "1",
                                   text: "1111"),
                     BlockMenuItem(id: "2",
                                   panelId: "1",
                                   text: "2222"),
                     BlockMenuItem(id: "3",
                                   panelId: "1",
                                   text: "3333"),
                     BlockMenuItem(id: "4",
                                   panelId: "1",
                                   text: "4444"),
                     BlockMenuItem(id: "5",
                                   panelId: "1",
                                   text: "5555"),
                     BlockMenuItem(id: "6",
                                   panelId: "1",
                                   text: "6666"),
                     BlockMenuItem(id: "7",
                                   panelId: "1",
                                   text: "7777")]

        var blockMenuModel = BlockMenuViewModel(isIPad: true,
                                                data: items)
        blockMenuModel.menuWidth = 315
        var heights = blockMenuModel.countItemHeight(itemWidth: 96)

        XCTAssertTrue(3 == heights.count)

        blockMenuModel = BlockMenuViewModel(isIPad: true,
                                            data: items)
        blockMenuModel.menuWidth = 375
        heights = blockMenuModel.countItemHeight(itemWidth: 69)
        XCTAssertTrue(2 == heights.count)


        blockMenuModel = BlockMenuViewModel(isIPad: false,
                                            data: items)
        blockMenuModel.menuWidth = 422
        heights = blockMenuModel.countItemHeight(itemWidth: 56)

        XCTAssertTrue(1 == heights.count)
    }
}
