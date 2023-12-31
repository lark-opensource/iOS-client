//
//  ExternalInvitationIndexViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/9/23.
//

import Foundation
import Swinject
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import RxSwift
import RxCocoa
import LarkModel
import LKMetric
import LKCommonsLogging
import LarkReleaseConfig
import LarkContainer
import LarkContactComponent
import LarkSetting

protocol DataSourceBindable {
    func bindWithModel(model: UserProfile, tenantNameService: LarkTenantNameService, fgService: FeatureGatingService)
}

final class ExternalInvitationIndexViewModel: ExternalSplitBaseViewModel {
    let scenes: ExternalContactsInvitationScenes
    @ScopedInjectedLazy var router: ExternalContactsInvitationRouter?
    @ScopedInjectedLazy var presenterRouter: ExternalContactImportRouter?
    @ScopedInjectedLazy private var dependency: UnifiedInvitationDependency?
    let isOversea: Bool
    let isStandardBUser: Bool
    let addMeSettingPush: Observable<PushWayToAddMeSettingMessage>
    private static let logger = Logger.log(ExternalInvitationIndexViewModel.self, category: "LarkContact.ExternalInvitationIndexViewModel")

    init(scenes: ExternalContactsInvitationScenes,
         fromEntrance: ExternalInviteSourceEntrance,
         isOversea: Bool,
         addMeSettingPush: Observable<PushWayToAddMeSettingMessage>,
         isStandardBUser: Bool,
         resolver: UserResolver) {
        self.scenes = scenes
        self.isOversea = isOversea
        self.addMeSettingPush = addMeSettingPush
        self.isStandardBUser = isStandardBUser
        super.init(fromEntrance: fromEntrance, resolver: resolver)
    }

    func fetchInviteContextFromLocal() -> Observable<ExternalInviteContext> {
        return Observable.zip(
            fetchDisplayGuideFlagObservable(),
            fetchInviteLinkFromLocal()
        ).flatMap { (context) -> Observable<ExternalInviteContext> in
            return .just(
                ExternalInviteContext(
                    needDisplayGuide: context.0,
                    inviteInfo: context.1
                )
            )
        }.do { [weak self] (context) in
            guard let `self` = self, .externalInvite == self.scenes else { return }
            let canShareLink = context.inviteInfo.externalExtraInfo?.canShareLink ?? true
            Tracer.trackInvitePeopleExternalView(
                status: canShareLink ? 0 : 1,
                source: self.fromEntrance.rawValue
            )
        }.observeOn(MainScheduler.instance)
    }

    func fetchInviteContextFromServer() -> Observable<ExternalInviteContext> {
        return Observable.zip(
            fetchDisplayGuideFlagObservable(),
            fetchInviteLinkFromServer()
        ).flatMap { (context) -> Observable<ExternalInviteContext> in
            return .just(
                ExternalInviteContext(
                    needDisplayGuide: context.0,
                    inviteInfo: context.1
                )
            )
        }.do { [weak self] (context) in
            guard let `self` = self, .externalInvite == self.scenes else { return }
            let canShareLink = context.inviteInfo.externalExtraInfo?.canShareLink ?? true
            Tracer.trackInvitePeopleExternalView(
                status: canShareLink ? 0 : 1,
                source: self.fromEntrance.rawValue
            )
        }.observeOn(MainScheduler.instance)
    }

    func fetchDisplayGuideFlagObservable() -> Observable<Bool> {
        switch scenes {
        case .externalInvite:
            return fetchDisplayGuideFlag().catchErrorJustReturn(false)
        case .myQRCode:
            return .just(false)
        }
    }

    func title() -> String {
        switch scenes {
        case .externalInvite:
            return isStandardBUser ?
                BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB :
                BundleI18n.LarkContact.Lark_NewContacts_AddContactsb
        case .myQRCode:
            return BundleI18n.LarkContact.Lark_NewContacts_AddExternalContacts_MyQRCodePage_title
        }
    }

    func tableSectionCount() -> Int {
        switch scenes {
        case .externalInvite:
            return sectionCount
        case .myQRCode:
            return 0
        }
    }

    func tableRowsForSection(section: Int = 0) -> Int {
        switch scenes {
        case .externalInvite:
            return rowCountInSection[section]
        case .myQRCode:
            return 0
        }
    }
}
