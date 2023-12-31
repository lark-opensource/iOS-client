//
//  SmartComposeService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2023/6/21.
//

import Foundation
import EditTextView
import LarkModel
public enum SmartComposeScene: Int {
    case UNKNOWN = 0
    case MESSENGER = 1
}
public protocol SmartComposeService {
    func setupSmartCompose(chat: LarkModel.Chat?,
                           scene: SmartComposeScene,
                           with inputTextView: LarkEditTextView?,
                           fromVC: UIViewController?)
}
