//
//  ToastItem.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/6/21.
//

import Foundation

typealias BottomToastClickHandler = () -> Void

enum BottomToastItem {

    static let defaultDuration = 3.0

    struct MetaInfo {
        let duration: TimeInterval
        let text: String
        var forceInert: Bool = false
        var customBottomMarging: CGFloat = 64.0 // 44.0 + 20.0 默认首页tab

        init(duration: TimeInterval = BottomToastItem.defaultDuration, text: String) {
            self.duration = duration
            self.text = text
        }
    }

    case nomarl(MetaInfo) // 黑框纯文字 tost
    case loading(MetaInfo) // 转圈 loading Toast : forceInsert会强制
    case success(MetaInfo) // ✅toast
    case fail(MetaInfo) // ❎ toast
    case action(MetaInfo, rightTitle: String, BottomToastClickHandler) // 右边有按钮的
}
