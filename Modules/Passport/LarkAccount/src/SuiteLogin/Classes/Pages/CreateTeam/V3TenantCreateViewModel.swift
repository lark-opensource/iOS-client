//
//  V3CreateTeamViewModel.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/9/23.
//

import Foundation
import RxSwift
import Homeric
import LarkPerf
import LarkAccountInterface

class V3TenantCreateViewModel: V3ViewModel {

    let createInfo: V3CreateTenantInfo
    let api: JoinTeamAPIProtocol

    init(step: String,
         createInfo: V3CreateTenantInfo,
         api: JoinTeamAPIProtocol,
         context: UniContextProtocol
    ) {
        self.createInfo = createInfo
        self.api = api
        super.init(step: step, stepInfo: createInfo, context: context)
        if createInfo.supportedRegionInput != nil &&
            (createInfo.supportedRegionList == nil || (createInfo.supportedRegionList?.isEmpty ?? true)) {
            V3ViewModel.logger.warn("n_action_tenant_create_has_region_input_but_list_is_empty")
        }
    }

    var tenantName: String = ""
    var userName: String = ""
    var industryInfo: (main: V3Industry, sub: V3Industry?)?
    var scaleInfo: V3StaffScale?
    var selectedRegion: Region?
    var optIn: Bool?

    func create() -> Observable<()> {
        let tenantName: String?
        if self.hasInputContainerForType(type: .tenantName) {
            tenantName = self.tenantName
        } else {
            tenantName = nil
        }
        let userName: String?
        if self.hasInputContainerForType(type: .userName) {
            userName = self.userName
        } else {
            userName = nil
        }
        let sceneInfo = [
            MultiSceneMonitor.Const.scene.rawValue: MultiSceneMonitor.Scene.setTenantName.rawValue,
            MultiSceneMonitor.Const.type.rawValue: "create_team",
            MultiSceneMonitor.Const.result.rawValue: "success"
        ]
        var industryType: String?
        if let industry = self.industryInfo {
            if let sub = industry.sub {
                industryType = "\(industry.main.code)-\(sub.code)"
            } else {
                industryType = industry.main.code
            }
        }

        return api.create(
            UserCreateReqBody(
                isC: false,
                tenantName: tenantName,
                userName: userName,
                tenantType: self.createInfo.tenantType ?? TenantTag.standard.rawValue,
                optIn: self.optIn,
                sceneInfo: sceneInfo,
                staffSize: self.scaleInfo?.code,
                industryType: industryType,
                regionCode: self.selectedRegion?.code,
                flowType: self.createInfo.flowType,
                usePackageDomain: self.createInfo.usePackageDomain ?? false,
                context: context,
                trustedMailIn: self.showTrustedMail
            ), serverInfo: self.createInfo)
            .post(additionalInfo, vcHandler: nil, context: context)
    }

    func trackNextClick() {
        SuiteLoginTracker.track(Homeric.REGISTER_CREATE_TEAM_CLICK_NEXT,
                               params: [TrackConst.path: trackPath, TrackConst.isPersonalUse: TrackConst.no])
        SuiteLoginTracker.track(Homeric.TENANT_CREATE_CLICK_NEXT,
                               params: [TrackConst.path: trackPath, TrackConst.isPersonalUse: TrackConst.no])
        let params = SuiteLoginTracker.makeCommonClickParams(flowType: flowType, click: "next", target: TrackConst.passportUserInfoSettingView)
        SuiteLoginTracker.track(Homeric.PASSPORT_TEAM_INFO_SETTING_CLICK, params: params)
    }
}

extension V3TenantCreateViewModel {
    var title: String {
        return createInfo.title ?? I18N.Lark_Login_V3_CreateTeamTitle
    }

    var subtitle: String {
        return createInfo.subTitle ?? I18N.Lark_Login_V3_createteamsubtitle
    }

    var img: String {
        return createInfo.img ?? ""
    }

    var nextButtonText: String {
        return createInfo.nextButton?.text ?? ""
    }

    var showOptIn: Bool {
        if let needOptIn = createInfo.needOptIn {
            return needOptIn
        } else {
            return false
        }
    }

    var optInText: NSAttributedString {
        let attributedString = NSMutableAttributedString.tip(
            str: createInfo.optInText ?? "",
            color: UIColor.ud.textPlaceholder,
            font: UIFont.systemFont(ofSize: 12.0),
            aligment: .left
        )
        return attributedString
    }

