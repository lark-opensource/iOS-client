//
//  UserCheckSessionAPI.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/7.
//

import Foundation
import RxSwift
import EENavigator


struct SessionInvalidAction {
    //弹窗
    static let showDialog: String = "show_dialog"
    //切换到下一个有效租户
    static let switchNextValidUser: String = "switch_next"
    //先清除缓存再切换到下一个有效租户
    static let clearCacheAndSwitchNextValidUser: String = "clear_cache_switch_next"
}


typealias checkSessionResp = V3.CommonResponse<UserCheckSessionResponse>

class UserCheckSessionAPI : APIV3{
    
    func checkSessions() -> Observable<UserCheckSessionResponse>{
        
        let req = UserCheckSessionRequest<checkSessionResp>(pathSuffix: APPID.checkStatus.apiIdentify())
        let userIDs = UserManager.shared.getUserList().compactMap({ $0.userID })
        var params: [String: Any] = ["user_ids": userIDs]
        var sessionTenantIDMap: [String: String] = [:]
        UserManager.shared.getUserList().forEach { userInfo in
            if let session = userInfo.suiteSessionKey {
                sessionTenantIDMap[session] = userInfo.user.tenant.id
            }
        }
        params["session_tid"] = sessionTenantIDMap
        req.required(.sessionKeys)
        req.required(.suiteSessionKey)
        req.body = params
        req.domain = .passportAccounts()
        
        return Observable.create { (ob)->Disposable in
            self.client.send(req) { resp, _ in
                guard var data = resp.dataInfo else {
                    LoginAPI.logger.error("n_action_session_invalid_req_data_invalid")
                    ob.onError(V3LoginError.badServerData)
                    return
                }
                data.requestUserList = userIDs
                ob.onNext(data)
                ob.onCompleted()
            } failure: { error in
                LoginAPI.logger.error("n_action_session_invalid_req_fail")
                ob.onError(error)
            }
            return Disposables.create()
        }
    }

    // 风险 session 弹窗提示后，用户选择稍后提示，调用该接口告知服务端短期内豁免
    // remind_type 后续可扩展，当前为 0
    func exemptRemind() -> Observable<Bool> {
        let request = UserCheckSessionRequest<V3.SimpleResponse>(pathSuffix: APPID.exemptRemind.apiIdentify())
        let params: [String: Int] = ["remind_type": 0]
        request.required(.sessionKeys).required(.suiteSessionKey)
        request.body = params
        request.domain = .passportAccounts()

        return Observable.create { (ob) -> Disposable in
            self.client.send(request) { resp, _ in
                ob.onNext((resp.code == 0))
                ob.onCompleted()
            } failure: { error in
                ob.onError(error)
            }
            return Disposables.create()
        }
    }
    
    #if DEBUG || ALPHA
    func makeSessionInvalid(logoutReason: Int32,_ session: String ){
        let req = AfterLoginRequest<V3.SimpleResponse>.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: "mock/app/logout")
        let params: [String: Any] = [
            CommonConst.appId: PassportConf.shared.appID,
            CommonConst.sessionKey: session,
            "logout_reason": logoutReason
        ]
        req.body = params
        req.domain = .passportAccounts()
        self.client.send(req) { resp, _ in
        } failure: { Error in
            LoginAPI.logger.error("n_action_session_invalid_mock_failed")
        }
    }
    #endif
}


class UserCheckSessionRequest<ResponseData: ResponseV3>: AfterLoginRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
     }

}

struct UserCheckSessionResponse: Codable {
 
    let sessionList: [String: UserCheckSessionItem]
    let userList: [String: UserExpressiveStatus]?
    var requestUserList: [String]?
    
    enum CodingKeys: String, CodingKey {
        case sessionList = "session_status"
        case userList = "user_status"
    }
}

struct UserCheckSessionItem: Codable {
 
    let isLogged: Bool
    let logoutRawReason: Int?
    let logoutReason : LogoutReason
    let action: String
    let deadlineLogoutTime: String?
    let actionStep: V4StepData?

    enum CodingKeys: String, CodingKey {
        case action
        case isLogged = "is_logged"
        case logoutReason = "logout_reason"
        case deadlineLogoutTime = "deadline_logout_time"
        case actionStep = "action_step"
    }
    
    enum LogoutReason: Int, Codable {
        case unknown = 0
        case resign = 10 //离职
        case tenantDismiss = 11 //租户解散
        case quitTenant = 17  //退出租户
        case unregister = 18 //账号注销
        case crossBrand = 29 //禁止登录跨域租户
        case highRisk = 40 //高风险session

        init(from decoder: Decoder) throws {
            let value = try? decoder.singleValueContainer().decode(Int.self)
            self = Self(rawValue: value ?? 0) ?? .unknown
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.logoutRawReason = try? container.decode(Int.self, forKey: .logoutReason)
        self.logoutReason = LogoutReason(rawValue: self.logoutRawReason ?? 0) ?? .unknown
        
        let isLoggedValue = try container.decode(Bool.self, forKey: .isLogged)
        self.isLogged = isLoggedValue
        //action 如果没有下发，默认show dialog
        self.action = (try? container.decode(String.self, forKey: .action)) ?? SessionInvalidAction.showDialog
        self.deadlineLogoutTime = try? container.decode(String.self, forKey: .deadlineLogoutTime)
        self.actionStep = try? container.decode(V4StepData.self, forKey: .actionStep)
    }

    func logoutReasonDescription() -> String {
        switch self.logoutRawReason {
        case 1:
            return "inactive"
        case 2:
            return "reset_pwd"
        case 3:
            return "same_device_kick_off"
        case 4:
            return "remote_logout"
        case 5:
            return "cross_boundary_logout"
        case 6:
            return "blocked"
        case 7:
            return "migrate_kick_off"
        case 8:
            return "lean_mode"
        case 9:
            return "freeze"
        case 10:
            return "resign"
        case 11:
            return "tenant_delete"
        case 12:
            return "proactive"
        case 13:
            return "qm_migrate_kick_off"
        case 14:
            return "guest_without_permission"
        case 15:
            return "session_not_found"
        case 16:
            return "reset_cp"
        case 17:
            return "quit_team"
        case 18:
            return "unregister"
        case 19:
            return "exceed_max_alive_count"
        case 20:
            return "block_by_identity"
        case 21:
            return "block_by_tenant"
        case 22:
            return "block_by_credential"
        case 23:
            return "anonymous_to_normal"
        default:
            return "unknown"
        }
    }
}


