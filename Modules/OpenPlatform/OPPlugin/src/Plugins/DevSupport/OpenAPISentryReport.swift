//
//  OpenAPISentryReport.swift
//  OPPlugin
//
//  Created by 窦坚 on 2021/7/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LarkContainer

final class OpenAPISentryReport: OpenBasePlugin {

    public func sentryReport(params: OpenAPISentryReportModel, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        let headerDict: NSMutableDictionary = params.headerDict.mutableCopy() as! NSMutableDictionary
        headerDict["User-Agent"] = BDPUserAgent.getString()
        if (!BDPIsEmptyString(params.urlString)) {
            DispatchQueue.global(qos: .default).async {
                let config: BDPNetworkRequestExtraConfiguration = BDPNetworkRequestExtraConfiguration.init()
                config.bdpRequestHeaderField = headerDict as? [AnyHashable : Any]
                config.flags = [.needCommonParams, .autoResume]
                config.methodStr = params.methodString ?? "GET"
                BDPNetworking.task(withRequestUrl: params.urlString, parameters: params.data, extraConfig: config) { (error, jsonObj, response) in
                    if let error = error {
                        context.apiTrace.error("sentryReport request error:\(error)")
                    }
                }
            }
        }
        callback(.success(data: nil))
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "sentryReport", pluginType: Self.self, paramsType: OpenAPISentryReportModel.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.sentryReport(params: params, context: context, callback: callback)
        }
    }

}
