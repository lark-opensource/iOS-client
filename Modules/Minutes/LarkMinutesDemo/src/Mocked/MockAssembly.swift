//
//  MockAssembly.swift
//  Minutes_Example
//
//  Created by lvdaqian on 2018/6/20.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import Swinject
import LarkAccountInterface
import LarkAppConfig
import LarkGuide
import LarkTab
import AnimatedTabBar
import LarkUIKit
import RxRelay
import EENavigator
import LarkNavigation
import LarkRustClient
import BootManager
import AppContainer
import LarkAssembler

public class MinutesMockAssembly: LarkAssemblyInterface {
    
    public init() {}
    
    public func registContainer(container: Container) {
//        container.register(NavigationAPI.self) { (resolver) -> NavigationAPI in
//            let rustClient = resolver.resolve(RustService.self)!
//            return NavigationAPIImpl(client: rustClient)
//        }.inObjectScope(.user)
    }
    
    
    public func registLaunch(container: Container) {
        NewBootManager.register(SetupServerPushTask.self)
        NewBootManager.register(NewSetupGuideTask.self)
    }
    
    public func registBootLoader(container: Container) {
        (VideoEngineApplicationDelegate.self, DelegateLevel.default)
    }
    
    public func registTabRegistry(container: Container) {
        (Tab.feed, { (_: [URLQueryItem]?) -> TabRepresentable in
            DemoTab()
        })
    }
    
    public func registRouter(container: Container) {
        Navigator.shared.registerRoute_(plainPattern: Tab.feed.urlString) { (_, res) in
            let vc = ListTableViewController()
            vc.isLkShowTabBar = false
            res.end(resource:vc)
        }
    }
}
