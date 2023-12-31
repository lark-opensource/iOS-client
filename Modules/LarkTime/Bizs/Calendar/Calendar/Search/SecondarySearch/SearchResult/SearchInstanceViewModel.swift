//
//  SearchInstanceViewModel.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/11.
//

import UIKit
import Foundation

protocol SearchInstanceViewContent {
    /// 跨天日程有这个
    var timeDes: String { get }
    var timeText: String { get }
    var titleText: String { get }
    var locationText: String { get }
    var attendeeText: String { get }
    var descText: String { get }

    var highlightStrings: HighlightTexts { get }
    var highlightedBGColor: UIColor { get }

    var dashedBorderColor: UIColor? { get }
    var backgroundColor: UIColor { get }
    var textColor: UIColor { get }

    var indicatorInfo: (color: UIColor, isStripe: Bool)? { get }

    var hasStrikethrough: Bool { get }

    var stripBackgroundColor: UIColor? { get }
    var stripLineColor: UIColor? { get }

    var startDate: Date { get }
    var endDate: Date { get }
    var isCoverPassEvent: Bool { get }

    var maskOpacity: Float { get }
    var currentDayCount: Int { get }
    var totalDayCount: Int { get }
}
