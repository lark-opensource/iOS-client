//
//  OpenPluginSendMessageCard.swift
//  OPPlugin
//
//  Created by lilun.ios on 2021/5/1.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import ECOProbe
import OPSDK
import LarkOPInterface
import OPPluginBiz
import OPFoundation
import LarkFeatureGating
import LarkSetting
import LarkContainer

final class OpenPluginSendMessageCard: OpenBasePlugin {
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    @ScopedProvider var openApiService: LarkOpenAPIService?
    
    /// 解析schema中的场景值scene
    private func getSceneFromSchema(schema: BDPSchema?) -> String? {
        guard let sceneInfo = OPUnsafeObject(BDPApplicationManager.shared().sceneInfo as? [String: Any]),
              let launchFrom = schema?.launchFrom else {
            return nil
        }
        return schema?.scene ?? (sceneInfo[launchFrom] as? String)
    }
    
    private static func sendMessageCard(chatIDs: [String]?, triggerCode: String?, scene: String, cardContent: [AnyHashable: Any], withMessage: Bool, gadgetContext: OPAPIContextProtocol, errorCallback: @escaping((OpenAPIErrorCodeProtocol, Int? , String?, [EMASendCardInfo]? ,[EMASendCardAditionalTextInfo]? ) -> Void), successCallback: @escaping (OpenAPIBaseResponse<OpenAPISendMessageCardResult>) -> Void) {
        
        guard let delegate = EMAProtocolProvider.getEMADelegate() else {
            let errorMsg = "cannot find sendMessageCard impl"
            errorCallback(OpenAPICommonErrorCode.unable,
                          EMASendMessageCardErrorCode.otherError.rawValue,
                          errorMsg, nil, nil)
            return
        }

        delegate.sendMessageCard(with: gadgetContext.uniqueID,
                                                  scene: scene,
                                                  triggerCode: triggerCode,
                                                  chatIDs: chatIDs,
                                                  cardContent: cardContent,
                                                  withMessage: withMessage) {
            (errorCode, errorMsg, failedChatIDs, sendinfos, sendTextInfos) in
            guard errorCode == EMASendMessageCardErrorCode.noError else {
                errorCallback(OpenAPICommonErrorCode.unknown, errorCode.rawValue,
                              errorMsg ?? "openChatIds send card fail \(errorCode)", sendinfos, sendTextInfos)
                return
            }
            let sendinfosArray = sendinfos?.map({ info in
                return info.toJsonObject()
            })
            successCallback(.success(data: OpenAPISendMessageCardResult(errCode: 0,
                                                                        errMsg: "sendMessageCard:ok",
                                                                        failedOpenChatIDs: [], sendCardInfo: sendinfosArray)))
        }
    }
    
