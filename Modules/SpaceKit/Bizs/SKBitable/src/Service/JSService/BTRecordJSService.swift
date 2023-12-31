//
//  BTRecordJSService.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/6.
//

import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import SKInfra

struct GetAddRecordContentParams: SKFastDecodable {
    
    var callback: String?
    
    static func deserialized(with dictionary: [String : Any]) -> GetAddRecordContentParams {
        var model = Self.init()
        model.callback <~ (dictionary, "callback")
        return model
    }
}

struct GetRecordContentParams: SKFastDecodable {
    
    var callback: String?
    
    static func deserialized(with dictionary: [String : Any]) -> GetRecordContentParams {
        var model = Self.init()
        model.callback <~ (dictionary, "callback")
        return model
    }
}

final class BTRecordJSService: BaseJSService {
}

extension BTRecordJSService: DocsJSServiceHandler {
    
    var container: BTContainer? {
        get {
            return (registeredVC as? BitableBrowserViewController)?.container
        }
    }
    
    var handleServices: [DocsJSService] {
        return [
            .getAddRecordContent,
            .getRecordContent,
            .sendMention,
        ]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        switch DocsJSService(serviceName) {
        case .getAddRecordContent:
            getAddRecordContent(params: params)
            break
        case .getRecordContent:
            getRecordContent(params: params)
            break
        case .sendMention:
            sendMention(params: params)
            break
        default:
            ()
        }
    }
    
    // nolint: duplicated_code
    private func getRecordContent(params: [String: Any]) {
        guard UserScopeNoChangeFG.YY.bitablePerfOpenInRecordShare else {
            DocsLogger.error("getRecordContent fg closed")
            return
        }
        let model = GetRecordContentParams.deserialized(with: params)
        guard let callback = model.callback else {
            DocsLogger.error("getRecordContent invalid callback")
            return
        }
        container?.indRecordPlugin.getRecordContent(callback: { [weak self] params in
            guard let self = self else {
                return
            }
            self.model?.jsEngine.callFunction(
                DocsJSCallBack(callback),
                params: params, completion: nil
            )
        })
    }
    
    // nolint: duplicated_code
    private func getAddRecordContent(params: [String: Any]) {
        guard UserScopeNoChangeFG.YY.baseAddRecordPage else {
            DocsLogger.error("getAddRecordContent fg closed")
            return
        }
        let model = GetAddRecordContentParams.deserialized(with: params)
        guard let callback = model.callback else {
            DocsLogger.error("getAddRecordContent invalid callback")
            return
        }
        container?.addRecordPlugin.getAddRecordContent(callback: { [weak self] params in
            guard let self = self else {
                return
            }
            self.model?.jsEngine.callFunction(
                DocsJSCallBack(callback),
                params: params, completion: nil
            )
        })
    }
    
    private func sendMention(params: [String: Any]) {
        guard UserScopeNoChangeFG.YY.baseAddRecordPage else {
            DocsLogger.error("sendMention fg closed")
            return
        }
        guard let bodys = params["bodys"] as? [[String: Any]] else {
            DocsLogger.error("sendMention invalid bodys")
            return
        }
        guard bodys.count > 0 else {
            DocsLogger.error("sendMention bodys is empty")
            return
        }
        bodys.forEach { body in
            let path = OpenAPI.APIPath.mentionNotification
            let request = DocsRequest<Any>(path: path, params: body)
                .set(encodeType: .jsonEncodeDefault)
                .set(method: .POST)
                .set(needVerifyData: false)
            request.start { (data, _, error) in
                if let data = data, let result = String(data: data, encoding: .utf8) {
                    DocsLogger.info("sendMention success \(result)")
                } else {
                    let error = error ?? DocsNetworkError.invalidData
                    DocsLogger.error("sendMention failed: \(error)")
                }
            }
            request.makeSelfReferenced()
        }
    }
}


