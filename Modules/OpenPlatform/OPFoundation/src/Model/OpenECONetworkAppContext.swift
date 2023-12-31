//
//  OpenECONetworkAppContext.swift
//  OPFoundation
//
//  Created by 刘焱龙 on 2023/5/16.
//

import Foundation
import ECOInfra

@objc public final class OpenECONetworkContext: NSObject, ECONetworkServiceContext {
    private let trace: OPTrace
    private let source: ECONetworkRequestSource

    @objc public init(trace: OPTrace, source: ECONetworkRequestSource) {
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


@objc public final class OpenECONetworkAppContext: NSObject, ECONetworkServiceAppContext {
    private let trace: OPTrace
    private let uniqueId: OPAppUniqueID
    private let source: ECONetworkRequestSource

    @objc public init(trace: OPTrace, uniqueId: OPAppUniqueID, source: ECONetworkRequestSource) {
        self.trace = trace
        self.uniqueId = uniqueId
        self.source = source
    }

    @objc public func getTrace() -> OPTrace {
        return trace
    }

    @objc public func getAppId() -> String {
        return uniqueId.appID
    }

    @objc public func getAppType() -> String {
        return OPAppTypeToString(uniqueId.appType)
    }
    
    @objc public func getUniqueID() -> OPAppUniqueID {
        return uniqueId
    }

    @objc public func getSource() -> ECONetworkRequestSourceWapper? {
        return ECONetworkRequestSourceWapper(source: source)
    }
}
