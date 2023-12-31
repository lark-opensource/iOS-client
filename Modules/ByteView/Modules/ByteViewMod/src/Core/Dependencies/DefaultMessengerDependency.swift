//
//  DefaultMessengerDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/26.
//

import Foundation
import ByteView
import ByteViewNetwork

final class DefaultMessengerDependency: MessengerDependency {
    func fetchChatInfo(by chatId: String, completion: @escaping (Result<(String, Bool), Error>) -> Void) {
        completion(.success(("test", false)))
    }

    func sendText(_ text: String, chatId: String, completion: ((String?) -> Void)?) {
        completion?(nil)
    }

    func shareMeetingCard(meetingId: String, from: UIViewController, source: ShareMeetingCardSource, canShare: (() -> Bool)?) {
    }

    func richTextToString(_ richText: MessageRichText) -> NSMutableAttributedString {
        NSMutableAttributedString(string: "demo调richText 需要引入LarkCore\n这是换行测试\n这是多行测试🍎🍊🍌🍍🍑🌽🍉🍺🍃🌰🍐🍒🍇🥝🍅🍓🍈🎃🥛🥒🥬🍆🌶️🍔🍗🍟🍜🥟🥕🍬\n这是链接测试http://www.baidu.com")
    }

    func stringToRichText(_ string: NSAttributedString) -> MessageRichText? {
        nil
    }
}
