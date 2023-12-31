//
//  FeedFloatMenuSubModule.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/11/29.
//

import Foundation
import LarkOpenIM

public protocol HasFloatMenuOptionType {
    var type: FloatMenuOptionType { get }
}

open class BaseFeedFloatMenuSubModule: Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>, HasFloatMenuOptionType {
    /// 开始构造视图，canHandle == true && activated == true，才会执行后续方法
    open var type: FloatMenuOptionType {
        assertionFailure("must override")
        return .unknown
    }
    /// 是否应该展示视图
    public var display: Bool = false

    open func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? { return nil }
    open func didClick() {}
}

open class FeedFloatMenuSubModule: BaseFeedFloatMenuSubModule {}
