//
//  SmartCorrectService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2023/5/12.
//

import Foundation
import EditTextView
import LarkModel

public enum SmartCorrectScene {
    case im
    case richText
}
public protocol SmartCorrectService {
    func setupCorrectService(chat: LarkModel.Chat?,
                             scene: SmartCorrectScene,
                             fromController: UIViewController?,
                             inputTextView: LarkEditTextView?)
}
