//
//  Chat.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit

struct Chat {

    var avatar: UIColor
    var name: String
    var lastMessage: String?
    var lastActiveTime: String?

}

extension Chat {

    static func getExamples() -> [Chat] {
        // TODO: 3.41 暂时不上此页面，没有给出国际化文案。后面补上 @王海栋
        return [
            Chat(
                avatar: .systemBlue,
                name: "飞书助手",
                lastMessage: "选择问题分类，更快找到答案",
                lastActiveTime: "10:09"
            ),
            Chat(
                avatar: .systemRed,
                name: "会话盒子",
                lastMessage: "[45个会话有新消息]",
                lastActiveTime: "昨天"
            ),
            Chat(
                avatar: .systemGreen,
                name: "飞书团队",
                lastMessage: "你好，如果你有任何关于飞书的使用问题请随时与我们联系",
                lastActiveTime: "11月2日"
            ),
            Chat(
                avatar: .systemOrange,
                name: "飞书文档",
                lastMessage: "选择一个模版",
                lastActiveTime: "10月31日"
            )
        ]
    }

}