    var optInDefaultValue: Bool {
        return createInfo.optIn ?? false
    }

    var pageName: String {
        return Homeric.REGISTER_SUCCESS_ENTER_CREATE_TEAM
    }

    var placeholderName: String? {
        if let name = createInfo.name {
            V3ViewModel.logger.info("use server name placeholder length: \(name.count)")
            return name
        }
        if let name = service.userName {
            V3ViewModel.logger.info("use biz inject name placeholder length: \(name.count)")
            return name
        }
        return createInfo.name
    }

    func trackViewAppear() {
        SuiteLoginTracker.track(pageName, params: [TrackConst.path: trackPath])
        let params = SuiteLoginTracker.makeCommonViewParams(flowType: flowType)
        SuiteLoginTracker.track(Homeric.PASSPORT_TEAM_INFO_SETTING_VIEW, params: params)
    }
}

extension V3TenantCreateViewModel: V3SetUpTeamProtocol {
    var showTrustedMail: Bool? {
        return createInfo.showTrustedMail
    }

    var trustedMailTitle: String? {
        return createInfo.trustedMailTitle
    }

    var trustedMailHover: String? {
        return createInfo.trustedMailHover
    }

    var flowType: String {
        return createInfo.flowType ?? ""
    }

    var inputContainerInfoList: [V3InputContainerInfo] {
        createInfo.inputContainerInfoList
    }

    var industryTypeList: [V3Industry]? {
        createInfo.industryTypeList
    }

    var staffSizeList: [V3StaffScale]? {
        createInfo.staffSizeList
    }
    
    var supportedRegionList: [Region]? {
        createInfo.supportedRegionList
    }
    
    var topRegionList: [Region]? {
        createInfo.topRegionList
    }
    
    var currentRegion: String? {
        createInfo.currentRegion
    }
    
    var beforeSelectRegionText: String? {
        createInfo.beforeSelectRegionText
    }
    
    var afterSelectRegionText: String? {
        createInfo.afterSelectRegionText
    }

    var defaultTenantName: String? { nil }

    func hasInputContainerForType(type: V3InputContainerType) -> Bool {
        return self.inputContainerInfoFor(type: type) != nil
    }

    func inputContainerInfoFor(type: V3InputContainerType) -> V3InputContainerInfo? {
        for item in createInfo.inputContainerInfoList {
            if item.type == type {
                return item
            }
        }
        return nil
    }

    func isLastInput(inputContainerInfo: V3InputContainerInfo) -> Bool {
        guard let last = createInfo.inputContainerInfoList.last else {
            return false
        }
        return last.type == inputContainerInfo.type
    }
    
    func hasRegionInput() -> Bool {
        return createInfo.supportedRegionInput != nil &&
        createInfo.supportedRegionList != nil &&
        !(createInfo.supportedRegionList?.isEmpty ?? true)
    }

    func shouldShowTrustMailLabel() -> Bool {
        if let shouldShow = showTrustedMail {
            return shouldShow
        } else {
            return false
        }
    }

    func getTrustedMailTips() -> NSAttributedString {
        guard let trustedMailTitle = self.trustedMailTitle else {
            return NSAttributedString(string: "")
        }
        var attributedString = NSMutableAttributedString(attributedString: attributedString(for: trustedMailTitle,
                                                                                            UIColor.ud.textCaption,
                                                                                            UIFont.systemFont(ofSize: 14.0, weight: .regular)))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.string.count ))
        return attributedString

    }

    func getLearnMoreTips() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let suffixLink = NSAttributedString.link(
            str: I18N.Lark_Passport_ApprovedEmailJoinDirectly_DisplayedMessage_LearnMoreButton,
            url: Link.trustedMailHoverURL,
            color: UIColor.ud.textLinkHover,
            font: UIFont.systemFont(ofSize: 14.0)
        )
        return suffixLink
    }

    func getTurstedMailHover() -> NSAttributedString {
        guard let trustedMailHover = self.trustedMailHover else {
            return NSAttributedString(string: "")
        }
        let attributedString = NSMutableAttributedString(attributedString: attributedString(for: trustedMailHover,
                                                                                            UIColor.ud.textCaption,
                                                                                            UIFont.systemFont(ofSize: 14.0, weight: .regular)))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.string.count ))
        return attributedString
    }

}

extension Link {
    static let trustedMailHoverURL = URL(string: "//trustedMailHover")!
}


