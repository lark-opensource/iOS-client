//
//  MessageMenuViewModel.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/29.
//

import UIKit
import Foundation
import Homeric
import LarkModel
import LarkUIKit
import LKCommonsTracker
import LKCommonsLogging
import LarkEmotion
import LarkMessageBase
import LarkMenuController
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkSetting
import LarkEmotionKeyboard
import LarkCore
import LarkGuide
import UniverseDesignToast

public typealias MenuMessageSelectedType = CopyMessageSelectedType

public struct MessageMenuInfoKey {
        public static let menuItem = "menuItem"
        public static let copyType = "copyType"
        public static let selectedType = "selectedType"
        public static let time = "time"
        public static let anonymousKey = "anonymousIDKey"
        public static let reactionKey = "reactionKey"
        public static let reactionSource = "reactionSource"
        public static let threadMessage = "threadMessage"
        public static let scene = "scene"
        public static let isSkintonePanel = "isSkintonePanel"
        public static let skintoneEmojiSelectWay = "skintone_emoji_select_way"
        public static let chatFromWhere = "chatFromWhere"
}
