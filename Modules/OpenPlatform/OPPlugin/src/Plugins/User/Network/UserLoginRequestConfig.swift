//
//  UserLoginRequestConfig.swift
//  OPPlugin
//
//  Created by zhangxudong on 3/7/22.
//

import OPPluginManagerAdapter
import LarkSetting
import LarkAppConfig
import LarkContainer

// 网络框架 UserAgentHeaderMiddleware:ECONetworkMiddleware
// login 接口的配置文件
struct UserLoginRequestConfig: ECONetworkRequestConfig  {

    typealias ParamsType = [String: Any]

    typealias ResultType = OPenAPINetworkLoginModel

    typealias RequestSerializer = ECORequestBodyJSONSerializer

    typealias ResponseSerializer = ECOResponseJSONDecodableSerializer<OPenAPINetworkLoginModel>

    static var path: String { "/open-apis/mina/v2/login" }

    static var method: ECONetworkHTTPMethod { .POST }

    static var requestSerializer: RequestSerializer { ECORequestBodyJSONSerializer() }

    static var responseSerializer: ResponseSerializer {
        ECOResponseJSONDecodableSerializer(type: OPenAPINetworkLoginModel.self)
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

/// API 登录 接口返回的model
struct OPenAPINetworkLoginModel: Codable {
    struct Data: Codable {
        let code: String?
    }
    /// 自定义解析的key
    private enum CodingKeys : String, CodingKey {
        case errorCode = "error"
        case message
        case session
        case data
        case autoConfirm = "auto_confirm"
        case scope
    }
    let errorCode: Int?
    let session: String?
    let message: String?
    let data: Data?
    let autoConfirm: Bool?
    let scope: String?
}
