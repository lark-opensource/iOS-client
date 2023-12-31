//
//  UserInfoHandler.swift
//  LarkWeb
//
//  Created by zhenning on 2019/12/29.
//

import WebBrowser
import LKCommonsLogging
import LarkAccountInterface
import Swinject
import LarkSDKInterface
import LarkContainer

class UserInfoHandler: JsAPIHandler, UserResolverWrapper {
    
    @ScopedProvider private var userService: PassportUserService?
    @ScopedProvider private var chatterService: ChatterManagerProtocol?
    @ScopedProvider private var dependency: PassportWebViewDependency?
    
    let userResolver: UserResolver

    init(resolver: UserResolver) {
        userResolver = resolver
    }

    private static let logger = Logger.log(UserInfoHandler.self, category: "UserInfoHandler")

    func handle(args: [String: Any], api: WebBrowser, sdk: JsSDK, callback: WorkaroundAPICallBack) {
        dependency?.monitorSensitiveJsApi(apiName: "biz.user.userInfo.get", sourceUrl: api.browserURL, from: "JSSDK")

        guard let url = api.webView.url, api.hasPermission(url: url, resolver: resolver) else {
            UserInfoHandler.logger.error("request url not in the whteList, url = \(String(describing: api.webView.url))")
            return
        }
        
        guard let userService else {
            Self.logger.error("resolve PassportUserService failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }
        guard let chatterService else {
            Self.logger.error("resolve ChatterManagerProtocol failed")
            callback.callbackFailure(param: NewJsSDKErrorAPI.resolveServiceError.description())
            return
        }
        
        let currentUser = chatterService.currentChatter
        let currentTenant = userService.userTenant

        if let onSuccess = args["onSuccess"] as? String {
            let arguments = [["localizedName": currentUser.localizedName, "avatarUrl": currentUser.avatar.thumbnail.urls.first ?? "",
                              "tenantName": currentTenant.tenantName,
                              "tenantIconUrl": currentTenant.iconURL]] as [[String: Any]]
            callbackWith(api: api, funcName: onSuccess, arguments: arguments)
        }
        UserInfoHandler.logger.debug("UserInfoHandler success")
    }

}
