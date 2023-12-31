//
//  SearchUniversalPickerBody.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/8/30.
//

import UIKit
import Foundation
import EENavigator
import LarkSDKInterface
import LarkSearchFilter
import LarkMessengerInterface
import ServerPB
import RustPB

public enum UniversalPickerType: Equatable {
    public static func == (lhs: UniversalPickerType, rhs: UniversalPickerType) -> Bool {
        switch (lhs, rhs) {
        case (.folder, .folder): return true
        case (.workspace, .workspace): return true
        case let (.chat(lhsMode), .chat(rhsMode)): return lhsMode == rhsMode
        case let (.filter(lhsInfo), .filter(rhsInfo)): return lhsInfo.id == rhsInfo.id
        case (.defaultType, .defaultType): return true
        case (.userAndGroupChat, .userAndGroupChat): return true
        default:
            return false
        }
    }

    /// 所在文件夹筛选器
    case folder
    /// 所在知识空间筛选器
    case workspace
    /// 所在会话筛选器，在UI上与转发场景不同
    case chat(chatMode: ChatFilterMode)
    /// 筛选器
    case filter(ServerPB.ServerPB_Searches_PlatformSearchFilter.CustomFilterInfo)
    /// 转发及其他场景
    case defaultType
    case label((Int) -> String)
    case userAndGroupChat

    public func sameType(with other: UniversalPickerType) -> Bool {
        switch (self, other) {
        case (.folder, .folder): return true
        case (.workspace, .workspace): return true
        case (.chat, .chat): return true
        case (.filter, .filter): return true
        case (.defaultType, .defaultType): return true
        case (.userAndGroupChat, .userAndGroupChat): return true
        default:
            return false
        }
    }
}

public struct SearchChatPickerBody: PlainBody {
    public static let pattern = "//client/search/chatPicker"

    public var selectedItems: [SearchChatPickerItem] = []
    public var pickType: ChatFilterMode = .unlimited
    public var didFinishPickChats: ((UIViewController, [SearchChatPickerItem]) -> Void)?

    public init() {}
}

public struct SearchUniversalPickerBody: PlainBody {
    public static let pattern = "//client/search/UniversalPicker"

    public var pickType: UniversalPickerType
    public var selectedItems: [ForwardItem]
    public var didFinishPick: ((UIViewController, [ForwardItem]) -> Void)?
    public var selectMode: SelectMode
    public var enableMyAi: Bool
    public var supportFrozenChat: Bool?

    public init(pickType: UniversalPickerType,
                selectedItems: [ForwardItem],
                selectMode: SelectMode = .Multi,
                enableMyAi: Bool = false,
                supportFrozenChat: Bool? = nil) {
        self.pickType = pickType
        self.selectedItems = selectedItems
        self.selectMode = selectMode
        self.enableMyAi = enableMyAi
        self.supportFrozenChat = supportFrozenChat
    }
    public enum SelectMode {
        case Single
        case Multi
    }
}
