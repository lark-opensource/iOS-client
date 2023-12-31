//
//  WebContainerDependencyImpl.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/11/22.
//

import Foundation
import EENavigator

// profile
public struct OpenUserProfileService {
    public let userId: String
    public let fromVC: UIViewController
    public let fileName: String?
    public let params: [String: Any]
}

// chat
public struct WAOpenChatBody : Codable, PlainBody {
    public static let pattern = "//client/docs/openchat"
    public let chatId: String
    public let position: Int?

    public init(chatId: String, position: Int?) {
        self.chatId = chatId
        self.position = position
    }
}
