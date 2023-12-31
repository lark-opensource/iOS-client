//
//  UnifiedInvitationDependency.swift
//  LarkContact
//
//  Created by zhenning on 2020/07/28.
//
import Foundation
import LKCommonsLogging
import Swinject
import LarkTourInterface
import UniverseDesignTheme
import LarkAccountInterface

protocol ContactDataDependency {
    func uploadContactsIntervalMins() -> Int?
    func onboardingUploadContactsMaxNum() -> Int?
    func contactUploadContactsMaxNum() -> Int?
    func memberCountRuleImageURL() -> URL?
}

final class ContactDataDependencyImpl: ContactDataDependency {

    private static let logger = Logger.log(ContactDataDependencyImpl.self, category: "ContactData")

    private let resolver: Resolver
    private let dynamicResourceService: DynamicResourceService?
    private let isOversea: Bool

    init(resolver: Resolver) {
        self.resolver = resolver
        self.dynamicResourceService = try? resolver.resolve(assert: DynamicResourceService.self)
        let passportService = try? resolver.resolve(assert: PassportService.self)
        self.isOversea = passportService?.isOversea ?? false
    }

    func uploadContactsIntervalMins() -> Int? {
        guard let dynamicResourceService = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: dynamicResourceService,
                                         domain: Domain.all_invite_config,
                                            resourceKey: ResourceKey.upload_contacts_cd_mins)
           Self.logger.info("upload_contacts_cd_mins by Settings >>> \(String(describing: value))")
           if let value = value, let intValue = Int(value) {
               return intValue
           }
           let defaultValue: Int = 60
           return defaultValue
       }
    func onboardingUploadContactsMaxNum() -> Int? {
        guard let dynamicResourceService = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: dynamicResourceService,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.onboarding_upload_contacts_max_num)
        Self.logger.info("onboarding_upload_contacts_max_num by Settings >>> \(String(describing: value))")
        if let value = value, let intValue = Int(value) {
            return intValue
        }
        let defaultValue: Int = 200
        return defaultValue
    }
    func contactUploadContactsMaxNum() -> Int? {
        guard let dynamicResourceService = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: dynamicResourceService,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.upload_contacts_max_num)
        Self.logger.info("upload_contacts_max_num by Settings >>> \(String(describing: value))")
        if let value = value, let intValue = Int(value) {
            return intValue
        }
        let defaultValue: Int = 3000
        return defaultValue
    }

    func memberCountRuleImageURL() -> URL? {
        guard let dynamicResourceService = self.dynamicResourceService else { return nil }

        var isDarkMode = false
        if #available(iOS 13.0, *) {
            isDarkMode = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }

        let key: String
        if isOversea {
            if isDarkMode {
                key = ResourceKey.member_count_rule_url_lark_dark
            } else {
                key = ResourceKey.member_count_rule_url_lark_light
            }
        } else {
            if isDarkMode {
                key = ResourceKey.member_count_rule_url_feishu_dark
            } else {
                key = ResourceKey.member_count_rule_url_feishu_light
            }
        }

        if let value = dynamicResourceValue(dynamicResourceService: dynamicResourceService,
                                            domain: Domain.all_invite_config,
                                            resourceKey: key) {
            Self.logger.info("member_count_rule_url by Settings >>> \(String(describing: value))")
            return URL(string: value)
        }

        return nil
    }
}

func dynamicResourceValue(dynamicResourceService: DynamicResourceService, domain: String, resourceKey: String) -> String? {
    let resource = dynamicResourceService.dynamicResource(
        for: Config.invite_config_data,
        domain: domain)?[resourceKey]
    let localizedValue = resource?.localizedValue
    // 如果对应语种下的 tcc 动态文案没有配置，则默认使用本地的该语种静态文案
    if let resource = resource, case ResourceTypeKey.text = resource.type {
        return localizedValue
    }
    // 其他资源暂使用英文作为兜底内容
    return localizedValue ?? resource?.value["en_US"]
}

// MARK: - Dynamic Resources
enum Config {
    static let invite_config_data: String = "guide_config_data"
}

enum Domain {
    static let all_invite_config: String = "all_invite_config"
    static let all_award_config: String = "all_award_config"
}

enum ResourceKey {
    static let add_member_link_guide_text: String = "Lark_Invitation_AddMembersAdminGuideLink"
    static let add_member_qr_guide_text: String = "Lark_Invitation_AddMembersAdminGuideQRCode"
    static let add_member_team_code_guide_text: String = "Lark_Invitation_AddMembersAdminGuideTeamCode"
    static let invite_help_url: String = "invite_help_url"
    static let invite_b2b_help_url: String = "invite_b2b_help_url"
    static let invite_b2b_type_help_url: String = "invite_b2b_type_help_url"
    static let team_code_usage_url: String = "team_code_help_url"
    static let member_undirect_invite_tip_import_lark = "Lark_Invitation_AddMembersQCodeDescriptionLark"
    static let member_undirect_invite_tip_import_feishu = "Lark_Invitation_AddMembersQCodeDescriptionFeishu"
    static let external_undirect_invite_import_tip_lark = "Lark_UserGrowth_InvitePeopleContactsQRCodeTipLark"
    static let external_undirect_invite_import_tip_feishu = "Lark_UserGrowth_InvitePeopleContactsQRCodeTipFeishu"
    static let award_invite_external_url = "award_invite_external_url"
    static let award_invite_member_url = "award_invite_member_url"
    static let team_code_paste_panel_content_feishu = "Lark_Invitation_TeamCodeShareContentFeishu"
    static let team_code_paste_panel_content_lark = "Lark_Invitation_TeamCodeShareContentLark"
    static let team_code_paste_panel_button_text = "Lark_Invitation_TeamCodeShareButton"
    static let team_code_help_gif = "team_code_help_gif"
    static let team_code_paste_panel_copy_content_feishu = "Lark_Invitation_FeishuCopyToken"
    static let team_code_paste_panel_copy_content_lark = "Lark_Invitation_TeamCodeCopyLark"
    static let upload_contacts_max_num = "upload_contacts_max_num"
    static let onboarding_upload_contacts_max_num = "onboarding_upload_contacts_max_num"
    static let upload_contacts_cd_mins = "upload_contacts_cd_mins"
    static let lark_add_enterprise_member_pic = "lark_add_enterprise_member_pic"
    static let feishu_add_enterprise_member_pic = "feishu_add_enterprise_member_pic"
    static let member_count_rule_url_feishu_light = "member_count_rule_url_feishu_light"
    static let member_count_rule_url_feishu_dark = "member_count_rule_url_feishu_dark"
    static let member_count_rule_url_lark_light = "member_count_rule_url_lark_light"
    static let member_count_rule_url_lark_dark = "member_count_rule_url_lark_dark"
}