    func sendMessageCard(
        with params: OpenAPISendMessageCardParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        callback: @escaping (OpenAPIBaseResponse<OpenAPISendMessageCardResult>) -> Void)
    {
        /// 通用错误回调方法
        let errorCallback: ((OpenAPIErrorCodeProtocol, Int? , String?, [EMASendCardInfo]? ,
                             [EMASendCardAditionalTextInfo]? ) -> Void) =
            { (code, outErrorCode , monitorMsg, sendcardInfos , sendTextInfos) in
            let error = OpenAPIError(code: code)
            if let outErrorCode {
                error.setOuterCode(outErrorCode)
            }
            if let monitorMsg {
                error.setMonitorMessage(monitorMsg)
            }
            if let additional = OpenAPISendMessageCardResult
                .toJSONDict(sendCardInfo: sendcardInfos,
                            sendTextInfo: sendTextInfos) {
                error.setAddtionalInfo(additional)
            }
            callback(.failure(error: error))
            context.apiTrace.error("sendMessageCard fail \(monitorMsg ?? "") \(code)")
        }
        guard let cardContent = params.cardContent else {
            let errorMsg = "sendMessageCardWithParam \(gadgetContext.uniqueID) end with \(EMASendMessageCardErrorCode.cardContentEmpty)"
            errorCallback(OpenAPICommonErrorCode.unknown, EMASendMessageCardErrorCode.cardContentEmpty.rawValue, errorMsg, nil, nil)
            return
        }
        
        let common = BDPCommonManager.shared()?.getCommonWith(gadgetContext.uniqueID)
        let scene = getSceneFromSchema(schema: common?.schema) ?? ""
        let withMessage = params.withAdditionalMessage ?? false
        if params.shouldChooseChat {
            
            guard let delegate = EMAProtocolProvider.getEMADelegate() else {
                let errorMsg = "cannot find sendMessageCard impl"
                errorCallback(OpenAPICommonErrorCode.unable,
                              EMASendMessageCardErrorCode.otherError.rawValue,
                              errorMsg, nil, nil)
                return
            }
            
            /// 需要选择会话
            var allowCreateGroup: Bool = false
            var multiSelect: Bool = true
            var externalChat: Bool = true
            var confirmTitle = ""
            var selectType: Int = 0
            var ignoreSelf: Bool = false
            var ignoreBot: Bool = false
            /// 解析选人参数
            if let chooseChatParams = params.chooseChatParams {
                allowCreateGroup = (chooseChatParams["allowCreateGroup"] as? Bool) ?? false
                multiSelect = (chooseChatParams["multiSelect"] as? Bool) ?? true
                externalChat = (chooseChatParams["externalChat"] as? Bool) ?? true
                confirmTitle = (chooseChatParams["confirmTitle"] as? String) ?? ""
                selectType = (chooseChatParams["selectType"] as? Int) ?? 0
                ignoreSelf = (chooseChatParams["ignoreSelf"] as? Bool) ?? false
                ignoreBot = (chooseChatParams["ignoreBot"] as? Bool) ?? false
            }
            let ccParams = SendMessagecardChooseChatParams(allowCreateGroup: allowCreateGroup,
                                                           multiSelect: multiSelect,
                                                           confirmTitle: confirmTitle,
                                                           externalChat: externalChat,
                                                           selectType: selectType,
                                                           ignoreSelf: ignoreSelf,
                                                           ignoreBot: ignoreBot)
            delegate.chooseSendCard(with: gadgetContext.uniqueID,
                                                     cardContent: cardContent, withMessage: withMessage,
                                                     params: ccParams) { (errorCode, errorMsg, failedChatIDs, sendinfos, sendTextInfos) in
                guard errorCode == EMASendMessageCardErrorCode.noError else {
                    //消息卡片发送错误都归到了通用的unkown，这里临时对用户取消发送单独处理一下
                    var errorCodeOfOpenApi: OpenAPIErrorCodeProtocol
                    if  errorCode == .userCancel {
                        errorCodeOfOpenApi = MessageCardSendErrorCode.userCancel
                    }else {
                        errorCodeOfOpenApi = OpenAPICommonErrorCode.unknown
                    }
                    errorCallback(errorCodeOfOpenApi, errorCode.rawValue, errorMsg ?? "choose send card fail \(errorCode)", sendinfos, sendTextInfos)
                    return
                }
                
                let sendinfosArray = sendinfos?.map({ info in
                    return info.toJsonObject()
                })
                callback(.success(data: OpenAPISendMessageCardResult(errCode: 0,
                                                                     errMsg: "sendMessageCard:ok",
                                                                     failedOpenChatIDs: [], sendCardInfo: sendinfosArray)))
            }
        } else {
            let isEmptyOpenChatIDs = params.openChatIDs?.isEmpty ?? true
            let isEmptyTriggerCode = params.triggerCode?.isEmpty ?? true
            let isEmptyOpenIDs = params.openIDs?.isEmpty ?? true
            guard !isEmptyOpenChatIDs || !isEmptyTriggerCode || !isEmptyOpenIDs else {
                let errorMessage = "sendMessageCardWithParam \(gadgetContext.uniqueID) end with \(EMASendMessageCardErrorCode.openChatIDsTriggerCodeEmpty.rawValue)"
                errorCallback(OpenAPICommonErrorCode.unknown, EMASendMessageCardErrorCode.openChatIDsTriggerCodeEmpty.rawValue, errorMessage, nil, nil)
                return
            }
            let sendMessageCardMaxIDsCount = 10
            if !isEmptyOpenChatIDs && (params.openChatIDs?.count ?? 0) > sendMessageCardMaxIDsCount {
                let errorMessage = "sendMessageCardWithParam \(gadgetContext.uniqueID) end with \(EMASendMessageCardErrorCode.openChatIDsCountExceed.rawValue)"
                errorCallback(OpenAPICommonErrorCode.unknown, EMASendMessageCardErrorCode.openChatIDsCountExceed.rawValue, errorMessage, nil, nil)
                return
            }
            if !isEmptyOpenIDs && (params.openIDs?.count ?? 0) > sendMessageCardMaxIDsCount {
                errorCallback(OpenAPICommonErrorCode.internalError, nil, "openIDs count must be less than: \(sendMessageCardMaxIDsCount)", nil, nil)
                return
            }
            
            if !isEmptyOpenChatIDs {
                // 使用新版本的接口，H5应用和小程序都走这个接口
                if self.apiUniteOpt {
                    let model = ChatIDsByOpenChatIDsModel(appid: gadgetContext.uniqueID.appID, session: gadgetContext.session, openChatIDs: params.openChatIDs ?? [])
                    var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
                    header["Cookie"] = "sessionKey=\(gadgetContext.session)"
                    FetchIDUtils.fetchChatIDsByOpenChatIDs(uniqueID: gadgetContext.uniqueID, model: model, header: header) { chatIDs, error in
                        guard let chatIds = chatIDs?.map({String(describing: $0.value)}), !chatIds.isEmpty, error == nil else {
                            errorCallback(OpenAPICommonErrorCode.unknown, EMASendMessageCardErrorCode.otherError.rawValue, "fetch chatIDs failed", nil, nil)
                            return
                        }
                        context.apiTrace.info("getChatIDsByOpenChatIDs call back success")
                        Self.sendMessageCard(chatIDs: chatIds, triggerCode: nil, scene: scene, cardContent: cardContent, withMessage: withMessage, gadgetContext: gadgetContext, errorCallback: errorCallback, successCallback: callback)
                    }
                } else {
                    context.asyncCall(apiName: OPIDConverterPlugin.apiNameGetChatIDsByOpenChatIDs,
                                      params: ["openChatIDs": params.openChatIDs ?? []],
                                      context: context) { (result) in
                        switch result {
                        case .failure(_):
                            errorCallback(OpenAPICommonErrorCode.unknown, EMASendMessageCardErrorCode.otherError.rawValue, "fetch chatIDs failed", nil, nil)
                        case .success(let data):
                            guard let convertResult = data as? OpenAPIOpenChatIDToChatIDResult,
                                  let chatIds = OPUnsafeObject(convertResult.openChatIDToChatIDs.map({ "\($0.value)" })),
                                  !chatIds.isEmpty else {
                                errorCallback(OpenAPICommonErrorCode.unknown, EMASendMessageCardErrorCode.otherError.rawValue, "fetch chatIDs failed", nil, nil)
                                return
                            }
                            context.apiTrace.info("getChatIDsByOpenChatIDs call back success")
                            Self.sendMessageCard(chatIDs: chatIds, triggerCode: nil, scene: scene, cardContent: cardContent, withMessage: withMessage, gadgetContext: gadgetContext, errorCallback: errorCallback, successCallback: callback)
                            break
                        default:
                            errorCallback(OpenAPICommonErrorCode.unknown, nil, "getChatIDsByOpenChatIDs default", nil, nil)
                            break
                        }
                    }
                }
            } else if !isEmptyOpenIDs {
                if self.apiUniteOpt {
                    let model = ChatIDsByOpenIDsModel(appid: gadgetContext.uniqueID.appID, openIDs: params.openIDs ?? [])
                    let header: [String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
                    FetchIDUtils.fetchChatIDsByOpenIDs(uniqueID: gadgetContext.uniqueID, model: model, header: header) { chatIDs, error in
                        guard error == nil else {
                            errorCallback(OpenAPICommonErrorCode.internalError, nil, error?.localizedDescription, nil, nil)
                            return
                        }
                        Self.sendMessageCard(chatIDs: chatIDs, triggerCode: nil, scene: scene, cardContent: cardContent, withMessage: withMessage, gadgetContext: gadgetContext, errorCallback: errorCallback, successCallback: callback)
                    }
                    
                } else {
                    OPIDConverterPlugin.parseOpenIDsToChatIDs(openIDs: params.openIDs ?? [], context: context, gadgetContext: gadgetContext) { (chatIDs, errMsg) in
                        guard errMsg == nil else {
                            errorCallback(OpenAPICommonErrorCode.internalError, nil, errMsg, nil, nil)
                            return
                        }
                        
                        Self.sendMessageCard(chatIDs: chatIDs, triggerCode: nil, scene: scene, cardContent: cardContent, withMessage: withMessage, gadgetContext: gadgetContext, errorCallback: errorCallback, successCallback: callback)
                    }
                }
            } else {
                Self.sendMessageCard(chatIDs: nil, triggerCode: params.triggerCode, scene: scene, cardContent: cardContent, withMessage: withMessage, gadgetContext: gadgetContext, errorCallback: errorCallback, successCallback: callback)
            }
            return
        }
    }
   
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "sendMessageCard", pluginType: Self.self,
                             paramsType: OpenAPISendMessageCardParams.self,
                             resultType: OpenAPISendMessageCardResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.sendMessageCard(with: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
}
