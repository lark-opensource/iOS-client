//
//  SpaceBannerSection+TemplateCategory.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/28.
//

import Foundation
import SKCommon
import SKFoundation

extension SpaceBannerSection {

    typealias Category = TemplateCategoryBannerViewModel.Category

    func navigateToTemplateCenter(needReport: Bool = true) {
        if needReport {
            tracker.reportBannerClick(action: .openMoreTemplate)
        }
        let vc = TemplateCenterViewController(mountLocation: .default, source: .fromOnboardingBanner)
        vc.trackParamter = DocsCreateDirectorV2.TrackParameters(source: .fromOnboardingBanner,
                                                                module: .home(.recent),
                                                                ccmOpenSource: .homeBanner)
        actionInput.accept(.presentOrPush(viewController: vc, popoverConfiguration: { (vc) in
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        }))
    }

    func navigateToTemplateCategory(category: Category, needReport: Bool = true) {
        if needReport {
            tracker.reportBannerClick(action: .open(categoryName: category.name))
        }
        let vc = TemplateCenterViewController(initialType: .gallery,
                                              templateCategory: category.categoryID,
                                              mountLocation: .default,
                                              source: .fromOnboardingBanner)
        vc.trackParamter = DocsCreateDirectorV2.TrackParameters(source: .fromOnboardingBanner,
                                                                module: .home(.recent),
                                                                ccmOpenSource: .homeBanner)
        actionInput.accept(.presentOrPush(viewController: vc, popoverConfiguration: { (vc) in
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        }))
    }
}
