//
//  LarkInlineAIAssemble.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/18.
//  


import LarkAssembler
import LarkContainer
import Swinject
import LarkRustClient

public final class LarkInlineAIAssemble: LarkAssemblyInterface {
    
    public init() {}
    
    public func registRustPushHandlerInUserSpace(container: Swinject.Container) {
        (Command.inlineAiTaskStatusPush, InlineAITaskStatusPushHandler.init(resolver:))
    }
}

