//
//  MessageStatusButton.swift
//  LarkThread
//
//  Created by 姚启灏 on 2019/2/19.
//

import UIKit
import Foundation

final class MessageStatusButton: IconButton {
    private static func labelText(_ isFailed: Bool) -> String {
        return isFailed ? BundleI18n.LarkThread.Lark_Chat_Resend : BundleI18n.LarkThread.Lark_Chat_Sending
    }

    public class func sizeToFit(_ size: CGSize, iconSize: CGFloat, isFailed: Bool) -> CGSize {
        let title = labelText(isFailed)
        return super.sizeToFit(size, iconSize: iconSize, title: title)
    }

    public func update(isFailed: Bool) {
        let title = MessageStatusButton.labelText(isFailed)
        if !isFailed {
            let icon = Resources.threadMessageSendLoading
            self.update(title: title, icon: icon)
            self.icon.lu.addRotateAnimation()
            self.label.textColor = UIColor.ud.colorfulBlue
            self.isUserInteractionEnabled = false
            self.hitTestEdgeInsets = UIEdgeInsets(top: -5, left: 0, bottom: -5, right: 0)
        } else {
            self.update(title: title, icon: Resources.threadMessageSendFail)
            self.label.textColor = UIColor.ud.colorfulRed
            self.isUserInteractionEnabled = true
            self.hitTestEdgeInsets = UIEdgeInsets.zero
        }
    }
}
