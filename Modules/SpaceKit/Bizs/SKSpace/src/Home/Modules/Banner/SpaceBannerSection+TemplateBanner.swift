//
//  SpaceBannerSection+TemplateBanner.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/2.
//

import Foundation
import SKFoundation
import SKCommon
import SKInfra
import SKResource

extension SpaceBannerSection {
    func navigateToMoreBanner() {
        tracker.reportBannerClick(action: .openMoreTemplate)
        let vc = TemplateCenterViewController(source: .fromOnboardingBanner)
        vc.trackParamter = DocsCreateDirectorV2.TrackParameters(source: .fromOnboardingBanner,
                                                                module: .home(.recent),
                                                                ccmOpenSource: .homeBanner)
        actionInput.accept(.presentOrPush(viewController: vc, popoverConfiguration: { (vc) in
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        }))
    }

    private var personalFolderToken: String {
        // 用户的根目录
        return SettingConfig.singleContainerEnable ? "" : MyFolderDataModel.rootToken
    }

    func create(with template: Template, needReport: Bool = true) {
        guard let objToken = template.objToken else {
            return
        }
        if needReport {
            tracker.reportBannerClick(action: .openOther)
        }
        actionInput.accept(.showHUD(.loading))
        let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .fromOnboardingBanner,
                                                                   module: .home(.recent),
                                                                   ccmOpenSource: .homeBanner)
        let director = DocsCreateDirectorV2(type: template.objType, ownerType: ownerType, name: nil, in: personalFolderToken, trackParamters: trackParameters)
        let type: TemplateMainType = template.isCustom ? .custom : .gallery
        var extra = TemplateCenterTracker.formateStatisticsInfoForCreateEvent(source: .fromOnboardingBanner, categoryName: nil, categoryId: nil)
        extra?[SKCreateTracker.sourceKey] = FromSource.fromOnboardingBanner.rawValue
        director.createByTemplate(templateObjToken: objToken,
                                  templateType: type,
                                  templateCenterSource: nil,
                                  statisticsExtra: extra,
                                  completion: { [weak self] (_, vc, _, _, error) in

            self?.actionInput.accept(.hideHUD)

            if let error = error {
                if DocsNetworkError.error(error, equalTo: .createLimited) {
                    return
                } else {
                    self?.actionInput.accept(.showHUD(.failure(BundleI18n.SKResource.Doc_Facade_CreateFailed)))
                    return
                }
            }
            guard let realVC = vc else { return }
            self?.actionInput.accept(.showDetail(viewController: realVC))
        })
        director.makeSelfReferenced()
    }
}
