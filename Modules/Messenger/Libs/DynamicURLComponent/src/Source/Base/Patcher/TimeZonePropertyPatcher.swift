//
//  TimeZonePropertyPatcher.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/5/24.
//

import Foundation
import RustPB

struct TimeZonePropertyPatcher: PropertyPatcher {
    static func patch(base: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                      data: Basic_V1_URLPreviewPropertyData) -> Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty {
        assert(data.type == .timeZone, "type unmatched!")

        var timeZone = base?.timeZone ?? .init()
        let baseTimeZone = base?.timeZone ?? .init()
        data.previewPropertyData.forEach { key, value in
            guard let attr = Basic_V1_ComponentAttribute(rawValue: Int(key)) else { return }
            switch attr {
            case .timeZoneType: timeZone.timeZoneType = .init(rawValue: Int(value.i32)) ?? baseTimeZone.timeZoneType
            case .formatType: timeZone.formatType = .init(rawValue: Int(value.i32)) ?? baseTimeZone.formatType
            case .timePrecisionType: timeZone.timePrecisionType = .init(rawValue: Int(value.i32)) ?? baseTimeZone.timePrecisionType
            case .timeStyle: timeZone.timeStyle = .init(rawValue: Int(value.i32)) ?? baseTimeZone.timeStyle
            case .datePrecisionType: timeZone.datePrecisionType = .init(rawValue: Int(value.i32)) ?? baseTimeZone.datePrecisionType
            case .dateStatusType: timeZone.dateStatusType = .init(rawValue: Int(value.i32)) ?? baseTimeZone.dateStatusType
            case .startTimeStamp: timeZone.startTimeStamp = value.i64
            case .endTimeStamp: timeZone.endTimeStamp = value.i64
            case .enableGmt: timeZone.enableGmt = value.b
            @unknown default: return
            }
        }
        return .timeZone(timeZone)
    }
}
