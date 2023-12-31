//
//  TracerV2.swift
//  Calendar
//
//  Created by Rico on 2021/6/25.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging

/// 新埋点框架（View - Click - Target）类
struct CalendarTracerV2 {

    private static let logger = Logger.log(CalendarTracerV2.self, category: "calendar.CalendarTracerV2")

    static func trace(event: String, params: [String: Any]) {
        Tracker.post(TeaEvent(event, category: nil, params: params))
        logger.info("CalendarTracerV2: eventId: \(event), params: \(params)")
    }

    // 跟 traceView 一样，只是后缀是自由的
    static func trace<E: TracerEvent>(event: E.Type, commonParam: [String: Any] = [:], paramBuilder: ((ParamRefer<E.ViewParam>) -> Void)? = nil) {
        let param: [String: Any]

        if let builder = paramBuilder {
            let paramRef = ParamRefer<E.ViewParam>(value: event.defaultViewParam)
            builder(paramRef)
            param = paramRef.getParamDic()
        } else {
            param = [:]
        }
        trace(event: event.eventName, params: param.merging(commonParam, uniquingKeysWith: { $1 }))
    }

    static func traceView<E: TracerEvent>(event: E.Type, commonParam: [String: Any] = [:], paramBuilder: ((ParamRefer<E.ViewParam>) -> Void)? = nil) {
        let eventName = event.eventName.appendViewIfNeeded()
        let param: [String: Any]

        if let builder = paramBuilder {
            let paramRef = ParamRefer<E.ViewParam>(value: event.defaultViewParam)
            builder(paramRef)
            param = paramRef.getParamDic()
        } else {
            param = [:]
        }
        trace(event: eventName, params: param.merging(commonParam, uniquingKeysWith: { $1 }))
    }

    static func traceClick<E: TracerEvent>(event: E.Type, commonParam: [String: Any] = [:], paramBuilder: (ParamRefer<E.ClickParam>) -> Void) {
        let eventName = event.eventName.appendClickIfNeeded()
        let param: [String: Any]

        let paramRef = ParamRefer<E.ClickParam>(value: event.defaultClickParam)
        paramBuilder(paramRef)
        param = paramRef.getParamDic()

        trace(event: eventName, params: param.merging(commonParam, uniquingKeysWith: { $1 }))
    }
}

extension TracerEvent {

    /// 显式传入通参，推荐使用此函数，适用于类似 view 但不绑定 _view 后缀的埋点，调用方可自己指定完整的埋点名称，比如 cal_toast_status
    /// - Parameter paramBuilder: 对应模块埋点的View参数结构
    static func trace(commonParam: CommonParamData, paramBuilder: ((ParamRefer<Self.ViewParam>) -> Void)? = nil) {
        CalendarTracerV2.trace(event: self, commonParam: commonParam.toTracerFlatDic, paramBuilder: paramBuilder)
    }

    /// View埋点
    /// - Parameter paramBuilder: 对应模块埋点的View参数结构
    static func traceView(paramBuilder: ((ParamRefer<Self.ViewParam>) -> Void)? = nil) {
        CalendarTracerV2.traceView(event: self, paramBuilder: paramBuilder)
    }

    /// View埋点
    /// 显式传入通参，推荐使用此函数
    /// - Parameter paramBuilder: 对应模块埋点的View参数结构
    static func traceView(commonParam: CommonParamData, paramBuilder: ((ParamRefer<Self.ViewParam>) -> Void)? = nil) {
        CalendarTracerV2.traceView(event: self, commonParam: commonParam.toTracerFlatDic, paramBuilder: paramBuilder)
    }

    /// Click埋点
    /// - Parameter paramBuilder: 对应模块埋点的Click参数结构
    static func traceClick(paramBuilder: (ParamRefer<Self.ClickParam>) -> Void) {
        CalendarTracerV2.traceClick(event: self, paramBuilder: paramBuilder)
    }

    /// Click埋点
    /// 显式传入通参，推荐使用此函数
    /// - Parameter paramBuilder: 对应模块埋点的Click参数结构
    static func traceClick(commonParam: CommonParamData, paramBuilder: (ParamRefer<Self.ClickParam>) -> Void) {
        CalendarTracerV2.traceClick(event: self, commonParam: commonParam.toTracerFlatDic, paramBuilder: paramBuilder)
    }
    
    static func normalTrackClick(_ builder: () -> [String: Any]) {
        let eventName = Self.eventName.appendClickIfNeeded()
        let param: [String: Any] = builder()
        CalendarTracerV2.trace(event: eventName, params: param)
    }
    
    static func normalTrackView(_ builder: () -> [String: Any]) {
        let eventName = Self.eventName.appendViewIfNeeded()
        let param: [String: Any] = builder()
        CalendarTracerV2.trace(event: eventName, params: param)
    }
}

extension CalendarTracerV2 {
    /// 日程详情页 VC部分
    struct EventDetailVideoMeeting: TracerEvent {
        static let eventName = "cal_event_detail_meeting"

        static var defaultViewParam: ViewParams {
            ViewParams()
        }

        static var defaultClickParam: ClickParams {
            ClickParams()
        }

        final class ViewParams: ViewParamType {
            var base = BaseViewParams()
            var is_in_meeting = ""
        }

        final class ClickParams: ClickParamType {
            var base = BaseClickParams()
        }
    }
}
