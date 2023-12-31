//
//  PrefetchRequestV2Proxy.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/11/3.
//

import Foundation
import LarkOpenAPIModel

/// Prefetch 使用 v2 版本的网络请求
public protocol PrefetchRequestV2Proxy {
    func request(
        uniqueID: BDPUniqueID,
        url: URL,
        payload: String,
        tracing: BDPTracing,
        callback: @escaping (String?, OpenAPIError?) -> Void
    )
}
