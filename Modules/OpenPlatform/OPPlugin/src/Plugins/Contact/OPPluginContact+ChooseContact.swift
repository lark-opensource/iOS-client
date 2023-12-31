//
//  EMAPluginContact.m
//  Action
//
//  Created by yin on 2019/6/10.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import LarkOPInterface
import OPPluginBiz
import ECOProbe
import OPFoundation

extension OpenAPIChooseContactAPIExEmployeeFilterType: OpenAPIEnum {}

// MARK: - chooseContact

final class OpenAPIChooseContactParams: OpenAPIBaseParams {
    /// 是否多选
    @OpenAPIRequiredParam(userOptionWithJsonKey: "multi", defaultValue: true)
    public var multi: Bool

    /// 选择列表中是否排除当前用户，true：排除，false：不排除
    @OpenAPIRequiredParam(userOptionWithJsonKey: "ignore", defaultValue: false)
    public var ignore: Bool

    /// 指定已选取的openId数组。
    @OpenAPIOptionalParam(jsonKey: "choosenIds")
    public var choosenIds: [String]?

    /// 指定已选取的openId数组。
    @OpenAPIOptionalParam(jsonKey: "chosenIds")
    public var chosenIds: [String]?

    /// 联系人置灰、不可选择状态。 单选暂不支持。
    @OpenAPIOptionalParam(jsonKey: "disableChosenIds")
    public var disableChosenIds: [String]?

    /// 多选时候最大选人数量。
    @OpenAPIOptionalParam(jsonKey: "maxNum")
    public var maxNum: Int?

    /// 达到选人上限时的提示文案。
    @OpenAPIOptionalParam(jsonKey: "limitTips")
    public var limitTips: String?

    /// 选择联系人列表是否包含外部联系人，默认包含。
    @OpenAPIRequiredParam(userOptionWithJsonKey: "externalContact", defaultValue: true)
    public var externalContact: Bool
    
    /// 是否可以搜索到外部联系人
    @OpenAPIOptionalParam(jsonKey: "enableExternalSearch")
    public var enableExternalSearch: Bool?
    
    /// 是否包含 关联组织
    @OpenAPIOptionalParam(jsonKey: "showRelatedOrganizations")
    public var showRelatedOrganizations: Bool?

    /// code from yiying.1 (April 12th, 2021 4:47pm)
    /// feat(api): choosecontact增加联系人
    @OpenAPIRequiredParam(userOptionWithJsonKey: "enableChooseDepartment", defaultValue: false)
    public var enableChooseDepartment: Bool
    
    /// 搜索里是否能搜到离职/在职人员的选项
    @OpenAPIOptionalParam(jsonKey: "exEmployeeFilterType")
    public var exEmployeeFilterType: OpenAPIChooseContactAPIExEmployeeFilterType?

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_multi, _ignore, _choosenIds, _chosenIds, _disableChosenIds, _maxNum, _limitTips, _externalContact, _enableExternalSearch, _showRelatedOrganizations, _enableChooseDepartment, _exEmployeeFilterType]
    }
}

final class OpenAPIChooseContactResult: OpenAPIBaseResult {
    public var data: [[AnyHashable: Any]]?
    public var departmentItems: [[AnyHashable: Any]]?
    public init(departmentItems: [[AnyHashable: Any]]? = nil, data: [[AnyHashable: Any]]? = nil) {
        self.data = data
        self.departmentItems = departmentItems
        super.init()
    }
    public override func toJSONDict() -> [AnyHashable : Any] {
        var jsonDict: [AnyHashable : Any] = [:]
        if let data = data, !data.isEmpty {
            jsonDict["data"] = data
        }
        if let departmentItems = departmentItems {
            jsonDict["department_data"] = departmentItems
        }
        return jsonDict
    }
}

