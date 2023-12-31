//
//  Message.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit

struct Message {

    var id: Int
    var avatar: UIImage
    var name: String
    var content: String
    var isFromSelf: Bool

}

extension Message {

    static func getExamples() -> [Message] {
        return [
            Message(
                id: 0,
                avatar: Resources.ios_icon,
                name: "",
                content: BundleI18n.LarkMine.Lark_NewSettings_PreviewTextSize,
                isFromSelf: true
            ),
            Message(
                id: 1,
                avatar: Resources.ios_icon,
                name: "",
                content: BundleI18n.LarkMine.Lark_NewSettings_AdjustSlider,
                isFromSelf: false
            ),
            Message(
                id: 1,
                avatar: Resources.ios_icon,
                name: "",
                content: BundleI18n.LarkMine.Lark_NewSettings_TextSizeWillBeChanged(),
                isFromSelf: false
            )
        ]
    }

}
