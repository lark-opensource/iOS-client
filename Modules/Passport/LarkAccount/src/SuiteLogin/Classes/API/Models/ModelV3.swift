//
//  V3.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/18.
//

import Foundation
import LarkAccountInterface

protocol ResponseV3 {
    /// 0为成功
    var code: Int32 { get }

    /// 服务端错误信息
    var errorInfo: V3LoginErrorInfo? { get }

    init(dict: NSDictionary) throws
}

struct V3 {
    struct Const {
        static let code: String = "code"
        static let message: String = "message"
        static let data: String = "data"
        static let nextStep: String = "next_step"
        static let stepInfo: String = "step_info"
        static let successCode: Int32 = 0
        static let backFirst: String = "back_first"
        static let displayMsg: String = "message"
        static let env: String = "env"
        static let changeToUnit: String = "change_to_unit"
        static let changeToEnv: String = "change_to_env"
        static let expire: String = "expire"
        static let noMobileCredentialMsg: String = "message_mobile"
        static let bizCode: String = "biz_code"
        static let userList: String = "user_list"
    }

    /// 新版本通用Response
    ///
    ///  对应V3:
    ///  {
    ///     "code": 0,
    ///     "message": "ok",
    ///     "data": {
    ///         sessions: [{
    ///         }]
    ///     }
    ///  }
    ///
    struct CommonResponse<DataInfo: Codable>: ResponseV3 {
        var code: Int32
        var errorInfo: V3LoginErrorInfo?
        var dataInfo: DataInfo?

        init(dict: NSDictionary) throws {
            let code = dict[Const.code] as? Int32
            guard let serverCode = code else {
                throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: "response no code"))
            }

