//
//  ECONetworkRequestCommonConfig.swift
//  ECOInfra
//
//  Created by 刘焱龙 on 2023/4/26.
//

import Foundation
import ThreadSafeDataStructure
import LarkSetting

struct ECONetworkRequestConvenienceGetConfig: ECONetworkRequestJSONGetConfig {
    static var domain: String? { DomainSettingManager.shared.currentSetting[.open]?.first }

    static var path: String { "" }

    static var method: ECONetworkHTTPMethod { .GET }

    static var middlewares: [ECONetworkMiddleware] {
        [
            OPRequestCommonParamsMiddleware(shouldAddUA: false),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ]
    }
}

struct ECONetworkRequestConveniencePostConfig: ECONetworkRequestJSONPostConfig {
    static var domain: String? { DomainSettingManager.shared.currentSetting[.open]?.first }

    static var path: String { "" }

    static var method: ECONetworkHTTPMethod { .POST }

    static var middlewares: [ECONetworkMiddleware] {
        [
            OPRequestCommonParamsMiddleware(shouldAddUA: false),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ]
    }
}

struct ECONetworkRequestDecodablePostConfig<ResultType: Decodable>: ECONetworkRequestConfig {
    typealias ParamsType = [String: Any]

    typealias ResultType = ResultType

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONDecodableSerializer<ResultType>

    static var domain: String? { DomainSettingManager.shared.currentSetting[.open]?.first }

    static var path: String { "" }

    static var method: ECONetworkHTTPMethod { .POST }

    static var requestSerializer: ECORequestBodyJSONSerializer { ECORequestBodyJSONSerializer() }

    static var responseSerializer: ECOResponseJSONDecodableSerializer<ResultType> { ECOResponseJSONDecodableSerializer(type: ResultType.self) }

    static var middlewares: [ECONetworkMiddleware] {
        [
            OPRequestCommonParamsMiddleware(shouldAddUA: false),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ]
    }
}

struct ECONetworkRequestDecodableGetConfig<ResultType: Decodable>: ECONetworkRequestConfig {
    typealias ParamsType = [String: String]?

    typealias ResultType = ResultType

    typealias RequestSerializer = ECORequestQueryItemSerializer

    typealias ResponseSerializer = ECOResponseJSONDecodableSerializer<ResultType>

    static var domain: String? { DomainSettingManager.shared.currentSetting[.open]?.first }

    static var path: String { "" }

    static var method: ECONetworkHTTPMethod { .GET }

    static var requestSerializer: ECORequestQueryItemSerializer { ECORequestQueryItemSerializer() }

    static var responseSerializer: ECOResponseJSONDecodableSerializer<ResultType> { ECOResponseJSONDecodableSerializer(type: ResultType.self) }

    static var middlewares: [ECONetworkMiddleware] {
        [
            OPRequestCommonParamsMiddleware(shouldAddUA: false),
            OPRequestTraceMiddleware(),
            OPRequestLogMiddleware()
        ]
    }
}
