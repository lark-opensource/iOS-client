//
//  RedLinePositionInfo.swift
//  Calendar
//
//  Created by zhu chao on 2018/11/14.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation

struct RedlinePositionInfo {
    var indexPath: IndexPath
    var isUpSide: Bool
    var isFirst: Bool
    var isEvent: Bool// 会有今天一个日程都没有显示空的cell

    func indexPathToScrollsTop() -> IndexPath {
        if !isEvent || isFirst || !isUpSide {
            return indexPath
        }
        if indexPath.row > 0 {
            var desIndexPath = indexPath
            desIndexPath.row -= 1
            return desIndexPath
        }
        assertionFailureLog()
        return indexPath
    }
}
