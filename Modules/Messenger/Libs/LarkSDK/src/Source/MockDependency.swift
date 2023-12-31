//
//  MockAssembly.swift
//  LarkSDKAssembly
//
//  Created by CharlieSu on 10/11/19.
//

import Foundation
import LarkModel
import Swinject
import RustPB
import RxSwift
import LarkSDKInterface

/// 模块mock依赖的默认实现。如果不符合需求，外界可以重载某几个依赖
open class SDKDependencyMockImpl: SDKDependency {
    public init() {}

    public var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { return .excellent }

    public func messageSummerize(_ message: Message) -> String {
        return ""
    }

    public func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        return (false, "", "")
    }

    public func isBurned(message: Message) -> Bool {
        return false
    }

    public func calculateCacheSize() -> Observable<Float> { Observable.just(0) }

    public func clearCache() -> Observable<Void> { Observable.just(()) }

    public func trackClickMsgSend(_ chat: Chat, _ message: Message, chatFromWhere: String?) { }
}
