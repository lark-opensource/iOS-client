//
//  DataService+Config.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/9/16.
//

import Foundation
import RustPB
import RxSwift

struct UserMailConfig: Codable {
    struct Address: Codable {
        var isPrimary: Bool
        var address: String
        var name: String

        init(isPrimary: Bool, address: String, name: String) {
            self.isPrimary = isPrimary
            self.address = address
            self.name = name
        }
    }
    let userMailEnable: Bool
    let addressList: [Address]
    let userId: String

    var mailAddress: Address? {
        for item in addressList where item.isPrimary {
            return item
        }
        return nil
    }

    init(userMailEnable: Bool, addressList: [Address], userId: String) {
        self.userMailEnable = userMailEnable
        self.addressList = addressList
        self.userId = userId
    }
}

extension DataService {
    func getGoogleOrExchangeOauthUrl(type: MailOAuthURLType, emailAddress: String?, fromVC: UIViewController, showErrToast: Bool = true) -> Observable<(String, Bool, String?)> {
        var request = GetAuthURLRequest()
        request.oauthType = type
        if let address = emailAddress {
            request.emailAddress = address
        }
        return sendAsyncRequest(request).map({ (response: GetAuthURLResponse) -> (String, Bool, String?) in
            var errMsg: String?
            if response.accessDenied {
                if response.deniedReason == .unknown {
                    errMsg = BundleI18n.MailSDK.Mail_LinkAccount_DataClearing_Toast
                } else if response.deniedReason == .notExchangeEmail {
                    errMsg = BundleI18n.MailSDK.Mail_LinkMail_Non365OtherWays_Error
                } else {
                    MailLogger.error("getGoogleOrExchangeOauthUrl: unknown reason")
                    errMsg = BundleI18n.MailSDK.Mail_LinkAccount_DataClearing_Toast
                }
                if showErrToast, let errMsg = errMsg {
                    DispatchQueue.main.async {
                        MailRoundedHUD.showFailure(with: errMsg,
                                                   on: fromVC.view,
                                                   event: ToastErrorEvent(event: .mailclient_oauth_access_denied_deleting))
                            
                    }
                }
            }
            return (response.oauthURL, response.accessDenied, errMsg)
        }).observeOn(MainScheduler.instance)
    }

    func updateMailClientTabSetting(status: Bool) -> Observable<(Email_Client_V1_MailUpdateClientTabSettingResponse)> {
        var req = Email_Client_V1_MailUpdateClientTabSettingRequest()
        req.isEnabled = status
        return sendAsyncRequest(req).map({ (resp: Email_Client_V1_MailUpdateClientTabSettingResponse) -> Email_Client_V1_MailUpdateClientTabSettingResponse in

            NotificationCenter.default.post(name: Notification.Name.Mail.MAIL_SETTING_CHANGED_BYPUSH,
                                            object: Store.settingData.findCurrentSetting(account: resp.account))
            return resp
        }).observeOn(MainScheduler.instance)
    }

    func mailLastVersionIsNewUser() -> Observable<Bool> {
        let request = Email_Client_V1_MailLastVersionNewUserFlagRequest()
        return sendAsyncRequest(request).map({ (resp: Email_Client_V1_MailLastVersionNewUserFlagResponse) -> Bool in
            return resp.newUserFlag
        }).observeOn(MainScheduler.instance)
    }

    func fetchCanSendExternal(address: MailClientAddress) -> Observable<Bool> {
        var request = Email_Client_V1_MailCanSendExternalRequest()
        request.address = address
        return sendAsyncRequest(request).map({ (resp: Email_Client_V1_MailCanSendExternalResponse) -> Bool in
            return resp.canSendExternal
        }).observeOn(MainScheduler.instance)
    }
    
    func checkCanUserBindImap(fromVC: UIViewController) -> Observable<Bool> {
        let request = Email_Client_V1_MailImapCheckIfCanUserBindRequest()
        return sendAsyncRequest(request).map({ (response: Email_Client_V1_MailImapCheckIfCanUserBindResponse) -> Bool in
            if response.accessDenied {
                DispatchQueue.main.async {
                    MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_LinkAccount_DataClearing_Toast,
                                               on: fromVC.view,
                                               event: ToastErrorEvent(event: .mailclient_oauth_access_denied_deleting))
                }
                return false
            }
            return true
        }).observeOn(MainScheduler.instance)
    }
    
    func fetchSmtpImapConfig(mailAddress: String?) -> Observable<Email_Client_V1_MailImapGetSmtpImapConfigResponse> {
        var request = Email_Client_V1_MailImapGetSmtpImapConfigRequest()
        mailAddress.map { request.mailAddress = $0 }
        return sendAsyncRequest(request).observeOn(MainScheduler.instance)
    }
    
    func imapUserBindAccount(_ account: MailImapAccount) -> Observable<Email_Client_V1_MailImapUserBindAccountResponse.Status> {
        
        var request = Email_Client_V1_MailImapUserBindAccountRequest()
        request.mailAddress = account.mailAddress
        request.password = account.password
        request.bindType = account.bindType
        request.imapPort = account.imapPort
        request.smtpPort = account.smtpPort
        account.imapAddress.map { request.imapAddress = $0 }
        account.smtpAddress.map { request.smtpAddress = $0 }
        return sendAsyncRequest(request).map({ (response: Email_Client_V1_MailImapUserBindAccountResponse) -> Email_Client_V1_MailImapUserBindAccountResponse.Status in
            return response.status
        }).observeOn(MainScheduler.instance)
    }
}

extension DataService {
    func getSignaturesRequest(fromSetting: Bool,
                              accountId: String) -> Observable<Email_Client_V1_MailGetSignatureResponse> {
        var request = Email_Client_V1_MailGetSignaturesRequest()
        request.fromSetting = fromSetting
        request.accountID = accountId
        return sendAsyncRequest(request).map({ (resp: Email_Client_V1_MailGetSignatureResponse) ->
            Email_Client_V1_MailGetSignatureResponse in
            return resp
        }).observeOn(MainScheduler.instance)
    }
    func updateMailSignatureUsage(usage: SignatureUsage, accountId: String) -> Observable<Void> {
        var request = Email_Client_V1_MailUpdateSignatureUsageRequest()
        request.signatureUsage = usage
        request.accountID = accountId
        return sendAsyncRequest(request).map({ (resp: Email_Client_V1_MailUpdateSignatureUsageResponse) ->
            Void in
            return
        }).observeOn(MainScheduler.instance)
    }
}

extension DataService {
    func translateLargeTokenRequest(tokenList: [String], messageBizId: String) -> Observable<[String: String]> {
        var request = largeTokenReq()
        request.tokenList = tokenList
        request.mailMessageBizID = messageBizId
        return sendAsyncRequest(request).map({ (resp: largeTokenResp) ->
            [String: String] in
            return resp.oldTokenToNewTokenMap
        }).observeOn(MainScheduler.instance)
    }
}
