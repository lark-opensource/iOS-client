//
//  PrefetchRequestV2ProxyOCBridge.swift
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/11/2.
//

import Foundation
import LarkRustClient
import RxSwift
import RustPB
import ECOInfra
import LarkContainer
import LKCommonsLogging

@objcMembers
public final class PrefetchRequestV2ProxyOCBridge: NSObject {
    
    private static let logger = Logger.oplog(PrefetchRequestV2ProxyOCBridge.self, category: "PrefetchRequestV2ProxyOCBridge")
    
    public static func request(
        uniqueID: BDPUniqueID,
        url: URL,
        payload: String,
        tracing: BDPTracing,
        callback: @escaping (String?, NSError?) -> Void
    ) {
        // TODOZJX
        guard let prefetchRequest = try? OPUserScope.userResolver().resolve(assert: PrefetchRequestV2Proxy.self) else {
            Self.logger.error("resolve PrefetchRequestV2Proxy failed")
            callback(nil, NSError(domain: "PrefetchRequestV2ProxyOCBridge", code: -1, userInfo: [NSLocalizedDescriptionKey: "resolve PrefetchRequestV2Proxy failed"]))
            return
        }
        
        BDPLogInfo(tag: .prefetch, "PrefetchRequestV2Helper start: \(url.safeURLString), \(tracing.getRequestID())")
        prefetchRequest.request(
            uniqueID: uniqueID,
            url: url,
            payload: payload,
            tracing: tracing
        ) { payload, error in
            BDPLogInfo(tag: .prefetch, "PrefetchRequestV2Helper end: \(url.safeURLString), \(tracing.getRequestID()), \(error?.description ?? "")")
            var realError: NSError? = nil
            if let error = error {
                realError = NSError(domain: error.errnoError?.errString ?? "PrefetchRequestV2ProxyOCBridge",
                                    code: error.errnoError?.errnoValue ?? -1,
                                    userInfo: nil)
            }
            callback(payload, realError)
        }
    }
}
