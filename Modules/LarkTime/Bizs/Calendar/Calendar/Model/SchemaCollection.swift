//
//  SchemaCollection.swift
//  Calendar
//
//  Created by 张威 on 2020/4/12.
//

import Foundation
import LarkFoundation

// MARK: Schema Collection

extension Rust.SchemaCollection {

    func schemaEntity(forName uniqueName: String) -> Rust.SchemaEntity? {
        return entitySchemas.first(where: { $0.uniqueName == uniqueName })
    }

}

// MARK: Schema Keys

extension Rust.SchemaCollection {

    struct SchemaKey {
        var name: String
    }

    func schemaEntity(forKey key: SchemaKey) -> Rust.SchemaEntity? {
        return schemaEntity(forName: key.name)
    }

}

extension Rust.SchemaCollection.SchemaKey {

    static func named(_ name: String) -> Self {
        return Self(name: name)
    }

}

// MARK: 会议室

extension Rust.SchemaCollection.SchemaKey {
    /// 审批类会议室
    static let approvalTypeKey = named("ExternalAppApproval")

    /// 条件审批类会议室
    static let conditionalApprovalTypeKey = named("ExternalAppConditionalApproval")
}

extension Rust.SchemaCollection {

     /*
     https://meego.feishu.cn/larksuite/issue/detail/3209202?#detail
     1. 目前PC和Android都使用entitySchemas结构里面ExternalAppConditionalApproval和AppConditionalApproval
     来判断一个会议室是否是审批会议室，但iOS是根据bizData里面的approveInfo判断的，这个存在偏差，在会议室超管创建出来的某些日程会出问题。
     */
    var hasApprovalKey: Bool {
        schemaEntity(forKey: .approvalTypeKey) != nil
    }

    var hasConditionalApprovalKey: Bool {
        schemaEntity(forKey: .conditionalApprovalTypeKey) != nil
    }

    var approvalLink: String? {
        if hasApprovalKey {
            return schemaEntity(forKey: .approvalTypeKey)?.appLink
        } else if hasConditionalApprovalKey {
            return schemaEntity(forKey: .conditionalApprovalTypeKey)?.appLink
        } else {
            return nil
        }
    }
}

// MARK: 日程

extension Rust.SchemaCollection.SchemaKey {
    // 编辑页
    static let summary = named("Title")
    static let date = named("Time")
    static let meetingRoom = named("MeetingRoom")
    static let location = named("Location")
    static let color = named("Color")
    static let notes = named("Description")

    // 公共
    static let attendee = named("Attendee")
    static let guestPermission = named("Attendee")
    static let rrule = named("Rrule")
    static let reminder = named("Reminder")
    static let calendar = named("Calendar")
    static let freeBusy = named("FreeBusy")
    static let visibility = named("Scope")
    static let delete = named("DeleteIcon")

    // 详情页
    static let organizerOrCreater = named("OrganizerOrCreator")
    static let rsvp = named("RSVP")
    static let rsvpReply = named("RsvpReply")
    static let meetingChat = named("MeetingChatIcon")
    static let meetingVideo = named("MeetingVideo")
    static let meetingMinutes = named("MeetingMinutesIcon")
    static let share = named("ForwardIcon")
    static let transfer = named("TransferIcon")
    static let edit = named("EditIcon")
    static let report = named("ReportIcon")
}

internal func f_schemaCompatibleLevel(_ schemaCollection: Rust.SchemaCollection?) -> Rust.IncompatibleLevel? {
    // 将版本号转为Int方便与最低兼容版本比较，若版本号规则修改，此方法应一并修改
    // 例如：3.29.0-alpha(String) -> 329(Int)
    var computeCurrentVersion: Int? {
        let version = LarkFoundation.Utils.appVersion
        var result = ""
        var count = 0
        for c in version {
            if c == "." {
                count += 1
                if count == 2 {
                    break
                }
                continue
            }
            result.append(c)
        }
        // 如果次版本为一位数，例如3.2，需要补充一个0
        // 例如： 3.2.0-alpha(String) -> 302(Int)
        if result.count == 2 {
            result.insert("0", at: result.index(before: result.endIndex))
        }
        return Int(result)
    }

    guard
        let schemaCollection = schemaCollection,
        schemaCollection.hasCompatibility,
        schemaCollection.compatibility.hasMinimumCompatibilityVer,
        let currentVersion = computeCurrentVersion else {
        return nil
    }

    if currentVersion >= schemaCollection.compatibility.minimumCompatibilityVer {
        return nil
    } else {
        return schemaCollection.compatibility.incompatibleLevel
    }
}
