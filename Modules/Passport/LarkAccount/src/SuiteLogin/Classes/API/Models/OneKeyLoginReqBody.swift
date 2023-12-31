//
//  OneKeyLoginReqBody.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/15.
//

import Foundation
import LarkAccountInterface

#if ONE_KEY_LOGIN
extension OneKeyLoginService {
    var toFromParam: String {
        switch self {
        case .telecom:
            return "telecom_v2"
        default:
            return rawValue
        }
    }
}

class OneKeyLoginReqBody: RequestBody {

    let token: String
    let type: OneKeyLoginType
    let action: Int
    let service: OneKeyLoginService
    let context: UniContextProtocol

    init(
        token: String,
        type: OneKeyLoginType,
        action: Int,
        service: OneKeyLoginService,
        context: UniContextProtocol
    ) {
        self.token = token
        self.type = type
        self.action = action
        self.service = service
        self.context = context
    }

    func getParams() -> [String: Any] {
        return [
            CommonConst.queryScope: CommonConst.queryScopeAll,
            CommonConst.appId: PassportConf.shared.appID,
            CommonConst.token: token,
            CommonConst.from: service.toFromParam,
            CommonConst.action: action
        ]
    }

    func appId() -> APPID {
        return .v4OneKeyLogin
    }

    func monitorCode() -> ProcessMonitorCode {
        switch type {
        case .register: return .registerMAuth
        case .login: return .loginMAuth
        }
    }
}
#endif
