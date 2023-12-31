//
//  PhoneCallEntry.swift
//  ByteView
//
//  Created by kiri on 2023/6/19.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewUI
import UniverseDesignIcon
import ByteViewTracker

final class PhoneCallUtil {
    @discardableResult
    static func startPhoneCall(_ params: PhoneCallParams, dependency: MeetingDependency, from: UIViewController?,
                               file: String = #fileID, function: String = #function, line: Int = #line,
                               completion: ((Result<Void, Error>) -> Void)? = nil) -> MeetingSession? {
        Logger.phoneCall.info("startPhoneCall, params: \(params), from: \(from)", file: file, function: function, line: line)
        if params.idType == .telephone {
            self.startPersonalCall(params.id)
            Logger.phoneCall.info("startPhoneCall success, personal call", file: file, function: function, line: line)
            completion?(.success(Void()))
            return nil
        }
        let isDirectCall = dependency.setting.enterprisePhoneConfig.callType == .direct
        let trackStartType = params.idType.rawValue
        let matchID =  UUID().uuidString + "_\(params.idType)"
        Self.trackEnterpriseCallStart(matchID: matchID, isDirectCall: isDirectCall, startType: trackStartType)

        if isDirectCall || params.idType == .ipPhone {
            guard var call = params.toEnterpriseCallParams() else {
                Logger.phoneCall.info("startPhoneCall failed, idType \(params.idType) not supported", file: file, function: function, line: line)
                Self.trackEnterpriseCallFailed(matchID: matchID, isDirectCall: isDirectCall, startType: trackStartType, reason: "idType not supported")
                completion?(.failure(VCError.unknown))
                return nil
            }
            call.enterpriseCallMatchID = matchID
            call.enterpriseCallStartType = trackStartType

            let result = MeetingManager.shared.startMeeting(.enterpriseCall(call), dependency: dependency, from: from.map({ RouteFrom($0) }),
                                                            file: file, function: function, line: line)
            switch result {
            case .success(let session):
                Logger.phoneCall.info("startPhoneCall success, isDirect: \(isDirectCall), idType: \(call.idType)", file: file, function: function, line: line)
                completion?(.success(Void()))
                return session
            case .failure(let error):
                Logger.phoneCall.error("startPhoneCall failed, error: \(error)", file: file, function: function, line: line)
                Self.trackEnterpriseCallFailed(matchID: matchID, isDirectCall: isDirectCall, startType: trackStartType, reason: "api error: \(error)")
                completion?(.failure(error))
                return nil
            }
        } else {
            guard let request = params.toRequest() else {
                Logger.phoneCall.info("startPhoneCall failed, idType \(params.idType) not supported", file: file, function: function, line: line)
                Self.trackEnterpriseCallFailed(matchID: matchID, isDirectCall: isDirectCall, startType: trackStartType, reason: "idType not supported")
                completion?(.failure(VCError.unknown))
                return nil
            }
            do {
                try ByteViewApp.shared.preload(account: dependency.account, reason: "startPhoneCall")
            } catch {
                Logger.phoneCall.error("preload failed, \(error)", file: file, function: function, line: line)
                Self.trackEnterpriseCallFailed(matchID: matchID, isDirectCall: isDirectCall, startType: trackStartType, reason: "preload failed: \(error)")
                completion?(.failure(error))
                return nil
            }
            Logger.phoneCall.info("startPhoneCall, requesting Enterprise back2Back", file: file, function: function, line: line)
            dependency.httpClient.getResponse(request) { [weak from] result in
                switch result {
                case .success(let response):
                    let enterprisePhoneID = response.enterprisePhoneID
                    let candidateInfo = response.candidateInfo
                    Logger.phoneCall.info("startPhoneCall success, create enterprise phone: \(enterprisePhoneID), candidateID: \(candidateInfo?.candidateID)", file: file, function: function, line: line)
                    Util.runInMainThread {
                        guard let from = (from ?? VCScene.topMost()) else { return }
                        let vm = EnterpriseCallOutViewModel(dependency: dependency, userName: params.displayName(candidateName: candidateInfo?.candidateName), avatarKey: params.calleeAvatarKey, enterprisePhoneId: enterprisePhoneID, chatId: params.chatId, matchID: matchID, trackType: trackStartType)
                        let vc = EnterpriseCallOutViewController(viewModel: vm)
                        vc.modalPresentationStyle = .overFullScreen
                        from.vc.safePresent(vc, animated: true)
                    }
                    completion?(.success(Void()))
                case .failure(let error):
                    Logger.phoneCall.error("startPhoneCall failed, create enterprise phone error: \(error)", file: file, function: function, line: line)
                    Self.trackEnterpriseCallFailed(matchID: matchID, isDirectCall: isDirectCall, startType: trackStartType, reason: "api error: \(error)")
                    self.handleError(error, params: params, dependency: dependency)
                    completion?(.failure(error))
                }
            }
            return nil
        }
    }

