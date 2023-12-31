//
//  FetchIDUtils+ChatIDsByOpenChatIDs.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation

public struct ChatIDsByOpenChatIDsModel {
    public var appid: String
    public var session: String
    public var openChatIDs: [String]

    
    public init(appid: String, session: String, openChatIDs: [String]) {
        self.appid = appid
        self.session = session
        self.openChatIDs = openChatIDs
    }
}

extension FetchIDUtils {

    public static func fetchChatIDsByOpenChatIDs(uniqueID: OPAppUniqueID, model: ChatIDsByOpenChatIDsModel, header: [String: String]? = nil, completionHandler: @escaping ([String: AnyHashable]?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let cipher = EMANetworkCipher.getCipher()
        let networkContext = Self.generateContext(uniqueID: uniqueID)
        let params: [String: Any] = ["appid": model.appid, "session": model.session, "open_chatids": model.openChatIDs, "ttcode": cipher.encryptKey]
        let url: String = EMAAPI.chatIdByOpenChatIdURL()
        let task = Self.service.post(url: url, header: finalheader, params: params, context: networkContext) { response, error in
            guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: response?.result?["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let chatIDs = content["chatids"] as? [String: AnyHashable] else {
                completionHandler(nil, error)
                return
            }
            completionHandler(chatIDs, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
    }
}

