//
//  SpaceBannerTracker.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/24.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource

// public 是因为 onboarding banner 的展示逻辑不在 BannerSection 内，需要交给上层处理
public struct SpaceBannerTracker: SpaceTracker {

    let bizParameter: SpaceBizParameter

    enum OnboardingModule: String {
        static let key = "onboarding_module"
        case newBanner = "home_onboarding_newbanner"
        case oldBanner = "home_onboarding_oldbanner"
    }

    enum BannerType: String {
        static let key = "banner_type"
        case onboarding
        case activity
    }

    // 每个 banner 唯一，需要找 PM 确认
    enum BannerID: String {
        static let key = "banner_id"
        case onboardingNewBanner = "home_onboarding_newbanner"
        case onboardingOldBanner = "home_onboarding_oldbanner"
        case onboardingTemplate = "template_banner_V1"
        case onboardingTemplateCategory = "template_category_banner"
        case newYear2021 = "newyear_2021"
    }

    enum BannerAction {
        static let key = "action"
        /// 点击banner的某个item，尽量不要直接使用，参考 open(categoryName:)、openMoreTemplate 和 openOther
        case open(itemName: String?)
        /// 点击banner的关闭按钮
        case close

        /// 点击模板分类banner的某个category
        static func open(categoryName: String) -> Self {
            .open(itemName: categoryName)
        }

        /// 点击模板banner的更多模板选项
        static var openMoreTemplate: Self { .open(itemName: BundleI18n.SKResource.Doc_List_RecomTemplateMore) }

        /// 默认的open事件，不带额外参数，需要和产品确认是否不上报 item_name 参数
        static let openOther: Self = .open(itemName: nil)
    }

    var module: OnboardingModule?
    var bannerType: BannerType?
    var bannerID: BannerID?

    public func reportShowOnboardingGuide(step: Int) {
        guard let module = module else {
            spaceAssertionFailure("module is nil")
            return
        }
        let params: P = [
            OnboardingModule.key: module.rawValue,
            "step_index": step
        ]
        DocsTracker.log(enumEvent: .showOnboardingGuideMobile, parameters: params)
    }

    func reportBannerClick(action: BannerAction) {
        guard let type = bannerType, let bannerID = bannerID else {
            spaceAssertionFailure("bannerType or bannerID is nil")
            return
        }

        var params: P = [
            BannerType.key: type.rawValue,
            BannerID.key: bannerID.rawValue
        ]
        switch action {
        case .close:
            params[BannerAction.key] = "close"
        case let .open(itemName):
            params[BannerAction.key] = "open"
            if let itemName = itemName {
                params["click_item_name"] = itemName
            }
        }
        DocsTracker.log(enumEvent: .spaceBannerClick, parameters: params)
    }
}
