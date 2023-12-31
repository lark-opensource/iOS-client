//
//  AppLinkParser+CheckUser.swift
//  LarkAppLinkSDK
//
//  Created by bytedance on 2022/8/16.
//

import Foundation
import LarkAccountInterface

extension AppLinkParser {
    
    /// 检查用户身份
    func checkCurrentUserAvailable(_ appLink: AppLink) -> Bool {
        let secUserID = appLink.url.queryParameters["sec_user_id"]
        
        //appLink参数中没有secUserID，表示不需要校验
        guard let secUserID = secUserID else {
            Self.logger.info("AppLink need not check current user")
            return true
        }
        //appLink参数中secUserID和本地secUserID相同，通过校验
        if secUserID == resolver.userID.md5() {
            Self.logger.info("AppLink check current user pass")
            return true
        } else {
            Self.logger.info("AppLink check current user fail")
            return false
        }
    }
}
