//
//  WidgetKind+Definition.swift
//  LarkWidget
//
//  Created by Hayden Wang on 2022/4/14.
//

import Foundation
import WidgetKit

/// 小组件的唯一标识
public enum LarkWidgetKind {

    // 历史遗留小组件的唯一标识
    public static var todayWidget: String { "SmartWidget" }

    // “日历”小组件的唯一标识
    public static var calendarWidget: String { "CalendarWidget" }

    // “常用工具”小组件的唯一标识
    public static var utilityWidget: String { "UtilityWidget" }

    // “飞书任务”小组件的唯一标识
    public static var todoWidget: String { "TodoWidget" }

    // 小号“飞书日历”小组件的唯一标识
    public static var smallDocsWidget: String { "SmallDocsWidget" }

    // 中号“飞书日历”小组件的唯一标识
    public static var mediumDocsWidget: String { "MediumDocsWidget" }
}

public struct LarkWidgetTypes: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let todayWidget       = LarkWidgetTypes(rawValue: 1 << 0)
    public static let calendarWidget 	= LarkWidgetTypes(rawValue: 1 << 1)
    public static let utilityWidget     = LarkWidgetTypes(rawValue: 1 << 2)
    public static let todoWidget        = LarkWidgetTypes(rawValue: 1 << 3)
    public static let smallDocsWidget   = LarkWidgetTypes(rawValue: 1 << 4)
    public static let mediumDocsWidget  = LarkWidgetTypes(rawValue: 1 << 5)

    public static let all: LarkWidgetTypes = [
        .todayWidget,
        .calendarWidget,
        .utilityWidget,
        .todoWidget,
        .smallDocsWidget,
        .mediumDocsWidget
    ]
}

public enum LarkWidgetManager {

    public static func reloadWidgets(ofType types: LarkWidgetTypes) {
        guard #available(iOS 14, *) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if types == .all {
                WidgetCenter.shared.reloadAllTimelines()
                return
            }
            if types.contains(.todayWidget) {
                WidgetCenter.shared.reloadTimelines(ofKind: LarkWidgetKind.todayWidget)
            }
            if types.contains(.calendarWidget) {
                WidgetCenter.shared.reloadTimelines(ofKind: LarkWidgetKind.calendarWidget)
            }
            if types.contains(.utilityWidget) {
                WidgetCenter.shared.reloadTimelines(ofKind: LarkWidgetKind.utilityWidget)
            }
            if types.contains(.todoWidget) {
                WidgetCenter.shared.reloadTimelines(ofKind: LarkWidgetKind.todoWidget)
            }
            if types.contains(.smallDocsWidget) {
                WidgetCenter.shared.reloadTimelines(ofKind: LarkWidgetKind.smallDocsWidget)
            }
            if types.contains(.mediumDocsWidget) {
                WidgetCenter.shared.reloadTimelines(ofKind: LarkWidgetKind.mediumDocsWidget)
            }
        }
    }

    @available(iOS 14, *)
    public static func checkWidgetExistence(completion: @escaping (LarkWidgetTypes, [WidgetInfo]?, Error?) -> Void) {
        WidgetCenter.shared.getCurrentConfigurations { result in
            switch result {
            case .success(let infoList):
                var existTypes: LarkWidgetTypes = []
                var existKinds = infoList.map { $0.kind }
                if existKinds.contains(LarkWidgetKind.todayWidget) {
                    existTypes.insert(.todayWidget)
                }
                if existKinds.contains(LarkWidgetKind.calendarWidget) {
                    existTypes.insert(.calendarWidget)
                }
                if existKinds.contains(LarkWidgetKind.utilityWidget) {
                    existTypes.insert(.utilityWidget)
                }
                if existKinds.contains(LarkWidgetKind.todoWidget) {
                    existTypes.insert(.todoWidget)
                }
                if existKinds.contains(LarkWidgetKind.smallDocsWidget) {
                    existTypes.insert(.smallDocsWidget)
                }
                if existKinds.contains(LarkWidgetKind.mediumDocsWidget) {
                    existTypes.insert(.mediumDocsWidget)
                }
                completion(existTypes, infoList, nil)
            case .failure(let error):
                completion([], nil, error)
            }
        }
    }
}
