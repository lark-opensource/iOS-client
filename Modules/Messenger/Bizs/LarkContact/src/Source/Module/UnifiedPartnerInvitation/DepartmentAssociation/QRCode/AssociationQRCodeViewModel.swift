//
//  AssociationQRCodeViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/3/22.
//

import Foundation
import RxSwift
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkMessengerInterface

struct AssociationInviteInfo {
    let meta: CollaborationInviteInfo
    let expireDateDesc: String
}

final class AssociationQRCodeViewModel: UserResolverWrapper {
    private static let logger = Logger.log(
        AssociationQRCodeViewModel.self,
        category: "LarkContact.AssociationQRCodeViewModel"
    )
    private static let linkIsForeverValidFlag: Int64 = -1  // silver bullet..
    var userResolver: LarkContainer.UserResolver
    @ScopedProvider private var tenantAPI: TenantAPI?
    @ScopedProvider private var inviteStorageService: InviteStorageService?

    /// 是否是海外租户，用于关联组织邀请二维码中提示文案的判断
    let isOversea: Bool
    let source: AssociationInviteSource

    var inviteInfo: AssociationInviteInfo?
    var isAdmin: Bool {
        return inviteStorageService?.getInviteInfo(key: InviteStorage.isAdministratorKey) ?? false
    }
    let contactType: AssociationContactType

    var helpURL: URL? {
        var url: URL?
        if let dependency = try? resolver.resolve(assert: UnifiedInvitationDependency.self),
           let urlStr = dependency.inviteB2bHelpUrl() {
            url = URL(string: urlStr)
        }
        return url
    }

    init(source: AssociationInviteSource, isOversea: Bool, resolver: UserResolver, contactType: AssociationContactType) {
        self.source = source
        self.isOversea = isOversea
        self.contactType = contactType
        self.userResolver = resolver
    }

    func fetchCollaborationInviteInfo(needRefresh: Bool) -> Observable<AssociationInviteInfo>? {
        guard let tenantAPI = self.tenantAPI else { return nil }
        return tenantAPI.fetchCollaborationInviteQrCode(needRefresh: needRefresh, contactType: contactType.rawValue)
            .do { (_) in
                Self.logger.info("fetchCollaborationInviteInfo success")
            } onError: { (error) in
                guard let apiError = error.underlyingError as? APIError else { return }
                Self.logger.error("fetchCollaborationInviteInfo failed, " + apiError.localizedDescription)
            }
            .map({ [weak self] (resp) -> AssociationInviteInfo in
                var expireDateDesc = ""
                if resp.expiredTime == AssociationQRCodeViewModel.linkIsForeverValidFlag {
                    expireDateDesc = BundleI18n.LarkContact.Lark_Invitation_AddMembersPermanentLinkQRCode
                } else {
                    let date = NSDate(timeIntervalSince1970: TimeInterval(resp.expiredTime))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    expireDateDesc = formatter.string(from: date as Date)
                }
                let info = AssociationInviteInfo(
                    meta: resp,
                    expireDateDesc: expireDateDesc
                )
                self?.inviteInfo = info
                return info
            })
            .observeOn(MainScheduler.instance)
    }
}
