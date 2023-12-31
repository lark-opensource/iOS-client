//
//  ClientPerf.swift
//  LarkCore
//
//  Created by KT on 2019/9/16.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker

// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#
enum ExtraKey: String {
    // swiftlint:disable identifier_name
    case since_startup
    case since_latest_enter_foreground
    // swiftlint:enable identifier_name
}

/* Client Perf 打点
 https://bytedance.feishu.cn/space/doc/doccnE48d8T1Pz9bElDogDImzYf#6iZwmY
 */
public final class ClientPerf {
    public typealias Params = [String: String]
    public typealias Metric = [AnyHashable: Any]
    public typealias Category = [AnyHashable: Any]
    public static var shared = ClientPerf()

    private static let logger = Logger.log("perf")

    /// 单一事件打点
    /// - Parameter key: 事件key
    /// - Parameter params: 额外参数
    /// - Parameter time: 时间戳ms（不传默认当前时间戳）
    public func singleEvent(
        _ key: String,
        params: Params? = nil,
        time: TimeInterval? = nil,
        cost: Int64?, context: String? = nil,
        parentContext: String? = nil
    ) {
        self.printer(
            key: key,
            type: .signpost,
            params: params,
            time: time,
            cost: cost,
            context: context,
            parentContext: parentContext
        )
    }

    /// 连续事件打点 - [start]
    /// - Parameter key: 事件key
    /// - Parameter params: 额外参数
    /// - Parameter time: 时间戳ms（不传默认当前时间戳）
    public func startEvent(
        _ key: String,
        logid: String? = nil,
        params: Params? = nil,
        time: TimeInterval? = nil,
        context: String? = nil,
        parentContext: String? = nil
    ) {
        self.printer(
            key: key,
            type: .start,
            logid: logid,
            params: params,
            time: time,
            context: context,
            parentContext: parentContext
        )
    }

    /// 连续事件打点 - [end]
    /// - Parameter key: 事件key
    /// - Parameter params: 额外参数
    /// - Parameter time: 时间戳ms（不传默认当前时间戳）
    public func endEvent(
        _ key: String,
        logid: String? = nil,
        params: Params? = nil,
        time: TimeInterval? = nil,
        context: String? = nil,
        parentContext: String? = nil
    ) {
        self.printer(
            key: key,
            type: .end,
            logid: logid,
            params: params,
            time: time,
            context: context,
            parentContext: parentContext
        )
    }

    /// - Parameter service: 服务名
    /// - Parameter indentify: 同一服务内不同点标识符，同一时间段内同一服务可能存在多个点
    /// - Parameter logid: 本地日志使用，如果不打本地日志，可不传
    /// - Parameter params: 额外参数
    public func singleSlardarEvent(
        service: String,
        cost: CFTimeInterval,
        logid: String? = nil,
        metric: Metric? = nil,
        params: Params? = nil,
        category: Category? = nil) {
        let currentTimeStamp = CACurrentMediaTime() * 1_000
        let cost = Int64(cost)
        if logid != nil {
            self.printer(key: service, type: .signpost, logid: logid, params: params, time: nil, cost: cost)
        }
        var totalMetric: Metric = metric ?? Metric()
        totalMetric["latency"] = cost
        var totalExtra: Params = params ?? Params()
        totalExtra[ExtraKey.since_startup.rawValue] = "\(AppMonitor.getMillisecondSinceStartup(currentTimeStamp))"
        totalExtra[ExtraKey.since_latest_enter_foreground.rawValue] =
        "\(AppMonitor.getMillisecondSinceForeground(currentTimeStamp))"
        Tracker.post(SlardarEvent(name: service,
                                  metric: totalMetric,
                                  category: category ?? [:],
                                  extra: totalExtra))
    }

    /// - Parameter service: 服务名
    /// - Parameter indentify: 同一服务内不同点标识符，同一时间段内同一服务可能存在多个点
    /// - Parameter logid: 本地日志使用，如果不打本地日志，可不传
    public func startSlardarEvent(service: String, indentify: String = "", logid: String? = nil) {
        Tracker.start(token: service + indentify)
        if logid != nil {
            startEvent(service, logid: logid)
        }
    }

    /// - Parameter service: 服务名
    /// - Parameter indentify: 同一服务内不同点标识符，同一时间段内同一服务可能存在多个点
    /// - Parameter logid: 本地日志使用，如果不打本地日志，可不传
    /// - Parameter params: 额外参数
    public func endSlardarEvent(
        service: String,
        indentify: String = "",
        logid: String? = nil,
        metric: Metric? = nil,
        params: Params? = nil,
        category: Category? = nil
    ) {
        if logid != nil {
            endEvent(service, logid: logid)
        }
        guard let latency = Tracker.end(token: service + indentify) else { return }
        let currentTimeStamp = CACurrentMediaTime() * 1_000
        var totalMetric: Metric = metric ?? Metric()
        totalMetric["latency"] = CLongLong(round(latency.duration * 1_000))
        var totalExtra: Params = params ?? Params()
        totalExtra[ExtraKey.since_startup.rawValue] = "\(AppMonitor.getMillisecondSinceStartup(currentTimeStamp))"
        totalExtra[ExtraKey.since_latest_enter_foreground.rawValue] =
            "\(AppMonitor.getMillisecondSinceForeground(currentTimeStamp))"
        Tracker.post(SlardarEvent(name: service,
                                  metric: totalMetric,
                                  category: category ?? [:],
                                  extra: totalExtra))
    }

    private func printer(
        key: String,
        type: ClientPrefType,
        logid: String? = nil,
        params: Params? = nil,
        time: TimeInterval? = nil,
        cost: Int64? = nil,
        context: String? = nil,
        parentContext: String? = nil) {
        guard !key.isEmpty else { return }
        let tag = "perf"
        let message = "[\(tag)]" + keyWithPrefix(key) + type.rawValue + getArguments(time, cost, context, parentContext)
        ClientPerf.logger.info(logId: logid ?? "", message, params: params, tags: [tag])
    }

    @inline(__always)
    private func keyWithPrefix(_ key: String) -> String {
        return "[ios_\(key)]"
    }

    @inline(__always)
    private func getArguments(
        _ timeStamp: TimeInterval?,
        _ cost: Int64?,
        _ context: String?,
        _ parentContext: String?
    ) -> String {
        var args: [String] = []
        if let time = timeStamp {
            args.append("time=\(time)")
        }
        if let cost = cost {
            args.append("cost=\(cost)")
        }
        if let context = context {
            args.append("context=\(context)")
        }
        if let parentContext = parentContext {
            args.append("parent_context=\(parentContext)")
        }
        return args.joined(separator: ",")
    }
}

private enum ClientPrefType: String {
    case start = "[start]"
    case end = "[end]"
    case signpost = ""
}