    static func startPersonalCall(_ phoneNumber: String) {
        guard let phoneNumber = phoneNumber.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL(string: "tel://\(phoneNumber)") else { return }
        Util.runInMainThread {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) {
                    Logger.phoneCall.info("startPersonalCall: \(phoneNumber.count) done with result: \($0)")
                }
            } else {
                Logger.phoneCall.info("startPersonalCall failed: \(phoneNumber.count)")
            }
        }
    }

    static func showPhoneCallPicker(_ params: PhoneCallParams, dependency: MeetingDependency, from: UIViewController) {
        guard params.idType.isPhoneNumber else { return }
        let customRowHeight: CGFloat = 64.0
        let tableViewCornerRadius: CGFloat = 8.0
        let isRegular = from.traitCollection.isRegular
        let backgroundColor: UIColor = isRegular ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        let appearance = ActionSheetAppearance(backgroundColor: backgroundColor,
                                               customTextHeight: customRowHeight,
                                               tableViewCornerRadius: tableViewCornerRadius,
                                               contentAlignment: .center)
        let actionSheet = ActionSheetController(appearance: appearance)
        if dependency.setting.isEnterprisePhoneEnabled {
            let title = params.idType == .recruitmentPhone ? I18n.View_G_RecruitmentCall_Hover : I18n.View_MV_OfficePhonePaid
            actionSheet.addAction(SheetAction(title: title,
                                              titleFontConfig: .body,
                                              icon: UDIcon.getIconByKey(.officephoneOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)),
                                              sheetStyle: .iconAndLabel,
                                              handler: { _ in
                startPhoneCall(params, dependency: dependency, from: from)
            }))
        }
        actionSheet.addAction(SheetAction(title: I18n.View_MV_SelfPhoneHere,
                                          titleFontConfig: .body,
                                          icon: UDIcon.getIconByKey(.cellphoneOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)),
                                          sheetStyle: .iconAndLabel,
                                          handler: { _ in
            EnterpriseCallTracks.trackClickPersonalCall()
            startPhoneCall(PhoneCallParams(id: params.id, idType: .telephone), dependency: dependency, from: from)
        }))
        actionSheet.addAction(SheetAction(title: I18n.View_G_CancelButton,
                                          sheetStyle: .cancel,
                                          handler: { [weak actionSheet] _ in
            actionSheet?.dismiss(animated: true, completion: nil)
        }))
        from.presentDynamicModal(actionSheet,
                                 regularConfig: .init(presentationStyle: .formSheet),
                                 compactConfig: .init(presentationStyle: .pan))
    }

    static func handleInviteError(_ error: Error, phoneNumber: String, dependency: MeetingDependency) {
        handleError(error, phoneNumber: phoneNumber, handleUnknown: false, userId: nil, userName: nil, dependency: dependency)
    }

    static func handleError(_ error: Error, params: EnterpriseCallParams, dependency: MeetingDependency) {
        let phoneNumber = params.idType.isPhoneNumber ? params.id : nil
        handleError(error, phoneNumber: phoneNumber, handleUnknown: true, userId: params.calleeId, userName: params.calleeName, dependency: dependency)
    }

    private static func handleError(_ error: Error, params: PhoneCallParams, dependency: MeetingDependency) {
        handleError(error, phoneNumber: params.phoneNumber, handleUnknown: true, userId: params.calleeId, userName: params.calleeName, dependency: dependency)
    }

    /// - parameter userName: 这里不能是电话号码，参见`I18n.View_MV_HelloAdminControlled`
    /// - parameter ignoreUnknown: treat unknown as ignore
    private static func handleError(_ error: Error, phoneNumber: String?, handleUnknown: Bool, userId: String?, userName: String?,
                                    dependency: MeetingDependency) {
        guard let errorInfo = error.toRustError(), let msgInfo = errorInfo.msgInfo else {
            if handleUnknown {
                Toast.show(I18n.View_VM_ErrorTryAgain)
            }
            return
        }
        let vcError = error.toVCError()
        let alertType = vcError.toEnterpriseAlertType()
        switch alertType {
        case .custom:
            switch vcError {
            case .enterprisePhoneNoPermissionError:
                // nolint-next-line: magic number
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { // 防止在拨号盘中一起dismiss了
                    Logger.network.info("Enterprise call creat noPermissionError")
                    let vc = EnterprisePhoneQuotaLimitViewController(userName: userName ?? "", userId: userId ?? "",
                                                                     dependency: dependency)
                    let con = NavigationController(rootViewController: vc)
                    con.modalPresentationStyle = .overFullScreen
                    VCScene.topMost(preferredVcScene: false)?.present(con, animated: true, completion: nil)
                }
            case .enterprisePhoneQuotaLimitError:
                Logger.network.info("Enterprise call creat quotaLimitError")
            case .PhonePermissionError:
                Toast.show(I18n.View_MV_CallFailCantCallOthers_AdminSetToast, type: .error, duration: 6)
            case .enterprisePhoneCallerOrgOnlyError:
                Logger.network.info("Enterprise call creat OrgOnly")
                let icon = UDIcon.getIconByKey(.moreCloseOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 20, height: 20))
                Toast.show(.richText(icon, CGSize(width: 20, height: 20), I18n.View_G_CannotCallDueToSetting_Toast))
            case .PstnOutgoingCallSuspend:
                Toast.show(I18n.View_MV_LimitYourCallPermissions, type: .error)
            default:
                break
            }
        case .alert:
            guard let alert = msgInfo.alert, let footer = alert.footer else { return }
            let i18nKeys = [alert.title.i18NKey, alert.body.i18NKey, footer.text.i18NKey]
            dependency.httpClient.i18n.get(i18nKeys) { result in
                if let i18nValues = result.value {
                    ByteViewDialog.Builder()
                        .id(.netBusinessError)
                        .needAutoDismiss(true)
                        .title(i18nValues[i18nKeys[0]])
                        .message(i18nValues[i18nKeys[1]])
                        .rightTitle(i18nValues[i18nKeys[2]])
                        .rightHandler({ _ in })
                        .rightType(footer.waitTime > 0 ? .countDown(time: TimeInterval(footer.waitTime)) : nil)
                        .show()
                }
            }
        case .personalCall:
            guard let phoneNumber = phoneNumber, let alert = msgInfo.alert,
                  let footer = alert.footer, let footer2 = alert.footer2 else { return }
            let colorTheme: ByteViewDialogConfig.ColorTheme
            switch footer2.color {
            case .red:
                colorTheme = .redLight
            case .blue:
                colorTheme = .defaultTheme
            case .black:
                colorTheme = .handsUpConfirm
            default:
                colorTheme = .defaultTheme
            }
            let i18nKeys = [alert.title.i18NKey, alert.body.i18NKey, footer.text.i18NKey, footer2.text.i18NKey]
            dependency.httpClient.i18n.get(i18nKeys) { result in
                if let i18nValues = result.value {
                    ByteViewDialog.Builder()
                        .id(.enterpriseCall)
                        .colorTheme(colorTheme)
                        .title(i18nValues[i18nKeys[0]])
                        .message(i18nValues[i18nKeys[1]])
                        .leftTitle(i18nValues[i18nKeys[2]])
                        .leftHandler({ _ in })
                        .rightTitle(i18nValues[i18nKeys[3]])
                        .rightHandler({ _ in
                            PhoneCallUtil.startPersonalCall(phoneNumber)
                        })
                        .show()
                }
            }
        case .unknown:
            if handleUnknown {
                Toast.show(I18n.View_VM_ErrorTryAgain)
            }
        }
    }

    private static func trackEnterpriseCallStart(matchID: String, isDirectCall: Bool, startType: String) {
        VCTracker.post(name: .vc_business_phone_call_status, params: ["process": "start",
                                                                      "action_match_id": matchID,
                                                                      "is_two_way_call": !isDirectCall,
                                                                      "initial_tab": startType])
    }

    private static func trackEnterpriseCallFailed(matchID: String, isDirectCall: Bool, startType: String, reason: String) {
        VCTracker.post(name: .vc_business_phone_call_status, params: ["process": "end",
                                                                      "status": "fail",
                                                                      "fail_reason": reason,
                                                                      "action_match_id": matchID,
                                                                      "is_two_way_call": !isDirectCall,
                                                                      "initial_tab": startType])
    }
}

