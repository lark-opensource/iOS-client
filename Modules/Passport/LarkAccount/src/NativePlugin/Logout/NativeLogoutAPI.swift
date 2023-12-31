//
//  NativeLogoutAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift
import LarkContainer
import LKCommonsLogging

class NativeLogoutAPI: LogoutAPI {

    static let logger = Logger.plog(NativeLogoutAPI.self, category: "SuiteLogin.NativeLogoutAPI")
    @Provider var client: HTTPClient

    struct Const {
        static let logoutType: String = "logout_type"
    }

    func logout(sessionKeys: [String], makeOffline: Bool, logoutType: CommonConst.LogoutType, context: UniContextProtocol) -> Observable<Void> {
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.v4LogoutApp.apiIdentify())
        req.method = .post
        req.domain = .passportAccounts()
        let params: [String: Any] = [
            CommonConst.appId: PassportConf.shared.appID,
            CommonConst.logoutTime: Int(floor(Date().timeIntervalSince1970)),
            CommonConst.bodySessionKeys: sessionKeys,
            Const.logoutType: logoutType.rawValue
        ]
        req.body = params
        req.middlewareTypes = req.middlewareTypes.filter({ $0 != .captcha }) // 获取 captcha 会造成死锁
        return Observable.create({ (ob) -> Disposable in
            self.client.send(req, success: { (resp, header) in
                if let statusCode = header.statusCode, statusCode == 200 {
                    ob.onNext(())
                    ob.onCompleted()
                } else {
                    ob.onError(V3LoginError.badServerCode(resp.errorInfo ?? V3LoginErrorInfo(type: .unknown, message: "")))
                }
            }, failure: { error in
                ob.onError(error)
            })
            return Disposables.create()
        }).trace("NativeLogout")
    }

    func offlineLogout(logoutTokens: [String]) -> Observable<[String]> {
        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.v4LogoutToken.apiIdentify())
        req.method = .post
        req.domain = .passportAccounts()
        req.middlewareTypes = [.requestCommonHeader]
        req.required(.fetchDeviceId)
        let params: [String: Any] = [
            CommonConst.appId: PassportConf.shared.appID,
            CommonConst.logoutTime: Int(floor(Date().timeIntervalSince1970)),
            CommonConst.logoutTokens: logoutTokens
        ]
        req.body = params
        return Observable.create({ (ob) -> Disposable in
            self.client.send(req, success: { (resp, header) in
                if let statusCode = header.statusCode, statusCode == 200 {
                    ob.onNext(logoutTokens)
                    ob.onCompleted()
                } else {
                    ob.onError(V3LoginError.badServerCode(resp.errorInfo ?? V3LoginErrorInfo(type: .unknown, message: "")))
                }
            }, failure: { error in
                ob.onError(error)
            })
            return Disposables.create()
        }).trace("LogoutToken")
    }

    func barrier(
        userID: String,
        enter: @escaping (_ leave: @escaping (_ finish: Bool) -> Void) -> Void
    ) {
        enter({ _ in })
    }

}
