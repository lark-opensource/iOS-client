//
//  OpenPluginPrefetchRequestProvider.swift
//  OPPlugin
//
//  Created by 刘焱龙 on 2022/11/3.
//

import TTMicroApp
import OPPluginManagerAdapter
import RxSwift
import Swinject
import LarkRustClient
import RxSwift
import RustPB
import ECOInfra
import LarkContainer
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging

public final class OpenPluginPrefetchRequestProvider: PrefetchRequestV2Proxy {
    private let resolver: UserResolver
    private let disposeBag = DisposeBag()

    private let logger = Logger.oplog(OpenPluginPrefetchRequestProvider.self, category: "OpenPluginPrefetchRequestProvider")

    private let cookieService: ECOCookieService
    private let rustService: RustService

    public init(resolver: UserResolver) throws {
        self.resolver = resolver
        cookieService = try resolver.resolve(assert: ECOCookieService.self)
        rustService = try resolver.resolve(assert: RustService.self)
    }

    public func request(
        uniqueID: TTMicroApp.BDPUniqueID,
        url: URL,
        payload: String,
        tracing: BDPTracing,
        callback: @escaping (String?, OpenAPIError?) -> Void) {
            let context = OpenAPIContext(trace: tracing)
            do {
                logger.info("OpenPluginPrefetchRequestProvider start \(url.safeURLString), \(tracing.getRequestID())")
                let cookie = OpenPluginNetwork.getStorageCookies(cookieService:cookieService, from: uniqueID, url: url)

                try OpenPluginNetwork.sendAsyncRequest(
                    apiName: .requestPrefetch,
                    uniqueID: uniqueID,
                    trace: tracing,
                    url: url,
                    payload: payload,
                    cookieService: cookieService,
                    rustService: rustService,
                    disposeBag: disposeBag,
                    resultMonitor: nil) { [weak self] (payload, _) in
                        self?.logger.info("OpenPluginPrefetchRequestProvider onNext \(url.safeURLString), \(tracing.getRequestID())")
                        callback(payload, nil)
                    } fail: { [weak self] error in
                        self?.logger.error("OpenPluginPrefetchRequestProvider onError \(url.safeURLString), \(tracing.getRequestID()), \(error.localizedDescription)")
                        let apiError = OpenPluginNetwork.apiError(context: context, error: error)
                        callback(nil, apiError)
                    }
            } catch let error {
                logger.error("OpenPluginPrefetchRequestProvider catch error \(url.safeURLString), \(tracing.getRequestID())")
                let apiError = OpenPluginNetwork.apiError(context: context, error: error)
                callback(nil, apiError)
            }
    }
}
