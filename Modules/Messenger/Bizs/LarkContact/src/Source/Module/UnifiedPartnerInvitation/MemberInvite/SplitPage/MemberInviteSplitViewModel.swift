//
//  MemberInviteSplitViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/1/1.
//

import UIKit
import Foundation
import LarkUIKit
import LarkFeatureGating
import LarkMessengerInterface
import LarkAccountInterface
import LarkSDKInterface
import RxSwift
import LKCommonsLogging
import LKMetric
import LarkReleaseConfig
import LKCommonsTracker
import LarkContainer

protocol MemberInviteSplitPageRouter: ShareRouter {
    func pushToDirectedInviteController(baseVc: UIViewController,
                                        sourceScenes: MemberInviteSourceScenes,
                                        departments: [String],
                                        rightButtonClickHandler: (() -> Void)?)
    func pushToNonDirectedInviteController(baseVc: UIViewController,
                                           priority: MemberNoDirectionalDisplayPriority,
                                           sourceScenes: MemberInviteSourceScenes,
                                           departments: [String])
    func pushToGroupNameSettingController(baseVc: UIViewController,
                                          nextHandler: @escaping (Bool) -> Void)
    func pushToTeamCodeInviteController(baseVc: UIViewController,
                                        sourceScenes: MemberInviteSourceScenes,
                                        departments: [String])
    func pushToAddressBookImportController(baseVc: UIViewController,
                                           sourceScenes: MemberInviteSourceScenes,
                                           presenter: ContactBatchInvitePresenter)
    func pushToHelpCenterInternal(baseVc: UIViewController)
}

final class MemberInviteSplitViewModel: UserResolverWrapper {
    let sourceScenes: MemberInviteSourceScenes
    let router: MemberInviteSplitPageRouter
    var splitChannels: [[SplitChannel]] = [[]]
    var sectionCount: Int { return _sectionCount }
    var rowCountOfSections: [Int] { return _rowCountOfSections }
    var sectionTitles: [String] = []
    var tenantName: String {
        return passportUserService.userTenant.tenantName
    }
    var userName: String {
        return passportUserService.user.localizedName
    }
    let departments: [String]
    let isOversea: Bool
    let dependency: UnifiedInvitationDependency
    private let memberInviteAPI: MemberInviteAPI
    let batchInvitePresenter: ContactBatchInvitePresenter
    let hasPhoneInvitation: Bool
    let hasEmailInvitation: Bool
    let shouldPresentWechatInviteMsgPastePanel: Bool
    private var _sectionCount: Int = 0
    private var _rowCountOfSections: [Int] = []
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService
    @ScopedProvider private var userGeneralSettings: UserGeneralSettings?

    var currentTenantIsSimpleB: Bool {
        let userType = passportUserService.user.type
        return userType == .undefined || userType == .simple
    }

    private lazy var shouldShowWechatInviteChannel: Bool = {
        return !ReleaseConfig.isLark
    }()

    private lazy var fullDataSource: [[SplitChannel]] = {
        let brandName = isOversea ?
            BundleI18n.LarkContact.Lark_Invitation_BrandNameLark :
            BundleI18n.LarkContact.Lark_Invitation_BrandNameFeishu
        let directInviteTitle: String = {
            if hasEmailInvitation && hasPhoneInvitation {
                return BundleI18n.LarkContact.Lark_Invitation_AddMembersInputPhoneorEmail
            } else if hasEmailInvitation {
                return BundleI18n.LarkContact.Lark_Invitation_AddMembersInputEmail
            } else {
                return BundleI18n.LarkContact.Lark_Invitation_AddMembersInputPhone
            }
        }()

        return [[
            // 微信邀请
            SplitChannel(
                Resources.wechat_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleOne_QuickInvitation_InviteViaWeChat,
                "",
                .wechat
            ),
            // 飞书内邀请
            SplitChannel(
                Resources.feishu_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleOne_QuickInvitation_InviteViaFeishu,
                "",
                .larkInvite
            )
        ],
        [
            // 团队二维码
            SplitChannel(
                Resources.qrcode_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin_TeamQRCode,
                "",
                .nonDirectedQRCode
            ),
            // 团队链接
            SplitChannel(
                Resources.link_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin_TeamLink,
                "",
                .nonDirectedLink
            ),
            // 团队码
            SplitChannel(
                Resources.teamcode_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin_TeamCode,
                "",
                .teamCode
            )
        ],
        [
            // 从通讯录导入
            SplitChannel(
                Resources.addressbook_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleThree_AddMembersDirectly_ImportFromContacts,
                "",
                .addressbookImport
            ),
            // 定向邀请(手机+邮箱)
            SplitChannel(
                Resources.directed_invite_icon,
                BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleThree_AddMembersDirectly_EnterPhone,
                "",
                .directed
            )
        ]]
    }()

