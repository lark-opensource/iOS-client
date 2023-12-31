//
//  OPNetworkAPIPath.swift
//  OPFoundation
//
//  Created by 刘焱龙 on 2023/7/4.
//

import Foundation
import LarkContainer
import LKCommonsLogging

@objcMembers
public class OPNetworkAPIPath: NSObject {
    public static let searchPeople = "/open-apis/mina/searchPeople"
    public static let webAppGetUserInfo = "/open-apis/mina/jssdk/getUserInfo"
    public static let getUserInfo = "/open-apis/mina/getUserInfo"
    public static let getEnvConfig = "/open-apis/mina/getEnvConfig"
    public static let getScopes = "/open-apis/mina/api/GetScopes"
    public static let getTenantAppScopes = "/open-apis/mina/GetTenantAppScopes"
    public static let applyAppScopeStatus = "/open-apis/mina/ApplyAppScopeStatus"
    public static let applyAppScope = "/open-apis/mina/ApplyAppScope"
    public static let syncClientAuth = "/open-apis/mina/SyncClientAuth"
    public static let syncClientAuthBySession = "/open-apis/mina/syncClientAuthBySession"
    
    public static let getChatIDByOpenID = "/open-apis/mina/v2/getChatIDByOpenID"
    public static let getChatIDsByOpenIDs = "/open-apis/mina/getChatIDsByOpenIDs"
    public static let getOpenIDsByUserIDs = "/open-apis/mina/v2/getOpenIDsByUserIDs"
    public static let getUserIDByOpenID = "/open-apis/mina/v2/getUserIDByOpenID"
    public static let getUserIDsByOpenIDs = "/open-apis/mina/v2/getUserIDsByOpenIDs"
    public static let getOpenChatIDsByChatIDs = "/open-apis/mina/v4/getOpenChatIDsByChatIDs"
    public static let getOpenUserSummary = "/open-apis/mina/v4/getOpenUserSummary"
    public static let humanAuthIdentity = "/open-apis/mina/human_authentication/v1/identity"
    public static let humanAuthUserTicket = "/open-apis/mina/human_authentication/v1/user_ticket"
    public static let humanAuthUserTicketWithCode = "/open-apis/mina/human_authentication/v1/user_ticket_with_code"
}

@objc public final class OPECONetworkInterface: NSObject {
    private static let logger = Logger.oplog(OPECONetworkInterface.self, category: "ECONetwork")

    private static var service: ECONetworkService {
        return Injected<ECONetworkService>().wrappedValue
    }

    @objc public static func enableECO(path: String) -> Bool {
        return OPECONetworkAPISettingDependency.enableECONetwork(path: path)
    }
    
    /// open域名专用 POST请求 封装 ( 会添加open域名专属通用参数 )
    @objc public static func postForOpenDomain(
        url: String,
        context: ECONetworkServiceContext,
        params: [String: Any],
        header: [String: String],
        completionHandler: @escaping ([String: Any]?, Data?, URLResponse?, Error?) -> Void
    ) {
        var realHeader = header
        realHeader["domain_alias"] = "open"
        realHeader["User-Agent"] = BDPUserAgent.getString()
        let task = service.post(
            url: url,
            header: realHeader,
            params: params,
            context: context) { response, error in
                completionHandler(response?.result, response?.bodyData, response?.response, error)
            }
        guard let requestTask = task else {
            assertionFailure("create task fail")
            Self.logger.error("create task fail \(context.getTrace().traceId)")
            let opError = OPError.error(monitorCode: CommonMonitorCode.fail)
            completionHandler(nil, nil, nil, opError)
            return
        }
        service.resume(task: requestTask)
    }
}
