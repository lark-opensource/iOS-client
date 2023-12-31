//
//  BannerHandlerRegistry.swift
//  UGBanner
//
//  Created by mochangxing on 2021/3/2.
//

import UIKit
import Foundation

public protocol BannerHandler {
    // 处理Banner关闭事件
    func handleBannerClosed(bannerView: UIView) -> Bool

    // 处理Banner点击事件
    func handleBannerClick(bannerView: UIView, url: String) -> Bool

    // 是否可展示
    func isBannerEnable(bannerData: LarkBannerData) -> Bool
}

public extension BannerHandler {
    func handleBannerClosed(bannerView: UIView, url: String) -> Bool {
        return false
    }

    func isBannerEnable(bannerData: LarkBannerData) -> Bool {
        return true
    }
}

public final class BannerHandlerRegistry {
    var bannerHandlers: [String: BannerHandler] = [:]

    public init() {}

    public func register(bannerName: String, for handler: BannerHandler) {
        bannerHandlers[bannerName] = handler
    }

    public func getBannerHandler(bannerName: String) -> BannerHandler? {
        return bannerHandlers[bannerName]
    }
}
