//
//  ResourceModel.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/9.
//

import Foundation

public typealias PropertyHandler<T> = (T) -> Void
public typealias PropertyKey = String

final class PropertySet {
    var value: [PropertyKey: BlockObject] = [:]
    var keyPath: [AnyKeyPath: BlockObject] = [:]
}

struct BlockObject {
    public var block: () -> Void

    public init(_ block: @escaping () -> Void) {
        self.block = block
    }
}
