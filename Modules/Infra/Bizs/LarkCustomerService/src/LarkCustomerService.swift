//
//  LarkCustomerService.swift
//  Pods
//
//  Created by zhenning on 2019/6/2.
//

import UIKit
import Foundation
import EENavigator
import RxSwift
import RxCocoa
import LarkUIKit
import LarkRustClient
import LKCommonsLogging
import LarkContainer
import LarkSetting

private struct CustomServiceChatBody: CodablePlainBody {
    public static let pattern = "//client/chat/help"

    public init() {}
}

public final class LarkCustomerService: LarkCustomerServiceAPI {
    typealias OpenCustomerServiceHandler = () -> Void
    typealias PrepareHandler = (UIViewController) -> Void

    private static let logger = Logger.log(LarkCustomerService.self, category: "LarkCustomerService.SDK")
    private let disposeBag = DisposeBag()
    private var customServiceWebUrl: String = ""
    /// 是否跳转客服群
    private var gotoOncallChat: Bool = false
    // 跳转到客服群，兜底逻辑下，路由跳转为push方式
    let oncallChatShowBehavior: ShowBehaviour = .push
    /// 失败回调参数，请求失败和跳转失败，现在未用到
    private var isfetchUrlFailed: Bool = false
    var onSuccess: (() -> Void)?
    var onFailed: (() -> Void)?

    private let rustCustomerServiceAPI: RustLarkCustomerServiceAPI
    private let navigator: Navigatable
    public init(client: RustService, navigator: Navigatable, userResolver: UserResolver) {
        self.rustCustomerServiceAPI = RustLarkCustomerServiceAPI(client: client, userResolver: userResolver)
        self.navigator = navigator
    }

    public func launchCustomerService() {
        let urlStringObservable: Observable<(String, Bool)> = { () -> Observable<(String, Bool)> in
            return self.rustCustomerServiceAPI.getAppConfig()
                .flatMap { [weak self] (appConfig) -> Observable<(String, Bool, Bool)> in
                    guard let `self` = self else { return .empty() }

                    let zendeskLink = appConfig.zendesk.webFormURL
                    let isOncallChat = appConfig.zendesk.oncallChat
                    let isZendeskLinkObservable = self.rustCustomerServiceAPI.getGetLinkExtraData(link: zendeskLink)
                    return Observable.combineLatest(Observable.just(zendeskLink),
                                                    isZendeskLinkObservable,
                                                    Observable.just(isOncallChat),
                                                    resultSelector: { (link, flag, isOncallChat) in
                                                        (link, flag, isOncallChat) })
            }.map { (originWebUrl, isZendeskLink, isOncallChat) -> (String, Bool) in
                var zendeskUrl = ""
                // 默认backup逻辑跳值班号，返回true
                guard !originWebUrl.isEmpty else {
                    return (zendeskUrl, true)
                }
                guard let urlComponents = NSURLComponents(string: originWebUrl) else {
                    return (originWebUrl, isOncallChat)
                }
                var queryItems = urlComponents.queryItems ?? []
                if isZendeskLink { queryItems.append(URLQueryItem(name: "show_right_button", value: "false")) }
                urlComponents.queryItems = queryItems
                zendeskUrl = urlComponents.url!.absoluteString
                return (zendeskUrl, isOncallChat)
            }
        }()

        urlStringObservable.subscribe(onNext: { (urlString, isOncallChat) in
            self.gotoOncallChat = isOncallChat
            self.customServiceWebUrl = urlString
            LarkCustomerService.logger.debug("launchCustomerService",
                                             additionalData: ["isOncallChat": "\(isOncallChat)",
                                                "urlString": "\(self.customServiceWebUrl)"])
        }, onError: { (_) in
            self.isfetchUrlFailed = true
        }).disposed(by: self.disposeBag)
    }

    /// 跳转到客服
    ///  routerParams: 路由参数类
    ///  onSuccess: launch指定页面成功时的回调
    ///  onFailed: launch指定页面失败的回调
    public func showCustomerServicePage(routerParams: RouterParams, onSuccess: (() -> Void)?, onFailed: (() -> Void)?) {
        let urlStr = self.handleUrlStringBySourceType(urlStr: self.customServiceWebUrl,
                                                      sourceModuleType: routerParams.sourceModuleType)
        let needDissmiss = routerParams.needDissmiss
        let showBehavior = routerParams.showBehavior
        let prepare = routerParams.prepare
        let from = routerParams.from
        let wrap = routerParams.wrap
        self.onSuccess = onSuccess
        self.onFailed = onFailed

        // 如果zendesk，url转换失败,则执行失败回调
        guard !urlStr.isEmpty,
            let url = URL(string: urlStr),
            !gotoOncallChat else {
                LarkCustomerService.logger.debug("""
                                            LarkCustomerService showCustomerServicePage，
                                            1. urlStr is empty,
                                            or 2. urlStr transform to URL Failed,
                                            or 3. oncall_chat is true。 jump to CustomServiceChatBody
                    """, additionalData: ["isOncallChat": "\(self.gotoOncallChat)",
                        "urlStr": "\(urlStr)",
                        "needDissmiss": "\(needDissmiss)"])
                // 跳转到客服群，兜底逻辑下，路由跳转为push方式
                openNextPage(openAction: openOncallChatHandler(showBehavior: oncallChatShowBehavior,
                                                               prepare: prepare,
                                                               wrap: wrap,
                                                               from: from),
                             needDismiss: needDissmiss)
                return
        }

        openNextPage(openAction: openUrlHandler(url: url, showBehavior: showBehavior,
                                                prepare: prepare,
                                                wrap: wrap,
                                                from: from),
                     needDismiss: needDissmiss)
    }

