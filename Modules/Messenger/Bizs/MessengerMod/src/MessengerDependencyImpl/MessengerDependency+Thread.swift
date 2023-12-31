//
//  MessengerMockDependency+Thread.swift
//  LarkMessenger
//
//  Created by CharlieSu on 12/3/19.
//
import Foundation
import Swinject
import LarkThread
import RxSwift
import LarkContainer
#if CCMMod
import SpaceInterface
#endif
#if TodoMod
import TodoInterface
#endif

open class ThreadDependencyImpl: ThreadDependency {
    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func preloadDocFeed(_ url: String, from source: String) {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.preloadDocFeed(url, from: source)
        #endif
    }

    public func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.isSupportURLType(url: url) ?? (false, "", "")
        #else
        (false, "", "")
        #endif
    }
}
