//
//  FetchIDUtils+OpenChatIDsByUserIDs.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation

@objc
public class OpenChatIDsByChatIDsModel: NSObject {
    public var appType: OPAppType
    public var appID: String
    public var chats: [String: Any]?
    public var session: String
    public var chatsArray: [[String: Any]]?
    
    @objc
    public init(appType: OPAppType, appID: String, chats: [String: Any]? = nil, session: String, chatsArray: [[String: Any]]? = nil) {
        self.appType = appType
        self.appID = appID
        self.chats = chats
        self.session = session
        self.chatsArray = chatsArray
    }
}

extension FetchIDUtils {

    @objc
    public static func fetchOpenChatIDsByChatIDs(uniqueID: OPAppUniqueID, model: OpenChatIDsByChatIDsModel, header: [String: String]? = nil, completionHandler: @escaping ([String: Any]?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let url = EMAAPI.openChatIdsByChatIdsURL()
        let networkContext = Self.generateContext(uniqueID: uniqueID)
        let sessionKey = Self.getSessionKey(appType: model.appType)
        let ciper = EMANetworkCipher.getCipher()
        let chats: Any = (model.chats != nil) ? model.chats as Any : model.chatsArray ?? [:] as Any
        let task = Self.service.post(url: url, header: finalheader, params: ["chats": chats, "appid": model.appID, "ttcode": ciper.encryptKey, sessionKey: model.session], context: networkContext) { response, error in
            guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: response?.result?["encryptedData"] as? String ?? "", cipher: ciper) as? [String: Any], let openChatIDs = content["openchatids"] as? [String: Any] else {
                completionHandler(nil, error)
                return
            }
            completionHandler(openChatIDs, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
    }
}
