//
//  PreloadDefines.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/8/22.
//  

import SKFoundation
import SKInfra

public protocol DocPreloaderManagerAPI: AnyObject {
    func addManuOfflinePreloadKey(_ preloadKeys: [PreloadKey])
    func loadContent(_ url: String, from source: String)
    func IdlePreloadDocs(_ url: String)
    func getSSRPreloadTime(_ token: String) -> TimeInterval?
    func getClientVarsPreloadTime(_ token: String) -> TimeInterval?
    func registerIdelTask(preloadName: String, action: @escaping () -> Void) -> Bool
    func preloadFeedback(_ token: String, hitPreload: Bool)
}

extension DocPreloaderManager: DocPreloaderManagerAPI {

}

protocol ClientVarPreloader {
    func load(preloadKey: PreloadKey, result: @escaping DRRawResponse)
    static func requestWith(_ preloadKey: PreloadKey) -> ClientVarPreloader
    func referenceSelf()
}

extension DocsRequest: ClientVarPreloader where ResponseData == Any {
    func load(preloadKey: PreloadKey, result: @escaping DRRawResponse) {
        let additionalHeaders = ["Content-Type": "application/json",
                                 "Accept": "application/json, text/plain, */*",
                                 "http_request_tag": "docs_preload_clientvar"]
        self.set(headers: additionalHeaders)
            .set(needFilterBOMChar: true)
            .set(needVerifyData: false).start(rawResult: result)
    }
    
    static func requestWith(_ preloadKey: PreloadKey) -> ClientVarPreloader {
        if preloadKey.type == .docX {
            let openType = 1 // 标明文档client_var请求来源，0为文档打开，1为预加载
            let queryString = "?id=\(preloadKey.objToken)&open_type=\(openType)"
            return DocsRequest<Any>(path: OpenAPI.APIPath.preloadPageClientVar + queryString, paramConvertible: preloadKey)
                .set(forceComplexConnect: true)
                .set(method: .GET)
                .set(encodeType: .urlEncodeDefault)
        } else {
            let memberId = preloadKey.memberId
            let queryString = "?member_id=\(memberId)"  // 一定需要queryString
            let request = DocsRequest<Any>(path: OpenAPI.APIPath.preloadContent + queryString,
                paramConvertible: preloadKey).set(forceComplexConnect: true)
                .set(encodeType: .jsonEncodeDefault)
            return request
        }
    }
    func referenceSelf() {
        makeSelfReferenced()
    }
}

protocol DocPreloadClientVarAbility {
    var canLoad: Bool { get }
}

extension User: DocPreloadClientVarAbility {
    var canLoad: Bool {
        return info?.cacheKeyPrefix != nil
    }
}
