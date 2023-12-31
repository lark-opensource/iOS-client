//
//  Message.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit
import UniverseDesignTheme

struct Message {

    var id: Int
    var avatar: UIImage
    var name: String
    var content: Content
    var isFromSelf: Bool

    enum Content {
        case text(String)
        case image(UIImage)
    }

}

extension Message {

    static func getExamples() -> [Message] {
        return [
            Message(
                id: 0,
                avatar: UIImage(named: "avatar_user")!,
                name: "",
                content: .text("预览主题"),
                isFromSelf: true
            ),
            Message(
                id: 1,
                avatar: UIImage(named: "avatar_ux")!,
                name: "",
                content: .text("切换下面选项卡，可设置主题"),
                isFromSelf: false
            ),
            Message(
                id: 1,
                avatar: UIImage(named: "avatar_ux")!,
                name: "",
                content: .text("如果在使用过程中存在问题或意见，可反馈给 @王海栋"),
                isFromSelf: false
            ),
            Message(
                id: 2,
                avatar: UIImage(named: "avatar_lark")!,
                name: "",
                content: .text("这是一张动态照片"),
                isFromSelf: false
            ),
            Message(
                id: 2,
                avatar: UIImage(named: "avatar_lark")!,
                name: "",
                content: .image(UIImage(named: "image_light")! & UIImage(named: "image_dark")!),
                isFromSelf: false
            )
        ]
    }

}
