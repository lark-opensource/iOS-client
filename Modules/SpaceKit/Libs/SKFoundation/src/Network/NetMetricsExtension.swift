//
//  NetMetricsExtension.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/8.
//

import Foundation

extension URLSessionTaskTransactionMetrics {

    /// 是否来自网络的请求/返回
    var isFromNet: Bool {
        return resourceFetchType == .networkLoad || resourceFetchType == .serverPush
    }

    /// DNS 查询时间，如果没有这个步骤，返回nil
    var dnsLookUpInterval: TimeInterval? {
        if let dnsStart = domainLookupStartDate, let dnsEnd = domainLookupEndDate {
            return dnsEnd.timeIntervalSince(dnsStart)
        } else {
            return nil
        }
    }

    /// 连接建立时间（包括tls）
    var connectionEstablishInterval: TimeInterval? {
        if let connectStart = connectStartDate, let connectEnd = connectEndDate {
            return  connectEnd.timeIntervalSince(connectStart)
        } else {
            return nil
        }
    }

    /// tls 建立时间
    var tlsInterval: TimeInterval? {
        if let tlsStart = secureConnectionStartDate, let tlsEnd = secureConnectionEndDate {
            return tlsEnd.timeIntervalSince(tlsStart)
        } else {
            return nil
        }
    }

    /// 请求发出时间（从第一个字节发出，到最后一次字节发出）
    var requestInterval: TimeInterval? {
        if let requestStart = requestStartDate, let requestEnd = requestEndDate {
            return requestEnd.timeIntervalSince(requestStart)
        } else {
            return nil
        }
    }

    /// 最后一次请求字节发出，到第一个请求返回的时间
    var httpInterval: TimeInterval? {
        guard isFromNet else {
            return nil
        }
        if let responseStart = responseStartDate, let requestEnd = requestEndDate {
            return responseStart.timeIntervalSince(requestEnd)
        } else {
            return nil
        }
    }

    /// 收到第一个字节开始，到最后一个字节收到
    var responseInterval: TimeInterval? {
        if let fetchStart = responseStartDate, let responseEnd = responseEndDate {
            return responseEnd.timeIntervalSince(fetchStart)
        } else {
            return nil
        }
    }
}

extension URLSessionTaskMetrics: DocsNetTimeLine {
    var requestDuration: TimeInterval {
        return self.taskInterval.duration
    }
}

extension URLSessionTaskMetrics {

    /// 字典形式的表示
    var metricsDict: [String: Any] {
        let dict: [String: Any] = [
            "docs_net_redirectCount": self.redirectCount, //重定向次数
            "docs_net_transactionMetricsCount": self.transactionMetrics.count, // 有几次返回
            "docs_net_netTransactionCount": self.transactionMetrics.filter({ $0.isFromNet }).count, //有几次网络的返回
            "docs_net_dnsInterval": (self.dnsInterval ?? -1) * 1000, //dns 查询时间
            "docs_net_connectionEstablishInterval": (self.connectionEstablishInterval ?? -1) * 1000, //连接建立时间
            "docs_net_tlsInterval": (self.tlsInterval ?? -1) * 1000, //tls 握手时间
            "docs_net_requestInterval": (self.requestInterval ?? -1) * 1000, //发请求消耗的时间
            "docs_net_httpInterval": (self.httpInterval ?? -1) * 1000, //网络数据传输时间
            "docs_net_responseInterval": (self.responseInterval ?? -1) * 1000, // 接受请求消耗时间
            "docs_net_newConnection": self.newConnection, //是否新建了连接
            "docs_net_useProxy": self.useProxy, //是否使用了代理
            "docs_net_taskInterval": self.taskInterval.duration * 1000, // 消耗时间
            "docs_net_protocolName": self.protocolName ?? "empty"
        ]
        return dict
    }

    /// 所有的 transaction dns lookup 时间之和，如果没有，返回nil
    var dnsInterval: TimeInterval? {
        let all = self.transactionMetrics.compactMap({ $0.dnsLookUpInterval })
        return all.isEmpty ? nil : all.reduce(0, +)
    }

    /// 所有的 transaction 连接建立时间之和，如果没有，返回nil
    var connectionEstablishInterval: TimeInterval? {
        let all = self.transactionMetrics.compactMap({ $0.connectionEstablishInterval })
        return all.isEmpty ? nil : all.reduce(0, +)
    }

    /// 所有的 tls 连接建立时间之和，如果没有，返回nil
    var tlsInterval: TimeInterval? {
        let all = self.transactionMetrics.compactMap({ $0.tlsInterval })
        return all.isEmpty ? nil : all.reduce(0, +)
    }

    /// 所有的 transaction 请求发出时间（从第一个字节发出，到最后一次字节发出）
    var requestInterval: TimeInterval? {
        let all = self.transactionMetrics.compactMap({ $0.requestInterval })
        return all.isEmpty ? nil : all.reduce(0, +)
    }

    /// 所有的 transaction最后一次请求字节发出，到第一个请求返回的时间
    var httpInterval: TimeInterval? {
        let all = self.transactionMetrics.compactMap({ $0.httpInterval })
        return all.isEmpty ? nil : all.reduce(0, +)
    }

    ///  所有的 transaction 收到第一个字节开始，到最后一个字节收到
    var responseInterval: TimeInterval? {
        let all = self.transactionMetrics.compactMap({ $0.responseInterval })
        return all.isEmpty ? nil : all.reduce(0, +)
    }

    /// 是否使用了新的连接
    var newConnection: Bool {
        return self.transactionMetrics.contains { $0.isFromNet && !$0.isReusedConnection }
    }

    /// 是否使用了代理
    var useProxy: Bool {
        return self.transactionMetrics.contains { $0.isFromNet && $0.isProxyConnection }
    }

    /// 使用的网络协议
    var protocolName: String? {
        let allName = self.transactionMetrics.compactMap({ $0.networkProtocolName })
        guard !allName.isEmpty else {
            return nil
        }
        if allName.first(where: { $0 != "h2" }) == nil { return "h2" }// 都走了http2协议
        if allName.first(where: { $0 != "http/1.1" }) == nil { return "h1" } //都走了http1.1
        if allName.first(where: { $0 != "h2" && $0 != "http/1.1" }) == nil { return "h1/h2" } // 有http1，也有http2
        return allName.reduce("", +)
    }
}
