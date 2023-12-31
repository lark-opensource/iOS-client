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
import OPPluginBiz
import ECOProbe
import OPFoundation

final class OpenAPIGetChatInfoParams: OpenAPIBaseParams {
    enum ParamKey: String {
        /// 获取会话信息的会话Id
        case openChatId
        /// 会话的类型：0 单聊，1群聊
        case chatType
        /// 单聊用户类型：0用户，1bot。chatType为0 这个参数必须传
        case userType
    }

    @OpenAPIRequiredParam(userOptionWithJsonKey: ParamKey.openChatId.rawValue, defaultValue: "")
    public var openChatID: String

    @OpenAPIRequiredParam(userOptionWithJsonKey: ParamKey.chatType.rawValue, defaultValue: 0)
    public var chatType: Int

    @OpenAPIOptionalParam(jsonKey: ParamKey.userType.rawValue)
    public var userType: Int?

    public convenience init(
        openChatID: String,
        chatType: Int,
        userType: Int?
    ) throws {
        let dict: [String: Any] = [
            ParamKey.openChatId.rawValue: openChatID,
            ParamKey.chatType.rawValue: chatType,
            ParamKey.userType.rawValue: userType
        ]
        try self.init(with: dict)
    }

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [
            _openChatID,
            _chatType,
            _userType
        ]
    }
}

final class OpenAPIGetChatInfoResult: OpenAPIBaseResult {
    /// 未读消息数
    public var badge: Int?
    /// 被at数量 （3.12.0版本增加的字段）
    public var atCount: Int
    /// chat名称
    public var name: String?
    /// 会话的头像url数组，包含多种图片分辨率
    public var avatarUrls: [String]?
    /// 国际化会话名(可能为空)
    public var i18nNames: [AnyHashable: Any]?
    public init(
        badge: Int?,
        atCount: Int = 0,
        name: String?,
        avatarUrls: [String]?,
        i18nNames: [AnyHashable: Any]?
    ) {
        self.badge = badge
        self.atCount = atCount
        self.name = name
        self.avatarUrls = avatarUrls
        self.i18nNames = i18nNames
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        var jsonDict: [AnyHashable : Any] = [:]
        if let badge = badge {
            jsonDict["badge"] = badge
        }
        jsonDict["atCount"] = atCount
        if let name = name {
            jsonDict["name"] = name
        }
        if let avatarUrls = avatarUrls, !avatarUrls.isEmpty {
            jsonDict["avatarUrls"] = avatarUrls
        }
        if let i18nNames = i18nNames, !i18nNames.isEmpty {
            jsonDict["i18nNames"] = i18nNames
        }
        return jsonDict
    }
}

