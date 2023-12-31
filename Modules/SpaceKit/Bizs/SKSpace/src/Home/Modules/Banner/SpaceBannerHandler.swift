//
//  SpaceBannerHandler.swift
//  SKECM
//
//  Created by bytedance on 2021/1/18.
//

import Foundation
import UGBanner
import SKFoundation
import SKCommon
import SwiftyJSON
import SKUIKit
import SpaceInterface
enum LarkBannerHelper {
    enum EventPath: String {
        // 完整url举例：lark://client/banner/ccm_show_template_category_in_center?categeryID=xxx&categeryName=xxx
        case singleTemplateClick = "/banner/ccm_create_doc_from_template" // 单品和套件共用这个
        case templateCategoryClick = "/banner/ccm_show_template_category_in_center"
        case newYearTemplateClick = "/banner/ccm_show_new_year_template_list"
        case newerGuideClick = "/banner/ccm/spaceHome/newUserNavigation"
        case olderGuideClick = "/banner/ccm/spaceHome/oldUserNavigation"
    }
    
    static func isTargetEvent(for urlStr: String, event: EventPath) -> (Bool, [String: String]) {
        
        if let newStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
        let url = URL(string: newStr),
            event.rawValue == url.path {
            return (true, url.queryParameters)
        }
        return (false, [:])
    }
}

protocol SpaceBannerHandlerDelegate: AnyObject {
    func handleBannerClose(bannerView: UIView, bannerKey: SpaceBannerHandler.BannerKey) -> Bool
    func handleBannerClick(bannerView: UIView, bannerKey: SpaceBannerHandler.BannerKey, url: String) -> Bool
}

class SpaceBannerHandler {

    enum BannerKey: String {
        /// 单个模板推荐的banner，单品
        case singleProductTemplRecommendationV1 = "SingleProductTemplRecommendationV1" // 单品停止维护了，这个给单品用的，可以不管了
        
        /// 单个模板推荐的banner，套件
        case mobileTemplRecommendationV1 = "MobileTemplRecommendationV1"
        
        /// 一个大类模板banner
        case singleProductTemplRecommendationV3 = "SingleProductTemplRecommendationV3" // 单品停止维护了，这个给单品用的，可以不管了
        
        /// 首页新手引导banner
        case newUserNavigation = "NewUserNavigation" // 这个被下掉了的
        
        /// 老用户引导banner
        case oldUserNavigation = "OldUserNavigation"
        
        /// 新年活动banner
        case newYearTpl = "NewYearTpl" // 单品停止维护了，这个给单品用的，可以不管了
    }
    
    let bannerKey: BannerKey
    private weak var delegate: SpaceBannerHandlerDelegate?
    init(bannerKey: BannerKey, delegate: SpaceBannerHandlerDelegate) {
        self.bannerKey = bannerKey
        self.delegate = delegate
    }

    static func getBannerKeys() -> [SpaceBannerHandler.BannerKey] {
        let singleTemplateKey: SpaceBannerHandler.BannerKey = DocsSDK.isInLarkDocsApp ? .singleProductTemplRecommendationV1 : .mobileTemplRecommendationV1

        let bannerKeys: [SpaceBannerHandler.BannerKey] = [singleTemplateKey,
                                                          .mobileTemplRecommendationV1,
                                                          .singleProductTemplRecommendationV3,
                                                          .newUserNavigation,
                                                          .oldUserNavigation,
                                                          .newYearTpl]
        return bannerKeys
    }
}

// UGBanner点击回调
extension SpaceBannerHandler: BannerHandler {
    // 处理Banner关闭事件
    public func handleBannerClosed(bannerView: UIView) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.handleBannerClose(bannerView: bannerView, bannerKey: bannerKey)
    }

    // 处理Banner点击事件
    public func handleBannerClick(bannerView: UIView, url: String) -> Bool {
        // 根据需要是否需要出来click事件
        // 返回false 则由LarkBanner 通过Navigator路由到对应页面
        // 返回true 则由业务方自己处理
        guard let delegate = self.delegate else {
            spaceAssertionFailure("SpaceBannerHandlerDelegate can't be nil")
            return false
        }
        return delegate.handleBannerClick(bannerView: bannerView, bannerKey: bannerKey, url: url)
    }

}
