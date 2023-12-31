//
//  PreloadAssembly.swift
//  LarkPreload
//
//  Created by huanglx on 2023/4/12.
//

import Foundation
import Swinject
import LarkContainer
import LarkAssembler
import AppContainer
import LarkAccountInterface
import BootManager
import LarkOpenFeed

public class PreloadAssembly: LarkAssemblyInterface {
    public init() {}

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory {
            return PreloadAccountDelegate()
        }, PassportDelegatePriority.middle)
    }
    
    public func registLaunch(container: Swinject.Container) {
        NewBootManager.register(PreloadConfigTask.self)
    }
    
    @_silgen_name("Lark.Feed.Listener.preload")
    static public func registerFeedListener() {
        FeedListenerProviderRegistery.register(provider: { _ in FeedListListener() })
    }
}

