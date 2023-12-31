//
//  RustLarkCustomerServiceAPI.swift
//  Pods
//
//  Created by zhenning on 2020/5/14.
//

import Foundation
import RxSwift
import RustPB
import LarkRustClient
import LarkContainer
import LarkAccountInterface
import LarkSetting
import LKCommonsLogging
import ThreadSafeDataStructure

final class RustLarkCustomerServiceAPI: UserResolverWrapper {
    static let logger = Logger.log(RustLarkCustomerServiceAPI.self, category: "LarkCustomerService")
    let userResolver: UserResolver
    private let client: RustService
    private let scheduler: ImmediateSchedulerType = SerialDispatchQueueScheduler(internalSerialQueueName:
        "LarkCustomerService.scheduler")

    private lazy var sessionKey: String? = {
        return try? userResolver.resolve(assert: PassportUserService.self).user.sessionKey
    }()
    
    private lazy var passportService: PassportService? = {
        return try? userResolver.resolve(assert: PassportService.self)
    }()

    init(client: RustService, userResolver: UserResolver) {
        self.client = client
        self.userResolver = userResolver
    }

    /// 获取 app 配置
    func getAppConfig() -> Observable<RustPB.Basic_V1_AppConfig> {
        let request = RustPB.Basic_V1_GetAppConfigRequest()
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Basic_V1_GetAppConfigResponse) -> RustPB.Basic_V1_AppConfig in
            return response.appConfig
        }).subscribeOn(scheduler)
    }

    /// 检测链接是否为Zendesk
    func getGetLinkExtraData(link: String) -> Observable<Bool> {
        var request = RustPB.Basic_V1_GetLinkExtraDataRequest()
        request.link = link
        return client.sendAsyncRequest(request) { (res: RustPB.Basic_V1_GetLinkExtraDataResponse) -> (Bool) in
            if case .some(.zendeskLink) = res.extraData {
                return true
            }
            return false
        }.subscribeOn(scheduler)
    }

    private func getSessionHeader() -> [String: String]? {
        guard let sessionKey = self.sessionKey else {
            return nil
        }
        var header: [String: String] = [:]
        let sessionStr = "session=" + sessionKey
        header["Cookie"] = sessionStr
        return header
    }

    private lazy var ocicDomain: String? = {
        let result = DomainSettingManager.shared.currentSetting["csc_ocic"]?.first
        Self.logger.error("ocicDomain trace \(result ?? "")")
        return result
    }()

    private var newCustomerInfoFetching: SafeAtomic<Bool> = false + .readWriteLock

    func getNewCustomerInfo(botAppId: String, extInfo: String) -> Observable<GetNewCustomerInfoResult> {
        Self.logger.info("getNewCustomerInfo request trace \(botAppId) \(extInfo)")
        guard !newCustomerInfoFetching.value else {
            Self.logger.info("getNewCustomerInfo request trace in fetching \(botAppId) \(extInfo)")
            return .empty()
        }
        newCustomerInfoFetching.value = true
        guard let domain = self.ocicDomain else {
            Self.logger.error("getNewCustomerInfo request domain or sessionKey is miss \(botAppId)")
            newCustomerInfoFetching.value = false
            return Observable.error(NewCustomerRequestError.noDomain)
        }
        guard let header = self.getSessionHeader() else {
            Self.logger.error("getNewCustomerInfo request sessionKey is miss \(botAppId)")
            newCustomerInfoFetching.value = false
            return Observable.error(NewCustomerRequestError.noSession)
        }
        var httpRequest = Basic_V1_SendHttpRequest()
        httpRequest.headers = header
        if passportService?.isFeishuBrand ?? true {
            httpRequest.url = "https://" + domain + "/api/csc-platform/feishu/event/openAppLink"
        } else {
            httpRequest.url = "https://" + domain + "/lark/global-market/v1/lark_assistant/open_applink"
        }
        
        var bodyJson: [String: String] = [:]
        bodyJson["AppId"] = botAppId
        bodyJson["ExtInfo"] = extInfo
        guard let body = try? JSONSerialization.data(withJSONObject: bodyJson, options: []) else {
            Self.logger.error("getNewCustomerInfo request body is wrong \(botAppId)")
            newCustomerInfoFetching.value = false
            return Observable.error(NewCustomerRequestError.requestJsonError)
        }
        httpRequest.body = body
        httpRequest.method = .post
        return client.sendAsyncRequest(httpRequest, transform: { (res: RustPB.Basic_V1_SendHttpResponse) -> GetNewCustomerInfoResult in
            switch res.status {
            case .normal:
                guard let json = try? JSONSerialization.jsonObject(with: res.body, options: []) as? [String: Any] else {
                    Self.logger.error("getNewCustomerInfo callback json is wrong \(botAppId)")
                    return .fail(desc: nil)
                }
                let description = json["Description"] as? String ?? ""
                Self.logger.info("getNewCustomerInfo callback description is \(botAppId) \(description)")
                if let result = json["Result"] as? Int32 {
                    if result == 0 {
                        if let chatId = json["ChatId"] as? String {
                            Self.logger.info("getNewCustomerInfo callback chatId is \(botAppId) \(chatId)")
                            return .chatId(chatId)
                        } else {
                            Self.logger.error("getNewCustomerInfo callback ChatId is wrong \(botAppId)")
                            return .fail(desc: nil)
                        }
                    } else if result == 960001 {
                        if let applink = (json["FallbackAppLink"] as? String)?.removingPercentEncoding {
                            Self.logger.info("getNewCustomerInfo callback applink is \(botAppId) \(applink)")
                            if let url = URL(string: applink) {
                                return .fallbackLink(url)
                            } else {
                                Self.logger.error("getNewCustomerInfo callback result applink is not url \(botAppId) \(applink)")
                                return .fail(desc: nil)
                            }
                        }
                        Self.logger.error("getNewCustomerInfo callback result applink is not string \(botAppId)")
                        return .fail(desc: nil)
                    } else {
                        return .fail(desc: description.isEmpty ? nil : description)
                    }
                } else {
                    Self.logger.error("getNewCustomerInfo callback result is not Int \(botAppId)")
                    return .fail(desc: nil)
                }
            default:
                Self.logger.error("getNewCustomerInfo callback res status wrong \(botAppId) \(res.status.rawValue)")
                return .fail(desc: nil)
            }
        }).do(onNext: { [weak self] _ in
            self?.newCustomerInfoFetching.value = false
        }, onError: { [weak self] _ in
            self?.newCustomerInfoFetching.value = false
        })
        .subscribeOn(scheduler)
    }

    func enterNewCustomerChat(chatid: String) -> Observable<Void> {
        Self.logger.info("enterNewCustomerChat request trace \(chatid)")
        guard let domain = self.ocicDomain else {
            Self.logger.error("enterNewCustomerChat request domain or sessionKey is miss \(chatid)")
            return Observable.error(NewCustomerRequestError.noDomain)
        }
        guard let header = self.getSessionHeader() else {
            Self.logger.error("getNewCustomerInfo request sessionKey is miss \(chatid)")
            return Observable.error(NewCustomerRequestError.noSession)
        }
        var httpRequest = Basic_V1_SendHttpRequest()
        httpRequest.headers = header
        if passportService?.isFeishuBrand ?? true {
            httpRequest.url = "https://" + domain + "/api/csc-platform/feishu/event/enterIm"
        } else {
            httpRequest.url = "https://" + domain + "/lark/global-market/v1/lark_assistant/enter_im"
        }
        var bodyJson: [String: String] = [:]
        bodyJson["ChatId"] = chatid
        guard let body = try? JSONSerialization.data(withJSONObject: bodyJson, options: []) else {
            Self.logger.error("enterNewCustomerChat request body is wrong \(chatid)")
            return Observable.error(NewCustomerRequestError.requestJsonError)
        }
        httpRequest.body = body
        httpRequest.method = .post
        return client.sendAsyncRequest(httpRequest, transform: { (res: RustPB.Basic_V1_SendHttpResponse) -> Void in
            switch res.status {
            case .normal:
                guard let json = try? JSONSerialization.jsonObject(with: res.body, options: []) as? [String: Any] else {
                    Self.logger.error("enterNewCustomerChat callback json is wrong \(chatid)")
                    return
                }
                if let result = json["Result"] as? Int32 {
                    Self.logger.info("enterNewCustomerChat callback result is \(result) \(chatid)")
                }
                if let description = json["Description"] as? String {
                    Self.logger.info("enterNewCustomerChat callback description is \(description) \(chatid)")
                }
                return
            default:
                Self.logger.error("enterNewCustomerChat callback res status wrong \(chatid) \(res.status.rawValue)")
                return
            }
        }).subscribeOn(scheduler)
    }
}
