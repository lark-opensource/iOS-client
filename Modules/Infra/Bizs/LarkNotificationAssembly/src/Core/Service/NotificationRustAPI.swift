//
//  ReplyRustAPI.swift
//  LarkNotificationAssembly
//
//  Created by aslan on 2023/12/15.
//

import LarkRustClient
import ServerPB
import RustPB
import LKCommonsLogging
import RxSwift
import LarkNotificationContentExtensionSDK

final class NotificationRustAPI {

    let logger = Logger.log(NotificationRustAPI.self, category: "LarkNotificationAssembly")
    private var disposeBag = DisposeBag()

    func sendReadMessage(_ id: String, rustService: RustService?, userId: String?, chatID: String, completionHandler: (() -> Void)? = nil) {
        if let rustService = rustService {
            var request = ServerPB_Messages_PutReadMessagesRequest()
            request.chatID = chatID
            request.messageIds = [id]
            request.maxPosition = -1

            self.logger.info("Read Message: \(id), use RustService")

            rustService
                .sendPassThroughAsyncRequest(request,
                                             serCommand: .putReadMessages)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.logger.info("Read Message Success: \(id)")
                    completionHandler?()
                }, onError: { error in
                    self.logger.error("Read Message Failed: \(id), error: \(error)")
                    completionHandler?()
                }).disposed(by: self.disposeBag)
        } else {
            // 走 HTTP 兜底
            if let userId = userId {
                self.logger.info("Read Message: \(id), use HTTP request")
                LarkNCExtensionMessengerAPI.sendReadMessage(id, chatID: chatID, userId: userId) {
                    DispatchQueue.main.async {
                        completionHandler?()
                    }
                }
            }
        }
    }

    func sendReplyMessage(_ text: String,
                          rustService: RustService?,
                          userId: String?,
                          messageID: String,
                          chatID: String,
                          completionHandler: ((_ success: Bool) -> Void)? = nil) {
        if let rustService = rustService {
            var request = ServerPB_Messages_PutMessageRequest()
            request.chatID = chatID
            request.rootID = messageID
            request.parentID = messageID
            request.type = .text
            request.content = ServerPB_Messages_PutMessageRequest.Content()
            var richText = ServerPB_Entities_RichText()
            var textElement = ServerPB_Entities_RichTextElement()
            var textProperty = ServerPB_Entities_RichTextElement.TextProperty()
            textProperty.content = text
            textElement.tag = .text
            if let property = try? textProperty.serializedData() {
                textElement.property = property
            }

            var elements = ServerPB_Entities_RichTextElements()
            elements.dictionary = ["0": textElement]
            richText.elements = elements
            richText.elementIds = ["0"]
            richText.innerText = text
            request.content.richText = richText

            self.logger.info("Reply Message: \(messageID), use RustService")

            rustService
                .sendPassThroughAsyncRequest(request,
                                             serCommand: .putMessage)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.logger.info("Reply Message Success: \(messageID)")
                    completionHandler?(true)
                }, onError: { error in
                    self.logger.error("Reply Message Failed: \(messageID), error: \(error)")
                    completionHandler?(false)
                }).disposed(by: self.disposeBag)
        } else {
            // 走 HTTP 兜底
            if let userId = userId {
                self.logger.info("Reply Message: \(messageID), use HTTP Request")
                LarkNCExtensionMessengerAPI.sendReplyMessage(text, messageID: messageID, chatID: chatID, userId: userId) { success in
                    DispatchQueue.main.async {
                        completionHandler?(success)
                    }
                }
            }
        }
    }

    func sendReaction(_ key: String, rustService: RustService?, userId: String?, messageID: String, completionHandler: ((_ success: Bool) -> Void)? = nil) {
        if let rustService = rustService {
            var request = ServerPB_Reactions_PutReactionRequest()
            request.messageID = messageID
            request.reactionType = key

            self.logger.info("Send Reaction: \(messageID), use RustService")

            rustService
                .sendPassThroughAsyncRequest(request,
                                             serCommand: .putReaction)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    self.logger.info("Send Reaction Success: \(messageID)")
                    completionHandler?(true)
                }, onError: { error in
                    self.logger.error("Send Reaction Failed: \(messageID), error: \(error)")
                    completionHandler?(false)
                }).disposed(by: self.disposeBag)
        } else {
            // 走 HTTP 兜底
            if let userId = userId {
                self.logger.info("Send Reaction: \(messageID), use HTTP Request")
                LarkNCExtensionMessengerAPI.sendReaction(key, messageID: messageID, userId: userId) { success in
                    DispatchQueue.main.async {
                        completionHandler?(success)
                    }
                }
            }
        }
    }

    func handleOfflinePushData(_ data: Data, rustService: RustService, completionHandler: ((_ isFinish: Bool) -> Void)? = nil) {
        self.logger.info("handleOfflinePushData")

        var request = RustPB.Im_V1_HandleOfflinePushDataRequest()
        request.data = data

        rustService
        .sendAsyncRequest(request) {
            (res: RustPB.Im_V1_HandleOffilePushDataResponse) -> Bool in
            return res.status == .finish
        }.observeOn(MainScheduler.instance)
        .subscribe(onNext: { (isFinish) in
            if isFinish {
                completionHandler?(true)
            }
        }, onError: { _ in
            completionHandler?(false)
        }).disposed(by: self.disposeBag)
    }
}
