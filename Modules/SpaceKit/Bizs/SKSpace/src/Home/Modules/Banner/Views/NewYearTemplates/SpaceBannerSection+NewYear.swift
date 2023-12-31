//
//  SpaceBannerSection+NewYear.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/14.
//

import Foundation
import SKCommon
import SKFoundation

extension SpaceBannerSection {
 
    func clickNewYearAction(needReport: Bool = true) {
        if needReport {
            tracker.reportBannerClick(action: .openOther)
        }
        let vc = TemplateCenterViewController(initialType: .gallery,
                                              templateCategory: TemplateCategory.SpecialCategoryId.newYear.rawValue,
                                              mountLocation: .default,
                                              source: .fromActivityBanner) // 指定 gallery
        vc.trackParamter = DocsCreateDirectorV2.TrackParameters(source: .recent,
                                                                module: .home(.recent),
                                                                ccmOpenSource: .unknow)
        actionInput.accept(.presentOrPush(viewController: vc, popoverConfiguration: { (vc) in
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        }))
    }
}
