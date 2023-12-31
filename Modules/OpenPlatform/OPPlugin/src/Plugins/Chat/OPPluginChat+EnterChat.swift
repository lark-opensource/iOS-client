//
//  EMAPluginChat.m
//  Action
//
//  Created by yin on 2019/6/10.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import OPFoundation
import ECOProbe
import TTMicroApp
import OPPluginBiz
import LarkOPInterface

// MARK: - enterChat

final class OpenAPIEnterChatParams: OpenAPIBaseParams {
    enum ParamKey: String {
        /// 用户 openid
        case openid
        /// 会话openChatId
        case openChatId
        /// 会话chatId
        case chatid
        /// 是否需要展示会话页面左上角badge数
        case needBadge
    }

    @OpenAPIRequiredParam(userOptionWithJsonKey: ParamKey.openid.rawValue,
                          defaultValue: "")
    public var openID: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: ParamKey.openChatId.rawValue,
                          defaultValue: "")
    public var openChatID: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: ParamKey.chatid.rawValue,
                          defaultValue: "")
    public var chatID: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: ParamKey.needBadge.rawValue,
                          defaultValue: true)
    public var needBadge: Bool

    public convenience init(
        openID: String,
        openChatID: String,
        chatID: String,
        needBadge: Bool
    ) throws {
        let dict: [String: Any] = [
            ParamKey.openid.rawValue: openID,
            ParamKey.openChatId.rawValue: openChatID,
            ParamKey.chatid.rawValue: chatID,
            ParamKey.needBadge.rawValue: needBadge
        ]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [
            _openID,
            _openChatID,
            _chatID,
            _needBadge
        ]
    }
}

extension OPPluginChat {
    /// 进入聊天页
    /// code from yinhao (June 10th, 2019 8:21pm)
    /// [SUITE-12275]: 小程序API支持获取会话列表
    public func enterChat(params: OpenAPIEnterChatParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return
        }

