//
//  DocChatLifeCycleService.swift
//  LarkMessageCore
//
//  Created by Weston Wu on 2020/8/9.
//

import Foundation
import LarkMessageBase

public protocol DocChatLifeCycleServiceDependency {
    func notifyEnterChatPage()
    func notifyLeaveChatPage()
}

public struct DocChatLifeCycleService: PageService {

    private let dependency: DocChatLifeCycleServiceDependency

    public init(dependency: DocChatLifeCycleServiceDependency) {
        self.dependency = dependency
    }

    public func pageViewDidLoad() {
        // notify enter chat
        dependency.notifyEnterChatPage()
    }

    public func pageDeinit() {
        // notify leave chat
        dependency.notifyLeaveChatPage()
    }
}
