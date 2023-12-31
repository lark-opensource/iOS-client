//
//  TimeZoneComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/5/24.
//

import UIKit
import Foundation
import RustPB
import LarkContainer
import TangramComponent
import LarkSDKInterface
import TangramUIComponent
import LarkTimeFormatUtils

public typealias FormatType = Basic_V1_URLPreviewComponent.TimeZoneProperty.FormatType
public typealias TimePrecisionType = Basic_V1_URLPreviewComponent.TimeZoneProperty.TimePrecisionType
public typealias TimeStyle = Basic_V1_URLPreviewComponent.TimeZoneProperty.TimeStyle
public typealias DatePrecisionType = Basic_V1_URLPreviewComponent.TimeZoneProperty.DatePrecisionType
public typealias DateStatusType = Basic_V1_URLPreviewComponent.TimeZoneProperty.DateStatusType

// https://bytedance.feishu.cn/docx/doxcnmFq7WuwQMmQhS79vqAEBmd
public final class TimeZoneComponentViewModel: RenderComponentBaseViewModel {
    private lazy var _component: UILabelComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    @ScopedInjectedLazy public var userGeneralSettings: UserGeneralSettings?

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let timeZone = property?.timeZone ?? .init()
        let props = buildComponentProps(property: timeZone, style: style)
        _component = UILabelComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.TimeZoneProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> UILabelComponentProps {
        let props = UILabelComponentProps()
        props.text = timeZone(property: property)
        if let font = style.tcFont {
            props.font = font
        }
        if let textColor = style.tcTextColor {
            props.textColor = textColor
        }
        // 和UX确认，默认多行显示，不支持配置
        props.numberOfLines = 0
        return props
    }

    private func timeZone(property: Basic_V1_URLPreviewComponent.TimeZoneProperty) -> String {
        let startDate = Date(timeIntervalSince1970: TimeInterval(property.startTimeStamp))
        let options = timeZoneOptions(property: property)

        switch property.timeZoneType {
        case .meridiem:
            return TimeFormatUtils.formatMeridiem(from: startDate, with: options)
        case .week:
            return TimeFormatUtils.formatWeekday(from: startDate, with: options)
        case .month:
            return TimeFormatUtils.formatMonth(from: startDate, with: options)
        case .time:
            return TimeFormatUtils.formatTime(from: startDate, with: options)
        case .date:
            return TimeFormatUtils.formatDate(from: startDate, with: options)
        case .fullDate:
            return TimeFormatUtils.formatFullDate(from: startDate, with: options)
        case .dateTime:
            return TimeFormatUtils.formatDateTime(from: startDate, with: options)
        case .fullDateTime:
            return TimeFormatUtils.formatFullDateTime(from: startDate, with: options)
        case .dateRange:
            let endDate = Date(timeIntervalSince1970: TimeInterval(property.endTimeStamp))
            return TimeFormatUtils.formatDateRange(startFrom: startDate, endAt: endDate, with: options)
        case .dateTimeRange:
            let endDate = Date(timeIntervalSince1970: TimeInterval(property.endTimeStamp))
            return TimeFormatUtils.formatDateTimeRange(startFrom: startDate, endAt: endDate, with: options)
        @unknown default: assertionFailure("unknown case")
        }
        return ""
    }

    private func timeZoneOptions(property: Basic_V1_URLPreviewComponent.TimeZoneProperty) -> Options {
        return Options(timeZone: TimeZone.current,
                       is12HourStyle: is12HourStyle(timeStyle: property.timeStyle),
                       shouldShowGMT: property.enableGmt,
                       timeFormatType: property.formatType.timeFormatType,
                       timePrecisionType: property.timePrecisionType.timePrecisionType,
                       datePrecisionType: property.datePrecisionType.datePrecisionType,
                       dateStatusType: property.dateStatusType.dateStatusType,
                       shouldRemoveTrailingZeros: false)
    }

    private func is12HourStyle(timeStyle: TimeStyle) -> Bool {
        switch timeStyle {
        case .default:
            return !(userGeneralSettings?.is24HourTime.value ?? true)
        case .by12Hour: return true
        case .by24Hour: return false
        @unknown default:
            assertionFailure("unknown case")
            return !(userGeneralSettings?.is24HourTime.value ?? true)
        }
    }
}

private extension FormatType {
    var timeFormatType: Options.TimeFormatType {
        switch self {
        case .short: return .short
        case .long: return .long
        @unknown default:
            assertionFailure("unknown case")
            return .short
        }
    }
}

private extension TimePrecisionType {
    var timePrecisionType: Options.TimePrecisionType {
        switch self {
        case .second: return .second
        case .minute: return .minute
        case .hour: return .hour
        @unknown default:
            assertionFailure("unknown case")
            return .second
        }
    }
}

private extension DatePrecisionType {
    var datePrecisionType: Options.DatePrecisionType {
        switch self {
        case .dayType: return .day
        case .monthType: return .month
        @unknown default:
            assertionFailure("unknown case")
            return .day
        }
    }
}

private extension DateStatusType {
    var dateStatusType: Options.DateStatusType {
        switch self {
        case .absolute: return .absolute
        case .relative: return .relative
        @unknown default:
            assertionFailure("unknown case")
            return .absolute
        }
    }
}
