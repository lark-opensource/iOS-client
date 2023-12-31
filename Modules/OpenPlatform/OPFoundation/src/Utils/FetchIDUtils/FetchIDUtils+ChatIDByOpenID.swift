//
//  FetchIDUtils+ChatIDByOpenID.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation

public struct ChatIDByOpenIDModel {
    public var appid: String
    public var session: String
    public var openID: String
    
    public init(appid: String, session: String, openID: String) {
        self.appid = appid
        self.session = session
        self.openID = openID
    }
}

extension FetchIDUtils {

    public static func fetchChatIDByOpenID(uniqueID: OPAppUniqueID, model: ChatIDByOpenIDModel, header: [String: String]? = nil, completionHandler: @escaping (String?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let networkContext = Self.generateContext(uniqueID: uniqueID)
        let url: String = EMAAPI.chatIdURL()
        let cipher = EMANetworkCipher.getCipher()
        let params: [String: Any] = ["appid": model.appid, "session": model.session, "openid": model.openID, "ttcode": cipher.encryptKey]
        let task = Self.service.post(url: url, header: finalheader, params: params, context: networkContext) { response, error in
            guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: response?.result?["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let chatID = content["chatid"] as? String, !chatID.isEmpty else {
                completionHandler(nil, error)
                return
            }
            completionHandler(chatID, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
    }
    
}
