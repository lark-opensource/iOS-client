//
//  MemberInviteAPI.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/26.
//

import UIKit
import Foundation
import LarkSDKInterface
import RxSwift
import RustPB
import LKMetric
import LKCommonsLogging
import LarkAccountInterface
import LarkFoundation
import LarkRustClient
import UniverseDesignToast
import LarkMessengerInterface
import Homeric
import LarkContainer

final class MemberInviteAPI: UserResolverWrapper {
    typealias GetInvitationLinkResponse = RustPB.Contact_V1_GetInvitationLinkResponse
    /// 获取成员邀请信息的错误
    enum WrapError: Error {
        case buzError(displayMsg: String)
        case unknown
    }
    /// 批量添加成员请求的错误
    enum AddMemberError {
        case sendFailed         // => 发送失败，请重试
        case incorrectEmail     // => 请输入正确的邮箱
        case incorrectPhone     // => 请输入正确的手机号码
        case timeout            // => 发送超时，请重试
        case createLinkFailed   // => 生成邀请失败，请重试
        case userAlreadyJoined  // => 用户已存在(加入团队)
        case nameLengthError    // => 姓名长度错误
        case noCompliantName    // => 姓名有合规风险
        case permissionDeny     // => 没有邀请权限
        case unknown            // => 未知错误
    }
    /// 添加成员失败情况下的上下文
    struct AddMemberFailContext {
        let name: String
        let errorType: AddMemberError
        let errorMsg: String
    }
    /// 添加成员结果
    struct AddMemberResult {
        let isSuccess: Bool
        let needApproval: Bool
        let failContexts: [AddMemberFailContext]
    }
    /// 添加成员的邀请方式
    enum InviteWay: String {
        case email
        case phone
    }

