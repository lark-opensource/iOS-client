//
//  SecretChatService.swift
//  LarkModel
//
//  Created by shane on 2019/5/6.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import LarkUIKit

public protocol SecretChatService {
    var navigationBackgroundColor: UIColor { get }
    var keyboardItemsTintColor: UIColor { get }
    /// 当前用户是否能够使用密聊
    var secretChatEnable: Bool { get }

    /// 密聊功能介绍
    func featureIntroductions(secureViewIsWork: Bool) -> [String]
}
