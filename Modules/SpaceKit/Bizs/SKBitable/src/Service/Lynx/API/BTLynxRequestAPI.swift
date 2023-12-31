//
//  LynxRequestAPI.swift
//  SKBitable
//
//  Created by Nicholas Tau on 2023/11/6.
//

import Foundation
import SKFoundation
import LarkLynxKit
import BDXLynxKit
import LarkContainer
import LarkRustHTTP
import SwiftyJSON

public final class BTLynxRequestAPI: NSObject, BTLynxAPI {
    static let apiName = "request"
    let session = RustHTTPSession(configuration: .default,
                                  delegate: nil,
                                  delegateQueue: {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 5
            return queue
        }())
    @Injected private var containerEnvService: BTLynxContainerEnvService
    func invoke(params: [AnyHashable : Any],
                lynxContext: LynxContext?,
                bizContext: LynxContainerContext?,
                callback:  BTLynxAPICallback<BTLynxAPIBaseResult>?) {
        guard let method = (params["method"] as? String)?.lowercased() else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "method")))
            return
        }
        
        guard let userResolver = containerEnvService.resolver as? UserResolver else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "info", value: "resolver unwrapper error")))
            return
        }
        let url = params["url"] as? String ?? ""
        let path = params["path"] as? String ?? ""
        //url 和 path 不能同时为空
        guard !(url.isEmpty&&path.isEmpty) else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "path and url")))
            return
        }
        let netConfig = userResolver.docs.netConfig ?? NetConfig.shared
        let context = netConfig.sessionFor(.default, trafficType: .default)
        let requestURLString = url.isEmpty ? "\(context.host)/\(path)" : url
        var requestBody: Data? = nil
        if method == "get" {
            
        }else if method == "post" {
            guard let json = params["params"],
                  JSONSerialization.isValidJSONObject(json) else {
                callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "params")))
                return
            }
            do {
                requestBody =  try JSONSerialization.data(withJSONObject: json)
            } catch let error {
                callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "key", value: "dict to json data fail")))
                DocsLogger.btError("dict to json data fail with error: \(error)")
                return
            }
        } else {
            callback?(.failure(error: BTLynxAPIError(code: .paramsError).insertUserInfo(key: "method", value: "\(method) not support yet")))
        }
        let request = URLRequest(method: method, url: requestURLString, body: requestBody)
        guard let request = request else {
            callback?(.failure(error: BTLynxAPIError(code: .internalError).insertUserInfo(key: "key", value: "request initializing error")))
            return
        }
        
        let needSession = params["needSession"] as? Bool ?? false
        if needSession {
                DocsRequest<JSON>(request: request)
                .set(method: DocsHTTPMethod(rawValue: method) ?? .GET)
                .set(encodeType: .urlEncodeDefault)
                .makeSelfReferenced()
                .start(rawResult: { (data, _, error) in
                    if let data = data, error == nil {
                        callback?(.success(data: BTLynxAPIBaseResult(dataString: String(bytes: data, encoding: .utf8))))
                    } else {
                        callback?(.failure(error: BTLynxAPIError(code: .serverError).insertUserInfo(key: "error", value: error?.localizedDescription ?? "return data is empty")))
                    }
                })
        } else {
            DocsLogger.btInfo("BTLynx request with URL: \(requestURLString) method: \(method)")
            let dataTask = session.dataTask(with: request) { data, _, error in
                if let error = error {
                    callback?(.failure(error: BTLynxAPIError(code: .serverError).insertUserInfo(key: "error", value: error.localizedDescription)))
                    return
                }
                if let data = data {
                    callback?(.success(data: BTLynxAPIBaseResult(dataString: String(bytes: data, encoding: .utf8))))
                } else {
                    callback?(.failure(error: BTLynxAPIError(code: .serverError).insertUserInfo(key: "error", value: "return data is empty")))
                }
            }
            dataTask.resume()
        }
    }
}
