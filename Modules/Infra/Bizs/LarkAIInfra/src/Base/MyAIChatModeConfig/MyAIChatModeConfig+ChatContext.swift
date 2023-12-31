//
//  MyAIChatModeConfig+ChatContext.swift
//  LarkAIInfra
//
//  Created by Hayden on 17/10/2023.
//

import Foundation
import RustPB
import ServerPB

public extension MyAIChatModeConfig {
    
    /// 分会场开启新会话、NewTopic 时传递
    /// - NOTE: `extraMap` 传递当前分会场上下文
    /// - Returns: RustPB 的 ChatContext
    func getCurrentChatContext() -> RustPB.Basic_V1_ChatContext {
        var sceneObject = RustPB.Basic_V1_AISceneObject()
        sceneObject.objectID = self.delegate?.getObjectId(self) ?? self.objectId
        sceneObject.objectType = self.delegate?.getObjectType(self) ?? self.objectType.rawValue
        var chatContext = RustPB.Basic_V1_ChatContext()
        chatContext.extraMap = self.delegate?.getChatContextExtraMap(self) ?? self.appContextDataProvider?() ?? [:]
        chatContext.object = sceneObject
        return chatContext
    }

    /// 分会场开启新会话、NewTopic 时传递
    /// - NOTE: `extraMap` 传递当前分会场上下文
    /// - Returns: ServerPB 的 ChatContext
    func getCurrentChatContext() -> ServerPB_Entities_ChatContext {
        var sceneObject = ServerPB_Entities_AISceneObject()
        sceneObject.objectID = self.delegate?.getObjectId(self) ?? self.objectId
        sceneObject.objectType = self.delegate?.getObjectType(self) ?? self.objectType.rawValue
        var chatContext = ServerPB_Entities_ChatContext()
        chatContext.extraMap = self.delegate?.getChatContextExtraMap(self) ?? self.appContextDataProvider?() ?? [:]
        chatContext.object = sceneObject
        return chatContext
    }

    /// 分会场拉取快捷指令时传递
    /// - NOTE: `extraMap` 传递快捷指令流量特征
    /// - Returns: RustPB 的 ChatContext
    func getQuickActionChatContext() -> RustPB.Basic_V1_ChatContext {
        var sceneObject = RustPB.Basic_V1_AISceneObject()
        sceneObject.objectID = self.delegate?.getObjectId(self) ?? self.objectId
        sceneObject.objectType = self.delegate?.getObjectType(self) ?? self.objectType.rawValue
        var chatContext = RustPB.Basic_V1_ChatContext()
        chatContext.extraMap = self.triggerParamsProvider?() ?? [:]
        chatContext.object = sceneObject
        return chatContext
    }

    /// 分会场拉取快捷指令时传递
    /// - NOTE: `extraMap` 传递快捷指令流量特征
    /// - Returns: ServerPB 的 ChatContext
    func getQuickActionChatContext() -> ServerPB_Entities_ChatContext {
        var sceneObject = ServerPB_Entities_AISceneObject()
        sceneObject.objectID = self.delegate?.getObjectId(self) ?? self.objectId
        sceneObject.objectType = self.delegate?.getObjectType(self) ?? self.objectType.rawValue
        var chatContext = ServerPB_Entities_ChatContext()
        chatContext.extraMap = self.triggerParamsProvider?() ?? [:]
        chatContext.object = sceneObject
        return chatContext
    }
}
