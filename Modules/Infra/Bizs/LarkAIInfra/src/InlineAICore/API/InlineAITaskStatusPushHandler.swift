//
//  InlineAITaskStatusPushHandler.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/18.
//  


import Foundation
import RustPB
import LarkRustClient
import LarkContainer


class InlineAITaskStatusPushHandler: UserPushHandler {
    func process(push: InlineAIPushResponse) throws {
        PushDispatcher.shared.pushResponse.accept(push)
    }
}

