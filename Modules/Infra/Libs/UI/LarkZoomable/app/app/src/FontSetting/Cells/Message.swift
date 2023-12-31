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
                avatar: UIImage.from(color: .systemGreen),
                name: "",
                content: "预览字体大小",
                isFromSelf: true
            ),
            Message(
                id: 1,
                avatar: UIImage.from(color: .systemRed),
                name: "",
                content: "拖动下面的滑块，可设置字体大小",
                isFromSelf: false
            ),
            Message(
                id: 1,
                avatar: UIImage.from(color: .systemRed),
                name: "",
                content: "设置后，会改变聊天中的字体大小。如果在使用过程中存在问题或意见，可反馈给 @王海栋。",
                isFromSelf: false
            )
        ]
    }

}

extension UIImage {
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
