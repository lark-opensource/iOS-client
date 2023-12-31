//
//  SheetInputKeyboardDetails.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/6/2.
//  

import SKFoundation
import UniverseDesignDatePicker

public enum SheetDateTimeKeyboardSubtype: String {
    case none = ""
    case date = "date"
    case dateTime = "datetime"
    case time = "time"
    case clear = "clear"
}

extension SheetDateTimeKeyboardSubtype {
    public var datePickerMode: UDWheelsStyleConfig.WheelModel {
        switch self {
        case .date:
            return .yearMonthDayWeek
        case .time:
            return .hourMinuteCenter
        case .dateTime:
            return .dayHourMinute()
        default:
            return .dayHourMinute()
        }
    }
    //swiftlint:disable comma
    public var formats: [String] {
        let dateStrings = ["yyyy-MM-dd", "MM-dd-yyyy", "dd-MM-yyyy",
                           "yy-MM-dd"  , "MM-dd-yy"  , "dd-MM-yy"  ,
                           "yyyy-M-dd" , "M-dd-yyyy" , "dd-M-yyyy" ,
                           "yyyy-MM-d" , "MM-d-yyyy" , "d-MM-yyyy" ,
                           "yy-M-dd"   , "M-dd-yy"   , "dd-M-yy"   ,
                           "yy-MM-d"   , "MM-d-yy"   , "d-MM-yy"   ,
                           "yyyy-M-d"  , "M-d-yyyy"  , "d-M-yyyy"  ,
                           "yy-M-d"    , "M-d-yy"    , "d-M-yy"    ]
        let timeStrings = ["HH:mm:ss", "HH:mm"  , "H:mm"   ,
                           "H:mm:ss" , "HH:m:ss", "HH:mm:s",
                           "H:m:ss"  , "H:mm:s" , "HH:m:s" ,
                           "H:m:s"]
        switch self {
        case .date: return dateStrings
        case .time: return timeStrings
        default:
            var dateAndTimeStrings = [String]()
            for date in dateStrings {
                for time in timeStrings {
                    dateAndTimeStrings.append("\(date) \(time)")
                }
            }
            return dateAndTimeStrings
        }
    }
    //swiftlint:enable comma
}

public struct SheetInputKeyboardDetails {
    public var mainKeyboard: BarButtonIdentifier = .systemText
    public var subKeyboard: SheetDateTimeKeyboardSubtype = .none
    public init(mainType: BarButtonIdentifier, subType: SheetDateTimeKeyboardSubtype) {
        mainKeyboard = mainType
        subKeyboard = subType
    }
}