            if serverCode != Const.successCode {
                self.init(code: serverCode, dataInfo: nil, errorData: dict as? [String: Any])
            } else {
                guard let data = dict[Const.data] as? [String: Any],
                      let configData = V3LoginService.jsonToObj(type: DataInfo.self, json: data) else {
                    throw DecodingError.valueNotFound(DataInfo.self, DecodingError.Context(codingPath: [], debugDescription: "reponse no valid data info"))
                }
                self.init(code: serverCode, dataInfo: configData, errorData: nil)
            }
        }

        init(code: Int32, dataInfo: DataInfo?, errorData: [String: Any]?) {
            self.code = code
            self.dataInfo = dataInfo
            if let error = errorData {
                self.errorInfo = V3LoginErrorInfo(dic: error)
            }
        }
    }

    struct CommonArrayResponse<DataInfo: Codable>: ResponseV3 {
        var code: Int32
        var errorInfo: V3LoginErrorInfo?
        var dataInfo: DataInfo?

        init(dict: NSDictionary) throws {
            let code = dict[Const.code] as? Int32
            guard let serverCode = code else {
                throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: "response no code"))
            }

            if serverCode != Const.successCode {
                self.init(code: serverCode, dataInfo: nil, errorData: dict as? [String: Any])
            } else {
                guard let data = dict[Const.data] as? [Any],
                      let configData = V3LoginService.jsonArrayToObj(type: DataInfo.self, json: data) else {
                    throw DecodingError.valueNotFound(DataInfo.self, DecodingError.Context(codingPath: [], debugDescription: "response no valid data info"))
                }
                self.init(code: serverCode, dataInfo: configData, errorData: nil)
            }
        }

        init(code: Int32, dataInfo: DataInfo?, errorData: [String: Any]?) {
            self.code = code
            self.dataInfo = dataInfo
            if let error = errorData {
                self.errorInfo = V3LoginErrorInfo(dic: error)
            }
        }
    }

    typealias Config = CommonResponse<V3ConfigInfo>

    struct SimpleResponse: ResponseV3 {
        let code: Int32
        let message: String?
        let data: [String: Any]?
        var errorInfo: V3LoginErrorInfo?
        var rawData: [String: Any]?

        init(dict: NSDictionary) throws {
            let serverCode = dict[Const.code] as? Int32
            guard let code = serverCode else {
                throw DecodingError.valueNotFound(SimpleResponse.self, DecodingError.Context(codingPath: [], debugDescription: ""))
            }

            var errorDic: [String: Any]?
            if code != Const.successCode {
                errorDic = dict as? [String: Any]
            }
            self.init(
                code: code,
                message: dict[Const.message] as? String,
                data: dict[Const.data] as? [String: Any],
                errorData: errorDic,
                rawData: dict as? [String: Any]
            )
        }

        init(code: Int32, message: String?, data: [String: Any]?, errorData: [String: Any]?, rawData: [String: Any]?) {
            self.code = code
            self.message = message
            self.data = data
            self.rawData = rawData
            if let error = errorData {
                self.errorInfo = V3LoginErrorInfo(dic: error)
            }
        }
    }

    // MARK: - Step
    class Step: ResponseV3 {

        let code: Int32
        let stepData: DataClass
        var errorInfo: V3LoginErrorInfo?

        // MARK: - DataClass
        struct DataClass {
            let nextStep: String
            let stepInfo: [String: Any]
            let backFirst: Bool?
            let displayMsg: String?

            init(nextStep: String = "", stepInfo: [String: Any] = [:], backFirst: Bool? = nil, displayMsg: String? = nil) {
                self.nextStep = nextStep
                self.stepInfo = stepInfo
                self.backFirst = backFirst
                self.displayMsg = displayMsg
            }
        }

        required convenience init(dict: NSDictionary) throws {
            let serverCode = dict[Const.code] as? Int32
            guard let code = serverCode else {
                throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: Const.code))
            }
            // 服务端返回错误
            if code != Const.successCode {
                self.init(code: code, errorData: dict as? [String: Any])
            } else {
                // 请求服务端返回成功
                guard let data = dict[Const.data] as? [String: Any] else {
                    throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: "\(Const.data)"))
                }
                // code = 0
                let nextStep = Step.getNextStep(data)
                let stepInfo = Step.getStepInfo(data)
                let displayMsg = Step.getDisplayMsg(data)
                let backFirst = Step.getBackFirst(data)
                let dataClass = DataClass(nextStep: nextStep, stepInfo: stepInfo, backFirst: backFirst, displayMsg: displayMsg)
                self.init(code: code, errorData: nil, data: dataClass)
            }
        }

        init(code: Int32, errorData: [String: Any]?, data: DataClass = DataClass()) {
            self.code = code
            self.stepData = data
            if let error = errorData {
                self.errorInfo = V3LoginErrorInfo(dic: error)
            }
        }

        static func getNextStep(_ data: [String: Any]) -> String {
            return data[Const.nextStep] as? String ?? ""
        }

        static func getDisplayMsg(_ data: [String: Any]) -> String {
            return data[Const.displayMsg] as? String ?? ""
        }

        static func getStepInfo(_ data: [String: Any]) -> [String: Any] {
            let stepInfo = data[Const.stepInfo] as? [String: Any] ?? [:]
            return stepInfo
        }

        static func getBackFirst(_ data: [String: Any]) -> Bool? {
            return data[Const.backFirst] as? Bool
        }

        static func successStep(
            _ step: String,
            info: [String: Any] = [:],
            backFirst: Bool? = nil,
            displayMsg: String? = nil) -> Step {
            return .init(
                code: 0,
                errorData: nil,
                data: .init(
                    nextStep: step,
                    stepInfo: info,
                    backFirst: backFirst,
                    displayMsg: displayMsg
                )
            )
        }
    }

    class FastSwitchResponse: ResponseV3 {

        let code: Int32
        let message: String?
        let data: DataClass
        var errorInfo: V3LoginErrorInfo?

        required convenience init(dict: NSDictionary) throws {
            let serverCode = dict[Const.code] as? Int32
            guard let code = serverCode else {
                throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: Const.code))
            }
            let message = dict[Const.message] as? String
            // 服务端返回错误
            if code != Const.successCode {
                self.init(code: code, message: message, errorData: dict as? [String: Any])
            } else {
                // 请求服务端返回成功
                guard let data = dict[Const.data] as? [String: Any] else {
                    throw DecodingError.valueNotFound(FastSwitchResponse.self, DecodingError.Context(codingPath: [], debugDescription: "\(Const.data)"))
                }
                // code = 0
                let isStdLark: Bool
                if let value = data["is_std_lark"] as? Bool {
                    isStdLark = value
                } else {
                    V3ViewModel.logger.warn("miss field is_std_lark")
                    isStdLark = false
                }
                let dataClass = DataClass(isStdLark: isStdLark)
                self.init(
                    code: code,
                    message: message,
                    errorData: nil,
                    data: dataClass
                )
            }
        }

        init(
            code: Int32,
            message: String?,
            errorData: [String: Any]?,
            data: DataClass = DataClass(isStdLark: false)
        ) {
            self.code = code
            self.message = message
            self.data = data
            if let error = errorData {
                self.errorInfo = V3LoginErrorInfo(dic: error)
            }
        }

        struct DataClass {
            let isStdLark: Bool
        }
    }

    struct ListDevicesResponse: ResponseV3 {
        enum CodingKeys: String, CodingKey {
            case device = "device"
        }
        
        var code: Int32
        var message: String?
        var errorInfo: V3LoginErrorInfo?
        let data: [LoginDevice]?
                
        init(dict: NSDictionary) {
            let code = dict[Const.code] as? Int32 ?? Const.successCode
            let message = dict[Const.message] as? String
            var errorDict: [String: Any]?
            if code != Const.successCode {
                errorDict = dict as? [String: Any]
            }
            
            if let data = dict[Const.data] as? [String: Any], let deviceDictList = data[CodingKeys.device.rawValue] as? [Any]  {
                let deviceList = V3LoginService.jsonArrayToObj(type: [LoginDevice].self, json: deviceDictList)
                self.init(code: code, message: message, data: deviceList, errorDict: errorDict)
            } else {
                self.init(code: code, message: message, data: nil, errorDict: errorDict)
            }
        }
        
        init(code: Int32, message: String? = nil, data: [LoginDevice]? = nil, errorDict: [String: Any]? = nil) {            self.code = code
            self.message = message
            self.data = data
            if let errorDict = errorDict {
                self.errorInfo = V3LoginErrorInfo(dic: errorDict)
            }
        }
    }
    
    struct UpgradeLoginResponse: ResponseV3 {
        var code: Int32
        var message: String?
        var errorInfo: V3LoginErrorInfo?
        var data: [V4UserInfo]?

        init(dict: NSDictionary) throws {
            let code = dict[Const.code] as? Int32
            guard let serverCode = code else {
                throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: "response no code"))
            }
            
            var userList: [V4UserInfo] = []
            if let data = dict[Const.data] as? Dictionary<String, Any>, let listArray = data[Const.userList] as? Array<Dictionary<String, Any>> {
                listArray.forEach { userDict in
                    if let user = V3LoginService.jsonToObj(type: V4UserInfo.self, json: userDict) {
                        userList.append(user)
                    }
                }
            }
            
            self.init(code: serverCode, message: dict[Const.message] as? String, data: userList)
        }

        init(code: Int32, message: String?, data: [V4UserInfo]?) {
            self.code = code
            self.message = message
            self.data = data
        }
    }
    
    struct CredentialInfo: Codable {
        let allowRegionList: [String]?
        
        let blockRegionList: [String]?
        
        enum CodingKeys: String, CodingKey {
            case allowRegionList = "allow_region_list"
            case blockRegionList = "block_region_list"
        }
    }
        
    struct CredentialListResponse: ResponseV3 {
        var code: Int32
        
        let message: String?
        
        var errorInfo: V3LoginErrorInfo?
        
        var credentialInfo: CredentialInfo
        
        init(dict: NSDictionary) throws {
            guard let code = dict[Const.code] as? Int32 else {
                throw DecodingError.valueNotFound(Step.self, DecodingError.Context(codingPath: [], debugDescription: "response no code"))
            }
            
            var errorInfo: V3LoginErrorInfo?
            if code != Const.successCode {
                if let errorDict = dict as? [String: Any] {
                    errorInfo = V3LoginErrorInfo(dic: errorDict)
                }
            }
            
            var credentialInfo = CredentialInfo(allowRegionList: nil, blockRegionList: nil)
            if let dict = dict[Const.data] as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                if let decoded = try? JSONDecoder().decode(CredentialInfo.self, from: data) {
                    credentialInfo = decoded
                }
                
            }
            
            self.init(code: code,
                      message: dict[Const.message] as? String,
                      errorInfo: errorInfo,
                      credentialInfo: credentialInfo
            )
        }
        
        init(code: Int32, message: String?, errorInfo: V3LoginErrorInfo?, credentialInfo: CredentialInfo) {
            self.code = code
            self.message = message
            self.errorInfo = errorInfo
            self.credentialInfo = credentialInfo
        }
    }
}

struct ResponseHeader {
    let suiteSessionKey: String?
    let passportToken: String?
    let pwdToken: String?
    let statusCode: Int?
    let verifyToken: String?
    let flowKey: String?
    let proxyUnit: String?
    let xTTLogid: String?
    let authFlowKey: String?

    init(
        suiteSessionKey: String?,
        passportToken: String?,
        pwdToken: String?,
        statusCode: Int?,
        verifyToken: String?,
        flowKey: String?,
        proxyUnit: String?,
        xTTLogid: String?,
        authFlowKey: String?
    ) {
        self.suiteSessionKey = suiteSessionKey
        self.passportToken = passportToken
        self.pwdToken = pwdToken
        self.statusCode = statusCode
        self.verifyToken = verifyToken
        self.flowKey = flowKey
        self.proxyUnit = proxyUnit
        self.xTTLogid = xTTLogid
        self.authFlowKey = authFlowKey
    }
}
