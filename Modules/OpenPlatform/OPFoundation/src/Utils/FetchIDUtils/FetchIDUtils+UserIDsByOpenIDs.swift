//
//  FetchIDUtils+UserIDsByOpenIDs.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation

public struct UserIDsByOpenIDsModel {
    public var appType: OPAppType
    public var appID: String
    public var openIDs: [String]
    public var session: String
    public var ttcode: String
    
    public init(appType: OPAppType, appID: String, openIDs: [String], session: String, ttcode: String) {
        self.appType = appType
        self.appID = appID
        self.openIDs = openIDs
        self.session = session
        self.ttcode = ttcode
    }
}

extension FetchIDUtils {

    //TODO：和现在的代码处理位置不同，等老代码下线再处理数据解析部分
    public static func fetchUserIDsByOpenIDs(uniqueID: OPAppUniqueID, model: UserIDsByOpenIDsModel, header: [String: String]? = nil, completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let sessionKey = Self.getSessionKey(appType: model.appType)
        let networkContext = Self.generateContext(uniqueID: uniqueID)
        let params: [String: Any] = ["openids": model.openIDs, "appid": model.appID, "ttcode": model.ttcode, sessionKey: model.session]
        let url = EMAAPI.userIdsByOpenIDsURL()
        let task = Self.service.post(url: url, header: finalheader, params: params, context: networkContext) { response, error in
            completionHandler(response?.result, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
    }
}
