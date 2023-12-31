//
//  CheckSessionRequestConfig.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/10/22.
//

import OPPluginManagerAdapter
import ECOInfra
import LarkAppConfig
import Foundation

// CheckSession 接口的配置文件
struct CheckSessionRequestConfig: ECONetworkRequestConfig {

    typealias ParamsType = [String: Any]

    typealias ResultType =  OpenAPICheckSessionModel

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONDecodableSerializer<OpenAPICheckSessionModel>

    static var path: String { "/open-apis/mina/checkSession" }

    static var method: ECONetworkHTTPMethod { .POST }

    static var requestSerializer: RequestSerializer { ECORequestBodyJSONSerializer() }

    static var responseSerializer: ResponseSerializer {
        ECOResponseJSONDecodableSerializer(type: OpenAPICheckSessionModel.self)

    }

    static var initialHeaders: [String : String] { ["Content-Type": "application/json"]}

    static var middlewares: [ECONetworkMiddleware] {
        [
            DomainMiddleware(),
            // 链路中间件
            OPRequestTraceMiddleware(),
            // OpenPlatform 网络请求通用参数 OP的所有请求都要带上
            OPRequestCommonParamsMiddleware(),
            // OP 日志中间件
            OPRequestLogMiddleware()
        ]
    }
}
/// CheckSessionModel
struct OpenAPICheckSessionModel: Codable {
    struct DataModel: Codable {
        /// 自定义解析的key
        private enum CodingKeys : String, CodingKey {
            case valid = "valid"
            case expireTime = "expire_time"

        }
        let valid: Bool
        let expireTime: Int?
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let validStr = try container.decodeIfPresent(String.self, forKey: CodingKeys.valid)
            valid = ((validStr ?? "") as NSString).boolValue
            expireTime = try container.decodeIfPresent(Int.self, forKey: .expireTime)
        }
    }

    /// 自定义解析的key
    private enum CodingKeys : String, CodingKey {
        case errorCode = "error"
        case message
        case data
    }


    let errorCode: Int?
    let message: String?
    let data: DataModel?
}


