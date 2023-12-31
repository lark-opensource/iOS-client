//
//  ExternalContactSplitViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/12/30.
//

import Foundation
import LarkFoundation
import LarkContainer
import LarkMessengerInterface
import RxSwift

final class ExternalContactSplitViewModel: ExternalSplitBaseViewModel {
    @ScopedInjectedLazy var router: ExternalContactSplitRouter?
    @ScopedInjectedLazy var presenterRouter: ExternalContactImportRouter?
    let isOversea: Bool
    private let isStandardBUser: Bool

    init(
        fromEntrance: ExternalInviteSourceEntrance,
        isOversea: Bool,
        isStandardBUser: Bool,
        resolver: UserResolver
    ) {
        self.isOversea = isOversea
        self.isStandardBUser = isStandardBUser
        super.init(fromEntrance: fromEntrance, resolver: resolver)
    }

    func title() -> String {
        return isStandardBUser ?
            BundleI18n.LarkContact.Lark_NewContacts_AddExternalContactsB :
            BundleI18n.LarkContact.Lark_NewContacts_AddContactsb
    }

    func fetchInviteContextFromLocal() -> Observable<ExternalInviteContext> {
        return Observable.zip(
            fetchDisplayGuideFlag().catchErrorJustReturn(false),
            fetchInviteLinkFromLocal()
        ).flatMap { (context) -> Observable<ExternalInviteContext> in
            return .just(
                ExternalInviteContext(
                    needDisplayGuide: context.0,
                    inviteInfo: context.1
                )
            )
        }.do { [weak self] (context) in
            guard let `self` = self else { return }
            let canShareLink = context.inviteInfo.externalExtraInfo?.canShareLink ?? true
            Tracer.trackInvitePeopleExternalView(
                status: canShareLink ? 0 : 1,
                source: self.fromEntrance.rawValue
            )
        }.observeOn(MainScheduler.instance)
    }

    func fetchInviteContextFromServer() -> Observable<ExternalInviteContext> {
        return Observable.zip(
            fetchDisplayGuideFlag().catchErrorJustReturn(false),
            fetchInviteLinkFromServer()
        ).flatMap { (context) -> Observable<ExternalInviteContext> in
            return .just(
                ExternalInviteContext(
                    needDisplayGuide: context.0,
                    inviteInfo: context.1
                )
            )
        }.do { [weak self] (context) in
            guard let `self` = self else { return }
            let canShareLink = context.inviteInfo.externalExtraInfo?.canShareLink ?? true
            Tracer.trackInvitePeopleExternalView(
                status: canShareLink ? 0 : 1,
                source: self.fromEntrance.rawValue
            )
        }.observeOn(MainScheduler.instance)
    }
}