extension OPPluginContact {
    private func exEmployeeFilterParamEnabled(_ uniqueID: OPAppUniqueID) -> Bool {
        let config = exEmployeeFilterParamConfig
        
        let containersMap: [OPAppType: String] = [
            .gadget: "GadgetAPP",
            .webApp: "WebAPP",
            .block: "BlockitApp"
        ]
        
        guard let containers = config["containers"] as? [String],
              let container = containersMap[uniqueID.appType],
                containers.contains(container) else {
            return false
        }
        
        guard let apps = config["apps"] as? [String], apps.contains(uniqueID.appID) else {
            return false
        }
        
        return true
    }
    
    /// 选择联系人
    /// code from yinhao (June 10th, 2019 8:21pm)
    /// [SUITE-12275]: 小程序API支持获取会话列表
    public func chooseContact(params: OpenAPIChooseContactParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIChooseContactResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        let multi = params.multi
        let ignore = params.ignore
        let externalContact = params.externalContact
        let enableExternalSearch = params.enableExternalSearch as NSNumber?
        let showRelatedOrganizations = params.showRelatedOrganizations as NSNumber?
        let enableChooseDepartment = params.enableChooseDepartment
        let hasMaxNum = (params.maxNum != nil)
        let maxNum = params.maxNum ?? 0
        let limitTips = params.limitTips ?? NSString(format: BDPI18n.contact_max_num as NSString, maxNum.description) as String
        let disableIDs = params.disableChosenIds ?? []
        let exEmployeeFilterType: String? = exEmployeeFilterParamEnabled(uniqueID) ? params.exEmployeeFilterType?.rawValue : nil
        var hasAuth = false
        var orgAuthMapState = EMAOrgAuthorizationMapState.unknown
        if uniqueID.appType == .block || uniqueID.appType == .thirdNativeApp {
            // Block 不在这里进行权限校验，前置校验，这里直接放过;nativeApp先暂时放行，后续需求补上组织鉴权相关
            hasAuth = true
        } else {
            // @lixiaorui：BDPAuth后期会重构，所以没直接写在OPAPIContextProtocol协议里；
            // 重构之后，是不能直接依赖BDPAuth这个class的，到时候就能写到协议里了，然后会改一波。
            if let gadgetAPIContext = gadgetContext as? GadgetAPIContext, let orgAuthMap = gadgetAPIContext.authorization?.source.orgAuthMap {
                orgAuthMapState = BDPIsEmptyDictionary(orgAuthMap) ? .empty : .notEmpty
                hasAuth = EMAOrgAuthorization.orgAuth(withAuthScopes: orgAuthMap, invokeName: "chooseContact")
            }
        }
        let hostVersion = BDPDeviceTool.bundleShortVersion
        let appVersion = BDPCommonManager.shared()?.getCommonWith(uniqueID)?.model.version ?? ""
        OPMonitor(kEventName_mp_organization_api_invoke)
            .setUniqueID(uniqueID)
            .addCategoryValue("api_name", "chooseContact")
            .addCategoryValue("auth_name", "userInfo")
            .addCategoryValue("has_auth", hasAuth ? 1 : 0)
            .addCategoryValue("app_version", appVersion)
            .addCategoryValue("lark_version", hostVersion)
            .addCategoryValue("org_auth_map", "\(orgAuthMapState.rawValue)")
            .flush()
        context.apiTrace.info("mp_organization_api_invoke uniqueID:\(uniqueID), hasAuth: \(hasAuth)")
        BDPExecuteOnMainQueue {
            var chooseIDs: [String] = []
            if multi {
                if let chosenIds = params.chosenIds, !chosenIds.isEmpty {
                    chooseIDs = chosenIds
                } else if let choosenIds = params.choosenIds, !choosenIds.isEmpty {
                    chooseIDs = choosenIds
                }
            }
            self.fetchUserIDs(
                openChoosenIDs: chooseIDs,
                openDisableIds: disableIDs,
                context: context,
                gadgetContext: gadgetContext) { (choosenUserIdDs, disableUserIdDs) in
                    let selectedChatterNamesBlock: (([String]?, [String]?, [String]?) ->(() -> Void)?) = { [weak self] (_chatterNames, _chatterIDs, _departmentIDs) -> (() -> Void)? in
                        let chatterNames = _chatterNames ?? []
                        let chatterIDs = _chatterIDs ?? []
                        let departmentIDs = _departmentIDs ?? []
                        /// 选择联系人共有两次回调：1）传过来选择了哪些联系人 2）选择结束，此时联系人为nil
                        /// 故需要防止传给js两次回调
                        guard let `self` = self else {
                            let errMsg = "self is released"
                            let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage(errMsg)
                                .setErrno(OpenAPICommonErrno.unknown)
                            context.apiTrace.error(errMsg)
                            callback(.failure(error: err))
                            return {}
                        }
                        let isNotFinished = self.chooseContactCallback != nil ? true : false
                        self.isSelectChatterNamesVCPresented = false
                        self.chooseContactCallback = nil
                            
                        let fetchUserInfos: ([String], OpenAPIContext, OPAPIContextProtocol, [[String: String]]) -> Void = {
                            chatterIDs, context, gadgetContext, departmentItems in
                            // 没有选择个人
                            if chatterNames.isEmpty {
                                if !departmentItems.isEmpty {
                                    context.apiTrace.info("CallBackTypeSuccess only department")
                                    callback(.success(data: OpenAPIChooseContactResult(departmentItems: enableChooseDepartment ? departmentItems : nil)))
                                    return
                                } else {
                                    // 说明取消选择联系人
                                    if (isNotFinished) {
                                        if ChatAndContactSettings.isChooseContactStandardizeEnabled {
                                            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                                                .setErrno(OpenAPIContactErrno.cancel)
                                                .setMonitorMessage("Cancel")
                                            callback(.failure(error: error))
                                        } else {
                                            callback(.success(data: nil))
                                        }
                                    }
                                    context.apiTrace.info("isNotFinished: \(isNotFinished)")
                                    return
                                }
                            }
                            /// 选择联系人>=1之后才会去将larkID -> openID
                            let count = chatterNames.count <= chatterIDs.count ? chatterNames.count: chatterIDs.count
                            self.fetchUserInfos(
                                larkIDs: chatterIDs,
                                context: context,
                                gadgetContext: gadgetContext
                            ) { (userInfos, error) in
                                // 过滤网络错误
                                if let error = error {
                                    if !departmentItems.isEmpty {
                                        context.apiTrace.info("CallBackTypeSuccess only department")
                                        callback(.success(data: OpenAPIChooseContactResult(departmentItems: enableChooseDepartment ? departmentItems : nil)))
                                        return
                                    } else {
                                        context.apiTrace.info("fetchOpenIDsByLarkIDs error: \(error)")
                                        callback(.failure(error: error))
                                        return
                                    }
                                }
                                var openArr: [[AnyHashable: Any]] = []
                                // 过滤空数据
                                if userInfos.isEmpty {
                                    if !departmentItems.isEmpty {
                                        context.apiTrace.info("CallBackTypeSuccess only department")
                                        callback(.success(data: OpenAPIChooseContactResult(departmentItems: enableChooseDepartment ? departmentItems : nil)))
                                        return
                                    } else {
                                        /// openIDs 为空
                                        let errMsg = "openIDs is empty."
                                        context.apiTrace.error(errMsg)
                                        let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                            .setOuterMessage(errMsg)
                                            .setErrno(OpenAPIContactErrno.NetworkDataException)
                                        context.apiTrace.info(errMsg)
                                        callback(.failure(error: err))
                                        return
                                    }
                                } else {
                                    for i in 0..<count {
                                        if let userInfo = userInfos[chatterIDs[i]] as? [AnyHashable: Any], !userInfo.isEmpty {
                                            var elementDict: [AnyHashable: Any] = [:]
                                            elementDict["openId"] = userInfo["openid"]
                                            elementDict["unionId"] = userInfo["union_id"]
                                            if hasAuth {
                                                elementDict["name"] = userInfo["name"]
                                                elementDict["i18nNames"] = userInfo["i18n_name"]
                                                elementDict["avatarUrls"] = userInfo["avatar_urls"]
                                                elementDict["displayName"] = userInfo["display_name"]
                                                elementDict["i18nDisplayNames"] = userInfo["i18n_display_name"]
                                            }
                                            openArr.append(elementDict)
                                        }
                                    }
                                }
                                let result = OpenAPIChooseContactResult(departmentItems: enableChooseDepartment ? departmentItems : nil, data: openArr)
                                context.apiTrace.info("CallBackTypeSuccess: \(result.toJSONDict())")
                                callback(.success(data: result))
                            }
                        }
                        
                        // 根据departmentIds获取openDepartmentIds
                        var departmentItems: [[String: String]] = []
                        if !departmentIDs.isEmpty {
                            self.getOpenDepartmentIDs(
                                context: context,
                                gadgetContext: gadgetContext,
                                departmentIDs: departmentIDs
                            ){ departmentDataList, error in
                                if let error = error {
                                    callback(.failure(error: error))
                                    return
                                }
                                departmentIDs.forEach { departmentId in
                                    if let openDepartmentId = departmentDataList[departmentId] as? String {
                                        departmentItems.append(["departmentId": departmentId, "openDepartmentId": openDepartmentId])
                                    }
                                }
                                fetchUserInfos(chatterIDs, context, gadgetContext, departmentItems)
                            }
                        } else {
                            fetchUserInfos(chatterIDs, context, gadgetContext, departmentItems)
                        }
                        return nil
                    }
                    if Self.apiUniteOpt {
                        let config = ChooseContactConfig(multi: multi, ignore: ignore, externalContact: externalContact, enableExternalSearch: enableExternalSearch?.boolValue, showRelatedOrganizations: showRelatedOrganizations?.boolValue, enableChooseDepartment: enableChooseDepartment, selectedUserIDs: choosenUserIdDs, hasMaxNum: hasMaxNum, maxNum: maxNum, limitTips: limitTips, disableIds: disableUserIdDs, exEmployeeFilterType: exEmployeeFilterType)
                        guard let sourceVC = gadgetContext.controller else {
                            let errMsg = "can not find sourceVC"
                            let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage(errMsg)
                                .setErrno(OpenAPICommonErrno.unknown)
                            context.apiTrace.error(errMsg)
                            callback(.failure(error: err))
                            return
                        }
                        guard let openApiService = self.openApiService else {
                            let errMsg = "openApiService impl is empty"
                            let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage(errMsg)
                                .setErrno(OpenAPICommonErrno.unknown)
                            context.apiTrace.error(errMsg)
                            callback(.failure(error: err))
                            return
                        }
                        let presentCompletion: (() -> Void) = {
                            self.chooseContactCallback = callback
                            self.isSelectChatterNamesVCPresented = true
                        }
                        openApiService.chooseContact(config: config, sourceVC: sourceVC, presentCompletion: presentCompletion, selectedNameCompletion: selectedChatterNamesBlock)
                    } else {
                        //  仅移动层级，完全不改变逻辑
                        guard let getPickChatterVCBlock = EMARouteMediator.sharedInstance().getPickChatterVCBlock else {
                            let errMsg = "lark has not impl getPickChatterVCBlock"
                            let err = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                                .setMonitorMessage(errMsg)
                                .setErrno(OpenAPICommonErrno.unable)
                            context.apiTrace.error(errMsg)
                            callback(.failure(error: err))
                            return
                        }
                        
                        guard let contactVC = getPickChatterVCBlock(multi, ignore, externalContact, enableExternalSearch, showRelatedOrganizations, enableChooseDepartment, choosenUserIdDs, hasMaxNum, maxNum, limitTips, disableUserIdDs, exEmployeeFilterType) else {
                            let errMsg = "can not find contactVC"
                            let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setMonitorMessage(errMsg)
                                .setErrno(OpenAPICommonErrno.unknown)
                            context.apiTrace.error(errMsg)
                            callback(.failure(error: err))
                            return
                        }
                        EMARouteMediator.sharedInstance().selectChatterNamesBlock = selectedChatterNamesBlock
                        //TODO yinhao
                        let sourceVC = gadgetContext.controller
                        // code from lilun.ios(March 25th, 2021 4:11pm)
                        // 消息卡片- 按钮标题折行方式bugfix
                        //这儿一定要做iPhone与iPad的判断，因为这儿只有iPhone可以present，iPad需pop，所以这儿actVC.popoverPresentationController.sourceView = self.view;在iPad下必须有，不然iPad会crash，self.view你可以换成任何view，你可以理解为弹出的窗需要找个依托。
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            contactVC.modalPresentationStyle = .formSheet
                            contactVC.popoverPresentationController?.sourceView = sourceVC?.view
                        } else {
                            contactVC.modalPresentationStyle = .fullScreen
                        }
                        sourceVC?.present(contactVC, animated: true, completion: {
                            self.chooseContactCallback = callback
                            self.isSelectChatterNamesVCPresented = true
                        })
                    }
            }
        }
    }

    /// departmentID -> openDepartmentID
    func getOpenDepartmentIDs(
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        departmentIDs: [String],
        callback: @escaping ((_ departmentData: [AnyHashable: Any], _ error: OpenAPIError?) -> Void)) {
        
        var parameters: [String : Any] = [
            "appid": gadgetContext.uniqueID.appID ?? "",
            "session": gadgetContext.session ?? "",
            "depids": departmentIDs.compactMap { Int($0) }
        ]
        
        var sessionKey = "minaSession"
        if gadgetContext.uniqueID.appType == .webApp {
            sessionKey = "h5Session"
        }
        parameters[sessionKey] = gadgetContext.session
            
        let completionHandler: ([AnyHashable : Any]?, Error?) -> Void = {
            (result, error) in
            if let error = error {
                context.apiTrace.error("network internal error", error: error)
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPICommonErrno.networkFail)
                errorInfo.setAddtionalInfo(OpenAPIConfigError.networkError.errorInfo)
                callback([:], errorInfo)
                return
            }
            guard let result = result else {
                context.apiTrace.error("internal error: result is nil")
                let errorInfo = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setErrno(OpenAPIContactErrno.NetworkDataException)
                errorInfo.setAddtionalInfo(OpenAPIConfigError.invalidDataFormat.errorInfo)
                callback([:], errorInfo)
                return
            }
            context.apiTrace.info("get DepartmentData success")
            callback(result, nil)
            return
        }
        let ecoContext = OpenECONetworkAppContext(trace: context.getTrace(), uniqueId: gadgetContext.uniqueID, source: .api)
        ChooseContactNetworkInterface.getOpenDepartmentIDs(with: ecoContext, parameters: parameters, completionHandler: completionHandler)
        return
    }

    /// 获取联系人信息
    func fetchUserInfos(
        larkIDs: [String],
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        completionHandler: @escaping ((_ userInfos: [AnyHashable: Any], _ error: OpenAPIError?) -> Void)
    ) {
        let cipher = EMANetworkCipher.getCipher()
        func handleResult(dataDic: [AnyHashable: Any]?, response: URLResponse?, error: Error?, completionHandler: @escaping ((_ userInfos: [AnyHashable: Any], _ error: OpenAPIError?) -> Void)) {
            BDPExecuteOnMainQueue{
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                guard let openIDDict = dataDic, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setError(error as NSError?)
                        .setMonitorMessage("server data error(logid:\(logID))")
                        .setOuterMessage(error?.localizedDescription ?? "")
                    context.apiTrace.error(error?.localizedDescription ?? "")
                    monitor
                        .setResultTypeFail()
                        .setError(error)
                        .flush()
                    completionHandler([:], err)
                    return
                }
                monitor.setResultTypeSuccess()
                    .timing()
                    .flush()

                guard let encryptedContent = openIDDict["encryptedData"] as? String, let decryptedDict = EMANetworkCipher.decryptDict(forEncryptedContent: encryptedContent, cipher: cipher) as? [AnyHashable: Any]
                else {
                    let code = openIDDict["error"] as? Int ?? 0
                    let msg = openIDDict["message"] as? String ?? ""
                    let errMsg = "decrypt content failed with dataDic: \(dataDic)(logid:\(logID), code:\(code), msg:\(msg))"
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIContactErrno.NetworkDataException)
                        .setMonitorMessage(errMsg)
                    context.apiTrace.error(errMsg)
                    completionHandler([:], err)
                    return
                }
                guard let userInfos = decryptedDict["open_user_summary"] as? [AnyHashable: Any] else {
                    let errMsg = "Network data content not have open_user_summary \(decryptedDict)"
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIContactErrno.NetworkDataException)
                        .setMonitorMessage(errMsg)
                    context.apiTrace.error(errMsg)
                    completionHandler([:], err)
                    return
                }
                context.apiTrace.info("fetchUserInfos success with userInfos:\(userInfos)")
                completionHandler(userInfos, nil)
            }
        }
        
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("fetchUserInfosByLarkIDs, larkIds: \(larkIDs), app=\(uniqueID)")
        let session = gadgetContext.session
        if larkIDs.isEmpty {
            completionHandler([:], nil)
            return
        }
        let url = EMAAPI.contactInfosURL()
        let appType = uniqueID.appType
        var sessionKey = "minaSession"
        if appType == .webApp {
            sessionKey = "h5Session"
        }
        let params: [String: Any] = [
            "appid": uniqueID.appID,
            "session": session,
            sessionKey: session,
            "userids": larkIDs,
            "ttcode": cipher.encryptKey
        ]
        let monitor = OPMonitor(kEventName_mp_fetch_openid).setUniqueID(uniqueID).timing().tracing(context.apiTrace)
        var header: [String: String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        if let userSession = EMARequestUtil.userSession() {
            header["Cookie"] = "session=\(userSession)"
        }
        
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.getOpenUserSummary) {
            OPECONetworkInterface.postForOpenDomain(url: url, context: OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: gadgetContext.uniqueID, source: .api), params: params, header: header) { json, _, response, error in
                handleResult(dataDic: json, response: response, error: error, completionHandler: completionHandler)
            }
        } else {
            EMANetworkManager.shared().requestUrl(
                url,
                method: "POST",
                params: params,
                header: header,
                completionWithJsonData: { (dataDic, response, error) in
                    handleResult(dataDic: dataDic, response: response, error: error, completionHandler: completionHandler)
                },
                eventName: "getOpenUserSummary", requestTracing: context.apiTrace.subTrace()
            )
        }
    }

    /// 选择联系人
    func fetchUserIDs(
        openChoosenIDs: [String],
        openDisableIds: [String],
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        completion: @escaping ((_ choosenUserIDs: [String], _ disableUserIDs: [String]) -> Void)
    ) {
        var openIds: [String] = []
        openIds.append(contentsOf: openChoosenIDs)
        openIds.append(contentsOf: openDisableIds)

        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("fetchUserIDs, openChoosenIDs: \(openChoosenIDs), openDisableIds: \(openDisableIds), app=\(uniqueID)")
        Self.fetchUserIDs(
            openIDs: openIds,
            context: context,
            gadgetContext: gadgetContext) { (userIDDict, error) in
            context.apiTrace.info("fetchUserIDs completed with userIDDict: \(userIDDict), error: \(error)")
            var choosenIds: [String] = []
            openChoosenIDs.forEach { openID in
                if let userID = userIDDict[openID] as? String, !userID.isEmpty {
                    choosenIds.append(userID)
                }
            }
            var disableIds: [String] = []
            openDisableIds.forEach { openID in
                if let userID = userIDDict[openID] as? String, !userID.isEmpty {
                    disableIds.append(userID)
                }
            }
            completion(choosenIds, disableIds)
        }
    }

    /// OpenIDs => UserIDs
    static func fetchUserIDs(
        openIDs: [String],
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        completionHandler: @escaping ((_ userIDDict: [AnyHashable: Any], _ error: OpenAPIError?) -> Void)
    ) {
        let cipher = EMANetworkCipher.getCipher()
        func handleResult(dataDic: [AnyHashable: Any]?, response: URLResponse?, error: Error?, completionHandler: @escaping ((_ userIDDict: [AnyHashable: Any], _ error: OpenAPIError?) -> Void)) {
            BDPExecuteOnMainQueue{
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                guard let openIDDict = dataDic, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.networkFail)
                        .setError(error as NSError?).setMonitorMessage("server data error(logid:\(logID))")
                    context.apiTrace.error(error?.localizedDescription ?? "")
                    completionHandler([:], err)
                    return
                }
                guard let encryptedContent = openIDDict["encryptedData"] as? String, let decryptedDict = EMANetworkCipher.decryptDict(forEncryptedContent: encryptedContent, cipher: cipher) as? [AnyHashable: Any]
                else {
                    let code = openIDDict["error"] as? Int ?? 0
                    let msg = openIDDict["message"] as? String ?? ""
                    let errMsg = "decrypt content failed with dataDic: \(dataDic)(logid:\(logID), code:\(code), msg:\(msg))"
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIContactErrno.NetworkDataException)
                        .setMonitorMessage(errMsg)
                    context.apiTrace.error(errMsg)
                    completionHandler([:], err)
                    return
                }
                guard let userIDDict = decryptedDict["userids"] as? [AnyHashable: Any] else {
                    let code = openIDDict["error"] as? Int ?? 0
                    let msg = openIDDict["message"] as? String ?? ""
                    let errMsg = "Network data content not have userids \(decryptedDict)"
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPIContactErrno.NetworkDataException)
                        .setMonitorMessage(errMsg)
                    context.apiTrace.error(errMsg)
                    completionHandler([:], err)
                    return
                }
                context.apiTrace.info("fetchUserInfos success with userIDDict:\(userIDDict)")
                completionHandler(userIDDict, nil)
            }
        }
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("fetchUserIDs, openIDs: \(openIDs), app=\(uniqueID)")
        if openIDs.isEmpty {
            let errMsg = "openIDs is empty"
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(errMsg)
                .setErrno(OpenAPICommonErrno.unknown)
            context.apiTrace.error(errMsg)
            completionHandler([:], error)
            return
        }
        let session = gadgetContext.session
        let url = EMAAPI.userIdsByOpenIDsURL()
        let appType = uniqueID.appType
        var sessionKey = "minaSession"
        if appType == .webApp {
            sessionKey = "h5Session"
        }
        let params: [String: Any] = [
            "appid": uniqueID.appID ,
            "session": session,
            sessionKey: session,
            "openids": openIDs,
            "ttcode": cipher.encryptKey
        ]
        var header: [String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.getUserIDsByOpenIDs) {
            let context = OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: gadgetContext.uniqueID, source: .api)
            if Self.apiUniteOpt {
                header["domain_alias"] = "open"
                header["User-Agent"] = BDPUserAgent.getString()
                let model = UserIDsByOpenIDsModel(appType: appType, appID: uniqueID.appID, openIDs: openIDs, session: session, ttcode: cipher.encryptKey)
                FetchIDUtils.fetchUserIDsByOpenIDs(uniqueID: uniqueID, model: model, header: header, completionHandler: {(response, error) in
                    handleResult(dataDic: response, response: nil, error: error, completionHandler: completionHandler)
                })
            } else {
                OPECONetworkInterface.postForOpenDomain(url: url, context: context, params: params, header: header) { json, _, response, error in
                    handleResult(dataDic: json, response: response, error: error, completionHandler: completionHandler)
                }
            }
        } else {
            EMANetworkManager.shared().postUrl(
                url,
                params: params,
                header: header,
                completionWithJsonData: { (dataDic, response, error) in
                    handleResult(dataDic: dataDic, response: response, error: error, completionHandler: completionHandler)
                },
                eventName: "getUserIDsByOpenIDs", requestTracing: nil
            )
        }
    }
}
