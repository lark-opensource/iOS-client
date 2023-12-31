//
//  MessengerDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/26.
//

import Foundation
import ByteViewNetwork
import RustPB

public protocol MessengerDependency {

    /// 获取chat会话标题 和 chat会话是否是日历会话
    /// - Parameter chatId: chat 会话ID
    func fetchChatInfo(by chatId: String, completion: @escaping (Result<(String, Bool), Error>) -> Void)

    /// 发送文本消息
    func sendText(_ text: String, chatId: String, completion: ((String?) -> Void)?)

    /// 会议卡片分享
    func shareMeetingCard(meetingId: String, from: UIViewController, source: ShareMeetingCardSource, canShare: (() -> Bool)?)

    func richTextToString(_ richText: MessageRichText) -> NSMutableAttributedString

    func stringToRichText(_ string: NSAttributedString) -> MessageRichText?
}

public enum ShareMeetingCardSource {
    case meetingDetail
    case participants
}
