//
//  HttpBridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/4.
//  


import SKFoundation
import BDXServiceCenter
import BDXBridgeKit
import SwiftyJSON
import RxSwift
import Foundation

class HttpBridgeHandler: BridgeHandler {
    enum ErrorCode: Int {
        case param = -11_2000
        case inner = -11_3000
        case net = -11_4000
        case http = -11_5000
        case server = -11_6000
    }
    
    let methodName = "ccm.request"
    private static let disposeBag = DisposeBag()
    
    let handler: BDXLynxBridgeHandler
    
    init() {
        handler = { (_, _, params, callback) in
            Self.handleEvent(params: params, callback: callback)
        }
    }
    
    private static func handleEvent(params: [AnyHashable: Any]?, callback: @escaping (Int, [AnyHashable: Any]?) -> Void) {
        guard let path = params?["url"] as? String, let methodStr = params?["method"] as? String, let method = DocsHTTPMethod(rawValue: methodStr) else {
            callback(BDXBridgeStatusCode.failed.rawValue, ["errorCode": ErrorCode.param.rawValue, "message": "bridge params error", "httpCode": -1])
            return
        }
        let header = params?["header"] as? [String: String]
        var reqParams: [String: Any]?
        var encoding = ParamEncodingType.urlEncodeDefault
        if header?["Content-Type"]?.lowercased() == "application/json" {
            encoding = .jsonEncodeDefault
        }
        if method == .POST {
            reqParams = params?["body"] as? [String: Any]
        } else if method == .GET {
            reqParams = params?["params"] as? [String: Any]
        }

        let request: DocsRequest<JSON>
        let urlComponent = URLComponents(string: path)
        if urlComponent?.host != nil {
            request = DocsRequest<JSON>(url: path, params: reqParams).set(method: method).set(encodeType: encoding)
        } else {
            request = DocsRequest<JSON>(path: path, params: reqParams).set(method: method).set(encodeType: encoding)
        }
        request.rxStart()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe { response in
                guard let response = response else {
                    callback(BDXBridgeStatusCode.failed.rawValue, ["errorCode": ErrorCode.inner.rawValue, "message": "response data error", "httpCode": -1])
                    return
                }
                if let code = response["code"] as? Int, code != 0 {
                    let msg = response["msg"] as? String ?? ""
                    callback(BDXBridgeStatusCode.failed.rawValue, ["errorCode": ErrorCode.server.rawValue, "message": "server error:\(msg)", "httpCode": code])
                    return
                }
                callback(BDXBridgeStatusCode.succeeded.rawValue, ["response": response.object])
            } onError: { error in
                DocsLogger.error("Lynx http failed:\(path)")
                var mainCode: ErrorCode = .inner
                var subCode: Int = -1
                if let serverError = error as? DocsNetworkError {
                    mainCode = .server
                    subCode = serverError.code.rawValue
                } else {
                    mainCode = .net
                    subCode = (error as NSError).code
                }
                callback(BDXBridgeStatusCode.failed.rawValue, ["errorCode": mainCode.rawValue, "message": "network request error:\(error)", "httpCode": subCode])
            }
            .disposed(by: disposeBag)
    }
}
