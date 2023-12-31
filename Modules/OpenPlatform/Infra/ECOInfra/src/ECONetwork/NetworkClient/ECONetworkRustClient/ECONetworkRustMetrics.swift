//
//  ECONetworkRustMetrics.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation
import LarkRustHTTP

final class ECONetworkRustMetrics: NSObject, ECONetworkMetricsProtocol {
    var dnsCost: TimeInterval = 0
    var connectionCost: TimeInterval  = 0
    var tlsCost: TimeInterval  = 0
    var totalCost: TimeInterval  = 0
    
    init(with urlMetrics: RustHttpMetrics) {
        super.init()
        dnsCost = urlMetrics.dnsCost
        connectionCost = urlMetrics.connectionCost
        tlsCost = urlMetrics.tlsCost
        totalCost = urlMetrics.totalCost
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "dnsCost": dnsCost,
            "connectionCost": connectionCost,
            "tlsCost": tlsCost,
            "totalCost": totalCost
        ]
    }
}
