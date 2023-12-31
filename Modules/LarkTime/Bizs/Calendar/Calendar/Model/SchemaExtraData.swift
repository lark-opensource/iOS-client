//
//  SchemaExtraData.swift
//  Calendar
//
//  Created by 张威 on 2020/10/21.
//

import Foundation
import CalendarFoundation
import RustPB

extension Rust.SchemaExtraData: CalendarExtensionCompatible { }

extension CalendarExtension where BaseType == Rust.SchemaExtraData {

    /// 具体的审批类型 （无需审批、条件审批、全量审批）
    enum ApprovalType: Equatable {
        case none
        case conditional(trigger: Int64)
        case global

        /// 触发条件审批的最短会议时长（相等也算） nil 表示无需判断条件审批 但不代表无需审批
        var conditionalApprovalTriggerDuration: Int64? {
            if case let .conditional(trigger) = self { return trigger }
            return nil
        }

        /// 判断日程的时长是否触发条件审批
        /// - Parameter duration: 日程时长
        /// - Returns: 是否触发条件审批
        /// - Note: 对于全量审批会返回 false
        func shouldTriggerApprovalOff(duration: Int64) -> Bool {
            guard case let .conditional(trigger) = self else { return false }
            return trigger <= duration
        }
    }

    /// 在 SchemaExtraData 上抽象一层 用以区分无需审批/条件审批/全量审批
    var approvalType: ApprovalType {
        if resourceApprovalInfo != nil {
            if let trigger = conditionalApprovalTriggerDuration {
                return .conditional(trigger: trigger)
            } else {
                return .global
            }
        } else if approvalRequest != nil {
            return .global
        } else {
            return .none
        }
    }

    /// 触发条件审批的最短会议时长（相等也算） nil 表示无需判断条件审批 但不代表无需审批
    var conditionalApprovalTriggerDuration: Int64? {
        guard resourceApprovalInfo?.hasTrigger ?? false else { return nil }
        return resourceApprovalInfo?.trigger.durationTrigger
    }

    // 会议室审批人信息（移动端正常情况下用不到这个字段）
    var resourceApprovalInfo: Rust.ApprovalInfo? {
        base.bizData.first(where: { $0.type == .resourceApprovalInfo })?.resourceApprovalInfo
    }

    /// 会议室审批的相关字段（申请会议室理由、申请人、审批人）通常是作为端上的 input 传给 server
    var approvalRequest: Rust.ApprovalRequest? {
        base.bizData.first(where: { $0.type == .approvalRequest })?.approvalRequest
    }

    /// 会议室预定策略（单次会议最长时长、最早可提前预定时间、每日最早可预定时间、每日最晚可预定时间、时区）
    var resourceStrategy: Rust.ResourceStrategy? {
        base.bizData.first(where: { $0.type == .resourceStrategy })?.resourceStrategy
    }

    /// 会议室计划占用（开始时间、结束时间、联系人、占用原因）
    var resourceRequisition: Rust.ResourceRequisition? {
        base.bizData.first(where: { $0.type == .resourceRequisition })?.resourceRequisition
    }

    /// 会议室预定表单（表单问题、联系人、最晚表单提交时间）
    var resourceCustomization: Rust.ResourceCustomization? {
        base.bizData.first(where: { $0.type == .resourceCustomization })?.resourceCustomization
    }
}
