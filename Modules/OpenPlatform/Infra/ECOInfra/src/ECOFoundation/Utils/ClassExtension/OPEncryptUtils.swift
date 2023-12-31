//
//  OPEncryptUtils.swift
//  ECOInfra
//
//  Created by ByteDance on 2022/10/13.
//

import Foundation
import LKCommonsLogging
import LarkContainer
import LarkAccountInterface

public final class OPEncryptUtils {
    private static let logger = Logger.oplog(OPEncryptUtils.self, category: "securityEncrypt.OPEncryptUtils")
    
    
    public static var userID : String?
    public static var deviceID : String?
    public static var deviceLoginID : String?
    
    public static func webURLAES256Encrypt(content: String) -> String {
        guard !content.isEmpty else {
            Self.logger.info("can not encrypt data, content is empty")
            return ""
        }
//        let deviceService = InjectedOptional<DeviceService>().wrappedValue
//        let userID = AccountServiceAdapter.shared.currentAccountInfo.userID
        guard let did = deviceID, let loginID = deviceLoginID,let uid = userID, !uid.isEmpty else {
            Self.logger.info("can not encrypt data, deviceID/loginID/userID is empty")
            let backup = "OpenPlatform"
            let backKey = backup + backup
            let backIv = OPAES256Utils.getIV(backup, backup: backup)
            return OPAES256Utils.encrypt(withContent: content, key: backKey, iv: backIv)
        }
        let key = did + uid
        let iv = OPAES256Utils.getIV(loginID, backup: uid)
        return OPAES256Utils.encrypt(withContent: content, key: key, iv: iv)
    }
}