        context.apiTrace.info("enterChat params: \(params)")
        realEnterChat(params: params, context: context, gadgetContext: gadgetContext, controller: controller, callback: callback)
    }

    public func realEnterChat(
        params: OpenAPIEnterChatParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        controller: UIViewController,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>
        ) -> Void) {
        let openId = params.openID
        let dutyId = params.chatID
        let openChatId = params.openChatID
        let showBadge = params.needBadge
        let uniqueID = gadgetContext.uniqueID

        let openIdCallBack: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) = { [weak self] result in
            guard let self = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage("self is nil")
                callback(.failure(error: error))
                return
            }
            guard !openChatId.isEmpty else {
                callback(result)
                return
            }
            switch result {
            case .failure(error: let error):
                context.apiTrace.info("openId enterChat fail, will use openChatId enterChat")
                do {
                    self.realEnterChat(params: try OpenAPIEnterChatParams(openID: "",
                                                                          openChatID: openChatId,
                                                                          chatID: dutyId,
                                                                          needBadge: showBadge),
                                       context: context,
                                       gadgetContext: gadgetContext,
                                       controller: controller,
                                       callback: callback)
                } catch {
                    callback(result)
                }
            default:
                callback(result)
            }
        }

        if !openId.isEmpty {
            if ChatAndContactSettings.isEnterChatStandardizeEnabled {
                enterChatForOpenID(
                    params: params,
                    context: context,
                    gadgetContext: gadgetContext,
                    controller: controller) { result in
                        openIdCallBack(result)
                    }
                return
            } else {
                enterChatForOpenID(
                    params: params,
                    context: context,
                    gadgetContext: gadgetContext,
                    controller: controller,
                    callback: callback
                )
                return
            }
        }
        if !openChatId.isEmpty {
            enterChatForOpenChatId(
                params: params,
                context: context,
                gadgetContext: gadgetContext,
                controller: controller,
                callback: callback
            )
            return
        }
        if !dutyId.isEmpty {
            enterChatForDutyId(
                params: params,
                context: context,
                gadgetContext: gadgetContext,
                controller: controller,
                callback: callback
            )
            return
        }
        context.apiTrace.error("enterChat failed, uniqueID: \(uniqueID), openId openChatId dutyId is empty")
        let errMsg = "openId openChatId dutyId is empty"
        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setErrno(OpenAPIChatErrno.OpenIdAndOpenChatIdCannotBothEmpty)
            .setOuterMessage(errMsg)
        callback(.failure(error: error))
    }

    /// 普通调个人聊天，js传openId,请求chatid调聊天页面
    func enterChatForOpenID(
        params: OpenAPIEnterChatParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        controller: UIViewController,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        let openId = params.openID
        let showBadge = params.needBadge
        let uniqueID = gadgetContext.uniqueID
        let appID = uniqueID.appID
        let monitor = OPMonitor(kEventName_mp_enter_chat).setUniqueID(uniqueID).timing()

        do {
            if self.apiUniteOpt {
                let model = ChatIDByOpenIDModel(appid: gadgetContext.uniqueID.appID, session: gadgetContext.session, openID: openId)
                let header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
                FetchIDUtils.fetchChatIDByOpenID(uniqueID: uniqueID, model: model, header: header, completionHandler: {(chatID, error) in
                    guard let chatID = chatID, error == nil else {
                        let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setErrno(OpenAPICommonErrno.networkFail)
                            .setError(error).setMonitorMessage("server data error")
                        callback(.failure(error: err))
                        return
                    }
                    context.apiTrace.info("enterChat chatID: \(chatID)")
                    self.enterChat(context: context, gadgetContext: gadgetContext, showBadge: showBadge, chatID: chatID)
                    callback(.success(data: nil))
                    
                })
            } else {
                let apiParams = try OpenAPIOpenIDToChatIDParams(openID: openId)
                let _ = context.asyncCall(
                    apiName: OPIDConverterPlugin.apiNameGetChatIDByOpenID,
                    params: apiParams,
                    context: context) { result in
                    BDPExecuteOnMainQueue{
                        switch result {
                        case .continue(event: _, data: _):
                            break
                        case let .failure(error):
                            let errMsg = error.monitorMsg
                            monitor
                                .setResultTypeFail()
                                .setErrorMessage(errMsg)
                                .addCategoryValue(kEventKey_app_id, appID)
                                .flush()
                            context.apiTrace.error(errMsg ?? "")
                            callback(.failure(error: error))
                        case let .success(data):
                            guard let convertResult = data as? OpenAPIOpenIDToChatIDResult,
                                  !convertResult.chatID.isEmpty
                            else {
                                let errMsg = "chatID is empty"
                                monitor
                                    .setResultTypeFail()
                                    .setErrorMessage(errMsg)
                                    .addCategoryValue(kEventKey_app_id, appID)
                                    .flush()
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                                    .setMonitorMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            let chatID = convertResult.chatID
                            guard let enterChatBlock = EMARouteMediator.sharedInstance().enterChatBlock else {
                                let errMsg = "no implementation"
                                monitor
                                    .setResultTypeFail()
                                    .setErrorMessage(errMsg)
                                    .addCategoryValue(kEventKey_app_id, appID)
                                    .flush()
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                                    .setErrno(OpenAPICommonErrno.unable)
                                    .setMonitorMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            context.apiTrace.info("enterChat chatID: \(chatID)")
                            enterChatBlock(chatID, showBadge, uniqueID, controller)
                            context.apiTrace.info("enterChat success")
                            callback(.success(data: nil))
                            monitor
                                .setResultTypeSuccess()
                                .timing()
                                .flush()
                        }
                    }
                }
            }

        } catch {
            let errMsg = error.localizedDescription ?? "OpenAPIOpenIDToChatIDParams error: \(error)"
            context.apiTrace.error(errMsg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage(errMsg)
            callback(.failure(error: error))
        }
    }

    func enterChatForOpenChatId(
        params: OpenAPIEnterChatParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        controller: UIViewController,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        let openChatId = params.openChatID
        let showBadge = params.needBadge
        let uniqueID = gadgetContext.uniqueID
        if self.apiUniteOpt {
            var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
            header["Cookie"] = "sessionKey=\(gadgetContext.session)"
            FetchIDUtils.fetchChatIDsByOpenChatIDs(uniqueID: uniqueID, model: ChatIDsByOpenChatIDsModel(appid: uniqueID.appID, session: gadgetContext.session, openChatIDs: [openChatId]), header: header, completionHandler: {(chatIDsDict, error) in
                guard let chatIDsDict = chatIDsDict, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setError(error)
                        .setMonitorMessage("server data error")
                    callback(.failure(error: err))
                    return
                }
                guard let chatId = chatIDsDict[openChatId] else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("get chatids from response data error)")
                    callback(.failure(error: error))
                    return
                }
                self.enterChat(context: context, gadgetContext: gadgetContext, showBadge: showBadge, chatID: String(describing:chatId))
                callback(.success(data: nil))
            })
        } else {
            do {
                let apiParams = try OpenAPIOpenChatIDToChatIDParams(openChatIDs: [openChatId])
                let _ =
                    context.asyncCall(apiName: OPIDConverterPlugin.apiNameGetChatIDsByOpenChatIDs,
                                      params: apiParams,
                                      context: context) { (result) in
                        switch result {
                        case .continue(event: _, data: _):
                            break
                        case let .failure(error):
                            let errMsg = error.monitorMsg ?? "fetch chatIDs failed"
                            context.apiTrace.error(errMsg)
                            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage(errMsg)
                            callback(.failure(error: error))
                        case let .success(data):
                            guard let convertResult = data as? OpenAPIOpenChatIDToChatIDResult,
                                  let chatDict = OPUnsafeObject(convertResult.openChatIDToChatIDs),
                                  !chatDict.isEmpty else {
                                let errMsg = "fetch chatIDs failed with data: \(data)"
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                                    .setMonitorMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            context.apiTrace.info("getChatIDsByOpenChatIDs callback success")
                            guard let enterChatBlock = EMARouteMediator.sharedInstance().enterChatBlock else {
                                let errMsg = "[EMARouteMediator sharedInstance].enterChatBlock is nil"
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                                    .setErrno(OpenAPICommonErrno.unable)
                                    .setOuterMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            let chatId = chatDict[openChatId]
                            context.apiTrace.info("enterChat chatId: \(chatId)")
                            enterChatBlock(chatId ?? "", showBadge, uniqueID, controller)
                            callback(.success(data: nil))
                        }
                    }
            } catch {
                let errMsg = error.localizedDescription ?? "OpenAPIOpenIDToChatIDParams error: \(error)"
                context.apiTrace.error(errMsg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                    .setErrno(OpenAPICommonErrno.unable)
                    .setMonitorMessage(errMsg)
                callback(.failure(error: error))
            }
        }
    }

    /// 值班号跳聊天,js传chat_id,直接调聊天页面
    func enterChatForDutyId(
        params: OpenAPIEnterChatParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        controller: UIViewController,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        let dutyId = params.chatID
        let showBadge = params.needBadge
        let uniqueID = gadgetContext.uniqueID
        let appID = uniqueID.appID
        if self.apiUniteOpt {
            self.enterChat(context: context, gadgetContext: gadgetContext, showBadge: showBadge, chatID: dutyId)
            context.apiTrace.info("enterChat success, dutyId: \(dutyId)")
            callback(.success(data: nil))
        } else {
            guard let enterChatBlock = EMARouteMediator.sharedInstance().enterChatBlock else {
                let errMsg = "[EMARouteMediator sharedInstance].enterChatBlock is nil"
                context.apiTrace.error(errMsg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                    .setErrno(OpenAPICommonErrno.unable)
                    .setOuterMessage(errMsg)
                callback(.failure(error: error))
                return
            }
            context.apiTrace.info("enterChat dutyId: \(dutyId)")
            enterChatBlock(dutyId, showBadge, uniqueID, controller)
            context.apiTrace.info("enterChat success")
            callback(.success(data: nil))
        }
    }
    
    private func enterChat(context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, showBadge: Bool, chatID: String) {
        let window = gadgetContext.controller?.view.window ?? gadgetContext.uniqueID.window
        let from = OPNavigatorHelper.topmostNav(window: window)
        self.openApiService?.enterChat(chatID: chatID, showBadge: showBadge, from: from)
    }
}
