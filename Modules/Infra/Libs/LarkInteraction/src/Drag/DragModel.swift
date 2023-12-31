//
//  DragModel.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/25.
//

import UIKit
import Foundation

public enum DragItemData {
    /// 满足 NSItemProviderWriting  实例对象
    case objectType(NSItemProviderWriting)
    /// 数据 URL
    case fileURL(URL)
    /// 自定义 provider
    case custom(item: NSSecureCoding, typeIdentifier: String)
}

public struct DragItemValue {
    /// item 名
    public var suggestedName: String?
    /// item 数据
    public var data: DragItemData
    /// item preview
    public var priview: (() -> UIDragPreview)?

    init(
        suggestedName: String? = nil,
        data: DragItemData,
        priview: (() -> UIDragPreview)? = nil
    ) {
        self.suggestedName = suggestedName
        self.data = data
        self.priview = priview
    }
}
