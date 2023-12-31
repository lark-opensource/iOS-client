//
//  OpenPluginUnitTestsConfig.swift
//  OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/2/24.
//

import XCTest
import RustPB
import LarkRustClient
import TTMicroApp
import OPUnitTestFoundation
enum OpenPluginUnitTestConfigError: Error {
    case configFileNameIsNil
    case getFilePathFail
    case getParamsFail
    case getErrResultFail
    case getTestConfigFail
    case getResponsePayloadFail
    case getExtraFail
}

struct UnitTestErrResult: Codable {
    let errno: Int
    let errString: String
}

fileprivate enum ConfigKey: String {
    case params
    case responsePayload
    case responseExtra = "extra"
    case errResult
}

@available(iOS 13.0, *)
protocol OpenPluginUnitTestsConfig {
    var configFileName: String { get }
    var config: [AnyHashable: Any]? { get set }

    func loadConfig() throws -> [AnyHashable: Any]?

    func getParams(key: String) throws -> String
    func getParams(key: String, customKey: [String: String]) throws -> String
    
    func getParamsDictionary(key: String) throws -> [AnyHashable: Any]

    func mockSuccessResponse(
        key: String
    ) throws -> [MockRustResponse]
    func mockSuccessResponse(
        key: String,
        payloadCustomKey: [String: String],
        extraCustomKey: [String: String]
    ) throws -> [MockRustResponse]

    func mockFailResponse(errorCode: Int) -> [MockRustResponse]

    func getErrResult(key: String) throws -> UnitTestErrResult
}

@available(iOS 13.0, *)
extension OpenPluginUnitTestsConfig {
    func loadConfig() throws -> [AnyHashable: Any]? {
        guard let path = Bundle(for: OpenPluginNetworkTests.self).path(forResource: "TestsResource", ofType: "bundle") else {
            throw OpenPluginUnitTestConfigError.getFilePathFail
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: "\(path)/\(configFileName).json"))
        return try JSONSerialization.jsonObject(with: data) as? [AnyHashable : Any]
    }

    func getParams(key: String) throws -> String {
        return try getParams(key: key, customKey: [:])
    }
    
    func getParamsDictionary(key: String) throws -> [AnyHashable: Any] {
        guard let jsonDic = try getTestConfig(key: key)[ConfigKey.params.rawValue] as? [AnyHashable: Any] else {
            throw OpenPluginUnitTestConfigError.getParamsFail
        }
        return jsonDic
    }

    func getParams(key: String, customKey: [String: String]) throws -> String {
        let jsonDic = try getParamsDictionary(key: key)
        var payload = try jsonDic.convertToJsonStr()
        payload = Self.matchContent(content: payload, customKey: customKey)
        return payload
    }

    func mockSuccessResponse(
        key: String
    ) throws -> [MockRustResponse] {
        return try mockSuccessResponse(key: key, payloadCustomKey: [:], extraCustomKey: [:])
    }

    func mockSuccessResponse(key: String, payloadCustomKey: [String: String], extraCustomKey: [String: String]) throws -> [MockRustResponse] {
        var payload = try getResponsePayload(key: key)
        payload = Self.matchContent(content: payload, customKey: payloadCustomKey)
        var extra = try getResponseExtra(key: key)
        extra = Self.matchContent(content: extra, customKey: extraCustomKey)

        var response = Openplatform_Api_OpenAPIResponse()
        response.payload = payload
        response.extra = extra
        return [MockRustResponse(response: response, success: true)]
    }

    func mockFailResponse(errorCode: Int) -> [MockRustResponse] {
        let realErrorCode = Int32(truncatingIfNeeded: errorCode)
        let errorInfo = BusinessErrorInfo(code: realErrorCode, errorStatus: realErrorCode, errorCode: realErrorCode, debugMessage: "fail", displayMessage: "fail", serverMessage: "fail", userErrTitle: "fail", requestID: "123456")
        let error = RCError.businessFailure(errorInfo: errorInfo)
        return [MockRustResponse(response: error, success: false)]
    }

    func getErrResult(key: String) throws -> UnitTestErrResult {
        guard let errResultJson = try (getTestConfig(key: key)[ConfigKey.errResult.rawValue] as? [AnyHashable: Any]) else {
            throw OpenPluginUnitTestConfigError.getErrResultFail
        }
        let errResultData = try JSONSerialization.data(withJSONObject: errResultJson)
        return try JSONDecoder().decode(UnitTestErrResult.self, from: errResultData)
    }
}

@available(iOS 13.0, *)
extension OpenPluginUnitTestsConfig {
    private func getResponsePayload(key: String) throws -> String {
        guard let payload = try getTestConfig(key: key)[ConfigKey.responsePayload.rawValue] as? [AnyHashable: Any] else {
            throw OpenPluginUnitTestConfigError.getResponsePayloadFail
        }
        return try payload.convertToJsonStr()
    }

    private func getResponseExtra(key: String) throws -> String {
        guard let extra = try getTestConfig(key: key)[ConfigKey.responseExtra.rawValue] as? [AnyHashable: Any] else {
            throw OpenPluginUnitTestConfigError.getExtraFail
        }
        return try extra.convertToJsonStr()
    }

    private func getTestConfig(key: String) throws -> [AnyHashable: Any] {
        guard let config = config else {
            throw OpenPluginUnitTestConfigError.configFileNameIsNil
        }
        guard let testConfig = config[key] as? [AnyHashable: Any] else {
            throw OpenPluginUnitTestConfigError.getTestConfigFail
        }
        return testConfig
    }

    private static func matchContent(content: String, customKey: [String: String]) -> String {
        var realContent = content
        for (key, val) in customKey {
            let realKey = "${\(key)}"
            guard realContent.contains(realKey) else {
                continue
            }
            realContent = realContent.replacingOccurrences(of: realKey, with: val)
        }
        return realContent
    }
}
