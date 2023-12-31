//
//  MyAIToolsContext.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/22.
//

import Foundation
import LarkMessengerInterface

public struct MyAIToolsContext {

    /// 已选toolIds
    public var selectedToolIds: [String]
    /// 场景，默认为IM
    public var scenario: String
    public var maxSelectCount: Int?
    public var aiChatModeId: Int64
    public var myAIPageService: MyAIPageService?
    public var extra: [AnyHashable: Any]

    public init(selectedToolIds: [String] = [],
                scenario: String,
                maxSelectCount: Int? = nil,
                aiChatModeId: Int64 = 0,
                myAIPageService: MyAIPageService? = nil,
                extra: [AnyHashable: Any] = [:]) {
        self.selectedToolIds = selectedToolIds
        self.scenario = scenario
        self.maxSelectCount = maxSelectCount
        self.aiChatModeId = aiChatModeId
        self.myAIPageService = myAIPageService
        self.extra = extra
    }
}
