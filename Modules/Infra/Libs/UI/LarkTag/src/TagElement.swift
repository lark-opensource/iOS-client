//
//  TagElement.swift
//  LarkTag
//
//  Created by kongkaikai on 2019/6/16.
//

import Foundation

/// Tag 元素，TagWrapperView支持使用符合该协议的数组设置显示内容
public protocol TagElement {
    // 当前 Element 对应的 Tag
    var tag: Tag { get }

    // 当前 Element 对应的 TagType
    var type: TagType { get }
}

extension Tag: TagElement {
    public var tag: Tag { return self }
}

extension TagType: TagElement {
    public var tag: Tag { return Tag(type: self) }
    public var type: TagType { return self }
}
