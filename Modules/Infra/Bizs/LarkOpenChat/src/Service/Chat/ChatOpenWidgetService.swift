//
//  ChatOpenWidgetService.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/1/9.
//

import UIKit
import Foundation
import LarkModel

public protocol ChatOpenWidgetService: AnyObject {
    /// 更新一组 widget 数据
    func update(doUpdate: @escaping (ChatWidget) -> ChatWidget?, completion: ((Bool) -> Void)?)
    /// 刷新列表
    func refresh()
    var containerSize: CGSize { get }
}

public final class DefaultChatOpenWidgetServiceImp: ChatOpenWidgetService {
    public func update(doUpdate: @escaping (ChatWidget) -> ChatWidget?, completion: ((Bool) -> Void)?) {}
    public func refresh() {}
    public var containerSize: CGSize { return .zero }
    public init() {}
}
