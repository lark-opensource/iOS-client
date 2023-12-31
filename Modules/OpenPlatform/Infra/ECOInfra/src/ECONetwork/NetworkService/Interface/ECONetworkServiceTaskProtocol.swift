//
//  ECONetworkServiceRequestContext.swift
//  ECOInfra
//
//  Created by MJXin on 2021/6/7.
//

import Foundation
import ECOProbe

public protocol ECONetworkServiceTaskProtocol: ECONetworkServiceContext {
    var identifier: String { get }
    var type: ECONetworkTaskType { get }
    var context: ECONetworkServiceContext { get }
    var trace: OPTrace { get }
}
