//
//  ECONetworkRequestSource.swift
//  ECOInfra
//
//  Created by 刘焱龙 on 2023/5/23.
//

import Foundation

@objc public enum ECONetworkRequestSource: Int {
    case api = 0
    case workplace = 1
    case other = 2
    case web = 3
}

/*
 ECONetwork 埋点数据分流和分析用，默认为 other
 如需新增 source，可以直接修改 enum，并提供 sourceString
 因为需要兼容 OC，所以这里用 ECONetworkRequestSourceWapper 包了一层
*/
@objc public class ECONetworkRequestSourceWapper: NSObject {
    private let source: ECONetworkRequestSource

    @objc public init(source: ECONetworkRequestSource) {
        self.source = source
    }

    var sourceString: String {
        switch source {
        case .api:
            return "api"
        case .workplace:
            return "workplace"
        case .other:
            return "other"
        case .web:
            return "web"
        }
    }
}