private extension PhoneCallParams {
    var phoneNumber: String? {
        self.idType.isPhoneNumber ? self.id : nil
    }

    var chatId: String? {
        self.idType == .chatId ? self.id : nil
    }

    func toEnterpriseCallParams() -> EnterpriseCallParams? {
        switch self.idType {
        case .ipPhone:
            return .ipPhone(id: id, idType: .ipPhoneNumber, calleeId: calleeId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
        case .chatId:
            return .enterprise(id: calleeId ?? "", idType: .calleeUserId, calleeId: calleeId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
        case .candidateId, .enterprisePhone, .recruitmentPhone:
            return .enterprise(id: id, idType: idType.toEnterpriseCallType(), calleeId: calleeId, calleeName: calleeName, calleeAvatarKey: calleeAvatarKey)
        case .telephone:
            return nil
        }
    }

    func toRequest() -> CreateEnterprisePhoneRequest? {
        let calleeId = self.calleeId ?? ""
        switch idType {
        case .candidateId:
            return .init(calleeId: "", chatId: nil, phoneNumber: nil, phoneType: .recruitment, candidateInfo: CandidateInfo(candidateID: id, candidateName: nil, candidatePhoneNumber: nil))
        case .chatId:
            return .init(calleeId: calleeId, chatId: id, phoneNumber: nil, phoneType: .enterprise, candidateInfo: nil)
        case .recruitmentPhone:
            return .init(calleeId: calleeId, chatId: nil, phoneNumber: id, phoneType: .recruitment, candidateInfo: CandidateInfo(candidateID: "", candidateName: nil, candidatePhoneNumber: id))
        case .enterprisePhone:
            return .init(calleeId: calleeId, chatId: nil, phoneNumber: id, phoneType: .enterprise, candidateInfo: nil)
        case .ipPhone, .telephone:
            return nil
        }
    }
}

private extension PhoneCallParams.IdType {
    func toEnterpriseCallType() -> EnterpriseCallParams.IdType {
        switch self {
        case .candidateId:
            return .candidateId
        case .chatId:
            return .calleeUserId
        case .enterprisePhone:
            return .enterprisePhoneNumber
        case .ipPhone:
            return .ipPhoneNumber
        case .recruitmentPhone:
            return .recruitmentPhoneNumber
        case .telephone:
            assertionFailure("unsupported IdType")
            return .ipPhoneNumber
        }
    }
}

private enum EnterpriseKeyPadAlertType {
    case unknown
    case custom
    case alert
    case personalCall
}

private extension VCError {
    func toEnterpriseAlertType() -> EnterpriseKeyPadAlertType {
        switch self {
        case .enterprisePhoneNumberLimitError:
            return .personalCall
        case .enterprisePhoneAreaCodeLimitError,
                .enterprisePhoneCallSelfLimitError,
                .enterprisePhoneUserQuotaLimitError,
                .enterprisePhoneCallInLandLimitError:
            return .alert
        case .enterprisePhoneNoPermissionError,
                .enterprisePhoneQuotaLimitError,
                .PhonePermissionError,
                .enterprisePhoneCallerOrgOnlyError,
                .PstnOutgoingCallSuspend:
            return .custom
        default:
            return .unknown
        }
    }
}
