//
//  LarkNotificationAssembly.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/11/15.
//

import Foundation
import LarkAssembler
import RustPB
import LarkRustClient
import LarkContainer
import Swinject
import AppContainer
import LarkAccountInterface
#if !LARK_NO_DEBUG
import LarkDebugExtensionPoint
#endif

public class LarkNotificationAssembly: LarkAssemblyInterface {

    public init() {}

    public func registRustPushHandlerInBackgroundUserSpace(container: Container) {
        (Command.pushNotification, NotificationPushHandler.init(resolver:))
    }

    public func registBootLoader(container: Container) {
        (NotificationApplicationDelegate.self, DelegateLevel.default)
    }

    public func registPassportDelegate(container: Container) {
        (PassportDelegateFactory(delegateProvider: {
            NotificationPassportDelegate(resolver: container)
        }), PassportDelegatePriority.low)
    }

#if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({ () in NotificationDebugItem() }, SectionType.debugTool)
    }
#endif
}
