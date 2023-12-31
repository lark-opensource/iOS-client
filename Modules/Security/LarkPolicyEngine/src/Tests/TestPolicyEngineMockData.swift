//
//  TestPolicyEngineMockData.swift
//  LarkPolicyEngine-Unit-Tests
//
//  Created by Wujie on 2023/5/31.
//

import Foundation
@testable import LarkPolicyEngine
import LarkSnCService
import XCTest

struct TestSnCService: SnCService {
    var client: LarkSnCService.HTTPClient?
    var storage: LarkSnCService.Storage?
    var logger: LarkSnCService.Logger?
    var tracker: LarkSnCService.Tracker?
    var monitor: LarkSnCService.Monitor?
    var settings: LarkSnCService.Settings?
    var environment: LarkSnCService.Environment?
}

final class TestLogger: Logger {

    func log(level: LarkSnCService.LogLevel, _ message: String, file: String, line: Int, function: String) {
        // do nothing
    }

}

final class TestLoggerForDecisionLogManager: Logger {

    var flag = 0
    func log(level: LarkSnCService.LogLevel, _ message: String, file: String, line: Int, function: String) {
        if message == "Successfully deleted decision log." {
            flag = 1
        } else if message.contains("Failed to delete decision log, error:") {
            flag = 2
        }
    }

}

final class TestMonitor: Monitor {

    func sendInfo(service name: String, category: [String: Any]?, metric: [String: Any]?) {
        // do nothing
    }

    func sendError(service name: String, error: Error?) {
        // do nothing
    }

}

private typealias FastPassConfig = [String: [String]]

private struct PolicyTypeTenantsResponse: Codable {
    let policyTypeTenants: FastPassConfig?
}

final class TestHTTPClient: HTTPClient {

    public func request(_ request: LarkSnCService.HTTPRequest, completion: ((Result<Data, Error>) -> Void)?) {
        if request.path == "/lark/scs/guardian/policy_engine/pointcut/query" {
            let modelData: PointcutQueryDataModel = PointcutQueryDataModel(pointcuts: [pointCutModel])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/policy_type_tenants/query" {
            let modelData: PolicyTypeTenantsResponse = PolicyTypeTenantsResponse(policyTypeTenants: testFastPassConfig)
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/runtime_config/query" {
            guard let testPolicyInfo = testPolicyInfoPolicyRuntimeConfigModel else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            let modelData: PolicyRuntimeConfigModel = testPolicyInfo
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/enforce" {
            let modelData: RemoteValidate.RemoteValidateDataModel = RemoteValidate.RemoteValidateDataModel(
                resultMap: [testRequestKey: RemoteValidate.EnforceResult(effect: .permit,
                                                                         actions: ["{\"name\":\"name\",\"params\":{\"params1\":\"params1\"}}"], errorCode: 0, appliedPolicySetResults: [])])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/pointcut/control_check" {
            struct CheckPointcutIsControlledBySpecificFactorsModel: Codable {
                let isUnderControlled: [String: Bool]
            }
            let modelData: CheckPointcutIsControlledBySpecificFactorsModel = CheckPointcutIsControlledBySpecificFactorsModel(isUnderControlled: [testRequestKey: false])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/evaluate_uk/report" {
            let modelData: EvaluateInfo = EvaluateInfo(evaluateUk: "1", operateTime: "2", policySetKeys: ["3"])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/evaluate_log/delete" {
            let modelData: EvaluateInfo = EvaluateInfo(evaluateUk: "1", operateTime: "2", policySetKeys: ["3"])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/client_policy_pair/query" {
            let modelData: PolicyPairsModel = testPolicyPairsModel
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/client_policy_entity/query" {
            let modelData: PolicyEntityResponse = testPolicyEntityResponse
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/subject_factor/query" {
            let modelData: SubjectFactorResponse = testSubjectFactorResponse
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/ip/query" {
            let modelData: IPFactorInfoResponse = testIPFactorInfoResponse
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        }
    }

    func request<T: Decodable>(_ request: HTTPRequest,
                               dataType: T.Type,
                               completion: ((Result<T, Error>) -> Void)?) {
        self.request(request) { result in
            completion?(result.flatMap { data in
                do {
                    let model = try JSONDecoder().decode(dataType, from: data)
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            })
        }
    }
}

final class TestHTTPClientErrorCodeNotZero: HTTPClient {

