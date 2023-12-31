//
//  LarkGeckoTTNetDelegate.swift
//  LarkGeckoTTNet
//
//  Created by ByteDance on 2022/10/23.
//

import Foundation
import IESGeckoKit
import TTNetworkManager


final class LarkGeckoTTNetDelegate: NSObject {
    fileprivate let ttnet = TTNetworkManager.shareInstance()
}

extension LarkGeckoTTNetDelegate: IESGurdNetworkDelegate {
    func downloadPackage(with model: IESGurdDownloadInfoModel, completion: @escaping IESGurdNetworkDelegateDownloadCompletion) {
        IESGurdKit.downloaderDelegate?.downloadPackage(with: model, completion: { url, _, error in
            completion(url, error)
        })
    }
    
    func cancelDownload(withIdentity identity: String) {
        
    }
    
    func request(withMethod method: String, urlString URLString: String, params: [AnyHashable : Any], completion: @escaping (IESGurdNetworkResponse) -> Void) {
        let useJson = method == "POST"
        ttnet.requestForJSON(
            withResponse: URLString,
            params: params,
            method: method,
            needCommonParams: true,
            headerField: useJson ? ["Content-Type": "application/json"] : nil,
            requestSerializer: useJson ? GeckoNetworkTTRequsetJSONSerializer.self : TTHTTPRequestSerializerBase.self,
            responseSerializer: TTHTTPJSONResponseSerializerBase.self,
            autoResume: true) { error, obj, response in
                let result = IESGurdNetworkResponse()
                if let response {
                    result.statusCode = response.statusCode
                    result.responseObject = obj
                    result.error = error
                    if let allHeaderFields = response.allHeaderFields as? [AnyHashable : Any] {
                        result.allHeaderFields = allHeaderFields
                    }
                }
                completion(result)
            }
    }
}

fileprivate final class GeckoNetworkTTRequsetJSONSerializer: TTDefaultHTTPRequestSerializer {
    override func urlRequest(
        withURL URL: String!,
        headerField headField: [AnyHashable : Any]!,
        params: Any!,
        method: String!,
        constructingBodyBlock bodyBlock: TTConstructingBodyBlock!,
        commonParams commonParam: [AnyHashable : Any]!) -> TTHttpRequest! {
            let request = super.urlRequest(withURL: URL, headerField: headField, params: params, method: method, constructingBodyBlock: bodyBlock, commonParams: commonParam)
            if params != nil {
                let data = try? JSONSerialization.data(withJSONObject: params)
                request?.httpBody = data
            }
            return request
        }
}

