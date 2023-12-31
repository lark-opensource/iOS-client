//
//  QRCodeAPImp.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/8.
//

import Foundation
import LarkContainer
import RxSwift

class QRCodeRequest<Response: ResponseV3>: AfterLoginRequest<Response> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.qrloginApiPath, pathSuffix: pathSuffix)

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }
}

/// 这里的 QRCode API 是登录后扫码授权相关能力，设计为用户态
/// iPad 登录前 QRCode 场景（init/polling）在 loginAPI 中，设计为全局态
class NativeQRCodeAPI: APIV3, QRCodeAPI {

    init(resolver: UserResolver) { }

    func checkTokenForLogin(token: String, loginType: QRLoginType) -> Observable<V3.Step> {
        // qrlogin/scan
        let request = QRCodeRequest<V3.Step>(pathSuffix: "scan")
        request.domain = .passportAccounts()
        request.body = [
            "token": token,
            "qr_source": loginType.rawValue
        ]
        return client
            .send(request)
            .trace(
                "QRCodeCheck",
                params: [
                    "tokenLength": String(describing: token.count),
                    "tokenMd5": genMD5(token, salt: nil)
                ])
    }

    func confirmTokenForLogin(token: String, scope: String, isMultiLogin: Bool, loginType: QRLoginType) -> Observable<V3.Step> {
        // qrlogin/confirm
        let request = QRCodeRequest<V3.Step>(pathSuffix: "confirm")
        request.domain = .passportAccounts()
        request.body = [
            "token": token,
            "scope": scope,
            "is_multi_login": isMultiLogin,
            "qr_source": loginType.rawValue
        ]
        return client
            .send(request)
            .trace(
                "QRCodeConfirm",
                params: [
                    "tokenLength": String(describing: token.count),
                    "tokenMd5": genMD5(token, salt: nil)
                ]
            )
    }

    func cancelTokenForLogin(token: String, loginType: QRLoginType) -> Observable<Void> {
        // qrlogin/cancel
        let request = QRCodeRequest<V3.SimpleResponse>(pathSuffix: "cancel")
        request.domain = .passportAccounts()
        request.body = [
            "token": token,
            "qr_source": loginType.rawValue
        ]
        return client
            .send(request)
            .map({ _ in })
            .trace(
                "QRCodeCancel",
                params: [
                    "tokenLength": String(describing: token.count),
                    "tokenMd5": genMD5(token, salt: nil)
                ]
            )
    }
}
