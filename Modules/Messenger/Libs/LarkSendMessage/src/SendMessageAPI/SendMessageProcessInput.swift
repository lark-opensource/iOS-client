//
//  SendMessageProcessInput.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/19.
//

import Foundation
import FlowChart // FlowChartInput
import LarkModel // Message

public protocol SendMessageModelProtocol {
}

public struct SendMessageProcessInput<M: SendMessageModelProtocol>: FlowChartInput {
    /// FlowChartInput协议要求，FlowChart内部会在Process执行过程中往extraInfo写数据
    public var extraInfo: [String: String] = [:]
    var context: APIContext?
    /// 发送不同消息类型，可以指定不同的范型M
    var model: M
    var rootId: String?
    var parentId: String?
    /// 回调发送状态
    var stateHandler: ((SendMessageState) -> Void)?
    var parentMessage: LarkModel.Message?
    /// 端上、Rust创建的假消息
    var message: LarkModel.Message?
    /// 多选发送图片的时候使用一个串行队列去发送，这里用SerialToken来标记
    var multiSendSerialToken: UInt64?
    /// 目前发图速度太快,临时通过 delay 限制频率 > 10ms 避免图片乱序
    var multiSendSerialDelay: TimeInterval?
    /// 封装埋点逻辑
    var sendMessageTracker: SendMessageTrackerProtocol?
    /// 是否是端上创建假消息上屏
    var useNativeCreate: Bool = false
    /// 话题形式回复
    var replyInThread: Bool = false
    /// 图片编码、视频转码等耗时，埋点使用
    var processCost: TimeInterval?
    /// 定时发送的时间，默认为空
    var scheduleTime: Int64?
}
