//
//  MyAIServiceImpl+QuickAction.swift
//  LarkAI
//
//  Created by ByteDance on 2023/12/28.
//
import Foundation
import LarkAIInfra

public extension MyAIServiceImpl {
    // chatID + aiChatModeID 作为缓存的 key；messagePosition 作为缓存的 version
    func putAuickActions(chatID: Int64, aiChatModeID: Int64, messagePosition: Int64, quickActions: [AIQuickActionModel]) {
        let key = "\(chatID)_\(aiChatModeID)"
        if messagePosition >= quickActionsVersionCache[key] ?? 0 {
            MyAIServiceImpl.logger.info("put quick actions cache key:\(key) messagePosition: \(messagePosition) len \(quickActions.count)")
            quickActionsCache[key] = quickActions
            quickActionsVersionCache[key] = messagePosition
        }
    }

    // 获取 chatID + aiChatModeID 对应的 QuickActions。若 messagePosition > 缓存的 messagePosition，返回空数组
    func getAuickActions(chatID: Int64, aiChatModeID: Int64, messagePosition: Int64) -> [AIQuickActionModel] {
        let key = "\(chatID)_\(aiChatModeID)"

        if messagePosition <= quickActionsVersionCache[key] ?? 0 {
            MyAIServiceImpl.logger.info("use quick actions cache key:\(key) messagePosition: \(messagePosition) len \(quickActionsCache[key]?.count ?? 0)")
            return quickActionsCache[key] ?? []
        }

        return []
    }
}