    static private let logger = Logger.log(MemberInviteSplitViewModel.self,
                                           category: "LarkContact.MemberInviteSplitViewModel")

    init(sourceScenes: MemberInviteSourceScenes,
         isOversea: Bool,
         router: MemberInviteSplitPageRouter,
         dependency: UnifiedInvitationDependency,
         departments: [String],
         resolver: UserResolver) throws {
        self.sourceScenes = sourceScenes
        self.isOversea = isOversea
        self.router = router
        self.dependency = dependency
        self.departments = departments
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.memberInviteAPI = MemberInviteAPI(resolver: resolver)
        self.batchInvitePresenter = ContactBatchInvitePresenter(
            isOversea: isOversea,
            departments: departments,
            memberInviteAPI: memberInviteAPI,
            sourceScenes: sourceScenes,
            resolver: userResolver
        )
        self.hasEmailInvitation = userResolver.fg.staticFeatureGatingValue(with: "invite.member.email.enable")
        self.hasPhoneInvitation = true
        self.shouldPresentWechatInviteMsgPastePanel =
            !userResolver.fg.staticFeatureGatingValue(with: "invite.member.third.share.wx.enable")

        genSplitChannelsContext()
    }

    func fetchInviteLink() -> Observable<InviteAggregationInfo> {
        return memberInviteAPI.fetchInviteAggregationInfo(forceRefresh: false, departments: departments)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
    }

    func forwordInviteLinkInLark(from: UIViewController,
                                 closeHandler: @escaping () -> Void) {
        memberInviteAPI.forwardInviteLinkInLark(source: sourceScenes,
                                                departments: departments,
                                                router: router,
                                                from: from,
                                                closeHandler: closeHandler)
    }

}

private extension MemberInviteSplitViewModel {
    func genSplitChannelsContext() {
        splitChannels = fullDataSource.compactMap { (section) -> [SplitChannel]? in
            let channels = section.filter { (channel) -> Bool in
                switch channel.channelFlag {
                case .wechat:
                    return shouldShowWechatInviteChannel
                case .nonDirectedQRCode:
                    return userResolver.fg.staticFeatureGatingValue(with: "invite.member.channels.page.qrcode.enable")
                case .nonDirectedLink:
                    return userResolver.fg.staticFeatureGatingValue(with: "invite.member.channels.page.link.enable")
                case .larkInvite:
                    return true
                case .addressbookImport:
                    return true
                case .directed:
                    return hasEmailInvitation || hasPhoneInvitation
                case .teamCode:
                    return true
                case .unknown:
                    return false
                }
            }
            return channels.isEmpty ? nil : channels
        }
        // provide section & row contexts
        var tempSectionTitles: [String] = []
        for channels in splitChannels {
            let channelFlags = channels.map { $0.channelFlag }
            if channelFlags.contains(ChannelFlag.wechat) ||
                channelFlags.contains(ChannelFlag.larkInvite) {
                tempSectionTitles.append(BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleOne_QuickInvitation)
                continue
            }
            if channelFlags.contains(ChannelFlag.nonDirectedQRCode) ||
                channelFlags.contains(ChannelFlag.nonDirectedLink) ||
                channelFlags.contains(ChannelFlag.teamCode) {
                tempSectionTitles.append(BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleTwo_AddMemberstoJoin)
                continue
            }
            if channelFlags.contains(ChannelFlag.addressbookImport) ||
                channelFlags.contains(ChannelFlag.directed) {
                tempSectionTitles.append(BundleI18n.LarkContact.Lark_Invitation_AddMembers_SubtitleThree_AddMembersDirectly)
                continue
            }
        }
        sectionTitles = tempSectionTitles

        _sectionCount = splitChannels.count
        for sub in splitChannels {
            _rowCountOfSections.append(sub.count)
        }
    }
}
