//
//  InputHandleProtocol.swift
//  Lark
//
//  Created by lichen on 2017/11/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel

public struct RichTextAttrPriority: RawRepresentable {
    public typealias RawValue = UInt

    public static let high: RichTextAttrPriority = RichTextAttrPriority(rawValue: 1000)!
    public static let medium: RichTextAttrPriority = RichTextAttrPriority(rawValue: 500)!
    // 内容节点， 具有排他性，所有小于等于 content 节点只保留一个优先级最高的
    public static let content: RichTextAttrPriority = RichTextAttrPriority(rawValue: 100)!
    public static let lowest: RichTextAttrPriority = RichTextAttrPriority(rawValue: 0)!

    public init?(rawValue: RichTextAttrPriority.RawValue) {
        self.rawValue = rawValue
    }

    public var rawValue: RichTextAttrPriority.RawValue
}

public struct RichTextAttr {
    public let priority: RichTextAttrPriority
    public let tuple: RichTextParseHelper.RichTextAttrTuple

    public init(priority: RichTextAttrPriority, tuple: RichTextParseHelper.RichTextAttrTuple) {
        self.priority = priority
        self.tuple = tuple
    }

    public func split(range: NSRange, origin: NSRange) -> RichTextAttr? {
        // 切分 range 必须为原有 range 的子集
        if range.location < origin.location || range.location + range.length > origin.location + origin.length {
            return nil
        }

        switch self.tuple.tag {
        case .text:
            if case let RichTextParseHelper.PropertyWapper.text(text) = self.tuple.property {
                var text = text
                /// 前面是依据NSString计算location和length，这里画也需要统一NSString标准
                let textLength = (text.content as NSString).length
                if origin.length > textLength + 1 {
                    assertionFailure("不应该出现这种情况")
                }

                var subRange = NSRange(location: range.location - origin.location, length: range.length)
                if origin.length == textLength + 1 {
                    // 前面的 \n 被删除了， 整体向前移动一位
                    if subRange.location > 0 {
                        subRange = NSRange(location: range.location - origin.location - 1, length: range.length)
                    } else {
                        subRange = NSRange(location: range.location - origin.location, length: range.length - 1)
                    }
                }

                if subRange.location + subRange.length > textLength {
                    // subRange的结束不应该大于总字符串的长度，如果遇到请联系李晨，康思婉
                    assertionFailure("subRang error, @lichen.arthur, @kangsiwan")
                    subRange = NSRange(location: subRange.location, length: textLength - subRange.location)
                }
                text.content = (text.content as NSString).substring(with: subRange)
                return RichTextAttr(priority: self.priority, tuple: (tag: .text, id: InputUtil.randomId(), property: .text(text), self.tuple.style))
            }
        // 目前只针对 text 做处理
        case .figure, .p, .img, .media, .at, .emotion, .a, .b, .i, .u, .link, .mention, .codeBlockV2, .myAiTool:
            return self
        case .unknown, .button, .select, .progressselect, .div, .textablearea, .time:
            return nil
        case .selectmenu, .overflowmenu, .datepicker,
             .docs, .h1, .h2,
             .h3, .h4, .h5, .h6, .ul, .li,
             .quote, .code, .codeBlock,
             .hr, .ol, .timepicker, .datetimepicker:
            return nil
        case .reaction: return nil
        @unknown default:
            assert(false, "new value")
            break
        }

        return nil
    }
}

public struct RichTextFragmentAttr {
    public let range: NSRange
    public let attrs: [RichTextAttr]

    public init(_ range: NSRange, _ attrs: [RichTextAttr]) {
        self.range = range
        self.attrs = attrs
    }
}
