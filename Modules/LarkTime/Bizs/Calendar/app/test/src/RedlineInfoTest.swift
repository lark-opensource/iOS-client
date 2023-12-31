//
//  RedlineInfoTest.swift
//  CalendarTests
//
//  Created by zhu chao on 2018/11/14.
//  Copyright © 2018 EE. All rights reserved.
//

import XCTest
@testable import Calendar

class RedlineInfoTest: XCTestCase {

    func testExample() {
        //列表视图今天日程为空case
        var indexPath = IndexPath(row: 0, section: 0)
        var position = RedlinePositionInfo(indexPath: indexPath, isUpSide: false, isFirst: true, isEvent: false)
        XCTAssertEqual(indexPath, position.indexPathToScrollsTop())

        //列表视图月视图今天日程不为空但红线位于第一个日程
        indexPath = IndexPath(row: 0, section: 0)
        position = RedlinePositionInfo(indexPath: indexPath, isUpSide: true, isFirst: true, isEvent: true)
        XCTAssertEqual(indexPath, position.indexPathToScrollsTop())

        //列表视图月视图所有日程都已经结束
        indexPath = IndexPath(row: 5, section: 0)
        position = RedlinePositionInfo(indexPath: indexPath, isUpSide: false, isFirst: false, isEvent: true)
        XCTAssertEqual(indexPath, position.indexPathToScrollsTop())

        //红线落在了中间的某个日程上面
        indexPath = IndexPath(row: 5, section: 0)
        position = RedlinePositionInfo(indexPath: indexPath, isUpSide: true, isFirst: false, isEvent: true)
        XCTAssertEqual(IndexPath(row: indexPath.row - 1, section: 0), position.indexPathToScrollsTop())
    }
}
