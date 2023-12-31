//
//  OpenPluginChat.swift
//  OPPlugin
//
//  Created by bytedance on 2021/6/16.
//

import UIKit
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginBiz
import OPPluginManagerAdapter
import OPFoundation
import LarkSetting
import LarkContainer
import LarkNavigator
import EENavigator

final class OpenPluginChatBadgeChange: OpenBasePlugin {
    
    lazy var apiUniteOpt: Bool = {
        userResolver.fg.dynamicFeatureGatingValue(with: "openplatform.open.interface.api.unite.opt")
    }()
    
    @ScopedProvider var openApiService: LarkOpenAPIService?
    
    func chooseChat(
        params: OpenPluginChooseChatRequest,
        context:OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseChatResponse>) -> Void) {
        context.apiTrace.info("chooseChat begin")
        let uniqueID = gadgetContext.uniqueID
        let hasSessionAuth = !gadgetContext.session.isEmpty
        var orgAuthMapState = EMAOrgAuthorizationMapState.unknown
        guard hasSessionAuth else {
            context.apiTrace.error("chooseChatWithParam authorization is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("no authorization")
            callback(.failure(error: error))
            return
        }
        if params.confirmTitle.isEmpty {
            params.confirmTitle = BDPI18n.chat_chosen
        }
        if params.chosenOpenIds?.count ?? 0 > 0 || params.chosenOpenChatIds?.count ?? 0 > 0 {
            params.multiSelect = true
        }
        var dict = [
            "allowCreateGroup": params.allowCreateGroup,
            "multiSelect": params.multiSelect,
            "ignoreBot": params.ignoreBot,
            "ignoreSelf": params.ignoreSelf,
            "externalChat": params.externalChat,
            "confirmDesc": params.confirmDesc,
            "showMessageInput": params.showMessageInput,
            "confirmText": params.confirmText
        ] as [String : Any]
        let chosenOpenIds = params.chosenOpenIds
        let chosenOpenChatIds = params.chosenOpenChatIds
        func auth() -> Bool {
            let orgAuthMap : [AnyHashable : Any]
            if let authorization = gadgetContext.authorization {
                orgAuthMap = authorization.source.orgAuthMap
            } else {
                context.apiTrace.info("authorization is nil")
                orgAuthMap = [AnyHashable : Any]()
            }
            orgAuthMapState = BDPIsEmptyDictionary(orgAuthMap) ? .empty : .notEmpty
            return EMAOrgAuthorization.orgAuth(withAuthScopes: orgAuthMap, invokeName: "chooseChat")
        }
        // Block 不在这里进行权限校验，前置校验，这里直接放过
        let hasAuth = uniqueID.appType == .block || auth()
        context.apiTrace.info("chooseChat auth:\(hasAuth)")
        let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let version:String
        if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
            version = common.model.version ?? ""
        } else {
            version = ""
            context.apiTrace.info("commonManager is nil?:\(BDPCommonManager.shared() == nil)")
        }
        OPMonitor(kEventName_mp_organization_api_invoke).setUniqueID(uniqueID).tracing(trace)
            .addCategoryValue("api_name", "chooseChat")
            .addCategoryValue("auth_name", "chatInfo")
            .addCategoryValue("has_auth", "\(hasAuth)")
            .addCategoryValue("app_version", version)
            .addCategoryValue("lark_version", BDPDeviceTool.bundleShortVersion ?? "")
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        guard let delegate = EMAProtocolProvider.getEMADelegate() else {
            context.apiTrace.error("chooseChat delegate is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("chooseChat delegate is nil")
            callback(.failure(error: error))
            return
        }
        let completion = { [weak self] (res: [String: Any]?, cancel: Bool) in
            guard let `self` = self else {
                context.apiTrace.error("self is nil")
                return
            }
            if cancel {
                context.apiTrace.error("chooseChat cancel")
                // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPIChatErrno.Cancel)
                    .setOuterMessage("cancel")
                callback(.failure(error: error))
                return
            }
            guard let res = res else {
                context.apiTrace.error("chooseChat response is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage("chooseChat response is nil")
                callback(.failure(error: error))
                return
            }
            guard let items = res["items"] as? [[String:Any]], !items.isEmpty else {
                context.apiTrace.error("chooseChat response items is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage("chooseChat response items is nil")
                callback(.failure(error: error))
                return
            }
            let session = gadgetContext.session
            if self.apiUniteOpt {
                let model = OpenChatIDsByChatIDsModel(appType: uniqueID.appType, appID: uniqueID.appID, session: session, chatsArray: items)
                FetchIDUtils.fetchOpenChatIDsByChatIDs(uniqueID: uniqueID, model: model) { openChatIdDict, error in
                    Self.handleOpenChatId(openChatIdDict: openChatIdDict, error: error, items: items, hasAuth: hasAuth, showMessageInput: params.showMessageInput, messageInput: res["input"] as? String, context: context, callback: callback)
                }
                
            } else {
                EMARequestUtil.fetchOpenPluginChatIDs(byChatIDs: items, uniqueID: uniqueID, session: session , sessionHeader: GadgetSessionFactory.storage(for: gadgetContext).sessionHeader) { (openChatIdDict, error) in
                    Self.handleOpenChatId(openChatIdDict: openChatIdDict, error: error, items: items, hasAuth: hasAuth, showMessageInput: params.showMessageInput, messageInput: res["input"] as? String, context: context, callback: callback)
                }
            }
        }
        self.fetchChatIdAndChatterId(
            openIds: chosenOpenIds,
            openChatIds: chosenOpenChatIds,
            context: context,
            gadgetContext: gadgetContext) {[weak self] userIds, chatIds in
                guard let `self` = self else {
                    context.apiTrace.error("self is nil")
                    return
                }
                dict["chosenOpenIds"] = userIds
                dict["chosenOpenChatIds"] = chatIds
                let safeUserIds = userIds?.map{ $0.reuseCacheMask() }
                let safeChatIds = chatIds?.map{ $0.reuseCacheMask() }
                context.apiTrace.info("chooseChat fetchChatIdAndChatterId finish \(safeUserIds ?? []) \(safeChatIds ?? [])")
                
                if self.apiUniteOpt {
                    guard let fromVC = uniqueID.window?.fromViewController ?? self.userResolver.navigator.mainSceneWindow?.fromViewController, let openApiService = self.openApiService else {
                        context.apiTrace.error("chooseChat fromVC is nil")
                        return
                    }
                    let config = ChooseChatConfig(params: dict, title: params.confirmTitle ?? "", selectType: params.selectType.rawValue, window: uniqueID.window, fromVC: fromVC, completion: completion)
                    openApiService.chooseChat(config: config)
                } else {
                    delegate.chooseChat(
                        dict,
                        title: params.confirmTitle,
                        selectType: params.selectType.rawValue,
                        uniqueID: uniqueID,
                        from: gadgetContext.controller,
                        block: completion
                    )
                }
            }
    }
    
    private static func handleOpenChatId(openChatIdDict: [AnyHashable: Any]?, error: Error?, items: [[String:Any]], hasAuth: Bool, showMessageInput: Bool, messageInput: String?, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginChooseChatResponse>) -> Void) {
        guard error == nil else {
            context.apiTrace.error("chooseChat network fail \(error?.localizedDescription ?? "")")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.networkFail)
                .setMonitorMessage("chooseChat network fail")
            callback(.failure(error: error))
            return
        }
        guard let openChatIdDict = openChatIdDict, !openChatIdDict.isEmpty else {
            context.apiTrace.error("chooseChat response chatiddict is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPIChatErrno.NetworkDataException)
                .setMonitorMessage("chooseChat response chatiddict is nil")
            callback(.failure(error: error))
            return
        }
        var dataArray = [OpenPluginChooseChatResponse.DataItem]()
        for item in items {
            let chatIdString = item["chatid"] as? String ?? ""
            let chatId = Int(chatIdString) ?? 0
            if chatId <= 0 {
                continue
            }
            if let openChatItem = openChatIdDict["\(chatId)"] as? [String : Any] {
                let id = openChatItem["open_chat_id"] as? String
                var name: String?
                var i18nNames: [String: Any]?
                var avatarUrls: [String]?
                if hasAuth {
                    name = openChatItem["chat_name"] as? String
                    i18nNames = openChatItem["chat_i18n_names"] as? [String : Any]
                    avatarUrls = openChatItem["chat_avatar_urls"] as? [String]
                }
                // 此处type标记群/单聊等选择
                let type = item["type"] as? Int ?? 0
                let types = Self.getChatTypeAndUserType(type: type)
                let i18nNamesItem = Self.getI18nNamesItem(i18nNamesObject: i18nNames)
                let newItem = OpenPluginChooseChatResponse.DataItem(
                    id: id,
                    chatType: types?.chatType,
                    userType: types?.userType,
                    avatarUrls: avatarUrls,
                    name: name,
                    i18nNames: i18nNamesItem
                )
                dataArray.append(newItem)
            } else {
                continue
            }
        }
        if dataArray.count == 0 {
            context.apiTrace.error("chooseChat callback is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setOuterMessage("get chat fail")
            callback(.failure(error: error))
            return
        }

        var message: String? = nil
        if showMessageInput {
            message = messageInput
        }
        callback(.success(data: OpenPluginChooseChatResponse(data: dataArray, message: message)))

    }

    private static func getI18nNamesItem(i18nNamesObject: [String: Any]?) -> OpenPluginChooseChatResponse.I18nNamesObject? {
        guard let realI18nNamesObject = i18nNamesObject else {
            return nil
        }
        return OpenPluginChooseChatResponse.I18nNamesObject(
            zh_cn: realI18nNamesObject["zh_cn"] as? String,
            en_us: realI18nNamesObject["en_us"] as? String,
            ja_jp: realI18nNamesObject["ja_jp"] as? String
        )
    }

    private func fetchChatIdAndChatterId(
        openIds: [String]?,
        openChatIds: [String]?,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        completion: @escaping ([String]?, [String]?) -> Void
    ) {
        if openIds?.count ?? 0 <= 0, openChatIds?.count ?? 0 <= 0 {
            completion(nil, nil)
            return
        }

        var choosenUserIds: [String] = []
        var choosenChatIds: [String] = []

        let dispatchGroup: DispatchGroup = DispatchGroup()
        if let realOpenIds = openIds {
            dispatchGroup.enter()
            OPPluginContact.fetchUserIDs(
                openIDs: realOpenIds,
                context: context,
                gadgetContext: gadgetContext) { userIDDict, error in
                    context.apiTrace.info("chooseChat fetchUserIDs success \(error == nil) \(error?.localizedDescription ?? "")")
                    realOpenIds.forEach { openID in
                        if let userID = userIDDict[openID] as? String, !userID.isEmpty {
                            choosenUserIds.append(userID)
                        }
                    }
                    dispatchGroup.leave()
                }
        }
        if let realOpenChatIds = openChatIds {
            dispatchGroup.enter()
            self.fetchChatIDsByOpenChatIDs(
                openChatIDs: realOpenChatIds,
                uniqueID: gadgetContext.uniqueID,
                context: context) { _ in
                    context.apiTrace.error("fetchChatIDsByOpenChatIDs fail")
                } successCompletionHandler: { chatDict, error in
                    context.apiTrace.info("chooseChat fetchChatIDsByOpenChatIDs success \(error == nil) \(error?.localizedDescription ?? "")")
                    guard let chatDict = chatDict else {
                        context.apiTrace.info("chooseChat fetchChatIDsByOpenChatIDs chatDict is nil")
                        dispatchGroup.leave()
                        return
                    }
                    realOpenChatIds.forEach { openChatId in
                        if let chatId = chatDict[openChatId] {
                            let realChatId = "\(chatId)"
                            if realChatId.count > 0 {
                                choosenChatIds.append(realChatId)
                            }
                        }
                    }
                    dispatchGroup.leave()
                }
        }
        dispatchGroup.notify(queue: .main) {
            completion(choosenUserIds, choosenChatIds)
        }
    }

    private static func getChatTypeAndUserType(type: Int) -> (chatType: OpenPluginChooseChatResponse.ChatTypeEnum?, userType: OpenPluginChooseChatResponse.UserTypeEnum?)? {
        /*
         1. 主端返回的 type 含义：0 是用户，1 是群聊，2 是机器人
         2. 开平的 chatType 含义: 0 是单聊，1 是群聊
         3. 开平的 userType 含义: 0 是普通用户，1 是机器人
        */
        if type == 0 {
            return (OpenPluginChooseChatResponse.ChatTypeEnum(rawValue: type), OpenPluginChooseChatResponse.UserTypeEnum(rawValue: type))
        } else if (type == 1) {
            // 群聊没有 userType
            return (OpenPluginChooseChatResponse.ChatTypeEnum(rawValue: type), nil)
        } else if (type == 2) {
            return (OpenPluginChooseChatResponse.ChatTypeEnum(rawValue: 0), OpenPluginChooseChatResponse.UserTypeEnum(rawValue: 1))
        }
        return nil
    }

    func onChatBadgeChange(
        params: OpenPluginChatBadgeChangeParams,
        context:OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("onChatBadgeChange begin")
        let uniqueID = gadgetContext.uniqueID
        let openChatId = params.openChatId
        let orgAuthMap : [AnyHashable : Any]
        if let authorization = gadgetContext.authorization {
            orgAuthMap = authorization.source.orgAuthMap
        } else {
            context.apiTrace.info("authorization is nil")
            orgAuthMap = [AnyHashable : Any]()
        }
        let hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: orgAuthMap, invokeName: "onChatBadgeChange")
        let orgAuthMapState: EMAOrgAuthorizationMapState = BDPIsEmptyDictionary(orgAuthMap) ? .empty : .notEmpty
        context.apiTrace.info("onChatBadgeChange hasAuth:\(hasAuth)")
        let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let version:String
        if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
            version = common.model.version ?? ""
        } else {
            version = ""
            context.apiTrace.info("commonManager is nil?:\(BDPCommonManager.shared() == nil)")
        }
        OPMonitor(kEventName_mp_organization_api_invoke).setUniqueID(uniqueID).tracing(trace)
            .addCategoryValue("api_name", "onChatBadgeChange")
            .addCategoryValue("auth_name", "chatInfo")
            .addCategoryValue("has_auth", "\(hasAuth)")
            .addCategoryValue("app_version", version)
            .addCategoryValue("lark_version", BDPDeviceTool.bundleShortVersion)
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        if !hasAuth {
            context.apiTrace.info("no chatInfo authorization")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.organizationAuthDeny)
                .setOuterMessage("no chatInfo authorization")
            callback(.failure(error: error))
            return
        }
        typealias completionBlock = ([AnyHashable : Any]?, Error?) -> Void
        let completionHandler:completionBlock = {
            (chatDict, error) in
                guard error == nil else {
                    context.apiTrace.info("onChatBadgeChange openChatId to chatId request fail \(error?.localizedDescription ?? "")")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setMonitorMessage("onChatBadgeChange openChatId to chatId request fail")
                    callback(.failure(error: error))
                    return
                }
                guard let chatDict = chatDict as? [String : Any] else {
                    context.apiTrace.info("onChatBadgeChange empty callback params")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("onChatBadgeChange empty callback params")
                    callback(.failure(error: error))
                    return
                }
                guard let chatId = chatDict[openChatId] else {
                    context.apiTrace.info("onChatBadgeChange empty callback chatId")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("onChatBadgeChange empty callback chatId")
                    callback(.failure(error: error))
                    return
                }
                let chatIdString = "\(chatId)"
                if chatIdString.isEmpty {
                    context.apiTrace.info("onChatBadgeChange empty callback chatId")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIChatErrno.NetworkDataException)
                        .setMonitorMessage("onChatBadgeChange empty callback chatId")
                    callback(.failure(error: error))
                    return
                }
                guard let delegate = EMAProtocolProvider.getEMADelegate() else {
                    context.apiTrace.error("onChatBadgeChange delegate is nil")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                        .setMonitorMessage("onChatBadgeChange delegate is nil")
                    callback(.failure(error: error))
                    return
                }
                delegate.onBadgeChange(chatIdString) { (res) in
                    if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID), common.isForeground == false {
                        context.apiTrace.info("onChatBadgeChange onBadgeChange isForeground")
                        return
                    }
                    // 此处的未读消息数量res?["badge"]是Int32类型，as? Int/String 都为nil，无法转型，所以有下边来回转型的操作
                    guard let badgeNum = res?["badge"] else {
                        context.apiTrace.info("onChatBadgeChange badgeNum is nil")
                        return
                    }
                    let badgeNumString = "\(badgeNum)"
                    if badgeNumString.isEmpty {
                        context.apiTrace.info("onChatBadgeChange badgeNumString is isEmpty")
                        return
                    }
                    do {
                        let fireEvent = try OpenAPIFireEventParams(event: "chatBadgeChangeObserved",
                                                                   sourceID: NSNotFound,
                                                                   data: ["openChatId":openChatId, "badge":Int(badgeNumString) ?? 0],
                                                                   preCheckType: .none,
                                                                   sceneType: .normal)
                        let result = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
                        switch result {
                        case let .failure(error: e):
                            context.apiTrace.error("fire event onChatBadgeChange fail \(e)")
                        default:
                            context.apiTrace.info("fire event onChatBadgeChange success")
                        }
                    } catch {
                        context.apiTrace.info("fire event onChatBadgeChange params error \(error)")
                    }
                }
                callback(.success(data: nil))
        };
        self.fetchChatIDsByOpenChatIDs(
            openChatIDs: [openChatId],
            uniqueID: uniqueID,
            context: context,
            failCallback: callback,
            successCompletionHandler: completionHandler
        )
    }

    private func fetchChatIDsByOpenChatIDs(
        openChatIDs: [String],
        uniqueID: OPAppUniqueID,
        context: OpenAPIContext,
        failCallback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void,
        successCompletionHandler: @escaping ([String: Any]?, Error?) -> Void
    ) {
        guard let commonManager = BDPCommonManager.shared() else {
            context.apiTrace.error("commonManager is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("commonManager is nil")
            failCallback(.failure(error: error))
            return
        }
        if self.apiUniteOpt {
            guard let gadgetContext = context.gadgetContext else {
                context.apiTrace.error("gadgetContext is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                failCallback(.failure(error: error))
                return
            }
            let model = ChatIDsByOpenChatIDsModel(appid: uniqueID.appID, session: gadgetContext.session, openChatIDs: openChatIDs)
            FetchIDUtils.fetchChatIDsByOpenChatIDs(uniqueID: uniqueID, model: model) { chatIdsDict, error in
                successCompletionHandler(chatIdsDict, error)
            }
        } else {
            guard let common = commonManager.getCommonWith(uniqueID) else {
                context.apiTrace.error("common is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.unknown)
                    .setMonitorMessage("common is nil")
                failCallback(.failure(error: error))
                return
            }
            EMANetworkObjcBridge.fetchChatIDByOpenChatIDs(with: common, openChatIDs: openChatIDs, completionHandler: successCompletionHandler)
        }
    }

    func offChatBadgeChange(
        params: OpenPluginChatBadgeChangeParams,
        context:OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        context.apiTrace.info("offChatBadgeChange begin")
        let uniqueID = gadgetContext.uniqueID
        let openChatId = params.openChatId
        let orgAuthMap : [AnyHashable : Any]
        if let authorization = gadgetContext.authorization {
            orgAuthMap = authorization.source.orgAuthMap
        } else {
            context.apiTrace.info("authorization is nil")
            orgAuthMap = [AnyHashable : Any]()
        }
        let orgAuthMapState: EMAOrgAuthorizationMapState = BDPIsEmptyDictionary(orgAuthMap) ? .empty : .notEmpty
        let hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: orgAuthMap, invokeName: "offChatBadgeChange")
        context.apiTrace.info("offChatBadgeChange hasAuth:\(hasAuth)")
        let trace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let version:String
        if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
            version = common.model.version ?? ""
        } else {
            version = ""
            context.apiTrace.info("commonManager is nil?:\(BDPCommonManager.shared() == nil)")
        }
        OPMonitor(kEventName_mp_organization_api_invoke).setUniqueID(uniqueID).tracing(trace)
            .addCategoryValue("api_name", "offChatBadgeChange")
            .addCategoryValue("auth_name", "chatInfo")
            .addCategoryValue("has_auth", "\(hasAuth)")
            .addCategoryValue("app_version", version)
            .addCategoryValue("lark_version", BDPDeviceTool.bundleShortVersion)
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        if !hasAuth {
            context.apiTrace.info("no chatInfo authorization")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.organizationAuthDeny)
                .setOuterMessage("no chatInfo authorization")
            callback(.failure(error: error))
            return
        }
        typealias completionBlock = ([AnyHashable : Any]?, Error?) -> Void
        let completionHandler:completionBlock = { (chatDict, error) in
            guard error == nil else {
                context.apiTrace.info("offChatBadgeChange openChatId to chatId request fail \(error?.localizedDescription ?? "")")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.networkFail)
                    .setMonitorMessage("offChatBadgeChange openChatId to chatId request fail")
                callback(.failure(error: error))
                return
            }
            guard let chatDict = chatDict as? [String : Any] else {
                context.apiTrace.info("offChatBadgeChange res is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                    .setMonitorMessage("offChatBadgeChange res is nil")
                callback(.failure(error: error))
                return
            }
            guard let chatId = chatDict[openChatId] else {
                context.apiTrace.info("offChatBadgeChange empty callback chatId")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                    .setMonitorMessage("offChatBadgeChange empty callback chatId")
                callback(.failure(error: error))
                return
            }
            let chatIdString = "\(chatId)"
            if chatIdString.isEmpty {
                context.apiTrace.info("offChatBadgeChange empty callback chatId")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPIChatErrno.NetworkDataException)
                    .setMonitorMessage("offChatBadgeChange empty callback chatId")
                callback(.failure(error: error))
                return
            }
            if let delegate = EMAProtocolProvider.getEMADelegate() {
                delegate.offBadgeChange(chatIdString)
            }
            callback(.success(data: nil))
        }
        self.fetchChatIDsByOpenChatIDs(
            openChatIDs: [openChatId],
            uniqueID: uniqueID,
            context: context,
            failCallback: callback,
            successCompletionHandler: completionHandler
        )
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "chooseChat", pluginType: Self.self, paramsType: OpenPluginChooseChatRequest.self, resultType: OpenPluginChooseChatResponse.self) { (this, params, context, gadgetContext, callback) in
            
            this.chooseChat(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "onChatBadgeChange", pluginType: Self.self, paramsType: OpenPluginChatBadgeChangeParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.onChatBadgeChange(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }
        registerInstanceAsyncHandlerGadget(for: "offChatBadgeChange", pluginType: Self.self, paramsType: OpenPluginChatBadgeChangeParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.offChatBadgeChange(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
        }

    }
}
