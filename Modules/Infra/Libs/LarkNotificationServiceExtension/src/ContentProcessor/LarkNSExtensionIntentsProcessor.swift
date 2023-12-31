//
//  LarkNSExtensionIntentsProcessor.swift
//  LarkNSExtensionIntentsProcessor
//
//  Created by 姚启灏 on 2021/8/20.
//
// swiftlint:disable all
import UserNotifications
import UIKit
import Foundation
import LarkExtensionServices
import LarkStorageCore
import Intents
import NotificationUserInfo

@available(iOSApplicationExtension 15.0, iOS 15.0, *)
final class LarkNSExtensionIntentsProcessor {
    static let store = KVStores.udkv(
        space: .global,
        domain: Domain.biz.core.child("NSEIntentsProcessor")
    ).usingMigration(   // 旧数据迁移
        config:
            .from(
                userDefaults: .standard,
                items: [
                    "LarkNSExtensionIntentsProcessor.userDefaultKey" ~> "cachedImagePaths"
                ]
            )
    )

    @KVConfig(key: "cachedImagePaths", store: store)
    static var imageCachePaths: [String: String]?

    static var currentDownloadTask: URLSessionDownloadTask?

    static var currentFileURL: URL?

    static func processIntents(by bestAttemptContent: UNMutableNotificationContent,
                               extra: LarkNSEExtra,
                               contentHandler: @escaping (UNNotificationContent) -> Void) {

        LarkNSELogger.logger.info("Get Intent, isNotComm: \(extra.isNotComm), pruneOutline: \(extra.pruneOutline)")

        if let dictionary = imageCachePaths,
           let imageUrl = extra.imageUrl,
           let url = dictionary[imageUrl],
           // lint:disable:next lark_storage_check - 不涉及加解密，不处理
           let image = UIImage(contentsOfFile: url) {
            LarkNSELogger.logger.info("Get image by UserDefaults")
            let messageContent = Self.processIntents(by: bestAttemptContent,
                                                     image: image,
                                                     extra: extra)
            let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? "", "type": "local"]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_process_intent_image",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            contentHandler(messageContent)
            return
        }