    public func request(_ request: LarkSnCService.HTTPRequest, completion: ((Result<Data, Error>) -> Void)?) {
        if request.path == "/lark/scs/guardian/policy_engine/pointcut/query" {
            let modelData: PointcutQueryDataModel = PointcutQueryDataModel(pointcuts: [pointCutModel])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/policy_type_tenants/query" {
            let modelData: PolicyTypeTenantsResponse = PolicyTypeTenantsResponse(policyTypeTenants: testFastPassConfig)
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/runtime_config/query" {
            guard let testPolicyInfo = testPolicyInfoPolicyRuntimeConfigModel else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            let modelData: PolicyRuntimeConfigModel = testPolicyInfo
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/enforce" {
            let modelData: RemoteValidate.RemoteValidateDataModel = RemoteValidate.RemoteValidateDataModel(
                resultMap: [testRequestKey: RemoteValidate.EnforceResult(effect: .permit,
                                                                         actions: ["{\"name\":\"name\",\"params\":{\"params1\":\"params1\"}}"], errorCode: 400, appliedPolicySetResults: [])])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/pointcut/control_check" {
            struct CheckPointcutIsControlledBySpecificFactorsModel: Codable {
                let isUnderControlled: [String: Bool]
            }
            let modelData: CheckPointcutIsControlledBySpecificFactorsModel = CheckPointcutIsControlledBySpecificFactorsModel(isUnderControlled: [testRequestKey: false])
            let response = ResponseModel(code: 0, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        }
    }

    func request<T: Decodable>(_ request: HTTPRequest,
                               dataType: T.Type,
                               completion: ((Result<T, Error>) -> Void)?) {
        self.request(request) { result in
            completion?(result.flatMap { data in
                do {
                    let model = try JSONDecoder().decode(dataType, from: data)
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            })
        }
    }
}

final class TestHTTPClientCodeNotZero: HTTPClient {

    public func request(_ request: LarkSnCService.HTTPRequest, completion: ((Result<Data, Error>) -> Void)?) {
        if request.path == "/lark/scs/guardian/policy_engine/pointcut/query" {
            let modelData: PointcutQueryDataModel = PointcutQueryDataModel(pointcuts: [pointCutModel])
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/policy_type_tenants/query" {
            let modelData: PolicyTypeTenantsResponse = PolicyTypeTenantsResponse(policyTypeTenants: testFastPassConfig)
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/runtime_config/query" {
            guard let testPolicyInfo = testPolicyInfoPolicyRuntimeConfigModel else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            let modelData: PolicyRuntimeConfigModel = testPolicyInfo
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/enforce" {
            let modelData: RemoteValidate.RemoteValidateDataModel = RemoteValidate.RemoteValidateDataModel(
                resultMap: [testRequestKey: RemoteValidate.EnforceResult(effect: .permit,
                                                                         actions: ["{\"name\":\"name\",\"params\":{\"params1\":\"params1\"}}"], errorCode: 0, appliedPolicySetResults: [])])
            let response = ResponseModel(code: 400, data: modelData, msg: "error")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/pointcut/control_check" {
            struct CheckPointcutIsControlledBySpecificFactorsModel: Codable {
                let isUnderControlled: [String: Bool]
            }
            let modelData: CheckPointcutIsControlledBySpecificFactorsModel = CheckPointcutIsControlledBySpecificFactorsModel(isUnderControlled: [testRequestKey: false])
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/client_policy_pair/query" {
            let modelData: PolicyPairsModel = testPolicyPairsModel
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/client_policy_entity/query" {
            let modelData: PolicyEntityResponse = testPolicyEntityResponse
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/subject_factor/query" {
            let modelData: SubjectFactorResponse = testSubjectFactorResponse
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        } else if request.path == "/lark/scs/guardian/policy_engine/ip/query" {
            let modelData: IPFactorInfoResponse = testIPFactorInfoResponse
            let response = ResponseModel(code: 400, data: modelData, msg: "")
            let data: Data? = try? JSONEncoder().encode(response)
            guard let data = data else {
                completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
                return
            }
            completion?(.success(data))
        }
    }

    func request<T: Decodable>(_ request: HTTPRequest,
                               dataType: T.Type,
                               completion: ((Result<T, Error>) -> Void)?) {
        self.request(request) { result in
            completion?(result.flatMap { data in
                do {
                    let model = try JSONDecoder().decode(dataType, from: data)
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            })
        }
    }
}

final class TestHTTPClientFailure: HTTPClient {

    public func request(_ request: LarkSnCService.HTTPRequest, completion: ((Result<Data, Error>) -> Void)?) {
        if request.path == "/lark/scs/guardian/policy_engine/pointcut/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/policy_type_tenants/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/runtime_config/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/enforce" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/pointcut/control_check" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/evaluate_uk/report" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/evaluate_log/delete" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/client_policy_pair/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/client_policy_entity/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/subject_factor/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        } else if request.path == "/lark/scs/guardian/policy_engine/ip/query" {
            completion?(.failure(PolicyEngineError(error: .unknownError, message: "request error")))
        }
    }

    func request<T: Decodable>(_ request: HTTPRequest,
                               dataType: T.Type,
                               completion: ((Result<T, Error>) -> Void)?) {
        self.request(request) { result in
            completion?(result.flatMap { data in
                do {
                    let model = try JSONDecoder().decode(dataType, from: data)
                    return .success(model)
                } catch {
                    return .failure(error)
                }
            })
        }
    }
}

final class TestSettings: Settings {
    var setting = [String: Any]()

    init() {
        setting["enable_policy_engine"] = true
        setting["policy_engine_disable_local_validate"] = false
        setting["policy_engine_fetch_policy_interval"] = 60 * 5
        setting["policy_engine_local_validate_count_limit"] = 100
        setting["policy_engine_pointcut_retry_delay"] = 5
    }

    func setting<T>(key: String) throws -> T? where T: Decodable {
        return (setting[key] as? T)
    }
}

final class TestSettingsRustExpr: Settings {
    var setting = [String: Any]()

    init() {
        setting["enable_policy_engine"] = true
        setting["policy_engine_disable_local_validate"] = false
        setting["policy_engine_fetch_policy_interval"] = 60 * 5
        setting["policy_engine_local_validate_count_limit"] = 100
        setting["policy_engine_pointcut_retry_delay"] = 5
        setting["use_rust_expression_engine"] = true
    }

    func setting<T>(key: String) throws -> T? where T: Decodable {
        return (setting[key] as? T)
    }
}

final class TestStorage: Storage {
    var mmkv = [String: Any]()

    init() {
    }

    func set<T>(_ value: T?, forKey: String, space: StorageSpace) throws where T: Encodable {
        mmkv[forKey] = value
    }

    func get<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable {
        return mmkv[key] as? T
    }

    func remove<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable {
        let value = mmkv[key] as? T
        mmkv.removeValue(forKey: key)
        return value
    }

    func clearAll(space: StorageSpace) {
        mmkv.removeAll()
    }
}

final class TestStorageFailure: Storage {
    var mmkv = [String: Any]()

    init() {
    }

    func set<T>(_ value: T?, forKey: String, space: StorageSpace) throws where T: Encodable {
        throw PolicyEngineError(error: .unknownError, message: "write error")
    }

    func get<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable {
        throw PolicyEngineError(error: .unknownError, message: "read error")
    }

    func remove<T>(key: String, space: StorageSpace) throws -> T? where T: Decodable {
        let value = mmkv[key] as? T
        mmkv.removeValue(forKey: key)
        return value
    }

    func clearAll(space: StorageSpace) {
        mmkv.removeAll()
    }
}

final class TestEnvironment: Environment {
    var isLogin: Bool = true

    var userBrand: String = ""

    var packageId: String = ""

    var isKA: Bool {
        true
    }

    var debug: Bool {
        true
    }

    var inhouse: Bool {
        true
    }

    var boe: Bool {
        false
    }

    var userId: String {
        ""
    }

    var tenantId: String {
        "1"
    }

    func get<T>(key: String) -> T? {
        if key == "domain" {
            if boe {
                return "https://internal-api-security.feishu-boe.cn" as? T
            } else {
                return "https://internal-api-security.feishu.cn" as? T
            }
        }
        return nil
    }
}

final class TestEnvironmentForPolicyPriority: Environment {
    var isLogin: Bool = true

    var userBrand: String = ""

    var packageId: String = ""

    var isKA: Bool {
        true
    }

    var debug: Bool {
        true
    }

    var inhouse: Bool {
        true
    }

    var boe: Bool {
        false
    }

    var userId: String {
        "7290815892810645524"
    }

    var tenantId: String {
        "7097511431411499028"
    }

    func get<T>(key: String) -> T? {
        if key == "domain" {
            if boe {
                return "https://internal-api-security.feishu-boe.cn" as? T
            } else {
                return "https://internal-api-security.feishu.cn" as? T
            }
        }
        return nil
    }
}

final class TestEnvironmentForPolicyPriorityErrorUserId: Environment {
    var isLogin: Bool = true

    var userBrand: String = ""

    var packageId: String = ""

    var isKA: Bool {
        true
    }

    var debug: Bool {
        true
    }

    var inhouse: Bool {
        true
    }

    var boe: Bool {
        false
    }

    var userId: String {
        "userId"
    }

    var tenantId: String {
        "7097511431411499028"
    }

    func get<T>(key: String) -> T? {
        if key == "domain" {
            if boe {
                return "https://internal-api-security.feishu-boe.cn" as? T
            } else {
                return "https://internal-api-security.feishu.cn" as? T
            }
        }
        return nil
    }
}

final class TestEnvironmentDomainFailure: Environment {
    var isLogin: Bool = true

    var userBrand: String = ""

    var packageId: String = ""

    var isKA: Bool {
        true
    }

    var debug: Bool {
        true
    }

    var inhouse: Bool {
        true
    }

    var boe: Bool {
        false
    }

    var userId: String {
        ""
    }

    var tenantId: String {
        "1"
    }

    func get<T>(key: String) -> T? {
        return nil
    }
}
