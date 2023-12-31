//
//  IsolatorCommonKey.swift
//  LarkAccount
//
//  Created by bytedance on 2021/5/19.
//

import Foundation

/**
 在此添加存储标志符
 命名规则： XxxXxxIsolator(业务名+存储实体名)
 */
public enum IsolatorNamespace: String {
    case passportGlobalIsolator = "com.bytedance.lark.passport.global"
    case passportStoreIsolator = "com.bytedance.lark.passport.store"
    case passportStoreUserInfoIsolator = "com.bytedance.lark.passport.store.user"
}

let commonConfig = IsolatorConfig(loggerClass: Isolator.self, shouldEncrypted: true)
