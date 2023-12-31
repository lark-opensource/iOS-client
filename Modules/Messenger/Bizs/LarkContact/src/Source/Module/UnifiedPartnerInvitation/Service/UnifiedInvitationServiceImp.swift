//
//  UnifiedInvitationServiceImp.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/1/9.
//

import UIKit
import Foundation
import RxSwift
import LarkAccountInterface
import LarkMessengerInterface
import LarkFeatureGating
import EENavigator
import LarkSDKInterface
import UniverseDesignToast
import LKCommonsLogging
import LarkKAFeatureSwitch
import LarkAppConfig
import LarkUIKit
import LarkContainer

final class UnifiedInvitationServiceImp: UnifiedInvitationService {
    private static let logger = Logger.log(UnifiedInvitationServiceImp.self, category: "LarkContact.UnifiedInvitationServiceImp")
    private let userResolver: UserResolver
    private let passportUserService: PassportUserService
    private let inviteStorageService: InviteStorageService
    private let userAPI: UserAPI
    private let contactAPI: ContactAPI
    private let isOversea: Bool
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    init(resolver: UserResolver,
         inviteStorageService: InviteStorageService,
         userAPI: UserAPI,
         contactAPI: ContactAPI,
         isOversea: Bool) throws {
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.inviteStorageService = inviteStorageService
        self.userAPI = userAPI
        self.contactAPI = contactAPI
        self.isOversea = isOversea
    }

    func dynamicMemberInvitePageResource(baseView: UIView?,
                                         sourceScenes: MemberInviteSourceScenes,
                                         departments: [String]) -> Observable<ExternalDependencyBodyResource> {
        InviteMemberApprecibleTrack.inviteMemberPageLoadTimeStart()
        if userResolver.fg.staticFeatureGatingValue(with: "invite.member.channels.page.enable") {
            if userResolver.fg.staticFeatureGatingValue(with: "invite.member.non_admin.non_directional.invite.enable") {
                if isOversea {
                    return .just(.memberLarkSplit(MemberInviteLarkSplitBody(sourceScenes: sourceScenes,
                                                                            departments: departments)))
                } else {
                    return .just(.memberFeishuSplit(MemberInviteSplitBody(sourceScenes: sourceScenes,
                                                                          departments: departments)))
                }
            }
            let userId = currentUserId
            var hud: UDToast?
            if let base = baseView {
                hud = UDToast.showLoading(on: base, disableUserInteraction: true)
            }
            let startTime = CACurrentMediaTime()

            /// 混合license组合管理的ORM改造
            /// https://bytedance.feishu.cn/wiki/wikcn5ztkKLHKp5U2QThtB2fJPg
            var showInviteEntryObservable: Observable<Bool> = userAPI.isAdministrator()
            return showInviteEntryObservable
                .timeout(.seconds(3), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .flatMap({ [weak self] (isAdmin) -> Observable<ExternalDependencyBodyResource> in
                    if isAdmin {
                        if self?.isOversea ?? true {
                            return .just(.memberLarkSplit(MemberInviteLarkSplitBody(sourceScenes: sourceScenes,
                                                                                    departments: departments)))
                        } else {
                            InviteMemberApprecibleTrack.updateInviteMemberPageSDKCostTrack(cost: CACurrentMediaTime() - startTime)
                            return .just(.memberFeishuSplit(MemberInviteSplitBody(sourceScenes: sourceScenes,
                                                                                  departments: departments)))
                        }
                    } else {
                        return .just(.memberDirected(MemberDirectedInviteBody(sourceScenes: sourceScenes,
                                                                              isFromInviteSplitPage: false,
                                                                              departments: departments)))
                    }
                })
                .catchError({ (error) -> Observable<ExternalDependencyBodyResource> in
                    if let apiError = error.underlyingError as? APIError {
                        InviteMemberApprecibleTrack.inviteMemberPageError(errorCode: Int(apiError.code ),
                                                                          errorMessage: apiError.localizedDescription)
                    } else {
                        InviteMemberApprecibleTrack.inviteMemberPageError(errorCode: (error as NSError).code,
                                                                          errorMessage: (error as NSError).localizedDescription)
                    }
                    return .just(.memberDirected(MemberDirectedInviteBody(sourceScenes: sourceScenes,
                                                                          isFromInviteSplitPage: false,
                                                                          departments: departments)))
                })
                .do(onNext: { (_) in
                    hud?.remove()
                },
                onDispose: {
                    hud?.remove()
                })
        } else {
            return .just(.memberDirected(MemberDirectedInviteBody(sourceScenes: sourceScenes,
                                                                  isFromInviteSplitPage: false,
                                                                  departments: departments)))
        }
    }

    func handleInviteEntryRoute(routeHandler: @escaping (InviteEntryType) -> Void) {
        let inviteUnionEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.union.enable")
        let addContactsEnable = userResolver.fg.staticFeatureGatingValue(with: "suite_to_c_enable")

        let enableMemberInvitePermission: Bool = inviteStorageService
            .getInviteInfo(key: InviteStorage.invitationAccessKey)
        let inviteMemberEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.member.enable")
            && enableMemberInvitePermission
        let inviteExternalEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.external.enable")
        let contactOptEnable = userResolver.fg.staticFeatureGatingValue(with: "lark.client.contact.opt.ui")

        if inviteUnionEnable {
            if contactOptEnable {
                if inviteExternalEnable || addContactsEnable {
                    UnifiedInvitationServiceImp.logger.info("invite entry = external")
                    routeHandler(.external)
                } else {
                    UnifiedInvitationServiceImp.logger.info("invite entry = none")
                    routeHandler(.none)
                }
            } else {
                if addContactsEnable {
                    if inviteMemberEnable && inviteExternalEnable {
                        UnifiedInvitationServiceImp.logger.info("invite entry = union")
                        routeHandler(.union)
                    } else if inviteMemberEnable {
                        UnifiedInvitationServiceImp.logger.info("invite entry = member")
                        routeHandler(.member)
                    } else {
                        UnifiedInvitationServiceImp.logger.info("invite entry = external")
                        routeHandler(.external)
                    }
                } else {
                    UnifiedInvitationServiceImp.logger.info("invite entry = none")
                    routeHandler(.none)
                }
            }
        } else {
            UnifiedInvitationServiceImp.logger.info("invite entry = other")
            routeHandler(.none)
        }
    }

    func hasExternalContactInviteEntry() -> Bool {
        let inviteUnionEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.external.enable")
        let inviteExternalEnable = userResolver.fg.staticFeatureGatingValue(with: "invite.external.enable")
        let addContactsEnable = userResolver.fg.staticFeatureGatingValue(with: "suite_to_c_enable")

        return inviteUnionEnable && (inviteExternalEnable || addContactsEnable)
    }
}
