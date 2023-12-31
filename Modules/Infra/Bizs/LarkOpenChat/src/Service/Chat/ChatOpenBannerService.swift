//
//  ChatOpenBannerService.swift
//  LarkOpenChat
//
//  Created by zc09v on 2022/1/11.
//

import Foundation

public protocol ChatOpenBannerService: AnyObject {
    /// 刷新Banner区域
    func refresh()
    /// 重新加载Banner区域
    func reload()
}

public final class DefaultChatOpenBannerService: ChatOpenBannerService {
    public init() {}
    public func refresh() {}
    public func reload() {}
}
