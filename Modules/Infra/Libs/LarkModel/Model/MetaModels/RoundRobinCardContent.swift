//
//  RoundRobinCardContent.swift
//  LarkModel
//
//  Created by tuwenbo on 2023/3/29.
//

import Foundation
import RustPB

public struct RoundRobinCardContent: MessageContent {

    public typealias AppointmentMessageRoundRobin = RustPB.Calendar_V1_AppointmentMessageRoundRobin
    public typealias AppointmentMessageStatus = RustPB.Calendar_V1_AppointmentMessageStatus
    public typealias AppointmentAction = RustPB.Calendar_V1_AppointmentAction
    public typealias Scheduler = RustPB.Calendar_V1_Scheduler
    public typealias AppointmentMessageExpiredReason = RustPB.Calendar_V1_AppointmentMessageExpiredReason

    private var pb: AppointmentMessageRoundRobin

    public init(pb: AppointmentMessageRoundRobin) {
        self.pb = pb
    }

    public var status: AppointmentMessageStatus { pb.status }  // 状态
    public var action: AppointmentAction { pb.action }  // 操作类型
    public var operatorID: String { pb.operatorID }  // 操作者ID
    public var schedulerID: String { pb.schedulerID }  // 活动ID
    public var schedulerType: Scheduler.TypeEnum { pb.schedulerType }  // 活动类型
    public var schedulerName: String { pb.schedulerName }  // 活动名称
    public var appointmentID: String { pb.appointmentID }  // 预约ID
    public var creatorID: String { pb.creatorID }  // 活动创建人UserID
    public var hostID: String { pb.hostID }  // 预约被预约人UserID
    public var guestName: String { pb.guestName }  // 预约访客名称
    public var guestEmail: String { pb.guestEmail }  // 预约访客email
    public var guestTimeZone: String { pb.timezone }  // 预约访客时区
    public var startTime: Int64 { pb.startTime }  // 预约开始时间戳
    public var endTime: Int64 { pb.endTime }  // 预约结束时间戳
    public var message: String { pb.message }  // 预约消息
    public var expiredReason: AppointmentMessageExpiredReason { pb.expiredReason } // 卡片失效原因
    public var hostName: String { pb.hostName }  // host的人名
    public var operatorName: String { pb.operatorName }  // 操作者名字
    public var isForwardMsg: Bool { pb.isForwardMsg }  // 是否是转发消息

    // 备用的 operatorName， operatorID 不存在时用 guestName 替代
    public var altOperatorName: String {
        operatorID.isEmpty ? guestName : operatorName
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) { }
}
