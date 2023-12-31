//
//  LarkInterface+SearchPicker.swift
//  SpaceInterface
//
//  Created by nine on 2019/7/1.
//

import Foundation
import EENavigator

/// 被选择的会话
public protocol LarkSearchChatPickerItemProtocol {
    var chatID: String { get }
    var avatarKey: String { get }
    var groupID: String? { get }
    var avatarID: String { get }
}

/// 被选择的所有者
public protocol LarkSearchChatterPickerItemProtocol {
    var chatterID: String { get }
    var avatarKey: String { get }
}

/// 所有者选择器
public struct LarkSearchContactPickerBody: PlainBody {
    public static let pattern = "//client/search/larkContactPicker"
    /// 选择器标题
    public let title: String
    public var selectedItems: [LarkSearchChatterPickerItemProtocol] = []
    public var didFinishChoosenItems: (([LarkSearchChatterPickerItemProtocol]) -> Void)

    public init(title: String, didFinishChoosenItems: @escaping (([LarkSearchChatterPickerItemProtocol]) -> Void)) {
        self.didFinishChoosenItems = didFinishChoosenItems
        self.title = title
    }
}

/// 所在会话选择器
public struct LarkSearchChatPickerBody: PlainBody {
    public static let pattern = "//client/search/larkChatPicker"

    public var selectedItems: [LarkSearchChatPickerItemProtocol] = []
    public var didFinishPickChats: ((UIViewController, [LarkSearchChatPickerItemProtocol]) -> Void)?

    public init() {}
}
