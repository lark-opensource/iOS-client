//
//  DataService+IMAPMigration.swift
//  MailSDK
//
//  Created by ByteDance on 2023/9/19.
//

import Foundation
import RustPB
import RxSwift
import UniverseDesignIcon

enum IMAPMigrationProvider: String {
    case office365 = "Office365"
    case exmail = "exmail"
    case exchange = "exchange"
    case gmail = "gmail"
    case qiye163 = "qiye.163"
    case alimail = "alimail"
    case zoho = "Zoho"
    case other = "other"
    case internationO365 = "international.o365"
    case chineseO365 = "chinese.o365"
        
    var info: (String, UIImage) {
        switch self {
        case .office365, .internationO365, .chineseO365:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Office365,
                    UDIcon.getIconByKey(.emailOffice365Colorful, size: CGSize(width: 70, height: 70)))
        case .exmail:
            return (BundleI18n.MailSDK.Mail_ThirdClient_TecentExmail,
                    UDIcon.getIconByKey(.emailTencentmailColorful, size: CGSize(width: 70, height: 70)))
        case .exchange:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Exchange,
                    UDIcon.getIconByKey(.emailExchangeColorful, size: CGSize(width: 70, height: 70)))
        case .gmail:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Google,
                    UDIcon.getIconByKey(.emailGmailColorful, size: CGSize(width: 70, height: 70)))
        case .qiye163:
            return (BundleI18n.MailSDK.Mail_ThirdClient_163Mail,
                    UDIcon.getIconByKey(.emailNeteasemailColorful, size: CGSize(width: 70, height: 70)))
        case .alimail:
            return (BundleI18n.MailSDK.Mail_ThirdClient_AliMail,
                    UDIcon.getIconByKey(.emailAlibabamailColorful, size: CGSize(width: 70, height: 70)))
        case .zoho:
            return (BundleI18n.MailSDK.Mail_ThirdClient_ZohoMail,
                    UDIcon.getIconByKey(.emailZohoColorful, size: CGSize(width: 70, height: 70)))
        case .other:
            return (BundleI18n.MailSDK.Mail_ThirdClient_Others, UDIcon.getIconByKey(.emailOthermailColorful, size: CGSize(width: 70, height: 70)))
        }
    }
    
}

extension DataService {
    // get imap migration state of current account
    func getIMAPMigartionState() -> Observable<Email_Client_V1_MailIMAPMigrationGetStateResponse> {
        var request = Email_Client_V1_MailIMAPMigrationGetStateRequest()
        request.fetchStatusFromServer = true
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailIMAPMigrationGetStateResponse) -> Email_Client_V1_MailIMAPMigrationGetStateResponse in
            DataService.logger.info("[mail_client] [imap_migration] get state success")
            return response
        }).observeOn(MainScheduler.instance)
    }
    
    // get all account imap migration states
    // key: int64表示account_id, 若为个人邮箱则表示lark_user_id
    func getAllAccountIMAPMigrationState(fromServer: Bool) -> Observable<Email_Client_V1_MailIMAPMigrationGetAllAccountStateResponse> {
        var request = Email_Client_V1_MailIMAPMigrationGetAllAccountStateRequest()
        request.fetchStatusFromServer = fromServer
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailIMAPMigrationGetAllAccountStateResponse) -> Email_Client_V1_MailIMAPMigrationGetAllAccountStateResponse in
            DataService.logger.info("[mail_client] [imap_migration] get all account states status \(response.status)")
            return response
        }).observeOn(MainScheduler.instance)
    }
    
    // imap auth by account and password
    func migartionLogin(account: String, password: String) -> Observable<Email_Client_V1_MailIMAPMigrationLoginResponse.MigrationLoginResult> {
        var request = Email_Client_V1_MailIMAPMigrationLoginRequest()
        request.username = account
        request.password = password
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailIMAPMigrationLoginResponse) ->  Email_Client_V1_MailIMAPMigrationLoginResponse.MigrationLoginResult in
            DataService.logger.info("[mail_client] [imap_migration] auth by account and password is success \(response.loginResult)")
            return response.loginResult
        }).observeOn(MainScheduler.instance)
    }
    
    // get imap migration auth url
    func getIMAPMigrationAuthURL(migrationID: Int64, emailAddress: String) ->Observable<Email_Client_V1_MailImapMigrationGetAuthInfoResponse> {
        var request = Email_Client_V1_MailImapMigrationGetAuthInfoRequest()
        request.migrationID = migrationID
        request.emailAddress = emailAddress
        return sendAsyncRequest(request, transform: {(response: Email_Client_V1_MailImapMigrationGetAuthInfoResponse) ->  Email_Client_V1_MailImapMigrationGetAuthInfoResponse in
            DataService.logger.info("[mail_client] [imap_migration] get auth info auth type \(response.authType)")
            return response
        }).observeOn(MainScheduler.instance)
    }
}
