//
//  ChatIDToOpenChatIDPlugin.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LarkOPInterface
import OPPluginManagerAdapter
import OPSDK
import LarkContainer

final class ChatIDToOpenChatIDPlugin: OpenBasePlugin {
    // 会话openChatID转chatID
    public func getOpenChatIDsByChatIDs(
        with params: OpenAPIChatIDToOpenChatIDParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIChatIDToOpenChatIDResult>) -> Void
    ) {
        func handleResult(dataDic: [AnyHashable: Any]?, response: URLResponse?, error: Error?, cipher: EMANetworkCipher, callback: @escaping (OpenAPIBaseResponse<OpenAPIChatIDToOpenChatIDResult>) -> Void) {
            BDPExecuteOnMainQueue{
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                guard let data = dataDic, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setError(error as NSError?).setMonitorMessage("server data error(logid:\(logID))")
                    callback(.failure(error: err))
                    return
                }
                guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: data["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let openChatIDs = content["openchatids"] as? [String: Any] else {
                    let code = data["error"] as? Int ?? 0
                    let msg = data["message"] as? String ?? ""
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("get openchatids from response data error \(data.keys)(logid:\(logID), code:\(code), msg:\(msg))")
                    callback(.failure(error: error))
                    return
                }
                callback(.success(data: OpenAPIChatIDToOpenChatIDResult(chatIDToOpenChatIDs: openChatIDs,
                                                                        apiTrace: context.apiTrace)))
            }
        }
        
        let cipher = EMANetworkCipher()
        let url = EMAAPI.openChatIdsByChatIdsURL()
        var sessionKey = "session"
        switch (context.additionalInfo["uniqueID"] as? OPAppUniqueID)?.appType ?? .unknown {
        case .webApp:
            sessionKey = "h5Session"
        case .gadget:
            sessionKey = "minaSession"
        default:
            break
        }
        let session = gadgetContext.session
        let requestParams: [String: Any] = [
            "appid": gadgetContext.uniqueID.appID,
            sessionKey: session,
            "chats": params.chatIDArray.map({ (ID) -> [String: String] in
                return ["chatid": ID]
            }),
            "ttcode":cipher.encryptKey
        ]
        var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        header["Cookie"] = "sessionKey=\(session)"
        
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.getOpenChatIDsByChatIDs) {
            OPECONetworkInterface.postForOpenDomain(url: url, context: OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: gadgetContext.uniqueID, source: .api), params: requestParams, header: header) { json, _, response, error in
                handleResult(dataDic: json, response: response, error: error, cipher: cipher, callback: callback)
            }
        } else {
            EMANetworkManager.shared().requestUrl(
                url,
                method: "POST",
                params: requestParams,
                header: header,
                completionWithJsonData: { (dataDic, response, error) in
                    handleResult(dataDic: dataDic, response: response, error: error, cipher: cipher, callback: callback)
                },
                eventName: "getChatIDsByOpenChatIDs", requestTracing: nil
            )
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        // 注册API及对应的Handler
        registerInstanceAsyncHandlerGadget(for: Self.apiName, pluginType: Self.self,
                              paramsType: OpenAPIChatIDToOpenChatIDParams.self,
                              resultType: OpenAPIChatIDToOpenChatIDResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getOpenChatIDsByChatIDs(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
    public static let apiName = "getOpenChatIdbyChatId"
}