    public func getNewCustomerInfo(botAppId: String, extInfo: String) -> Observable<GetNewCustomerInfoResult> {
        return self.rustCustomerServiceAPI.getNewCustomerInfo(botAppId: botAppId, extInfo: extInfo)
    }

    public func enterNewCustomerChat(chatid: String) -> Observable<Void> {
        return self.rustCustomerServiceAPI.enterNewCustomerChat(chatid: chatid)
    }

    private func handleUrlStringBySourceType (urlStr: String, sourceModuleType: SourceModuleType) -> String {
        var businessType = ""
        switch sourceModuleType {
        case .larkMine:
            businessType = "suite"
        case .docs:
            businessType = "docs"
        case .videoChat:
            businessType = "vc"
        }
        guard var urlComponents = URLComponents(string: urlStr) else {
            LarkCustomerService.logger.error("""
                LarkCustomerService handleUrlStringBySourceType failed, the urlComponents is nil urlStr = \(urlStr)
                """)
            return urlStr
        }
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "from", value: "app"))
        queryItems.append(URLQueryItem(name: "system", value: "ios"))
        queryItems.append(URLQueryItem(name: "business", value: businessType))
        urlComponents.queryItems = queryItems
        return urlComponents.url!.absoluteString
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Adaptor
private extension LarkCustomerService {
    func openNextPage(openAction: @escaping OpenCustomerServiceHandler,
                      needDismiss: Bool) {
        if needDismiss {
            navigator.navigation?.dismiss(animated: false, completion: {
                openAction()
            })
        } else {
            openAction()
        }
    }

    func openOncallChatHandler(showBehavior: ShowBehaviour,
                               prepare: PrepareHandler? = nil,
                               wrap: UINavigationController.Type? = nil,
                               from: UIViewController? = nil) -> OpenCustomerServiceHandler {
        guard let from = from else {
            Self.logger.error("openOncallChatHandler failed: from is nil")
            return { }
        }
        let navigator = self.navigator
        if showBehavior == .present {
            return {
                navigator.present(body: CustomServiceChatBody(), wrap: wrap, from: from, prepare: prepare)
            }
        }
        if Display.pad {
            return {
                navigator.showDetail(body: CustomServiceChatBody(), wrap: wrap, from: from)
            }
        }
        return {
            navigator.push(body: CustomServiceChatBody(), from: from)
        }
    }

    func openUrlHandler(url: URL,
                        showBehavior: ShowBehaviour,
                        prepare: PrepareHandler? = nil,
                        wrap: UINavigationController.Type? = nil,
                        from: UIViewController? = nil) -> OpenCustomerServiceHandler {
        guard let from = from else {
            Self.logger.error("openUrlHandler failed: from is nil")
            return {
                self.onFailed?()
            }
        }
        let navigator = self.navigator
        if showBehavior == .present {
            return {
                navigator.present(url, wrap: wrap, from: from, prepare: prepare) { (_, res) in
                    if res.error != nil, let onFailed = self.onFailed {
                        onFailed()
                        LarkCustomerService.logger.error("""
                            LarkCustomerService openUrlHandler failed，showBehavior present,
                            res.error = \(String(describing: res.error)),
                            url = \(url),
                            wrap = \(String(describing: wrap)),
                            from = \(String(describing: from))
                            """)
                    } else if let onSuccess = self.onSuccess {
                        onSuccess()
                    }
                }
            }
        }
        if Display.pad {
            return {
                navigator.showDetail(url, wrap: wrap, from: from) { (_, res) in
                    if res.error != nil, let onFailed = self.onFailed {
                        onFailed()
                        LarkCustomerService.logger.error("""
                            LarkCustomerService openUrlHandler failed，Display.pad,
                            res.error = \(String(describing: res.error)),
                            url = \(url),
                            wrap = \(String(describing: wrap)),
                            from = \(String(describing: from))
                            """)
                    } else if let onSuccess = self.onSuccess {
                        onSuccess()
                    }
                }
            }
        }        
        return {
            navigator.push(url, from: from) { (_, res) in
                if res.error != nil, let onFailed = self.onFailed {
                    onFailed()
                    LarkCustomerService.logger.error("""
                        LarkCustomerService openUrlHandler failed，showBehavior default,
                        res.error = \(res.error),
                        url = \(url),
                        from = \(String(describing: from))
                        """)
                } else if let onSuccess = self.onSuccess {
                    onSuccess()
                }
            }
        }
    }
}
