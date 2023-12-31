//
//  WPNetworkContext.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/11/28.
//

import Foundation
import ECOInfra
import LarkContainer

final class WPNetworkContext: ECONetworkServiceContext {
    let trace: OPTrace
    let injectInfo: WPRequestInjectInfo

    /// 由于ECONetworkMiddleware 不支持对 error 加附加信息
    /// 因此在预生成 logId 后赋给 context，在请求的 completion 回调中附加 logId 信息
    private(set) var logId: String?
    private(set) var userResolver: UserResolver?

    init(injectInfo: WPRequestInjectInfo = .default, trace: OPTrace) {
        self.injectInfo = injectInfo
        self.trace = trace
    }

    func getTrace() -> OPTrace {
        return self.trace
    }
    
    func getSource() -> ECONetworkRequestSourceWapper? {
        return ECONetworkRequestSourceWapper(source: .workplace)
    }
}

extension WPNetworkContext {
    func setLogID(_ logId: String) {
        self.logId = logId
    }

    func setUserResolver(_ userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}
