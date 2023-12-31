//
//  ExternalInviteAPI.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/6/17.
//

import UIKit
import Foundation
import RxSwift
import LarkAccountInterface
import LarkSDKInterface
import LKCommonsLogging
import LKMetric
import LarkModel
import Homeric
import AppReciableSDK
import LarkContainer
import RustPB

final class ExternalInviteAPI: UserResolverWrapper {
    @ScopedProvider private var chatApplicationAPI: ChatApplicationAPI?
    private let monitor = InviteMonitor()
    private let disposeBag = DisposeBag()
    static private let logger = Logger.log(
        MemberInviteAPI.self,
        category: "LarkContact.ExternalInviteAPI"
    )
    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService?
    private let chatterManager: ChatterManagerProtocol?
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
        self.chatterManager = try? resolver.resolve(assert: ChatterManagerProtocol.self)
    }

    /// （本地）获取外部联系人邀请信息(inviteLink、shareToken等)
    func fetchInviteAggregationInfoFromLocal() -> Observable<InviteAggregationInfo> {
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_GET_INVITE_INFO,
            indentify: String(startTimeInterval),
            reciableEvent: .externalOrientationGetInviteInfo
        )
        let trackKey = AppReciableTrack.getExternalContactPageTrackKey()
        guard let chatApplicationAPI = self.chatApplicationAPI else { return .just(InviteAggregationInfo.emptyInviteInfo()) }
        return chatApplicationAPI.fetchInviteLinkInfoFromLocal().map({ [weak self] (info: RustPB.Im_V2_GetContactTokenResponse) -> InviteAggregationInfo in
            guard let `self` = self,
                    let passportUserService = self.passportUserService else {
                return InviteAggregationInfo.emptyInviteInfo()
            }
            let tenantName = passportUserService.userTenant.localizedTenantName

            let userName = self.getChatterName()
            let chatterAvatarKey = self.chatterManager?.currentChatter.avatarKey
            let passportAvatarKey = passportUserService.user.avatarKey
            let avatarKey = chatterAvatarKey ?? passportAvatarKey
            let linkInviteData = ExternalInviteData(
                token: info.link.token,
                inviteURL: info.link.inviteURL,
                inviteMsg: info.link.inviteMsg,
                uniqueID: info.link.uniqueID
            )
            let qrcodeInviteData = ExternalInviteData(
                token: info.qrCode.token,
                inviteURL: info.qrCode.inviteURL,
                inviteMsg: info.qrCode.inviteMsg,
                uniqueID: info.qrCode.uniqueID
            )
            let externalInviteExtra = ExternalInviteExtraInfo(
                canShareLink: info.link.canSearchWithToken,
                linkInviteData: linkInviteData,
                qrcodeInviteData: qrcodeInviteData
            )
            let inviteInfo = InviteAggregationInfo(
                name: userName,
                tenantName: tenantName,
                avatarKey: avatarKey,
                externalExtraInfo: externalInviteExtra
            )
            return inviteInfo
        }).do(onNext: { [weak self] (inviteInfo) in
            ExternalInviteAPI.logger.info("fetch external invite link >>> \(inviteInfo.externalExtraInfo?.linkInviteData.inviteURL.md5() ?? "")")
            LKMetric.EN.getInviteInfoSuccess()
            self?.monitor.endEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_GET_INVITE_INFO,
                indentify: String(startTimeInterval),
                category: ["succeed": "true"],
                extra: [:],
                reciableState: .success,
                reciableEvent: .externalOrientationGetInviteInfo
            )
            AppReciableTrack.addExternalContactPageLinkCostTrack()
            AppReciableTrack.addExternalContactPageQRCodeCostTrack()
            AppReciableTrack.addExternalContactPageLoadingTimeEnd(key: trackKey)
        }, onError: { [weak self] (error) in
            LKMetric.EN.getInviteInfoFailed(errorMsg: error.localizedDescription)
            guard let apiError = error.underlyingError as? APIError else { return }
            self?.monitor.endEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_GET_INVITE_INFO,
                indentify: String(startTimeInterval),
                category: ["succeed": "false",
                           "error_code": apiError.code],
                extra: ["error_msg": apiError.serverMessage],
                reciableState: .failed,
                reciableEvent: .externalOrientationGetInviteInfo
            )
            if let apiError = error.underlyingError as? APIError {
                AppReciableTrack.addExternalContactPageError(errorCode: Int(apiError.code),
                                                             errorMessage: apiError.localizedDescription)
            } else {
                AppReciableTrack.addExternalContactPageError(errorCode: (error as NSError).code,
                                                             errorMessage: (error as NSError).localizedDescription)
            }
        }).observeOn(MainScheduler.instance)
    }

    /// （服务端）获取外部联系人邀请信息(inviteLink、shareToken等)
    func fetchInviteAggregationInfoFromServer() -> Observable<InviteAggregationInfo> {
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_GET_INVITE_INFO,
            indentify: String(startTimeInterval),
            reciableEvent: .externalOrientationGetInviteInfo
        )
        let trackKey = AppReciableTrack.getExternalContactPageTrackKey()
        guard let chatApplicationAPI = self.chatApplicationAPI else { return .just(InviteAggregationInfo.emptyInviteInfo()) }
        return chatApplicationAPI.fetchInviteLinkInfoFromServer().map({ [weak self] (info: RustPB.Im_V2_GetContactTokenResponse) -> InviteAggregationInfo in
            guard let `self` = self,
                    let passportUserService = self.passportUserService else {
                return InviteAggregationInfo.emptyInviteInfo()
            }
            let tenantName = passportUserService.userTenant.localizedTenantName

            let userName = self.getChatterName()
            let chatterAvatarKey = self.chatterManager?.currentChatter.avatarKey
            let passportAvatarKey = passportUserService.user.avatarKey
            let avatarKey = chatterAvatarKey ?? passportAvatarKey

            let linkInviteData = ExternalInviteData(
                token: info.link.token,
                inviteURL: info.link.inviteURL,
                inviteMsg: info.link.inviteMsg,
                uniqueID: info.link.uniqueID
            )
            let qrcodeInviteData = ExternalInviteData(
                token: info.qrCode.token,
                inviteURL: info.qrCode.inviteURL,
                inviteMsg: info.qrCode.inviteMsg,
                uniqueID: info.qrCode.uniqueID
            )
            let externalInviteExtra = ExternalInviteExtraInfo(
                canShareLink: info.link.canSearchWithToken,
                linkInviteData: linkInviteData,
                qrcodeInviteData: qrcodeInviteData
            )
            let inviteInfo = InviteAggregationInfo(
                name: userName,
                tenantName: tenantName,
                avatarKey: avatarKey,
                externalExtraInfo: externalInviteExtra
            )
            return inviteInfo
        }).do(onNext: { [weak self] (inviteInfo) in
            ExternalInviteAPI.logger.info("fetch external invite link >>> \(inviteInfo.externalExtraInfo?.linkInviteData.inviteURL.md5() ?? "")")
            LKMetric.EN.getInviteInfoSuccess()
            self?.monitor.endEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_GET_INVITE_INFO,
                indentify: String(startTimeInterval),
                category: ["succeed": "true"],
                extra: [:],
                reciableState: .success,
                reciableEvent: .externalOrientationGetInviteInfo
            )
            AppReciableTrack.addExternalContactPageLinkCostTrack()
            AppReciableTrack.addExternalContactPageQRCodeCostTrack()
            AppReciableTrack.addExternalContactPageLoadingTimeEnd(key: trackKey)
        }, onError: { [weak self] (error) in
            LKMetric.EN.getInviteInfoFailed(errorMsg: error.localizedDescription)
            guard let apiError = error.underlyingError as? APIError else { return }
            ExternalInviteAPI.logger.info("fetch external invite link failure")
            self?.monitor.endEvent(
                name: Homeric.UG_INVITE_EXTERNAL_NONDIRECTIONAL_GET_INVITE_INFO,
                indentify: String(startTimeInterval),
                category: ["succeed": "false",
                           "error_code": apiError.code],
                extra: ["error_msg": apiError.serverMessage],
                reciableState: .failed,
                reciableEvent: .externalOrientationGetInviteInfo
            )
            if let apiError = error.underlyingError as? APIError {
                AppReciableTrack.addExternalContactPageError(errorCode: Int(apiError.code),
                                                             errorMessage: apiError.localizedDescription)
            } else {
                AppReciableTrack.addExternalContactPageError(errorCode: (error as NSError).code,
                                                             errorMessage: (error as NSError).localizedDescription)
            }
        }).observeOn(MainScheduler.instance)
    }

    private func getChatterName() -> String {
        let chatter = self.chatterManager?.currentChatter
        var userName = chatter?.localizedName ?? ""
        if userName.isEmpty {
            userName = passportUserService?.user.localizedName ?? ""
        }
        return userName
    }
}