        if let imageUrl = extra.imageUrl,
           // lint:disable:next lark_storage_check - 不涉及加解密，不处理
           let url = URL(string: imageUrl) {
            LarkNSELogger.logger.info("Get image by URL")
            currentDownloadTask = URLSession.shared.downloadTask(with: url,
                                                                 completionHandler: { fileURL, _, error in
                if error != nil {
                    LarkNSELogger.logger.info("Failed to get image")

                    let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? "", "type": "url"]
                    ExtensionTracker.shared.trackSlardarEvent(key: "APNs_process_intent_error",
                                                              metric: [:],
                                                              category: category,
                                                              params: [:])

                    let messageContent = Self.processIntents(by: bestAttemptContent,
                                                             image: nil,
                                                             extra: extra)
                    contentHandler(messageContent)
                    return
                }

                if let fileURL = fileURL {
                    // lint:disable:next lark_storage_check - 不涉及加解密，不处理
                    let image = UIImage(contentsOfFile: fileURL.path)
                    if image != nil {
                        LarkNSELogger.logger.info("Get the image successfully")
                        var dictionary: [String: String] = [:]
                        if let dict = imageCachePaths {
                            dictionary = dict
                        }
                        dictionary[imageUrl] = fileURL.path
                        imageCachePaths = dictionary
                    }
                    let messageContent = Self.processIntents(by: bestAttemptContent,
                                                             image: image,
                                                             extra: extra)

                    let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? "", "type": "network"]
                    ExtensionTracker.shared.trackSlardarEvent(key: "APNs_process_intent_image",
                                                              metric: [:],
                                                              category: category,
                                                              params: [:])

                    contentHandler(messageContent)
                } else {
                    LarkNSELogger.logger.info("FileURL is empty")

                    let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? "", "type": "imageError"]
                    ExtensionTracker.shared.trackSlardarEvent(key: "APNs_process_intent_error",
                                                              metric: [:],
                                                              category: category,
                                                              params: [:])
                }
            })

            // Begin download task.
            currentDownloadTask?.resume()
        } else {
            LarkNSELogger.logger.info("Failed to get URL")
            let messageContent = Self.processIntents(by: bestAttemptContent,
                                                     image: nil,
                                                     extra: extra)
            contentHandler(messageContent)
            return
        }
    }

    private static func processIntents(by bestAttemptContent: UNMutableNotificationContent,
                                       image: UIImage?,
                                       extra: LarkNSEExtra) -> UNNotificationContent {
        var messageContent: UNMutableNotificationContent = bestAttemptContent
        let useStartCallIntent = processVCIntents(extra: extra)
        #if swift(>=5.5)
        if !extra.isNotComm {
            let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? ""]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_process_intent",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            var senderAvatar: INImage?
            if let image = image {
                senderAvatar = INImage(imageData: image.pngData()!)
            } else {
                LarkNSELogger.logger.info("Image is empty")
            }

            if !useStartCallIntent {
                let senderName = Self.processSenderName(senderName: extra.senderName, tenantName: extra.tenantName)
                var senderNameComponents = PersonNameComponents()
                senderNameComponents.nickname = senderName
                senderNameComponents.givenName = senderName
                messageContent.title = senderName

                let personHandle = INPersonHandle(value: extra.senderName, type: .unknown)
                let person = INPerson(
                    personHandle: personHandle,
                    nameComponents: senderNameComponents,
                    displayName: senderName,
                    image: senderAvatar,
                    contactIdentifier: extra.senderDigestId,
                    customIdentifier: nil
                )

                let incomingMessageIntent = INSendMessageIntent(recipients: [],
                                                                outgoingMessageType: .outgoingMessageText,
                                                                content: nil,
                                                                speakableGroupName: INSpeakableString(spokenPhrase: extra.groupName),
                                                                conversationIdentifier: String(extra.chatDigestId),
                                                                serviceName: nil,
                                                                sender: person,
                                                                attachments: [])
                if !extra.groupName.isEmpty {
                    messageContent.subtitle = extra.groupName
                    let groupInfoData = INSendMessageIntentDonationMetadata()
                    groupInfoData.isReplyToCurrentUser = extra.isReply
                    groupInfoData.mentionsCurrentUser = extra.isMentioned
                    groupInfoData.notifyRecipientAnyway = true
                    groupInfoData.recipientCount = extra.groupSize
                    incomingMessageIntent.donationMetadata = groupInfoData
                    incomingMessageIntent.setImage(senderAvatar, forParameterNamed: \.speakableGroupName)
                } else {
                    incomingMessageIntent.setImage(senderAvatar, forParameterNamed: \.sender)
                }

                let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
                interaction.direction = .incoming
                interaction.donate(completion: nil)

                do {
                    LarkNSELogger.logger.info("Processing content")
                    if let content = try bestAttemptContent.updating(from: incomingMessageIntent) as? UNMutableNotificationContent {
                        messageContent = content
                    }
                } catch {
                    LarkNSELogger.logger.info("Failed to process content")
                    let category: [String: Any] = ["Sid": extra.Sid, "messageId": extra.messageID ?? "", "type": "content"]
                    ExtensionTracker.shared.trackSlardarEvent(key: "APNs_process_intent_error",
                                                              metric: [:],
                                                              category: category,
                                                              params: [:])
                    messageContent = bestAttemptContent
                }
            } else {
                #if swift(>=5.5.2)
                guard #available(iOSApplicationExtension 15.2, iOS 15.2, *) else {
                    LarkNSELogger.logger.info("Failed to process VC content")
                    messageContent = bestAttemptContent
                    return messageContent
                }

                var senderNameComponents: PersonNameComponents?
                if !extra.senderName.isEmpty {
                    senderNameComponents = PersonNameComponents()
                    senderNameComponents!.nickname = extra.senderName
                    senderNameComponents!.givenName = extra.senderName
                    messageContent.title = extra.senderName
                }

                let personHandle = INPersonHandle(value: extra.senderName, type: .unknown)
                let person = INPerson(
                    personHandle: personHandle,
                    nameComponents: senderNameComponents,
                    displayName: extra.senderName,
                    image: senderAvatar,
                    contactIdentifier: extra.senderDigestId,
                    customIdentifier: nil
                )
                // INStartCallIntent 必须要使用 ringtoneSoundNamed 创建的铃声才会有振动
                // 自定义铃声也需要重新设置 sound
                var ringtoneName = extra.soundUrl ?? "vc_call_ringing.mp3"
                LarkNSELogger.logger.info("[NSE][INStartCall] ringtone: \(ringtoneName)")
                bestAttemptContent.sound = UNNotificationSound.ringtoneSoundNamed(.init(rawValue: ringtoneName))
                let callCapability: INCallCapability = extra.biz == .voip ? .audioCall : .videoCall
                let callIntent = INStartCallIntent(callRecordFilter: nil,
                                                   callRecordToCallBack: nil,
                                                   audioRoute: .unknown,
                                                   destinationType: .normal,
                                                   contacts: [person],
                                                   callCapability: callCapability)

                callIntent.setImage(senderAvatar, forParameterNamed: \.contacts)
                let interaction = INInteraction(intent: callIntent, response: nil)
                interaction.direction = .incoming
                interaction.donate(completion: nil)

                do {
                    LarkNSELogger.logger.info("Processing VC content")
                    if let content = try bestAttemptContent.updating(from: callIntent) as? UNMutableNotificationContent {
                        messageContent = content
                    }
                } catch {
                    LarkNSELogger.logger.info("Failed to process VC content")
                    messageContent = bestAttemptContent
                }
                #endif
            }
        }
        #endif

        LarkNSELogger.logger.info("End Processing content")
        return messageContent
    }

    private static func processSenderName(senderName: String, tenantName: String) -> String {
        return LarkNSEContentProcessor.process(prefixString: senderName, tenantName: tenantName)
    }

    /// 处理 VC 的推送通知，判断是否需要走 INStartCallIntent 通知
    /// - Parameter extra: LarkNSEExtra
    /// - Returns: 如果 vc 的通知需要走 INStartCallIntent，返回 true
    private static func processVCIntents(extra: LarkNSEExtra) -> Bool {
        var useStartCallIntent: Bool = false
        if extra.biz == .voip || extra.biz == .vc {
            if let bizExtra = extra.extraString,
               let bizData = bizExtra.data(using: .utf8),
               let bizDict = try? JSONSerialization.jsonObject(with: bizData, options: []) as? [String: Any] {
                #if swift(>=5.5.2)
                // 仅 iOS 15.2 及以上系统且 start_call_intent == true && action == 'ringing' 才能走通信通知新特性
                if #available(iOSApplicationExtension 15.2, iOS 15.2, *),
                   let action = bizDict["action"] as? String,
                   let startCallIntent = bizDict["start_call_intent"] as? Bool {
                    useStartCallIntent = action == "ringing" && startCallIntent == true
                }
                let hasActiveCall = LarkNSECallProvider.shared.hasActiveCall
                if useStartCallIntent, hasActiveCall {
                    useStartCallIntent = false
                }
                #endif
            } else {
                LarkNSELogger.logger.info("byteview extra failed: \(extra.extraString ?? "")")
            }
        }

        return useStartCallIntent
    }
}
// swiftlint:enable all
