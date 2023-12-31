//
//  OpenECONetworkWebContext.swift
//  EcosystemWeb
//
//  Created by baojianjun on 2023/11/21.
//

import Foundation
import ECOInfra
import ECOProbe

public final class OpenECONetworkWebContext: ECONetworkServiceContext {
    
    private let trace: OPTrace
    private let source: ECONetworkRequestSource

    public init(trace: OPTrace, source: ECONetworkRequestSource) {
        self.trace = trace
        self.source = source
    }

    public func getTrace() -> OPTrace {
        return trace
    }

    public func getSource() -> ECONetworkRequestSourceWapper? {
        return ECONetworkRequestSourceWapper(source: source)
    }
}
