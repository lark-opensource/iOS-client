//
//  KeyboardShareDataService.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/5/10.
//

import UIKit
import LarkChatOpenKeyboard
import LarkMessengerInterface
import LarkChatKeyboardInterface

public class KeyboardShareDataManager: KeyboardShareDataService {

    public lazy var countdownService: MultiEditCountdownService = {
        return MultiEditCountdownServiceImpl()
    }()

    public lazy var keyboardStatusManager: KeyboardStatusManager = {
       let keyboardStatusManager = KeyboardStatusManager()
        return keyboardStatusManager
    }()

    public var myAIInlineService: IMMyAIInlineService?

    public var isMyAIChatMode: Bool = false

    public var supportDraft: Bool = true

    public var supportPartReply = false

    public var unsupportPasteTypes: [KeyboardSupportPasteType] = []

    public init() {}

    public lazy var forwardToChatSerivce: SyncToChatOptionViewService = {
        return SyncToChatOptionViewServiceImp()
    }()
}
