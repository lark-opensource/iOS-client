//
//  PushDispatcher+Common.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/9/24.
//

import Foundation

// MARK: 一些Lark的通用push
extension PushDispatcher {
    public enum LarkEventPush {
        case dynamicNetStatusChange(DynamicNetTypeChange)
    }
}
