//
//  ChatDateCellViewModel.swift
//  LarkNewChat
//
//  Created by zc09v on 2019/3/31.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkCore
import LarkMessageBase
import LarkExtensions

final class ChatDateCellViewModel: SignCellViewModel<ChatContext> {
    final override var identifier: String {
        return "message-date"
    }

    private let date: TimeInterval

    final var dateStr: String {
        return date.lf.cacheFormat("t_date", formater: { $0.lf.formatedDate() })
    }

    final override var lineColor: UIColor {
        return UIColor.ud.N400
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    final override var textColor: UIColor {
        return UIColor.ud.N900
    }

    final override var backgroundColor: UIColor {
        return .clear
    }

    final override var centerText: String {
        return dateStr
    }

    init(date: TimeInterval, context: ChatContext) {
        self.date = date
        super.init(context: context, binder: SignCellComponentBinder<ChatContext>(context: context))
    }
}
