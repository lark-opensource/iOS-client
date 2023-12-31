//
//  ShareOption+Ext.swift
//  Calendar
//
//  Created by zhuheng on 2021/7/12.
//

import Foundation
import RustPB
import CalendarFoundation

extension CalendarExtension where BaseType == Rust.ShareOption {
    var shareOptionInfo: String {
        switch base {
        /// 未知的; 私有的，不可被订阅
        case .unknownShareOpt, .shareOptPrivate: // = 5
            return I18n.Calendar_Share_Private_Option
        /// 可被订阅，只可查看忙闲
        case .shareOptFreeBusyReader: // = 10
            return I18n.Calendar_Share_Guest_Option
        /// 可被订阅，可以查看详情
        case .shareOptReader: // = 15
            return I18n.Calendar_Share_Follower_Option
        /// 可被订阅，拥有该权限的共享成员可以编辑日历及日程信息
        case .shareOptWriter: // = 20
            return I18n.Calendar_Share_Editor_Option
        /// 可被订阅，拥有该权限的共享成员：1.拥有WRITER权限，2.可以设置日历共享成员
        case .shareOptOwner: // = 25
            return I18n.Calendar_Share_Administrator_Option
        @unknown default:
            return ""
        }
    }

    var shareOptionDescription: String {
        switch base {
        /// 未知的; 私有的
        case .unknownShareOpt:
            return I18n.Calendar_Share_OnlyBusyFree
        /// 不可被订阅
        case .shareOptPrivate:
            return I18n.Calendar_Share_CantViewCalendar
        /// 可被订阅，只可查看忙闲
        case .shareOptFreeBusyReader: // = 10
            return I18n.Calendar_Share_OnlyBusyFree
        /// 可被订阅，可以查看详情
        case .shareOptReader: // = 15
            return I18n.Calendar_Share_SeeAllEventDetails
        /// 可被订阅，拥有该权限的共享成员可以编辑日历及日程信息
        case .shareOptWriter: // = 20
            return I18n.Calendar_Share_CreateAndEditEvents
        /// 可被订阅，拥有该权限的共享成员：1.拥有WRITER权限，2.可以设置日历共享成员
        case .shareOptOwner: // = 25
            return I18n.Calendar_Share_ManageCalendar
        @unknown default:
            return ""
        }
    }

    var mappedAccessRole: Rust.CalendarAccessRole? {
        switch base {
        case .shareOptPrivate:
            return nil
        case .shareOptFreeBusyReader:
            return .freeBusyReader
        case .shareOptReader:
            return .reader
        case .shareOptWriter:
            return .writer
        case .shareOptOwner:
            return .owner
        @unknown default:
            assertionFailure("wrong share option !")
            return .freeBusyReader
        }
    }

    var shareOptionTracerDesc: String {
        switch base {
        case .shareOptPrivate: return "privacy"
        case .shareOptFreeBusyReader: return "visitor"
        case .shareOptReader: return "subscriber"
        @unknown default: return ""
        }
    }
}

extension Rust.ShareOption: CalendarExtensionCompatible {}

extension Rust.CalendarShareOptions {

    /// 默认权限设置-最高
    var innerDefaultTopOption: Rust.ShareOption {
        defaultTopOptionInCalendar
    }

    /// 默认权限设置
    var innerDefault: Rust.ShareOption {
        return defaultShareOption == .unknownShareOpt ? .shareOptReader : defaultShareOption
    }

    var externalDefaultTopOption: Rust.ShareOption {
        let crossTopShareOptionWithoutUnknown = crossTopShareOption == .unknownShareOpt ? .shareOptReader : crossTopShareOption
        return min(crossTopShareOptionWithoutUnknown, defaultTopOptionInCalendar)
    }

    var externalDefault: Rust.ShareOption {
        return crossDefaultShareOption == .unknownShareOpt ? .shareOptReader : crossDefaultShareOption
    }

    /// 出于安全考虑，日历侧限制到 reader
    var defaultTopOptionInCalendar: Rust.ShareOption {
        .shareOptReader
    }

    /// member 权限手动设置的最高（区别于 默认权限 的最高）
    /// - Parameters:
    ///   - memberType: 成员类型
    ///   - isExternal: 是否外部
    func topOption(of memberType: Rust.CalendarMember.CalendarMemberType, isExternal: Bool) -> Rust.ShareOption {
        if isExternal {
            let crossTopOption = crossTopShareOption == .unknownShareOpt ? .shareOptReader : crossTopShareOption
            return memberType == .individual ? crossTopOption : min(crossTopOption, .shareOptWriter)
        } else {
            return memberType == .individual ? .shareOptOwner : .shareOptWriter
        }
    }
}

extension Rust.ShareOption: Comparable {
    public static func < (lhs: Calendar_V1_Calendar.ShareOption, rhs: Calendar_V1_Calendar.ShareOption) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
