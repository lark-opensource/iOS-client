//
//  RustMeticsExtension.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/4/22.
//  

import Foundation
import LarkRustHTTP

struct RustMetricsHandle {
    static func handle(rustMetrics: [RustHttpMetrics]) -> [String: Any] {
        guard !rustMetrics.isEmpty else { return [:] }
        let dnsInterval = rustMetrics.map { $0.dnsCost }.reduce(0, +)
        let tlsInterval = rustMetrics.map { $0.dnsCost }.reduce(0, +)
        let connectionInterval = rustMetrics.map { $0.connectionCost }.reduce(0, +)
        let dict: [String: Any] = [
            //            "docs_net_redirectCount": self.redirectCount, //重定向次数
            "docs_net_transactionMetricsCount": rustMetrics.count, // 有几次返回
            "docs_net_netTransactionCount": rustMetrics.filter({ $0.resourceFetchType == .networkLoad }).count, //有几次网络的返回
            "docs_net_dnsInterval": (dnsInterval > 0 ? dnsInterval : -1) * 1000, //dns 查询时间
            "docs_net_connectionEstablishInterval": (connectionInterval > 0 ? connectionInterval : -1) * 1000, //连接建立时间
            "docs_net_tlsInterval": (tlsInterval > 0 ? tlsInterval : -1) * 1000 //tls 握手时间
        ]
        return dict
    }
}

extension URLSessionTask {
    var rustMetricsDict: [String: Any] {
        return RustMetricsHandle.handle(rustMetrics: rustMetrics)
    }
}


extension DocsInternalBaseRequest {
    var rustMetricsDict: [String: Any] {
        return RustMetricsHandle.handle(rustMetrics: rustMetrics)
    }
}
