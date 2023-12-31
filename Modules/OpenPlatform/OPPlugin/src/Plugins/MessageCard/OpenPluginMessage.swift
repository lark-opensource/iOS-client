//
//  OpenPluginMessage.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/4/19.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import OPPluginBiz
import OPFoundation
import LarkContainer
import LarkSetting

final class OpenPluginMessage: OpenBasePlugin {
    
    @Provider var opService: OpenPlatformService
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    func getTriggerContext(
        with params: OpenAPIGetTriggerContextParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIGetTriggerContextResult>) -> Void)
    {
        /// 通用错误回调方法
        let errorCallBack: ((String, OpenAPICommonErrorCode) -> Void) = { (errorMsg, code) in
            let error = OpenAPIError(code: code)
                .setMonitorMessage(errorMsg)
            callback(.failure(error: error))
            context.apiTrace.error("getTriggerContext fail \(errorMsg) \(code)")
        }
     
        guard let delegate = EMAProtocolProvider.getEMADelegate() else {
            let errorMsg = "not impl getTriggerContext method"
            errorCallBack(errorMsg, .unknown)
            return
        }
        delegate.getTriggerContext(withTriggerCode: params.triggerCode) { (result) in
            guard let validResult = result else {
                errorCallBack("getTriggerContext result empty", .unknown)
                return
            }
            guard let chatId = validResult["chatID"] as? String else {
                errorCallBack("getTriggerContext result chatID is not valid", .unknown)
                return
            }
            if self.apiUniteOpt {
                guard let gadgetContext = context.gadgetContext else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                        .setMonitorMessage("gadgetContext is nil")
                    callback(.failure(error: error))
                    return
                }
                let model = OpenChatIDsByChatIDsModel(appType: gadgetContext.uniqueID.appType, appID: gadgetContext.uniqueID.appID, chats: ["chatid": chatId], session: gadgetContext.session)
                
                var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
                header["Cookie"] = "sessionKey=\(gadgetContext.session)"
                
                FetchIDUtils.fetchOpenChatIDsByChatIDs(uniqueID: gadgetContext.uniqueID , model: model, header: header) { openChatIdDict, error in
                    guard let openChatIdDict = openChatIdDict, error == nil else {
                        let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setError(error as NSError?).setMonitorMessage("server data error")
                        callback(.failure(error: err))
                        return
                    }
                    guard let openChatItem = openChatIdDict[chatId] as? [String: Any] else {
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setErrno(OpenAPIChatErrno.NetworkDataException)
                            .setMonitorMessage("get openchatids from response data error)")
                        callback(.failure(error: error))
                        return
                    }
                    let bizType = (validResult["bizType"] as? String) ?? ""
                    guard let openChatID = openChatItem["open_chat_id"] as? String else {
                        errorCallBack("openChatID is empty", .unknown)
                        return
                    }
                    callback(.success(data: OpenAPIGetTriggerContextResult(openChatId: openChatID, bizType:bizType)))
                    context.apiTrace.info("getTriggerContext call back success")
                }
            } else {
                context.asyncCall(
                    apiName: ChatIDToOpenChatIDPlugin.apiName,
                    params: ["chatIDArray": [chatId]],
                    context: context) { result in
                    switch result {
                    case let .failure(error):
                        callback(.failure(error: error))
                    case let .success(data):
                        guard let convertResult = data as? OpenAPIChatIDToOpenChatIDResult,
                              let openChatId = convertResult[chatId]?.openChatId else {
                            errorCallBack("openChatID is empty", .unknown)
                            return
                        }
                        let bizType = (validResult["bizType"] as? String) ?? ""
                        callback(.success(data: OpenAPIGetTriggerContextResult(openChatId: openChatId, bizType:bizType)))
                        context.apiTrace.info("getTriggerContext call back success")
                        break
                    case .continue(event: _, data: _):
                        break
                    }
                }
            }
        }
    }
    
    func getBlockActionSourceDetail(
        with params: OpenAPIGetBlockSourceDetailParams,
        context: OpenAPIContext, gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIGetBlockSourceDetailResult>) -> Void)
    {
        
        opService.getBlockActionDetail(appID: gadgetContext.uniqueID.appID, triggerCode: params.triggerCode, extraInfo: nil) { error, errno, result in
            if let err = error {
                let errorMsg = err.localizedDescription
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage(errorMsg)
                    .setError(error as NSError?)
                    .setErrno(errno ?? OpenAPICommonErrno.internalError)
                    .setOuterMessage(errorMsg)
                    .setOuterCode((err as NSError).code)
                callback(.failure(error: apiError))
                context.apiTrace.error(errorMsg)
                return
            }
            guard let messageDetail = result as? [String: Any] else {
                let errorMsg = "getBlockActionSourceDetail return empty result"
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                    .setError(error as NSError?)
                callback(.failure(error: apiError))
                context.apiTrace.error(apiError.monitorMsg ?? errorMsg)
                return
            }
            callback(.success(data: OpenAPIGetBlockSourceDetailResult(messageDetail: messageDetail)))
        }
    }
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "getTriggerContext", pluginType: Self.self,
                             paramsType: OpenAPIGetTriggerContextParams.self,
                             resultType: OpenAPIGetTriggerContextResult.self) { (this, params, context, callback) in
            
            this.getTriggerContext(with: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(for: "getBlockActionSourceDetail", pluginType: Self.self,
                             paramsType: OpenAPIGetBlockSourceDetailParams.self,
                             resultType: OpenAPIGetBlockSourceDetailResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.getBlockActionSourceDetail(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}

