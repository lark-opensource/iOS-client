//
//  OPAccountTokenHelper.swift
//  OPFoundation
//
//  Created by ByteDance on 2023/7/5.
//

import Foundation

public struct OPAccountTokenHelper {
    public static func accountToken(userID:String, tenantID:String) -> String{
        let accountToken = (userID + "_" + tenantID).md5()
        return accountToken
    }
}
