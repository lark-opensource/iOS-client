//
//  MessageCardSession.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/9.
//

import UIKit
import LarkAppLinkSDK
import LarkModel
import ThreadSafeDataStructure

protocol CommonActionContextItem {
    var owner: String { get }
    var triggerCode: String { get }
    var createDate: Date { get }
}

class ChatActionContextItem: CommonActionContextItem {
    let chat: Chat
    let item: KeyboardApp?
    let owner: String
    let triggerCode: String
    let createDate = Date()

    init(chat: Chat, i: KeyboardApp?, user: String, ttCode: String) {
        self.chat = chat
        self.item = i
        self.owner = user
        self.triggerCode = ttCode
    }
}

class MessageActionContextItem: CommonActionContextItem {
    let chatId: String
    let messageIds: [String]
    let owner: String
    let triggerCode: String
    let createDate = Date()

    init(chatId: String, messageIds: [String], user: String, ttCode: String) {
        self.chatId = chatId
        self.messageIds = messageIds
        self.owner = user
        self.triggerCode = ttCode
    }
}
class MessageCardSession {

    private var chatActionSessions: [String: ChatActionContextItem] = [:]
    private var messageActionSessions: [String: MessageActionContextItem] = [:]
    private var lock = NSRecursiveLock()
    private static let _shared: MessageCardSession = {
        let shareInstance = MessageCardSession()
        return shareInstance
    }()

    public class func shared() -> MessageCardSession {
         return _shared
    }

    public func recordOpenChatAction(context: ChatActionContextItem) {
        lock.lock()
        chatActionSessions[context.triggerCode] = context
        lock.unlock()
    }
    public func recordOpenMessageAction(context: MessageActionContextItem) {
        lock.lock()
        messageActionSessions[context.triggerCode] = context
        lock.unlock()
    }
    public func getChatActionContext(triggerCode: String) -> ChatActionContextItem? {
        lock.lock()
        let record = chatActionSessions[triggerCode]
        lock.unlock()
        return record
    }
    public func getMessageActionContext(triggerCode: String) -> MessageActionContextItem? {
        lock.lock()
        let record = messageActionSessions[triggerCode]
        lock.unlock()
        return record
    }
}