extension OPPluginChat {
    public func getChatInfo(params: OpenAPIGetChatInfoParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetChatInfoResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        let openChatId = params.openChatID
        let chatType = params.chatType
        let userType = params.userType

        if (!ChatAndContactSettings.isGetChatInfoStandardizeEnabled) {
            if chatType == 0, userType == nil  {
                let errMsg = "userType is empty."
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setOuterMessage(errMsg)
                callback(.failure(error: error))
                context.apiTrace.error("getChatInfo fail errorMsg: \(errMsg)")
                return
            }
        }
        // code from 李论 (November 27th, 2020 3:49pm)
        // [MEEGO-0]feat(framework):+号相关API适配H5形态
        // H5和小程序都可以这样调用
        /// TODO：以下是判断权限相关的逻辑，如果通过fg关闭鉴权，authorization便会为空，为正常调用逻辑，后续的调用逻辑保持不变
        var hasAuth = false
        var orgAuthMapState = EMAOrgAuthorizationMapState.unknown
        // @lixiaorui：BDPAuth后期会重构，所以没直接写在OPAPIContextProtocol协议里；
        // 重构之后，是不能直接依赖BDPAuth这个class的，到时候就能写到协议里了，然后会改一波。
        if let gadgetAPIContext = gadgetContext as? GadgetAPIContext, let orgAuthMap = gadgetAPIContext.authorization?.source.orgAuthMap {
            orgAuthMapState = BDPIsEmptyDictionary(orgAuthMap) ? .empty : .notEmpty
            hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: orgAuthMap, invokeName: "getChatInfo")
        } else {
            context.apiTrace.error("getChatInfoWithParam authorization is nil")
        }
        let hostVersion = BDPDeviceTool.bundleShortVersion
        let appVersion = BDPCommonManager.shared()?.getCommonWith(uniqueID)?.model.version ?? ""
        let monitor = OPMonitor(kEventName_mp_organization_api_invoke)
            .setUniqueID(uniqueID)
            .addCategoryValue("api_name", "getChatInfo")
            .addCategoryValue("auth_name", "chatInfo")
            .addCategoryValue("has_auth", hasAuth ? 1 : 0)
            .addCategoryValue("app_version", appVersion)
            .addCategoryValue("lark_version", hostVersion)
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        context.apiTrace.info(("mp_organization_api_invoke with uniqueID:\(uniqueID), hasAuth:\(hasAuth)"))
        if !hasAuth {
            let errMsg = "no chatInfo authorization"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.organizationAuthDeny)
                .setOuterMessage(errMsg)
            callback(.failure(error: error))
            context.apiTrace.error("getChatInfo fail errorMsg: \(errMsg)")
            return
        }
        if self.apiUniteOpt {
            var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
            header["Cookie"] = "sessionKey=\(gadgetContext.session)"
            FetchIDUtils.fetchChatIDsByOpenChatIDs(uniqueID: uniqueID, model: ChatIDsByOpenChatIDsModel(appid: uniqueID.appID, session: gadgetContext.session, openChatIDs: [openChatId]), header: header, completionHandler: {(chatIDs, error) in
                guard let data = chatIDs, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setError(error)
                        .setMonitorMessage("server data error")
                    callback(.failure(error: err))
                    return
                }

                let convertedChaIDs = data.mapValues { String(describing: $0) }
                guard let chatId = convertedChaIDs[openChatId], !chatId.isEmpty else {
                    let errMsg = "empty callback chatId"
                    context.apiTrace.error(errMsg)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage(errMsg)
                    callback(.failure(error: error))
                    return
                }
                guard let openApiService = self.openApiService else {
                    let errMsg = "openApiService impl is empty"
                    context.apiTrace.error(errMsg)
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.internalError)
                        .setMonitorMessage(errMsg)
                    callback(.failure(error: error))
                    return
                }
                let chatInfo = openApiService.getChatInfo(chatID: chatId)
                var badgeNum = 0
                if let badge = chatInfo?["badge"], let num = Int("\(badge)") {
                    badgeNum = num
                }
                openApiService.getAtInfo(chatID: chatId, block: {dict in
                    var ats: Array<Any>?
                    if let atMsgs = dict?["atMsgs"], let atValues = atMsgs as? Array<Any> {
                        ats = atValues
                    }
                    self.fetchOpenChatIDsByChatIDs(gadgetContext: gadgetContext, badgeNum: badgeNum, atsCount: ats?.count ?? 0, context: context, chatId: chatId, callback: callback)
                })
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
                                .setErrno(OpenAPICommonErrno.networkFail)
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
                            guard let chatId = chatDict[openChatId], !chatId.isEmpty else {
                                let errMsg = "empty callback chatId"
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                                    .setMonitorMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            guard let delegate = EMAProtocolProvider.getEMADelegate(), delegate.responds(to: #selector(EMAProtocol.getChatInfo(_:))) else {
                                let errMsg = "no implementation"
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                                    .setErrno(OpenAPICommonErrno.unable)
                                    .setMonitorMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            context.apiTrace.info("getChatInfo chatId: \(chatId)")
                            let chatInfo = delegate.getChatInfo(chatId)
                            if chatInfo?.isEmpty ?? true {
                                context.apiTrace.error("get chatBadgeError")
                            }
                            var badgeNum = 0
                            if let badge = chatInfo?["badge"], let num = Int("\(badge)") {
                                badgeNum = num
                            }
                            guard let delegate = EMAProtocolProvider.getEMADelegate(), delegate.responds(to: #selector(EMAProtocol.getAtInfo(_:block:))) else {
                                let errMsg = "no implementation"
                                context.apiTrace.error(errMsg)
                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                                    .setErrno(OpenAPICommonErrno.unable)
                                    .setMonitorMessage(errMsg)
                                callback(.failure(error: error))
                                return
                            }
                            delegate.getAtInfo(chatId) { dict in
                                var ats: Array<Any>?
                                if let atMsgs = dict?["atMsgs"], let atValues = atMsgs as? Array<Any> {
                                    ats = atValues
                                }
                                do {
                                    let apiParams = try OpenAPIChatIDToOpenChatIDParams(chatIDs: [chatId])
                                    let _ =
                                        context.asyncCall(apiName: ChatIDToOpenChatIDPlugin.apiName,
                                                          params: apiParams,
                                                          context: context) { (result) in
                                            switch result {
                                            case .continue(event: _, data: _):
                                                break
                                            case let .failure(error):
                                                let errMsg = error.monitorMsg ?? "fetch openChatIDs failed"
                                                context.apiTrace.error(errMsg)
                                                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                                    .setErrno(OpenAPICommonErrno.networkFail)
                                                    .setMonitorMessage(errMsg)
                                                callback(.failure(error: error))
                                            case let .success(data):
                                                guard let convertResult = data as? OpenAPIChatIDToOpenChatIDResult,
                                                      let openChatItem = convertResult[chatId] else {
                                                    let errMsg = "fetch openChatIDs failed with data: \(data), chatId:\(chatId)"
                                                    context.apiTrace.error(errMsg)
                                                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                                                        .setMonitorMessage(errMsg)
                                                    callback(.failure(error: error))
                                                    return
                                                }
                                                context.apiTrace.info("getChatIDsByOpenChatIDs callback success")
                                                if hasAuth {
                                                    callback(.success(
                                                        data: OpenAPIGetChatInfoResult(
                                                            badge: badgeNum,
                                                            atCount: ats?.count ?? 0,
                                                            name: openChatItem.chatName,
                                                            avatarUrls: openChatItem.chatAvatarUrls,
                                                            i18nNames: openChatItem.chatI18nNames
                                                        )
                                                    ))
                                                } else {
                                                    let errMsg = "empty callback params with data: \(data), chatId:\(chatId)"
                                                    context.apiTrace.error(errMsg)
                                                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                                        .setErrno(OpenAPICommonErrno.unknown)
                                                        .setMonitorMessage(errMsg)
                                                    callback(.failure(error: error))
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
                        }
                    }
            } catch {
                let errMsg = error.localizedDescription ?? "OpenAPIOpenIDToChatIDParams error: \(error)"
                context.apiTrace.error(errMsg)
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage(errMsg)
                callback(.failure(error: error))
            }
        }
    }
    private func fetchOpenChatIDsByChatIDs(gadgetContext: GadgetAPIContext, badgeNum: Int, atsCount: Int, context: OpenAPIContext, chatId: String, callback: @escaping (OpenAPIBaseResponse<OpenAPIGetChatInfoResult>) -> Void) {
        var header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        header["Cookie"] = "sessionKey=\(gadgetContext.session)"
        FetchIDUtils.fetchOpenChatIDsByChatIDs(uniqueID: gadgetContext.uniqueID, model: OpenChatIDsByChatIDsModel(appType: gadgetContext.uniqueID.appType, appID: gadgetContext.uniqueID.appID, chats: ["chatid": chatId], session: gadgetContext.session), header: header, completionHandler: {(openChatIdDict, error) in
            guard let data = openChatIdDict, error == nil else {
                let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setError(error as NSError?).setMonitorMessage("server data error")
                callback(.failure(error: err))
                return
            }
            guard let openChatItem = data[chatId] as? [String: Any] else {
                let code = data["error"] as? Int ?? 0
                let msg = data["message"] as? String ?? ""
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                    .setMonitorMessage("get openchatids from response data error \(data.keys), code:\(code), msg:\(msg))")
                callback(.failure(error: error))
                return
            }
            callback(.success(
                data: OpenAPIGetChatInfoResult(
                    badge: badgeNum,
                    atCount: atsCount,
                    name: openChatItem["chat_name"] as? String,
                    avatarUrls: openChatItem["chat_avatar_urls"] as? [String],
                    i18nNames: openChatItem["chat_i18n_names"] as? [String: String]
                )
            ))
        })
    }
}