    var userResolver: LarkContainer.UserResolver
    private let passportUserService: PassportUserService?
    @ScopedProvider private var chatterAPI: ChatterAPI?
    private let disposeBag = DisposeBag()
    private let monitor = InviteMonitor()
    private static let linkIsForeverValidFlag: Int64 = -1  // silver bullet..
    static private let logger = Logger.log(MemberInviteAPI.self,
                                           category: "LarkContact.MemberInviteAPI")

    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.passportUserService = try? resolver.resolve(assert: PassportUserService.self)
    }
    /// 获取成员邀请信息(链接、shareToken、teamCode等)
    func fetchInviteAggregationInfo(forceRefresh: Bool,
                                    departments: [String]) -> Observable<InviteAggregationInfo> {
        let reqDepartments: [Int64] = departments.compactMap { Int64($0) }
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_GET_INVITE_INFO,
            indentify: String(startTimeInterval),
            reciableEvent: .memberOrientationGetInviteInfo
        )
        guard let chatterAPI = self.chatterAPI else { return .just(InviteAggregationInfo.emptyInviteInfo()) }
        return chatterAPI.fetchInvitationLink(
            forceRefresh: forceRefresh,
            isSameDepartment: nil,
            departments: reqDepartments)
            .do(onNext: { [weak self] (_) in
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_GET_INVITE_INFO,
                    indentify: String(startTimeInterval),
                    category: ["refresh": forceRefresh ? "true" : "false",
                               "succeed": "true"],
                    extra: [:],
                    reciableState: .success,
                    reciableEvent: .memberOrientationGetInviteInfo
                )
            }, onError: { [weak self] (error) in
                guard let apiError = error.underlyingError as? APIError else { return }
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_NONDIRECTIONAL_GET_INVITE_INFO,
                    indentify: String(startTimeInterval),
                    category: ["refresh": forceRefresh ? "true" : "false",
                               "succeed": "false",
                               "error_code": apiError.code],
                    extra: ["error_msg": apiError.serverMessage],
                    reciableState: .failed,
                    reciableEvent: .memberOrientationGetInviteInfo
                )
            })
            .map({ [weak self] (info: GetInvitationLinkResponse) -> InviteAggregationInfo in
                guard let `self` = self,
                        let passportUserService = self.passportUserService  else { return InviteAggregationInfo.emptyInviteInfo() }

                var expireDateDesc = ""
                if info.expiredTimestamp == MemberInviteAPI.linkIsForeverValidFlag {
                    expireDateDesc = BundleI18n.LarkContact.Lark_Invitation_AddMembersPermanentLinkQRCode
                } else {
                    let date = NSDate(timeIntervalSince1970: TimeInterval(info.expiredTimestamp))
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    expireDateDesc = formatter.string(from: date as Date)
                }

                let tenantName = passportUserService.userTenant.localizedTenantName
                let userName = passportUserService.user.localizedName
                let avatarKey = passportUserService.user.avatarKey
                let teamLogoURL = passportUserService.userTenant.iconURL
                let inviteMsg = BundleI18n.LarkContact.Lark_Invitation_AddMembersLinkHint(tenantName, info.invitationURL)
                var teamCode = ""
                if !info.teamCode.isEmpty {
                    var code = info.teamCode
                    MemberInviteAPI.logger.info("fetch teamcode success >>> \(code.md5())")
                    let space: Character = " "
                    code.insert(space, at: code.index(code.startIndex, offsetBy: code.count / 2))
                    teamCode = code
                }
                let memberInviteExtra = MemberInviteExtraInfo(
                    inviteMsg: inviteMsg,
                    urlForLink: info.invitationURL,
                    urlForQRCode: info.invitationQrURL,
                    expireDateDesc: expireDateDesc,
                    teamCode: teamCode,
                    teamLogoURL: teamLogoURL,
                    shareToken: info.shareToken
                )
                let inviteInfo = InviteAggregationInfo(
                    name: userName,
                    tenantName: tenantName,
                    avatarKey: avatarKey,
                    memberExtraInfo: memberInviteExtra
                )
                return inviteInfo
            }).catchError { (error) -> Observable<InviteAggregationInfo> in
                guard let wrappedError = error as? WrappedError,
                    let rcError = wrappedError.metaErrorStack.first(where: { $0 is RCError }) as? RCError
                    else { return .error(WrapError.unknown) }
                if forceRefresh {
                    LKMetric.IN.refreshInviteInfoFailed(errorMsg: wrappedError.localizedDescription)
                } else {
                    LKMetric.IN.getInviteInfoFailed(errorMsg: wrappedError.localizedDescription)
                }
                MemberInviteAPI.logger.info("GetInvitationLinkResponse error >>> \(rcError.localizedDescription)")
                switch rcError {
                case .businessFailure(let buzErrorInfo):
                    return .error(WrapError.buzError(displayMsg: buzErrorInfo.displayMessage))
                default:
                    return .error(WrapError.unknown)
                }
            }.do(onNext: { (inviteInfo) in
                if forceRefresh {
                    MemberInviteAPI.logger.info("refresh member invite link >>> \(inviteInfo.memberExtraInfo?.urlForLink.md5() ?? "")")
                    LKMetric.IN.refreshInviteInfoSuccess()
                } else {
                    MemberInviteAPI.logger.info("fetch member invite link >>> \(inviteInfo.memberExtraInfo?.urlForLink.md5() ?? "")")
                    LKMetric.IN.getInviteInfoSuccess()
                }
        }).observeOn(MainScheduler.instance)
    }

    /// 提交批量成员邀请
    func sendAddMemberInviteRequest(timeout: Int,
                                    inviteInfos: [String],
                                    names: [String],
                                    inviteWay: InviteWay,
                                    departments: [String]) -> Observable<AddMemberResult> {
        // merge search indexing
        var inviteInfoMap: [String: String] = [:]
        if inviteInfos.count == names.count {
            for (index, info) in inviteInfos.enumerated() {
                inviteInfoMap[info] = names[index]
            }
        }

        let reqDepartments: [Int64] = departments.compactMap { Int64($0) }
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_MEMBER_ORIENTATION_INVITE,
            indentify: String(startTimeInterval),
            reciableEvent: .memberOrientationInvite
        )
        guard let chatterAPI = self.chatterAPI else { return .just(AddMemberResult(isSuccess: false, needApproval: false, failContexts: [])) }
        return chatterAPI.commitAdminInvitationList(inviteInfos: inviteInfos,
                                                    names: names,
                                                    isEmail: inviteWay == .email,
                                                    departments: reqDepartments)
            .timeout(.seconds(timeout), scheduler: MainScheduler.instance)
            .do(onNext: { [weak self] (response) in
                // Record Metric Data
                if response.success {
                    let loadCost: Float = Float(Date().timeIntervalSince1970 * 1000 - startTimeInterval)
                    LKMetric.IO.logInviteSuccess(loadCost: Int64(loadCost))
                } else {
                    var infos: [String: Contact_V1_InviteInfo] = [:]
                    switch inviteWay {
                    case .email:
                        infos = response.email
                    case .phone:
                        infos = response.mobile
                    }
                    for (_, value) in infos {
                        LKMetric.IO.logInviteFailed(buzErrorCode: value.statusCode)
                    }
                }
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_ORIENTATION_INVITE,
                    indentify: String(startTimeInterval),
                    category: ["type": inviteWay.rawValue,
                               "succeed": "true"],
                    extra: [:],
                    reciableState: .success,
                    reciableEvent: .memberOrientationInvite
                )
            }, onError: { [weak self] (error) in
                guard let apiError = error.underlyingError as? APIError else { return }
                LKMetric.IO.logInviteFailed(error: apiError)
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_MEMBER_ORIENTATION_INVITE,
                    indentify: String(startTimeInterval),
                    category: ["type": inviteWay.rawValue,
                               "succeed": "false",
                               "error_code": apiError.code],
                    extra: ["error_msg": apiError.serverMessage],
                    reciableState: .failed,
                    reciableEvent: .memberOrientationInvite
                )
            })
            .map { (response) -> AddMemberResult in
                if response.success {
                    return AddMemberResult(isSuccess: true,
                                           needApproval: response.needApproval,
                                           failContexts: [])
                }
                var errorType: AddMemberError = .unknown
                var errorMsg: String = "unknown error"
                /// no authority
                if response.mobile.isEmpty && response.email.isEmpty {
                    var failContexts: [AddMemberFailContext] = []
                    for name in names {
                        failContexts.append(AddMemberFailContext(
                            name: name,
                            errorType: .permissionDeny,
                            errorMsg: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberPermissionDeny))
                    }
                    return AddMemberResult(isSuccess: false,
                                           needApproval: response.needApproval,
                                           failContexts: failContexts)
                }

                var infoMap: [String: Contact_V1_InviteInfo] = [:]
                switch inviteWay {
                case .email:
                    infoMap = response.email
                case .phone:
                    infoMap = response.mobile
                }

                var failContexts: [AddMemberFailContext] = []
                for (key, value) in infoMap {
                    switch value.statusCode {
                    case 20_001_501: errorType = .sendFailed         // => 发送失败，请重试
                    case 20_001_502: errorType = .incorrectEmail     // => 请输入正确的邮箱
                    case 20_001_503: errorType = .timeout            // => 发送超时，请重试
                    case 20_001_504: errorType = .createLinkFailed   // => 生成邀请失败，请重试
                    case 20_001_505: errorType = .incorrectPhone     // => 请输入正确的手机号码
                    case 20_001_506: errorType = .userAlreadyJoined  // => 用户已存在(加入团队)
                    case 20_001_601: errorType = .nameLengthError    // => 姓名长度错误
                    case 20_001_602: errorType = .noCompliantName    // => 姓名有合规风险
                    default: errorType = .unknown
                    }
                    errorMsg = value.statusMessage

                    if let name = inviteInfoMap[key] {
                        let failContext = AddMemberFailContext(name: name,
                                                               errorType: errorType,
                                                               errorMsg: errorMsg)
                        failContexts.append(failContext)
                    }
                }

                return AddMemberResult(isSuccess: false,
                                       needApproval: response.needApproval,
                                       failContexts: failContexts)
            }
    }

    /// 获取cp下是否有已激活用户
    func fetchCpActiveFlags(mobiles: [String], emails: [String]) -> Observable<[String: Bool]> {
        guard let chatterAPI = self.chatterAPI else { return .just([:]) }
        return chatterAPI.fetchActiveFlags(mobiles: mobiles, emails: emails)
            .observeOn(MainScheduler.instance)
            .do { (cp2active) in
                MemberInviteAPI.logger.info("fetchActiveFlags cp2active = \(cp2active)")
            } onError: { (error) in
                MemberInviteAPI.logger.warn("fetchActiveFlags error = \(error.localizedDescription)")
            }
    }

    /// 封装lark内分享转发邀请链接
    func forwardInviteLinkInLark(source: MemberInviteSourceScenes,
                                 departments: [String],
                                 router: ShareRouter,
                                 from: UIViewController,
                                 closeHandler: @escaping () -> Void) {
        Tracer.trackAddMemberLarkInviteClick(source: source)

        let hud = UDToast.showLoading(on: from.view)
        fetchInviteAggregationInfo(forceRefresh: false, departments: departments).subscribe(onNext: { [weak self] (info) in

            hud.remove()

            guard let `self` = self else { return }
            guard let url = info.memberExtraInfo?.urlForLink, !url.isEmpty else {
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_UserGrowth_InviteMemberPermissionDeny, on: from.view)
                return
            }

            router.routeToForwardLarkInviteMsg(
                with: info.memberExtraInfo?.inviteMsg ?? "",
                newTitle: nil,
                from: from) { (userIds, chatIds) in
                    MemberInviteAPI.logger.info("invite user count \(userIds.count) chat count \(chatIds.count)")
                    Tracer.trackAddMemberLarkInviteShareClick(
                        source: source,
                        userCount: userIds.count,
                        groupCount: chatIds.count
                    )
                    AddMemberFeedbackPresenter.presentForLarkInvite(
                        resolver: self.userResolver,
                        source: source,
                        baseVc: from,
                        doneCallBack: closeHandler
                    )
            }
        }, onError: { [weak from] (error) in
            hud.remove()
            if let err = error as? WrapError,
               case .buzError(let displayMsg) = err,
               let view = from?.view {
                UDToast.showFailure(with: displayMsg, on: view)
            }
        }, onDisposed: {
            hud.remove()
        }).disposed(by: disposeBag)
    }
}
