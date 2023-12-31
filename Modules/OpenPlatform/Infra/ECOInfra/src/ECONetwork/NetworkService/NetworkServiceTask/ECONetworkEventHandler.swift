//
//  ECONetworkEventHandler.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/16.
//

import Foundation
protocol ECONetworkEventHandler {
    var context: ECONetworkServiceContext { get }
    var progress: ECONetworkProgress { get }
    var metrics: ECONetworkMetrics? { get set }
}
