//  Created by weidong fu on 27/11/2017.

import Foundation

struct MailNetworkError: Error {
    enum Code: Int {
        case success = 0
        case fail = 1
        case invalidParams = 2
        case notFound = 3
        case loginRequired = 5
        case parseError = 110
        case invalidData = 111
        case createLimited = 11_001
    }
    let code: MailNetworkError.Code
    private var message: String {
        switch code {
        default:
            return ""
        }
    }
    var errorMsg: String?
    init(code: Code) {
        self.code = code
        self.errorMsg = message
    }
}

extension MailNetworkError: LocalizedError {
    var errorDescription: String? { return self.message }
    var failureReason: String? { return self.message }
    var recoverySuggestion: String? { return BundleI18n.MailSDK.Mail_ThreadList_NoNetwork }
    var helpAnchor: String? { return BundleI18n.MailSDK.Mail_Onboard_MailClientOnboardingLinkNow }
}

extension MailNetworkError {
    static let parse = MailNetworkError(code: .parseError)
    static let invalidData = MailNetworkError(code: .invalidData)
    static let invalidParams = MailNetworkError(code: .invalidParams)
    static let loginRequired = MailNetworkError(code: .loginRequired)
    static let createLimited = MailNetworkError(code: .createLimited)
}
