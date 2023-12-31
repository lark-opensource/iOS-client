//
//  FetchIDUtils+UserIDByOpenID.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation

public struct UserIDByOpenIDModel {
    public var appID: String
    public var openID: String
    public var session: String
    public var ttcode: String
    
    public init(appID: String, openID: String, session: String, ttcode: String) {
        self.appID = appID
        self.openID = openID
        self.session = session
        self.ttcode = ttcode
    }
}


extension FetchIDUtils {

    //TODO：和现在的代码处理位置不同，等老代码下线再处理数据解析部分
    public static func fetchUserIDByOpenID(uniqueID: OPAppUniqueID, model: UserIDByOpenIDModel, networkContext: ECONetworkServiceContext, header: [String: String]? = nil, completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let url = EMAAPI.userIdURL()
        let params: [String: Any] = ["openid": model.openID, "appid": model.appID, "ttcode": model.ttcode, "session": model.session]
        let task = Self.service.post(url: url, header: finalheader, params: params, context: networkContext) { response, error in
            completionHandler(response?.result, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
    }
}
