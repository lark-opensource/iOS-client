//
//  LarkNCExtensionMessengerAPI.swift
//  LarkNotificationContentExtension
//
//  Created by yaoqihao on 2022/4/11.
//

import Foundation
import LarkExtensionServices
import LarkHTTP

final public class LarkNCExtensionMessengerAPI {
    static public func sendReadMessage(_ id: String, chatID: String, userId: String, completionHandler: (() -> Void)? = nil) {
        var request = LarkNCExtensionPB_Messages_PutReadMessagesRequest()
        request.chatID = chatID
        request.messageIds = [id]
        request.maxPosition = -1

        let data = LarkNCExtensionUtils.generateHTTPBody(request: request, command: .putReadMessages)

        HTTP.POSTForLark(data: data, userId: userId) { response in
            LarkNCESDKLogger.logger.info("Read Message: \(id), chatID: \(chatID)")
            let isError = response.error != nil
            let category: [String: Any] = ["messageId": id, "status": isError ? "error" : "success"]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_read_message",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            if isError {
                LarkNCESDKLogger.logger.error("Read Message Failed: \(id), error: \(response.error)")
            } else {
                LarkNCESDKLogger.logger.info("Read Message Success: \(id)")
            }
            completionHandler?()
        }
    }

    static public func sendReplyMessage(_ text: String, messageID: String, chatID: String, userId: String, completionHandler: ((_ success: Bool) -> Void)? = nil) {
        var request = LarkNCExtensionPB_Messages_PutMessageRequest()
        request.chatID = chatID
        request.rootID = messageID
        request.parentID = messageID
        request.type = .text
        request.content = LarkNCExtensionPB_Messages_PutMessageRequest.Content()
        var richText = LarkNCExtensionPB_Entities_RichText()
        var textElement = LarkNCExtensionPB_Entities_RichTextElement()
        var textProperty = LarkNCExtensionPB_Entities_RichTextElement.TextProperty()
        textProperty.content = text
        textElement.tag = .text
        if let property = try? textProperty.serializedData() {
            textElement.property = property
        }

        var elements = LarkNCExtensionPB_Entities_RichTextElements()
        elements.dictionary = ["0": textElement]
        richText.elements = elements
        richText.elementIds = ["0"]
        richText.innerText = text
        request.content.richText = richText

        let data = LarkNCExtensionUtils.generateHTTPBody(request: request, command: .putMessage)

        HTTP.POSTForLark(data: data, userId: userId) { response in
            LarkNCESDKLogger.logger.info("Reply Message: \(messageID), chatID: \(chatID)")
            let isError = response.error != nil
            let category: [String: Any] = ["messageId": messageID, "status": isError ? "error" : "success"]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_reply_message",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            if isError {
                LarkNCESDKLogger.logger.error("Reply Message Failed: \(messageID), error: \(response.error)")
            } else {
                LarkNCESDKLogger.logger.info("Reply Message Success: \(messageID)")
            }
            completionHandler?(!isError)
        }
    }

    static public func sendReaction(_ key: String, messageID: String, userId: String, completionHandler: ((_ success: Bool) -> Void)? = nil) {
        var request = LarkNCExtensionPB_Reactions_PutReactionRequest()
        request.messageID = messageID
        request.reactionType = key

        let data = LarkNCExtensionUtils.generateHTTPBody(request: request, command: .putReaction)

        HTTP.POSTForLark(data: data, userId: userId) { response in
            LarkNCESDKLogger.logger.info("Reaction: \(messageID) reactionType: \(key)")
            let isError = response.error != nil
            let category: [String: Any] = ["messageId": messageID, "type": key, "status": isError ? "error" : "success"]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_reply_reaction",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            if isError {
                LarkNCESDKLogger.logger.error("Reaction Failed: \(messageID), error: \(response.error)")
            } else {
                LarkNCESDKLogger.logger.info("Reaction Success: \(messageID)")
            }
            completionHandler?(!isError)
        }
    }
}
