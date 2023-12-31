//
//  OPIDConverterPlugin.swift
//  OPPlugin
//
//  Created by lixiaorui on 2021/2/9.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import OPPluginManagerAdapter
import OPSDK
import LarkContainer
import LarkSetting

final class OPIDConverterPlugin: OpenBasePlugin {
    
    static func parseOpenIDsToChatIDs(openIDs: [String], context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, completion: @escaping ([String]?, String?) -> Void) {
        func handleResult(dataDic: [AnyHashable: Any]?, response: URLResponse?, error: Error?, cipher: EMANetworkCipher, completion: @escaping ([String]?, String?) -> Void) {
            BDPExecuteOnMainQueue{
                guard let data = dataDic, error == nil else {
                    completion(nil, "chatIDsByOpenIDs network error (\(error?.localizedDescription ?? "data nil"))")
                    return
                }
                
                guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: data["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let chatIDMap = content["chatids_map"] as? [String: Int], !chatIDMap.isEmpty else {
                    let code = data["error"] as? Int ?? 0
                    let msg = data["message"] as? String ?? ""
                    completion(nil, "chatIDsByOpenIDs get chatids from response data error (code:\(code), msg:\(msg))")
                    return
                }
                
                let chatIDs = chatIDMap.map { String($0.1) }
                completion(chatIDs, nil)
            }
        }
        
        let cipher = EMANetworkCipher.getCipher()
        let url = EMAAPI.chatIDsByOpenIDsURL()
        let header: [String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        let requestParams: [String: Any] = ["appid": gadgetContext.uniqueID.appID,
                             "openids": openIDs,
                             "ttcode":cipher.encryptKey]
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.getChatIDsByOpenIDs) {
            OPECONetworkInterface.postForOpenDomain(url: url, context: OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: gadgetContext.uniqueID, source: .api), params: requestParams, header: header) { json, _, response, error in
                handleResult(dataDic: json, response: response, error: error, cipher: cipher, completion: completion)
            }
        } else {
            EMANetworkManager.shared().postUrl(url, params: requestParams, header: header, completionWithJsonData: { (dataDic, response, error) in
                handleResult(dataDic: dataDic, response: response, error: error, cipher: cipher, completion: completion)
            }, eventName: "chatIDsByOpenIDs", requestTracing: context.apiTrace.subTrace())
        }
    }

    // 个人openID转单聊会话chatID
    func getChatIDByOpenID(with params: OpenAPIOpenIDToChatIDParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenIDToChatIDResult>) -> Void) {
        
        let cipher = EMANetworkCipher.getCipher()
        let requestParams = ["appid": gadgetContext.uniqueID.appID,
                             "session": gadgetContext.session,
                             "openid": params.openID,
                             "ttcode":cipher.encryptKey]
        let header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        let networkContext = OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: gadgetContext.uniqueID, source: .api)
        pr_getChatIDByOpenID(
            requestParams: requestParams,
            header: header,
            context: context,
            cipher: cipher,
            networkContext: networkContext,
            callback: callback)
    }
    
    func pr_getChatIDByOpenID(
        requestParams: [String: Any],
        header: [String: String],
        context: OpenAPIContext,
        cipher: EMANetworkCipher,
        networkContext: ECONetworkServiceContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenIDToChatIDResult>) -> Void
    ) {
        func handleResult(dataDic: [AnyHashable: Any]?, response: URLResponse?, error: Error?, cipher: EMANetworkCipher, callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenIDToChatIDResult>) -> Void) {
            BDPExecuteOnMainQueue{
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                guard let data = dataDic, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setError(error).setMonitorMessage("server data error(logid:\(logID))")
                    callback(.failure(error: err))
                    return
                }
                guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: data["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let chatID = content["chatid"] as? String, !chatID.isEmpty else {
                    let code = data["error"] as? Int ?? 0
                    let msg = data["message"] as? String ?? ""
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("get chatids from response data error \(data.keys)(logid:\(logID), code:\(code), msg:\(msg))")
                    callback(.failure(error: error))
                    return
                }
                callback(.success(data: OpenAPIOpenIDToChatIDResult(chatID: chatID)))
            }
        }
        
        let url = EMAAPI.chatIdURL()
        
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.getChatIDByOpenID) {
            OPECONetworkInterface.postForOpenDomain(url: url,
                                       context: networkContext,
                                       params: requestParams,
                                       header: header) { json, _, response, error in
                handleResult(dataDic: json, response: response, error: error, cipher: cipher, callback: callback)
            }
        } else {
            EMANetworkManager.shared().postUrl(url, params: requestParams, header: header, completionWithJsonData: { (dataDic, response, error) in
                handleResult(dataDic: dataDic, response: response, error: error, cipher: cipher, callback: callback)
            }, eventName: "getChatIDByOpenID", requestTracing: context.apiTrace.subTrace())
        }
        
    }

    // 会话openChatID转chatID
    func getChatIDsByOpenChatIDs(with params: OpenAPIOpenChatIDToChatIDParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenChatIDToChatIDResult>) -> Void) {
        let ciper = EMANetworkCipher.getCipher()
        var sessionKey = "session"
        switch gadgetContext.uniqueID.appType {
        case .webApp:
            sessionKey = "h5Session"
        case .gadget:
            sessionKey = "minaSession"
        default:
            break
        }
        let session = gadgetContext.session
        let requestParams: [String: Codable] = ["appid": gadgetContext.uniqueID.appID,
                                            sessionKey: session,
                                            "open_chatids": params.openChatIDs,
                                            "ttcode":ciper.encryptKey]
        var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        header["Cookie"] = "sessionKey=\(session)"
        
        pr_getChatIDsByOpenChatIDs(
            requestParams: requestParams,
            header: header,
            context: context,
            cipher: ciper,
            callback: callback)
    }
    
    func pr_getChatIDsByOpenChatIDs(
        requestParams: [String: Codable],
        header: [String: String],
        context: OpenAPIContext,
        cipher: EMANetworkCipher,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenChatIDToChatIDResult>) -> Void
    ) {
        EMANetworkManager.shared().requestUrl(EMAAPI.chatIdByOpenChatIdURL(), method: "POST", params: requestParams, header: header, completionWithJsonData: { (dataDic, response, error) in
            BDPExecuteOnMainQueue{
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                guard let data = dataDic, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setError(error)
                        .setMonitorMessage("server data error(logid:\(logID))")
                    callback(.failure(error: err))
                    return
                }
                guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: data["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let chatIDs = content["chatids"] as? [String: AnyHashable] else {
                    let code = data["error"] as? Int ?? 0
                    let msg = data["message"] as? String ?? ""
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("get chatids from response data error \(data.keys)(logid:\(logID), code:\(code), msg:\(msg))")
                    callback(.failure(error: error))
                    return
                }
                /// 为什么这里需要对value转义，因为上面字典中的value是Int类型（实际上是Int64类型）
                let convertedChaIDs = chatIDs.mapValues { String(describing: $0) }
                callback(.success(data: OpenAPIOpenChatIDToChatIDResult(openChatIDToChatIDs: convertedChaIDs)))
            }
        }, eventName: "getChatIDsByOpenChatIDs", requestTracing: context.apiTrace.subTrace())
    }
    
    @FeatureGatingValue(key: "openplatform.api.extension.decouple.with.ttmicro")
    var apiExtensionEnable: Bool

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        if apiExtensionEnable {
            registerAsync(
                for: Self.apiNameGetChatIDByOpenID,
                registerInfo: .init(
                    pluginType: Self.self,
                    paramsType: OpenAPIOpenIDToChatIDParams.self,
                    resultType: OpenAPIOpenIDToChatIDResult.self),
                extensionInfo: .init(
                    type: OpenAPIContactExtension.self,
                    defaultCanBeUsed: false)) {
                    Self.getChatIDByOpenID($0)
                }
            
            registerAsync(
                for: Self.apiNameGetChatIDsByOpenChatIDs,
                registerInfo: .init(
                    pluginType: Self.self,
                    paramsType: OpenAPIOpenChatIDToChatIDParams.self,
                    resultType: OpenAPIOpenChatIDToChatIDResult.self),
                extensionInfo: .init(
                    type: OpenAPIChatIDExtension.self,
                    defaultCanBeUsed: false)) {
                    Self.getChatIDsByOpenChatIDs($0)
                }
        } else {
        registerInstanceAsyncHandlerGadget(for: Self.apiNameGetChatIDByOpenID, pluginType: Self.self,
                              paramsType: OpenAPIOpenIDToChatIDParams.self,
                              resultType: OpenAPIOpenIDToChatIDResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getChatIDByOpenID(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

        registerInstanceAsyncHandlerGadget(for: Self.apiNameGetChatIDsByOpenChatIDs, pluginType: Self.self,
                              paramsType: OpenAPIOpenChatIDToChatIDParams.self,
                              resultType: OpenAPIOpenChatIDToChatIDResult.self) { (this, params, context, gadgetContext, callback) in
            this.getChatIDsByOpenChatIDs(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        }
    }

    /// getChatIDByOpenID api name key
    static let apiNameGetChatIDByOpenID = "getChatIDByOpenID"
    /// getChatIDByOpenID api name key
    static let apiNameGetChatIDsByOpenChatIDs = "getChatIDsByOpenChatIDs"

}

extension OPIDConverterPlugin {
    
    // 个人openID转单聊会话chatID
    func getChatIDByOpenID(
        params: OpenAPIOpenIDToChatIDParams,
        context: OpenAPIContext,
        contactExtension: OpenAPIContactExtension,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenIDToChatIDResult>) -> Void)
    {
        let cipher = EMANetworkCipher.getCipher()
        let requestParams = contactExtension.requestParams(openid: params.openID, ttcode: cipher.encryptKey)
        let header = contactExtension.sessionExtension.sessionHeader()
        let networkContext = contactExtension.networkContext()
        
        pr_getChatIDByOpenID(
            requestParams: requestParams,
            header: header,
            context: context,
            cipher: cipher,
            networkContext: networkContext,
            callback: callback)
    }
    
    func getChatIDsByOpenChatIDs(
        params: OpenAPIOpenChatIDToChatIDParams,
        context: OpenAPIContext,
        chatIDExtension: OpenAPIChatIDExtension,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIOpenChatIDToChatIDResult>) -> Void)
    {
        let cipher = EMANetworkCipher.getCipher()
        let requestParams = chatIDExtension.requestParams(openChatIDs: params.openChatIDs, ttcode: cipher.encryptKey)
        let header = chatIDExtension.sessionHeader()
        
        pr_getChatIDsByOpenChatIDs(
            requestParams: requestParams,
            header: header,
            context: context,
            cipher: cipher,
            callback: callback)
    }
}
