//
//  NotificaitionBannerHandler.swift
//  LarkFeedBanner
//
//  Created by mochangxing on 2021/3/18.
//

import UIKit
import Foundation
import UGBanner

final class NotificaitionBannerHandler: BannerHandler {
    static var bannerName: String = "NotificationAuthority"
    // 处理Banner点击事件
    func handleBannerClick(bannerView: UIView, url: String) -> Bool {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return false }
        UIApplication.shared.open(url,
                                  options: [:],
                                  completionHandler: nil)
        return true
    }

    func handleBannerClosed(bannerView: UIView) -> Bool {
        return false
    }
}
