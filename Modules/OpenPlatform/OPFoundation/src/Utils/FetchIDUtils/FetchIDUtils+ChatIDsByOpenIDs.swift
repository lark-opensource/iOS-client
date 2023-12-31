//
//  FetchIDUtils+ChatIDsByOpenIDs.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation

public struct ChatIDsByOpenIDsModel {
    public var appid: String
    public var openIDs: [String]
    
    public init(appid: String, openIDs: [String]) {
        self.appid = appid
        self.openIDs = openIDs
    }
}

extension FetchIDUtils {

    public static func fetchChatIDsByOpenIDs(uniqueID: OPAppUniqueID, model: ChatIDsByOpenIDsModel, header: [String: String]? = nil, completionHandler: @escaping ([String]?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let url: String = EMAAPI.chatIDsByOpenIDsURL()
        let cipher = EMANetworkCipher.getCipher()
        let networkContext = Self.generateContext(uniqueID: uniqueID)
        let params: [String: Any] = ["openids": model.openIDs, "appid": model.appid, "ttcode": cipher.encryptKey]
        let task = Self.service.post(url: url, header: finalheader, params: params, context: networkContext) { response, error in
            guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: response?.result?["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let chatIDMap = content["chatids_map"] as? [String: Int], !chatIDMap.isEmpty else {
                completionHandler(nil, error)
                return
            }
            let chatIDs = chatIDMap.map { String($0.1) }
            completionHandler(chatIDs, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
    }
}
