//
//  AdditionalTimeZoneModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/18.
//

import Foundation
import LKCommonsLogging

enum AdditionalTimeZoneCellType {
    case timeZoneCell(String)
    case addTimeZoneCell(String)
}

protocol AdditionalTimeZoneViewDataType {
    var type: AdditionalTimeZoneCellType { get }
}

struct AdditionalTimeZoneViewData: AdditionalTimeZoneViewDataType {
    let type: AdditionalTimeZoneCellType = .timeZoneCell(AdditionalTimeZoneCell.identifier)
    var title: String
    var subTitle: String
    var identifier: String
    var isSelectable: Bool = true
    var showBottomBorder: Bool = false
    var deleteAction: ((UITableViewCell) -> Void)
}

struct AddAdditionalTimeZoneViewData: AdditionalTimeZoneViewDataType {
    var type: AdditionalTimeZoneCellType = .addTimeZoneCell(AddAdditionanalTimeZoneCell.identifier)
    var clickAction: (() -> Void)?
}

struct LocalTimeZoneViewData {
    var title: String
    var subTitle: String
}

enum AdditionalTimeZoneUIStyle {
    // 视图页辅助时区列表
    enum DayScene {
        static let localTimeZoneHeight: CGFloat = 70
        static let additionalTimeZoneSwitchHeight: CGFloat = 52
        static let additonalTimeZoneCellHeight: CGFloat = 74
        static let addAdditionalTimeZoneHeight: CGFloat = 48
        static let addAdditionalTimeZoneListTopMargin: CGFloat = 14
        static let preferredHeight: CGFloat = 380
    }

    // 设置页辅助时区列表
    enum Setting {
        static let additonalTimeZoneCellHeight: CGFloat = 70
        static let addAdditionalTimeZoneHeight: CGFloat = 48
    }
}

enum AdditionalTimeZone {
    static let logger = Logger.log(EventEdit.self, category: "lark.calendar.additiontimezone")

    static func logUnreachableLogic(file: String = #fileID,
                                    function: String = #function,
                                    line: Int = #line) {
        assertionFailure("should not excute code!")
        logger.warn("should not excute code!")
    }

    static let maxAdditionalTimeZones = 10
}
