//
//  PermissonManager+EmbededDoc.swift
//  SKCommon
//
//  Created by guoqp on 2022/3/3.
//

import Foundation
import SwiftyJSON
import HandyJSON
import SKFoundation
import RxSwift
import SKInfra

///Dlp
extension PermissionManager {
    ///检测是否开启DLP策略
    func dlpPolicystatus(token: String,
                                   type: String,
                                   complete: @escaping ((DlpPolicy?, Error?) -> Void)) {
        let subpath = "?token=\(token)&policyType=DLP&entityType=\(type)"

        guard let host = SettingConfig.retentionDomainConfig else {
            DocsLogger.warning("get retention host error")
            complete(nil, DocsNetworkError.invalidParams)
            return
        }
        let path = "https://" + host + OpenAPI.APIPath.dlpPolicystatus

        let request = DocsRequest<JSON>(
            url: path + subpath,
            params: nil
        ).set(method: .GET).set(timeout: 20)

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard error == nil else {
                DocsLogger.error("get dlp policy status failed", error: error)
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("get dlp policy status failed, no code key")
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            
            if let err = DocsNetworkError(code) {
                DocsLogger.error("get dlp policy status failed, code is \(code)")
                DispatchQueue.main.async {
                    complete(nil, err)
                }
                return
            }
            guard code == 0 else {
                DocsLogger.error("get dlp policy status failed, code != 0, code is \(code)")
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            let policyJson = json["data"]["policy"]
            DocsLogger.error("get dlp policy status success")
            let policy = DlpPolicy(with: policyJson)
            DispatchQueue.main.async {
                complete(policy, nil)
            }
        })
        request.makeSelfReferenced()
    }



    /// dlp scs
    func dlpscs(token: String, type: String, complete: @escaping ((DlpScs?, Error?) -> Void)) {
        let parameters: [String: Any] = ["token": token, "entityType": type, "entityOperateList": DlpCheckAction.operateList()]

        guard let host = SettingConfig.retentionDomainConfig else {
            DocsLogger.warning("get retention host error")
            complete(nil, DocsNetworkError.invalidParams)
            return
        }
        let path = "https://" + host + OpenAPI.APIPath.dlpScs

        let request = DocsRequest<JSON>(
            url: path,
            params: parameters
        )
            .set(timeout: 20)
            .set(headers: ["Content-Type": "application/json"])
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)

        request.start(callbackQueue: callbackQueue, result: { json, error in
            guard error == nil else {
                DocsLogger.error("get dlp scs failed! error", error: error)
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            guard let json = json, let code = json["code"].int else {
                DocsLogger.error("get dlp scs failed! code key is nil")
                DispatchQueue.main.async {
                    complete(nil, CollaboratorsError.parseError)
                }
                return
            }
            if let err = DocsNetworkError(code) {
                DocsLogger.error("get dlp scs failed! code is \(code)")
                DispatchQueue.main.async {
                    complete(nil, err)
                }
                return
            }
            guard code == 0 else {
                DocsLogger.error("get dlp policy status failed, code != 0, code is \(code)")
                DispatchQueue.main.async {
                    complete(nil, error)
                }
                return
            }
            let data = json["data"]
            let scs = DlpScs(with: data)
            DispatchQueue.main.async {
                DocsLogger.info("get dlp scs success!")
                complete(scs, nil)
            }
        })
        request.makeSelfReferenced()
    }
}
