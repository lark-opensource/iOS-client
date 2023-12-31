//
//  NotificationService.swift
//  NotificationService
//
//  Created by admin on 2021/12/1.
//

import UserNotifications
import Intents
import AVFAudio

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.title) [NSE]"

            var content: UNNotificationContent?
            let userInfo = bestAttemptContent.userInfo
            if let showType = userInfo["show_type"] {
                let showType_ = showType as! String
                if showType_ == "message" {
                    content = handleMessageIntent(bestAttemptContent)
                } else if showType_ == "call" {
                    content = handleCallIntent(bestAttemptContent)
                }
            }

            contentHandler(content ?? bestAttemptContent)
        }
    }

    func handleMessageIntent(_ bestAttemptContent: UNMutableNotificationContent) -> UNNotificationContent {
#if swift(>=5.5)
        guard #available(iOSApplicationExtension 15, *) else {
            return bestAttemptContent
        }
        let handle = INPersonHandle(value: "unique-user-id-1", type: .unknown)
        let avatar = INImage(named: "profilepicture.png")
        let sender = INPerson(personHandle: handle,
                              nameComponents: nil,
                              displayName: "ByteView Messager",
                              image: avatar,
                              contactIdentifier: nil,
                              customIdentifier: nil)

        // Because this communication is incoming, you can infer that the current user is
        // a recipient. Don't include the current user when initializing the intent.
        let incomingMessageIntent = INSendMessageIntent(recipients: nil,
                                                        outgoingMessageType: .outgoingMessageText,
                                                        content: "ByteView Message content",
                                                        speakableGroupName: nil,
                                                        conversationIdentifier: "unique-conversation-id-1",
                                                        serviceName: nil,
                                                        sender: sender,
                                                        attachments: nil)
        incomingMessageIntent.setImage(avatar, forParameterNamed: \.sender)
        let interaction = INInteraction(intent: incomingMessageIntent, response: nil)
        interaction.direction = .incoming
        interaction.donate(completion: nil)

        do {
            let content = try bestAttemptContent.updating(from: incomingMessageIntent)
            return content
        } catch {
            return bestAttemptContent
        }
#else
        return bestAttemptContent
#endif
    }

    func handleCallIntent(_ bestAttemptContent: UNMutableNotificationContent) -> UNNotificationContent {
#if swift(>=5.5.2)
        guard #available(iOSApplicationExtension 15.2, *) else {
            return bestAttemptContent
        }

        bestAttemptContent.sound = UNNotificationSound.ringtoneSoundNamed(.init(rawValue: "call.caf"))
        // Initialize only the caller for a one-to-one call intent.
        let handle = INPersonHandle(value: "unique-user-id-1", type: .unknown)
        let avatar = INImage(named: "profilepicture.png")
        let caller = INPerson(personHandle: handle,
                              nameComponents: nil,
                              displayName: "ByteView Caller",
                              image: avatar,
                              contactIdentifier: nil,
                              customIdentifier: nil)

        // Include the other participants of the call in the contacts array.
        // Because this communication is incoming, you can infer that the current user is
        // a participant of the call. Don't include the user in the contacts array.
        var audioRoute: INCallAudioRoute = .bluetoothAudioRoute
        let route = AVAudioSession.sharedInstance().currentRoute
        for output in route.outputs {
            let portType = output.portType
            if portType == .builtInSpeaker {
                audioRoute = .speakerphoneAudioRoute
                break
            }
        }

        var callCapability: INCallCapability = .audioCall
        let userInfo = bestAttemptContent.userInfo
        if let callType = userInfo["call_type"] {
            let callType_ = callType as! String
            if callType_ == "video" {
                callCapability = .videoCall
            }
        }

        let record: INCallRecord = INCallRecord(
            identifier: handle.value!,
            dateCreated: Date(),
            caller: caller,
            callRecordType: .ringing,
            callCapability: callCapability,
            callDuration: 0,
            unseen: false,
            numberOfCalls: 1
        )
        let callIntent = INStartCallIntent(callRecordFilter: nil,
                                           callRecordToCallBack: record,
                                           audioRoute: audioRoute,
                                           destinationType: .normal,
                                           contacts: [caller],
                                           callCapability: callCapability)

        callIntent.setImage(avatar, forParameterNamed: \.contacts)
        let interaction = INInteraction(intent: callIntent, response: nil)
        interaction.direction = .incoming
        interaction.donate(completion: nil)

        do {
            let content = try bestAttemptContent.updating(from: callIntent)
            return content
        } catch {
            return bestAttemptContent
        }
#else
        return bestAttemptContent
#endif
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
