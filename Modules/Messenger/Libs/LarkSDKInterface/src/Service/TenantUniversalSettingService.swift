//
//  TenantUniversalSettingService.swift
//  LarkSDKInterface
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation

public protocol TenantUniversalSettingService {
    func loadTenantMessageConf(forceServer: Bool, onCompleted: ((Error?) -> Void)?)
    func getRecallEffectiveTime() -> Int64
    func supportRestrictMessage() -> Bool
    func getEditEffectiveTime() -> Int64
    func getIfMessageCanMultiEdit(createTime: TimeInterval) -> Bool
    func getIfMessageCanRecall(createTime: TimeInterval) -> Bool
    func getIfMessageCanRecallBySelf() -> Bool
    func getInputBoxPlaceholder() -> String?
    func replaceTenantPlaceholderEnable() -> Bool
}
