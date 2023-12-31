//
//  UtilSyncService.swift
//  SpaceKit
//
//  Created by Songwen Ding on 2018/7/3.
// swiftlint:disable line_length

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

public final class UtilSyncService: BaseJSService {
}

extension UtilSyncService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilSyncComplete, .offlineCreateDocs, .syncDocInfo, .getMgDomainConfig]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilSyncComplete.rawValue:
            if var objToken = params["objToken"] as? String {
                var type = DocsType.doc
                if let typeRaw = params["type"] as? Int, !DocsType(rawValue: typeRaw).isUnknownType {
                    type = DocsType(rawValue: typeRaw)
                } else {
                    DocsLogger.info("can not get type info")
                }
                if let wikiToken = params["wikiToken"] as? String {
                    objToken = wikiToken
                }
                model?.synchronizer.didSync(with: objToken, type: type)
            }
        case DocsJSService.offlineCreateDocs.rawValue:
            var innerDict = [String: String]()
            innerDict["fakeToken"] = params["fakeToken"] as? String
            var params1 = [String: Any]()
            params1["data"] = innerDict
            let callback = params["callback"] as? String
            params1[RNManager.callbackID] = params["callback"] as? String
            DocsOfflineSyncManager.shared.getOfflineCreateDoc(params: params1) { [weak self] callbackParams in
                guard let self = self else { return }
                guard let callback = callback else { return }
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: callbackParams, completion: { (_, err) in
                    err.map {
                        DocsLogger.info("offline createDoc callback error \($0)")
                    }
                })
            }
        case DocsJSService.syncDocInfo.rawValue:
            guard let callback = params["callback"] as? String else {
                DocsLogger.info("syncDocInfo no callback")
                return
            }
            var params1 = [String: Any]()
            params1["data"] = params
            params1[RNManager.callbackID] = callback
            DocsOfflineSyncManager.shared.syncDocInfo(params: params1) { [weak self] in
                guard let self = self else { return }
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["code": 0, "message": "", "data": ""], completion: { (_, err) in
                    err.map {
                        DocsLogger.info("offline syncDocInfo callback error \($0)")
                    }
                })
            }
        case DocsJSService.getMgDomainConfig.rawValue: //返回文档mg相关信息
            guard let callback = params["callback"] as? String else {
                DocsLogger.info("getMgDomainConfig no callback")
                return
            }
            var params = [String: Any]()
            guard let currentUrl = model?.browserInfo.currentURL else {
                DocsLogger.info("getMgDomainConfig currentUrl nil")
                return
            }
            
            let urlInfo = DocsUrlUtil.getDocsCurrentUrlInfo(currentUrl)
            if !urlInfo.docsApiPrefix.isEmpty, !urlInfo.frontierDomain.isEmpty { //两个都不为空才会传
                params["docsApiPrefix"] = urlInfo.docsApiPrefix
                params["frontierDomain"] = urlInfo.frontierDomain
            }
            if let unit = urlInfo.unit {
                params["unit"] = unit
            }
            if let brand = urlInfo.brand {
                params["brand"] = brand
            }
            if let srcUrl = urlInfo.srcUrl {
                params["srcUrl"] = srcUrl
            }
            if let srcHost = urlInfo.srcHost {
                params["srcHost"] = srcHost
            }
            DocsLogger.info("jsb getMgDomainConfig:\(urlInfo.docsApiPrefix ?? ""), frontierDomain:\(urlInfo.frontierDomain), unit:\(urlInfo.unit ?? ""), brand:\(urlInfo.brand ?? "")", component: LogComponents.version)
            
            self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: { (_, err) in
                err.map {
                    DocsLogger.info("getMgDomainConfig callback error \($0)")
                }
            })
        default:
            break
        }
    }

}
