//
//  LarkBannerFactory.swift
//  LarkBanner
//
//  Created by mochangxing on 2020/5/19.
//

import UIKit
import Foundation
import RustPB
import LKCommonsTracker
import Homeric

public final class LarkBannerViewFactory {

    public static func createBannerView(bannerData: LarkBannerData, bannerWidth: CGFloat) -> (LarkBaseBannerView, CGFloat)? {
        switch bannerData.bannerType {
        case .normal:
            let bannerView = LarkDynamicNormalBannerView(bannerData: bannerData, bannerWidth: bannerWidth)
            return (bannerView, bannerView.getContentSize().height)
        case .template:
            let bannerView = LarkTemplateBannerView(bannerData: bannerData, bannerWidth: bannerWidth)
            return (bannerView, bannerView.getContentSize().height)
        // TODO: @hujinzang 关注下新增的custom
        case .carousel, .sidebar, .custom:
            Tracker.post(SlardarEvent(name: Homeric.UG_UNKONW_BANNER_TYPE,
                                      metric: ["type": "\(bannerData.bannerType)"],
                                      category: [:],
                                      extra: [:]))
            return nil
        @unknown default:
            Tracker.post(SlardarEvent(name: Homeric.UG_UNKONW_BANNER_TYPE,
                                      metric: ["type": "\(bannerData.bannerType)"],
                                      category: [:],
                                      extra: [:]))
            return nil
        }
    }
}
