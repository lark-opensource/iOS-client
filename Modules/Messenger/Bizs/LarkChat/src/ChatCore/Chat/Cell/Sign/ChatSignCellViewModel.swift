//
//  ChatSignCellViewModel.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/3/31.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageCore
import LarkMessageBase

final class ChatSignCellViewModel: SignCellViewModel<ChatContext> {
    final override var identifier: String {
        return "message-sign"
    }

    final override var centerText: String {
        return BundleI18n.LarkChat.Lark_Legacy_NewMessageSign
    }

    final override var backgroundColor: UIColor {
        return UIColor.clear
    }

    final override var textColor: UIColor {
        return UIColor.ud.primaryContentPressed
    }

    final override var lineColor: UIColor {
        return UIColor.ud.primaryContentPressed
    }

    init(context: ChatContext) {
        super.init(context: context, binder: SignCellComponentBinder<ChatContext>(context: context))
    }
}
