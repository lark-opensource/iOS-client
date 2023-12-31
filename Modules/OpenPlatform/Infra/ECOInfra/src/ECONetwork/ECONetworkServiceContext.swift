//
//  ECONetworkServiceContext.swift
//  ECOInfra
//
//  Created by 刘焱龙 on 2023/5/30.
//

import Foundation

@objc public protocol ECONetworkServiceContext {
    @objc func getTrace() -> OPTrace

    /*
     ECONetwork 埋点数据分流和分析用，默认为 other
     如需新增 source，可以直接修改 ECONetworkRequestSourceWapper
    */
    @objc optional func getSource() -> ECONetworkRequestSourceWapper?
}

@objc public protocol ECONetworkServiceAppContext: ECONetworkServiceContext {
    @objc func getAppId() -> String
    @objc func getAppType() -> String
}
