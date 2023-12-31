//
//  DataService+Cache.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/29.
//

import Foundation
import RustPB
import RxSwift

extension DataService {
    struct PreloadConfig {
        var timeStamp: Email_Client_V1_MailPreloadTimeStamp
        var needPreloadImage: Bool
        var needPreloadAttach: Bool
        var allowMobileTraffic: Bool
    }
    func mailSetPreloadTimeStamp(accountID: String, config: PreloadConfig) -> Observable<Email_Client_V1_MailSetPreloadConfigResponse> {
        var req = Email_Client_V1_MailSetPreloadConfigRequest()
        req.timeStamp = config.timeStamp
        req.accountID = accountID
        req.allowMobileTraffic = config.allowMobileTraffic
        req.needPreloadImage = config.needPreloadImage
        req.needPreloadAttachment = config.needPreloadAttach
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailSetPreloadConfigResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailGetPreloadTimeStamp(accountID: String) -> Observable<Email_Client_V1_MailGetPreloadConfigResponse> {
        var req = Email_Client_V1_MailGetPreloadConfigRequest()
        req.accountID = accountID
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailGetPreloadConfigResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailGetPreloadStatus() -> Observable<Email_Client_V1_MailGetPreloadStatusResponse> {
        let req = Email_Client_V1_MailGetPreloadStatusRequest()
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailGetPreloadStatusResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailClosePreloadFinishedBanner() -> Observable<Email_Client_V1_MailClosePreloadBannerResponse> {
        let req = Email_Client_V1_MailClosePreloadBannerRequest()
        return sendAsyncRequest(req, transform: { (response: Email_Client_V1_MailClosePreloadBannerResponse) in
            return response
        }).observeOn(MainScheduler.instance)
    }
}
