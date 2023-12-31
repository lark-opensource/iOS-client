//
//  RecoverAccountAPI.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/2/3.
//

import Foundation
import RxSwift

/// 登录前/后 都会用到
class RecoverAccountRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix)
        self.middlewareTypes = [
            .requestCommonHeader,
            .saveToken,
            .costTimeRecord,
            .toastMessage,
            .checkSession
        ]
        self.requiredHeader = [.suiteSessionKey, .passportToken]
    }
}

class RecoverAccountAPI: APIV3 {
    func recoverAccountInfo(token: String, type: Int) -> Observable<V3.Step> {
        let req = RecoverAccountRequest<V3.Step>(pathSuffix: "recover/application/info")
        req.body = [
            "appeal_token": token,
            "type": type
        ]
        return client.send(req)
    }

    func applyCode(sourceType: Int?) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.codeType: VerifyCodeType.code.rawValue]
        if let source = sourceType {
            params[CommonConst.sourceType] = source
        }
        let req = RecoverAccountRequest<V3.Step>(pathSuffix: "otp/apply_code")
        req.body = params
        return client.send(req)
    }

    func verify(sourceType: Int?, code: String) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.code: code]
        if let source = sourceType {
            params[CommonConst.sourceType] = source
        }
        let req = RecoverAccountRequest<V3.Step>(pathSuffix: "otp/verify_code")
        req.body = params
        return client.send(req)
    }
}
