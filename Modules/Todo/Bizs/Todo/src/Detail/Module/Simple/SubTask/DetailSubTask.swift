//
//  DetailSubTask.swift
//  Todo
//
//  Created by baiyantao on 2022/7/30.
//

import Foundation
import LKCommonsLogging

struct DetailSubTask { }

// MARK: - View Config

extension DetailSubTask {
    static let emptyViewHeight: CGFloat = 48

    static let withTimeCellHeight: CGFloat = 64
    static let withoutTimeCellHeight: CGFloat = 40

    static let headerHeight: CGFloat = 42
    static let footerItemHeight: CGFloat = 36
    static let footerBottomOffset: CGFloat = 6
}

// MARK: - Logger

extension DetailSubTask {
    static let logger = Logger.log(DetailSubTask.self, category: "Todo.DetailSubTask")
}
