//
//  FetchIDUtils+OpenIDsByUserIDs.swift
//  OPPluginBiz
//
//  Created by ByteDance on 2023/9/20.
//

import Foundation


@objc
public class OpenIDsByUserIDsModel: NSObject {
    public var userIDs: [String]
    public var session: String
    
    @objc
    public init(userIDs: [String], session: String) {
        self.userIDs = userIDs
        self.session = session
    }
}

extension FetchIDUtils {
    @objc
    public static func fetchOpenIDsByUserIDs(uniqueID: OPAppUniqueID, model: OpenIDsByUserIDsModel, header: [String: String]? = nil, completionHandler: @escaping ([String: String]?, Error?) -> Void) {
        var finalheader: [String: String] = [:]
        if let header = header {
            finalheader = header
        }
        let url = EMAAPI.openIdURL()
        let cipher = EMANetworkCipher.getCipher()
        let networkContext = Self.generateContext(uniqueID: uniqueID)
        let params: [String: Any] = ["userids": model.userIDs, "appid": uniqueID.appID, "ttcode": cipher.encryptKey, "session": model.session]
        let task = Self.service.post(url: url, header: finalheader, params: params, context: networkContext) { response, error in
            guard let content = EMANetworkCipher.decryptDict(forEncryptedContent: response?.result?["encryptedData"] as? String ?? "", cipher: cipher) as? [String: Any], let openIDs = content["openids"] as? [String: String] else {
                completionHandler(nil, error)
                return
            }
            completionHandler(openIDs, error)
        }
        guard let task = task else {
            return
        }
        service.resume(task: task)
        
    }
}
