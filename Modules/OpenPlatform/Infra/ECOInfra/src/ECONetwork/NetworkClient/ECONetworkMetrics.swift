//
//  ECONetworkMetrics.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/14.
//

import Foundation
@objcMembers
open class ECONetworkMetrics: NSObject, ECONetworkMetricsProtocol {
    /// DNS查询解析耗时, 单位ms
    var dns: Int = 0
    /// TCP握手耗时, 单位ms
    var tcp: Int  = 0
    /// SSL握手耗时, 单位ms
    var ssl: Int  = 0
    /// 从连接建立完成, 到请求数据发送完毕, 单位ms
    var send: Int  = 0
    /// 首包耗时, 从发送完成到接受到首位数据, 单位ms
    var wait: Int  = 0
    /// 响应(header+body)完全接收耗时, 单位ms
    var receive: Int  = 0
    /// 是否复用连接
    var reuseConnect : Bool = false
    /// 请求时间
    var requestTime: Int  = 0
    
    init(with URLMetrics: URLSessionTaskTransactionMetrics) {
        super.init()
        self.updateMetrics(from: URLMetrics)
    }
    
    static func getDuration(start: Date?, end: Date?) -> Int {
        guard let start = start, let end = end else { return 0 }
        let result = (end.timeIntervalSince1970 - start.timeIntervalSince1970) * 1000
        return Int(result)
    }
    
    func updateMetrics(from taskMetrics: URLSessionTaskTransactionMetrics) {
        dns = Self.getDuration(
            start: taskMetrics.domainLookupStartDate,
            end: taskMetrics.domainLookupEndDate
        )
        tcp = Self.getDuration(
            start: taskMetrics.connectStartDate,
            end: taskMetrics.secureConnectionStartDate
        )
        ssl = Self.getDuration(
            start: taskMetrics.secureConnectionStartDate,
            end: taskMetrics.secureConnectionEndDate
        )
        send = Self.getDuration(
            start: taskMetrics.requestStartDate,
            end: taskMetrics.requestEndDate
        )
        wait = Self.getDuration(
            start: taskMetrics.requestEndDate,
            end: taskMetrics.responseStartDate
        )
        receive = Self.getDuration(
            start: taskMetrics.responseStartDate,
            end: taskMetrics.responseEndDate
        )
        requestTime = Self.getDuration(
            start: taskMetrics.requestStartDate,
            end: taskMetrics.requestEndDate
        )
        reuseConnect = taskMetrics.isReusedConnection
    }
    
    //TODO: 目前项目中有什么现成的 class -> dict 工具
    func toDictionary() -> [String: Any] {
        return [
            "dns": dns,
            "tcp": tcp,
            "ssl": ssl,
            "send": send,
            "wait": wait,
            "receive": receive,
            "reuseConnect": reuseConnect,
            "requestTime": requestTime
        ]
    }
}
