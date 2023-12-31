//
//  ExternalInviteSendViewModel.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/11/4.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkModel
import LKMetric
import LarkMessengerInterface
import Homeric
import RustPB

enum VerificationState {
    case empty
    case waiting
    case valid
    case invalid
}

final class ExternalInviteSendViewModel: VerificationBaseViewModel {
    private let chatApplicationAPI: ChatApplicationAPI
    private let monitor = InviteMonitor()
    let sendType: InviteSendType
    let content: String
    let initialCountryCode: String
    var countryCode: String
    let inviteMsg: String
    let uniqueId: String
    let isOversea: Bool
    let verificationStateSubject = BehaviorRelay<VerificationState>(value: .waiting)

    init(chatApplicationAPI: ChatApplicationAPI,
         sendType: InviteSendType,
         content: String,
         countryCode: String,
         inviteMsg: String,
         uniqueId: String,
         isOversea: Bool) {
        self.chatApplicationAPI = chatApplicationAPI
        self.sendType = sendType
        self.content = content
        self.initialCountryCode = countryCode
        self.countryCode = countryCode
        self.inviteMsg = inviteMsg
        self.uniqueId = uniqueId
        self.isOversea = isOversea
        super.init(isOversea: isOversea)
    }

    func sendInviteMessage(contactContent: String) -> Observable<InvitationResult> {
        let invitationType: RustPB.Contact_V1_SendUserInvitationRequest.TypeEnum = (sendType == .phone ? .mobile : .email)
        var typeDesc = "unknown"
        switch invitationType {
        case .mobile:
            typeDesc = "phone"
        case .email:
            typeDesc = "email"
        @unknown default: break
        }
        let startTimeInterval = CACurrentMediaTime()
        monitor.startEvent(
            name: Homeric.UG_INVITE_EXTERNAL_ORIENTATION_INVITE,
            indentify: String(startTimeInterval),
            reciableEvent: .externalOrientationInvite
        )
        return chatApplicationAPI
            .invitationUser(invitationType: invitationType, contactContent: contactContent)
            .do(onNext: { [weak self] (result) in
                if result.success {
                    LKMetric.EO.inviteSuccess()
                } else {
                    LKMetric.EO.inviteFailed(errorMsg: "RustPB.Contact_V1_SendUserInvitationResponse.success = false")
                }
                self?.monitor.endEvent(
                    name: Homeric.UG_INVITE_EXTERNAL_ORIENTATION_INVITE,
                    indentify: String(startTimeInterval),
                    category: ["succeed": "true",
                               "type": typeDesc],
                    extra: [:],
                    reciableState: .success,
                    reciableEvent: .externalOrientationInvite
                )
            }, onError: { [weak self] (error) in
                if let apiError = error.underlyingError as? APIError {
                    self?.monitor.endEvent(
                        name: Homeric.UG_INVITE_EXTERNAL_ORIENTATION_INVITE,
                        indentify: String(startTimeInterval),
                        category: ["succeed": "false",
                                   "type": typeDesc,
                                   "error_code": apiError.code],
                        extra: ["error_msg": apiError.localizedDescription],
                        reciableState: .failed,
                        reciableEvent: .externalOrientationInvite
                    )
                }
                LKMetric.EO.inviteFailed(errorMsg: error.localizedDescription)
            })
            .observeOn(MainScheduler.instance)
    }

    @discardableResult
    func verify(_ origin: String) -> Bool {
        /// Prevent problems with hidden characters in the ios system
        let fixedContent = origin.replacingOccurrences(of: "\\p{Cf}", with: "", options: .regularExpression)
        if sendType == .phone {
            return verifyPhoneNumberValidation(fixedContent)
        } else if sendType == .email {
            return verifyEmailValidation(fixedContent)
        }
        return false
    }

    func getPureContactsContent(_ origin: String) -> String {
        /// Prevent problems with hidden characters in the ios system
        let fixedContent = origin.replacingOccurrences(of: "\\p{Cf}", with: "", options: .regularExpression)
        if sendType == .phone {
            return self.countryCode + getPurePhoneNumber(fixedContent)
        } else if sendType == .email {
            return getPureEmail(fixedContent)
        }
        return origin
    }

    override func verifyPhoneNumberValidation(_ origin: String, countryCode: String? = nil) -> Bool {
        if origin.isEmpty {
            verificationStateSubject.accept(.empty)
            return false
        }
        if self.countryCode == "+86" {
            let isValid = VerificationBaseViewModel.chinaPhoneNumberPredicate.evaluate(with: getPurePhoneNumber(origin))
            verificationStateSubject.accept(isValid ? .valid : .invalid)
            return isValid
        } else {
            let isValid = VerificationBaseViewModel.overseaPhoneNumberPredicate.evaluate(with: getPurePhoneNumber(origin))
            verificationStateSubject.accept(isValid ? .valid : .invalid)
            return isValid
        }
    }

    override func verifyEmailValidation(_ origin: String) -> Bool {
        if origin.isEmpty {
            verificationStateSubject.accept(.empty)
            return false
        }
        let isValid = VerificationBaseViewModel.emailPredicate.evaluate(with: getPureEmail(origin))
        verificationStateSubject.accept(isValid ? .valid : .invalid)
        return isValid
    }

    override func getPurePhoneNumber(_ origin: String) -> String {
        return origin.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
    }
}
