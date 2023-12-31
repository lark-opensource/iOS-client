//
//  SDKRustService.swift
//  LarkSDKInterface
//
//  Created by CharlieSu on 11/12/19.
//

import Foundation
import LarkRustClient
import LarkCombine
import SwiftProtobuf
import RxSwift
import RustPB
import LarkModel

public protocol SDKRustService: RustService {
    var wrapped: RustService { get }
}

public typealias SDKDependency = RustSendMessageAPIDependency &
    RustSendThreadAPIDependency &
    DocsCacheDependency

public protocol RustSendMessageAPIDependency {
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
    func messageSummerize(_ message: LarkModel.Message) -> String
    func isSupportURLType(url: URL) -> (Bool, type: String, token: String)
    func trackClickMsgSend(_ chat: LarkModel.Chat, _ message: LarkModel.Message, chatFromWhere: String?)
}

public protocol RustSendThreadAPIDependency {
    func messageSummerize(_ message: LarkModel.Message) -> String
    func isSupportURLType(url: URL) -> (Bool, type: String, token: String)
    func trackClickMsgSend(_ chat: LarkModel.Chat, _ message: LarkModel.Message, chatFromWhere: String?)
}
