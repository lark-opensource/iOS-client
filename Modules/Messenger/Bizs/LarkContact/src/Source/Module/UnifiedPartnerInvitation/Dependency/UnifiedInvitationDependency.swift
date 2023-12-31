//
//  UnifiedInvitationDependency.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/20.
//

import UIKit
import Foundation
import LKCommonsLogging
import Swinject
import LarkTourInterface
import LarkAppConfig
import EENavigator
import LarkAccountInterface

public typealias UnifiedInvitationDependency = MemberInviteRouterDependency & InviteDynamicResourceDependency

public protocol MemberInviteRouterDependency {
    func jumpToGroupNameSettingPage(baseVc: UIViewController, nextHandler: @escaping (Bool) -> Void)
}

public protocol InviteDynamicResourceDependency {
    func memberInviteNoDirectionalGuideTeamCodeText() -> String?
    func unifiedInvitationHelpCenterURL() -> String?
    func teamCodeUsageHelpCenterURL() -> String?
    func memberInviteNoDirectionalImportTipText() -> String?
    func externalInviteNoDirectionalImportTipText() -> String?
    func teamCodePastePanelContent() -> String?
    func teamCodePastePanelButtonText() -> String?
    func teamCodePastePanelCopyContent() -> String?
    func addEnterpriseMemberPic() -> String?
    func inviteB2bHelpUrl() -> String?
    func inviteB2bTypeHelpUrl() -> String?

}

final class UnifiedInvitationDependencyImpl {
    static private let logger = Logger.log(UnifiedInvitationDependencyImpl.self, category: "Contact.UnifiedInvitationDependencyImpl")

    private let resolver: Resolver
    private let dynamicResourceService: DynamicResourceService?

    private let isOversea: Bool

    init(resolver: Resolver) {
        self.resolver = resolver
        self.dynamicResourceService = try? resolver.resolve(assert: DynamicResourceService.self)
        let passportService = try? resolver.resolve(assert: PassportService.self)
        let isOversea = passportService?.isOversea ?? false
        self.isOversea = isOversea
    }
}

extension UnifiedInvitationDependencyImpl: MemberInviteRouterDependency {
    func jumpToGroupNameSettingPage(baseVc: UIViewController, nextHandler: @escaping (Bool) -> Void) {
//        var body = EditTeamBody(from: .update_dialog)
//        body.nextHandler = nextHandler
//        navigator.push(body: body, from: baseVc)
    }
}

extension UnifiedInvitationDependencyImpl: InviteDynamicResourceDependency {
    func memberInviteNoDirectionalGuideTeamCodeText() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.add_member_team_code_guide_text)
        Self.logger.info("NoDirectionalGuideTeamCodeText by Settings >>> \(String(describing: value))")
          return value
    }

    func unifiedInvitationHelpCenterURL() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.invite_help_url)
        Self.logger.info("invite_help_url by Settings >>> \(String(describing: value))")
        return value
    }

    func inviteB2bHelpUrl() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.invite_b2b_help_url)
        Self.logger.info("invite_b2b_help_url by Settings >>> \(String(describing: value))")
        return value
    }

    func inviteB2bTypeHelpUrl() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.invite_b2b_type_help_url)
        Self.logger.info("invite_b2b_type_help_url by Settings >>> \(String(describing: value))")
        return value
    }

    func teamCodeUsageHelpCenterURL() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.team_code_usage_url)
        Self.logger.info("team_code_help_url by Settings >>> \(String(describing: value))")
        return value
    }

    func memberInviteNoDirectionalImportTipText() -> String? {
        if isOversea {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.member_undirect_invite_tip_import_lark)
            Self.logger.info("memberInviteNoDirectionalImportTipText by Settings >>> \(String(describing: value))")
            return value
        } else {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.member_undirect_invite_tip_import_feishu)
            Self.logger.info("memberInviteNoDirectionalImportTipText by Settings >>> \(String(describing: value))")
            return value
        }
    }

    func externalInviteNoDirectionalImportTipText() -> String? {
        if isOversea {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.external_undirect_invite_import_tip_lark)
            Self.logger.info("externalInviteNoDirectionalImportTipText by Settings >>> \(String(describing: value))")
            return value
        } else {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.external_undirect_invite_import_tip_feishu)
            Self.logger.info("externalInviteNoDirectionalImportTipText by Settings >>> \(String(describing: value))")
            return value
        }
    }

    func teamCodePastePanelContent() -> String? {
        if isOversea {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.team_code_paste_panel_content_lark)
            Self.logger.info("teamCodePastePanelContent by Settings >>> \(String(describing: value))")
            return value
        } else {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.team_code_paste_panel_content_feishu)
            Self.logger.info("teamCodePastePanelContent by Settings >>> \(String(describing: value))")
            return value
        }
    }

    func teamCodePastePanelButtonText() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.team_code_paste_panel_button_text)
        Self.logger.info("teamCodePastePanelButtonText by Settings >>> \(String(describing: value))")
        return value
    }

    func teamCodeGuideGifURL() -> String? {
        guard let service = self.dynamicResourceService else { return nil }
        let value = dynamicResourceValue(dynamicResourceService: service,
                                         domain: Domain.all_invite_config,
                                         resourceKey: ResourceKey.team_code_help_gif)
        if let urlStr = value {
            Self.logger.info("teamCodeGuideGifURL by Settings >>> \(String(describing: urlStr))")
            return urlStr
        }
        return nil
    }

    func teamCodePastePanelCopyContent() -> String? {
        if isOversea {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.team_code_paste_panel_copy_content_lark)
            Self.logger.info("teamCodePastePanelCopyContent by Settings >>> \(String(describing: value))")
            return value
        } else {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.team_code_paste_panel_copy_content_feishu)
            Self.logger.info("teamCodePastePanelCopyContent by Settings >>> \(String(describing: value))")
            return value
        }
    }

    func addEnterpriseMemberPic() -> String? {
        if !isOversea {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.feishu_add_enterprise_member_pic)
            Self.logger.info("add_enterprise_member_pic by Settings >>> \(String(describing: value))")
            return value
        } else {
            guard let service = self.dynamicResourceService else { return nil }
            let value = dynamicResourceValue(dynamicResourceService: service,
                                             domain: Domain.all_invite_config,
                                             resourceKey: ResourceKey.lark_add_enterprise_member_pic)
            Self.logger.info("add_enterprise_member_pic by Settings >>> \(String(describing: value))")
            return value
        }
    }
}
