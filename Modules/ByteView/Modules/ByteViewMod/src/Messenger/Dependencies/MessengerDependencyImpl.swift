//
//  MessengerDependencyImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/26.
//

import Foundation
import ByteView
import ByteViewCommon
import ByteViewNetwork
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LarkSendMessage
import RustPB
import LarkRichTextCore
import LarkBaseKeyboard

final class MessengerDependencyImpl: MessengerDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func fetchChatInfo(by chatId: String, completion: @escaping (Result<(String, Bool), Error>) -> Void) {
        do {
            let api = try userResolver.resolve(assert: ChatAPI.self)
            _ = api.fetchChat(by: chatId, forceRemote: false).map({ chat -> (String, Bool) in
                return (chat?.name ?? "", chat?.isMeeting ?? false)
            }).subscribe(onNext: {
                completion(.success(($0.0, $0.1)))
            }, onError: {
                completion(.failure($0))
            })
        } catch {
            completion(.failure(error))
        }
    }

    func sendText(_ text: String, chatId: String, completion: ((String?) -> Void)?) {
        do {
            let api = try userResolver.resolve(assert: SendMessageAPI.self)
            api.sendText(context: nil, content: .text(text), parentMessage: nil, chatId: chatId, threadId: nil) { state in
                if case .finishSendMessage(_, _, let messageId, _, _) = state {
                    completion?(messageId)
                }
            }
        } catch {
            Logger.dependency.error("MessengerDependency.sendText failed, \(error)")
        }
    }

    func shareMeetingCard(meetingId: String, from: UIViewController, source: ShareMeetingCardSource, canShare: (() -> Bool)?) {
        let body = ShareMeetingBody(meetingId: meetingId, skipCopyLink: true, style: .card, source: source.toMessenger(), canShare: canShare)
        userResolver.navigator.present(body: body, from: from)
    }

    func richTextToString(_ richText: MessageRichText) -> NSMutableAttributedString {
        let richTextRes = LarkRichTextCoreUtils.parseRichText(richText: richText, checkIsMe: nil, customAttributes: [:])
        return richTextRes.attriubuteText
    }

    func stringToRichText(_ string: NSAttributedString) -> MessageRichText? {
        return RichTextTransformKit.transformStringToRichText(string: string)
    }
}

private extension ShareMeetingCardSource {
    func toMessenger() -> ShareMeetingBody.Source {
        switch self {
        case .meetingDetail: return .meetingDetail
        case .participants: return .participants
        }
    }
}
