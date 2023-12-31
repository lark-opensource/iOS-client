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
import OPFoundation
import ECOProbe
import OPPluginBiz

// MARK: - enterProfile

final class OpenAPIEnterProfileParams: OpenAPIBaseParams {
    enum ParamKey: String {
        case openid
    }

    @OpenAPIRequiredParam(userRequiredWithJsonKey: ParamKey.openid.rawValue)
    var openID: String

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_openID]
    }
}

extension OPPluginContact {
    /// 查看个人简介
    /// code from yinhao (June 10th, 2019 8:21pm)
    /// [SUITE-12275]: 小程序API支持获取会话列表
    func enterProfile(params: OpenAPIEnterProfileParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let uniqueID = gadgetContext.uniqueID
        let appID = uniqueID.appID
        let cipher = EMANetworkCipher.getCipher()
        var requestParams: [String: Any] = [:]
        requestParams["appid"] = appID
        requestParams["session"] = gadgetContext.session
        requestParams["openid"] = params.openID
        requestParams["ttcode"] = cipher.encryptKey
        let header:[String:String] = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
        let monitor = OPMonitor(kEventName_mp_enter_profile).setUniqueID(uniqueID).timing()
        let networkContext = OpenECONetworkAppContext(trace: context.apiTrace, uniqueId: uniqueID, source: .api)
        
        pr_enterProfile(
            requestParams: requestParams,
            header: header,
            context: context,
            session: gadgetContext.session,
            uniqueID: gadgetContext.uniqueID,
            params: params,
            monitor: monitor,
            cipher: cipher,
            networkContext: networkContext,
            callback: callback) { userID in
                if Self.apiUniteOpt {
                    guard let openApiService = self.openApiService else {
                        return false
                    }
                    let window = gadgetContext.controller?.view.window ?? uniqueID.window
                    let from = OPNavigatorHelper.topmostNav(window: window)
                    openApiService.enterProfile(userID: userID, from: from)
                    return true
                } else {
                    guard let enterProfileBlock = EMARouteMediator.sharedInstance().enterProfileBlock else {
                        return false
                    }
                    enterProfileBlock(userID, uniqueID, gadgetContext.controller)
                    return true
                }
            }
    }
}

extension OPPluginContact {
    func pr_enterProfile(
        requestParams: [String: Any],
        header: [String: String],
        context: OpenAPIContext,
        session: String,
        uniqueID: OPAppUniqueID,
        params: OpenAPIEnterProfileParams,
        monitor: OPMonitor,
        cipher: EMANetworkCipher,
        networkContext: ECONetworkServiceContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void,
        actionBlock: @escaping (_ userID: String) -> Bool
    ) {
        func handleResult(dataDic: [AnyHashable: Any]?, response: URLResponse?, error: Error?, cipher: EMANetworkCipher, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
            BDPExecuteOnMainQueue{
                let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
                guard let data = dataDic, error == nil else {
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.internalError)
                        .setError(error as NSError?).setMonitorMessage("server data error(logid:\(logID))")
                    callback(.failure(error: err))
                    context.apiTrace.error(error?.localizedDescription ?? "")
                    monitor
                        .setResultTypeFail()
                        .setError(error)
                        .flush()
                    return
                }
                
                let failureBlock: (String) -> Void = { errMsg in
                    let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.internalError)
                        .setMonitorMessage(errMsg)
                    context.apiTrace.error(errMsg)
                    callback(.failure(error: err))
                    monitor
                        .setResultTypeFail()
                        .setErrorMessage(errMsg)
                        .flush()
                }

                guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: data["encryptedData"] as? String ?? "", cipher: cipher) as? [AnyHashable: Any],
                      let userID = content["userid"] as? String,
                      !userID.isEmpty
                      else {
                    let code = data["error"] as? Int ?? 0
                    let msg = data["message"] as? String ?? ""
                    let errMsg = "enterProfile error, no userid \(data.keys)(logid:\(logID), code:\(code), msg:\(msg))"
                        failureBlock(errMsg)
                    failureBlock(errMsg)
                    return
                }

                let success = actionBlock(userID)
                guard success else {
                    failureBlock("enterProfile error, no block or no openApiService")
                    return
                }
                context.apiTrace.info("enterProfile success")
                callback(.success(data: nil))
                monitor
                    .setResultTypeSuccess()
                    .timing()
                    .flush()
            }
        }
        let url = EMAAPI.userIdURL()
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.getUserIDByOpenID) {
            if Self.apiUniteOpt {
                let model = UserIDByOpenIDModel(appID: uniqueID.appID, openID: params.openID, session: session, ttcode: cipher.encryptKey)
                var realHeader: [String: String] = header
                realHeader["domain_alias"] = "open"
                realHeader["User-Agent"] = BDPUserAgent.getString()
                FetchIDUtils.fetchUserIDByOpenID(uniqueID: uniqueID, model: model, networkContext: networkContext, header: realHeader, completionHandler:{(response, error) in
                    handleResult(dataDic: response, response: nil, error: error, cipher: cipher, callback: callback)
                })
            } else {
                OPECONetworkInterface.postForOpenDomain(url: url, context: networkContext, params: requestParams, header: header) { json, _, response, error in
                    handleResult(dataDic: json, response: response, error: error, cipher: cipher, callback: callback)
                }

            }
        } else {
            EMANetworkManager.shared().postUrl(
                url,
                params: requestParams,
                header: header,
                completionWithJsonData: { (dataDic, response, error) in
                    handleResult(dataDic: dataDic, response: response, error: error, cipher: cipher, callback: callback)
                },
                eventName: "getUserIDByOpenID", requestTracing: nil
            )
        }
    }
}

// MARK: - enterProfile V2: 逻辑一致, 使用extension获取服务
extension OPPluginContact {
    func enterProfileV2(
        params: OpenAPIEnterProfileParams,
        context: OpenAPIContext,
        contactExtension: OpenAPIContactExtension,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)
    {
        let cipher = EMANetworkCipher.getCipher()
        let sessionExtension = contactExtension.sessionExtension
        let commonExtension = contactExtension.commonExtension
        let requestParams = contactExtension.requestParams(
            openid: params.openID,
            ttcode: cipher.encryptKey)
        let header = sessionExtension.sessionHeader()
        let networkContext = contactExtension.networkContext()
        let monitor = commonExtension.monitor(kEventName_mp_enter_profile).timing()
        let outerService = self.outerService
        
        guard let gadgetContext = context.gadgetContext else {
            let err = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("gadgetContext in nil")
            context.apiTrace.error("gadgetContext in nil")
            callback(.failure(error: err))
            return
        }
        
        pr_enterProfile(
            requestParams: requestParams,
            header: header,
            context: context,
            session: sessionExtension.session(),
            uniqueID: gadgetContext.uniqueID,
            params: params,
            monitor: monitor,
            cipher: cipher,
            networkContext: networkContext,
            callback: callback) { userID in
                if Self.apiUniteOpt {
                    guard let openApiService = self.openApiService else {
                        context.apiTrace.error("openApiService in nil")
                        return false
                    }
                    let window = commonExtension.window()
                    let from = OPNavigatorHelper.topmostNav(window: window)
                    openApiService.enterProfile(userID: userID, from: from)
                    return true
                } else {
                    let window = commonExtension.window()
                    outerService.enterProfile(userId: userID, window: window)
                    return true
                }
            }
    }
    
    
}
