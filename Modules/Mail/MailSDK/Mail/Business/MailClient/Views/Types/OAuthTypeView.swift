//
//  OAuthTypeView.swift
//  MailSDK
//
//  Created by Fawaz on 4/24/20.
//

import Foundation

protocol OAuthViewable {
    init(primaryButtonTappedBlock: @escaping (ImportViewButtonType) -> Void,
         policyTappedBlock: @escaping (MailPolicyType) -> Void,
         showDisclaimerView: Bool,
         userType: MailNewUserViewType)
}

typealias OAuthView = UIView

enum OAuthViewType {
    case typeNewUserOnboard
    case typeOauthExpired
    case typeOauthDeleted
    case typeLoading
    case typeLoadingFailed
    case typeNoOAuthView
    case typeExchangeOnboard
    case typeApiOnboard
}

extension OAuthViewType {
    func view(primaryButtonTappedBlock: @escaping (ImportViewButtonType) -> Void,
              policyTappedBlock: @escaping (MailPolicyType) -> Void,
              showDisclaimerView: Bool) -> OAuthView {
        switch self {
        case .typeNewUserOnboard: return MailNewUserView(primaryButtonTappedBlock: primaryButtonTappedBlock,
                                                         policyTappedBlock: policyTappedBlock,
                                                         showDisclaimerView: showDisclaimerView,
                                                         userType: MailNewUserViewType.gmail)
        case .typeExchangeOnboard: return MailNewUserView(primaryButtonTappedBlock: primaryButtonTappedBlock,
                                                          policyTappedBlock: policyTappedBlock,
                                                          showDisclaimerView: showDisclaimerView,
                                                          userType: MailNewUserViewType.exchange)
        case .typeOauthExpired: return MailLinkOAuthView(primaryButtonTappedBlock: primaryButtonTappedBlock,
                                                        policyTappedBlock: policyTappedBlock,
                                                        showDisclaimerView: showDisclaimerView,
                                                        userType: .gmail)
        case .typeOauthDeleted: return MailDeletedOauthView.init(frame: .zero)
        case .typeApiOnboard: return MailNewUserView(primaryButtonTappedBlock: primaryButtonTappedBlock,
                                                     policyTappedBlock: policyTappedBlock,
                                                     showDisclaimerView: showDisclaimerView,
                                                     userType: MailNewUserViewType.apiOnboard)
        default:
            return MailLinkOAuthView(primaryButtonTappedBlock: primaryButtonTappedBlock,
            policyTappedBlock: policyTappedBlock,
            showDisclaimerView: showDisclaimerView,
            userType: .gmail)
        }
    }
}
