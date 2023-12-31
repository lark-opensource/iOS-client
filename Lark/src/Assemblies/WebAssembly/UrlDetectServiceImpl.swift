//
//  URLDetectServiceImpl.swift
//  LarkCore
//
//  Created by 赵冬 on 2019/12/3.
//

import Foundation
import RxSwift
import LKCommonsLogging
import ThreadSafeDataStructure
import RxCocoa
import WebKit
import WebBrowser
import LarkAccountInterface
import EcosystemWeb
import OPWebApp
import LarkWebViewContainer
import LarkSetting
//code from zhaodong，为更改任何逻辑，只是换了个文件位置
//可以抽离到飞书源码

/// doc: https://bytedance.feishu.cn/docs/doccnJ0VyABjqFjygbaWETuoNoe
/// 后续可优化点: 可以复用500ms之前发送的请求，不需要另外再发送统一的请求
/// 白名单：1. 本地缓存的30分钟过期的白名单；2. settings v3配置
/// 目前依赖于rust sdk提供检测能力
/// 之前302跳转的问题：1. post改为get; 2. #hash值丢掉，需要另外处理
/// iOS：前500ms同步等待检测结果，等500ms之后如果结果仍然未回来，则取消同步等待，先加载网页，再并行发送检测请求，如果非法则再进行跳转提示用户
/// 同步等待能够覆盖大部分场景，因为网络请求一般几十ms即完成
/// 安卓只支持异步的方式，没有同步等待的先行步骤
final class URLDetectServiceImpl: URLDetectService {

    private enum ProcessType {
        case sync
        case async
    }

    private struct ProcessResult {
        var type: ProcessType
        var isSafe: Bool = true
        var isTimeOut: Bool = false
    }

    private var secLinkWhitelist: [String] = []

    static private var timeoutArray: [Int64] = []

    static private var isTimeOut3TimesFor30Min: Bool {
        guard Self.timeoutArray.count == 3,
            let first = Self.timeoutArray.first,
            let third = Self.timeoutArray.last else { return false }
        let thrityMin = 1800
        if third - first < thrityMin {
            return true
        }
        return false
    }

    // 缓存30分钟内检测为安全的链接
    static private var safeLinkFor30MinCache: SafeSet<URL> = SafeSet<URL>([], synchronization: .semaphore)
    static private var isTemporarilyCancelSyncDetect = false

    private var safeUrlArray: Set<URL> = []

    private var safeLinkEnable: Bool

    private var unsafeUrlArray: Set<URL> = []

    private var detectUrlHead: String?

    private var isUserTapUrl: Bool = true

    static let logger = LKCommonsLogging.Logger.log(URLDetectServiceImpl.self, category: "secLink.Log")

    private let disposeBag = DisposeBag()

    private let queue = DispatchQueue(label: "URLDetectServiceImpl.serialQueue", qos: .default)
    private lazy var queueScheduler: SchedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)

    var judgeURL: (String) -> Observable<Bool>

    private var publishSubject = PublishSubject<ProcessResult>()

    private var secLinkResultSubject = PublishSubject<Bool>()

    var secLinkResultDriver: Driver<Bool> {
        return self.secLinkResultSubject.take(1).asDriver(onErrorJustReturn: true)
    }

    init(safeLinkEnable: Bool,
         secLinkWhitelist: [String],
         detectUrlHead: String?,
         judgeURL: @escaping (String) -> Observable<Bool>) {
        self.safeLinkEnable = safeLinkEnable
        self.secLinkWhitelist = secLinkWhitelist
        self.detectUrlHead = detectUrlHead
        self.judgeURL = judgeURL
    }

    private var prefix: String? {
        if let detectUrlHead = self.detectUrlHead {
            return "https://" + detectUrlHead + "/link/safety"
        }
        return nil
    }

    private func isNeedToDetect(url: URL) -> Bool {
        let canUseNewVersion = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.seclinkprecheck.enable"))
        if canUseNewVersion {
            return self.newVersion_isNeedToDetect(url: url)
        } else {
            return self.oldVersion_isNeedToDetect(url: url)
        }
    }
    private func oldVersion_isNeedToDetect(url: URL) -> Bool {
        if AccountServiceAdapter.shared.currentAccountInfo.userID.isEmpty { return false }
        guard safeLinkEnable, let prefix = self.prefix else { return false }
        if OPWebAppManager.sharedInstance.isValidVhostInUrl(url) {
            // 按照离线包项目经理要求，vhost不走安全连接
            Self.logger.info("vhost need not detect")
            return false
        }
        let urlString = url.absoluteString
        let isHaveSafePrefix = urlString.hasPrefix(prefix)
        /// https://bytedance.feishu.cn/docs/doccn635C6MV62V6eum2IASGlOd#gr0xYO
        /// 白名单使用 host 进行匹配
        /// 如果是安全链接，不进行白名单检测
        let host = url.host ?? ""
        let isInWhiteList = isHaveSafePrefix || self.secLinkWhitelist.contains { (regex) -> Bool in
            host.lf.matchingStrings(regex: regex, options: [.caseInsensitive]).first?.first != nil
        }
        let isSafeLinkIn30Min = Self.safeLinkFor30MinCache.contains(url)
        let isNormalProtocol = urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
        let urlIsSafe = self.safeUrlArray.contains(url)
        let isNeedToCheck = !(isInWhiteList || urlIsSafe || isHaveSafePrefix || isSafeLinkIn30Min) && isNormalProtocol
        return isNeedToCheck
    }
    private func newVersion_isNeedToDetect(url: URL) -> Bool {
        if AccountServiceAdapter.shared.currentAccountInfo.userID.isEmpty {
            return false
        }
        guard safeLinkEnable, let prefix = self.prefix else {
            return false
        }
        // 离线包虚拟域名不检测
        if OPWebAppManager.sharedInstance.isValidVhostInUrl(url) {
            Self.logger.info("vhost need not detect")
            return false
        }
        let urlString = url.absoluteString
        // 只检测http&https链接
        let isNormalProtocol = urlString.hasPrefix("http://") || urlString.hasPrefix("https://")
        if !isNormalProtocol {
            return false
        }
        // 安全链接不检测
        let isHaveSafePrefix = urlString.hasPrefix(prefix)
        if isHaveSafePrefix {
            return false
        }
        //30min内检测过的url不检测
        let isSafeLinkIn30Min = Self.safeLinkFor30MinCache.contains(url)
        if isSafeLinkIn30Min {
            return false
        }
        //经用户确认的safeUrlArray缓存中不检测
        let urlIsSafe = self.safeUrlArray.contains(url)
        if urlIsSafe {
            return false
        }
        //命中白名单setting正则匹配的不检测
        //https://bytedance.feishu.cn/docs/doccn635C6MV62V6eum2IASGlOd#gr0xYO
        let host = url.host ?? ""
        let isInWhiteList = self.secLinkWhitelist.contains { (regex) -> Bool in
            host.lf.matchingStrings(regex: regex, options: [.caseInsensitive]).first?.first != nil
        }
        if isInWhiteList {
            return false
        }
        return true
    }

    private func processUrl(_ url: URL, isFirstTapURL: Bool = false) -> URL? {
        if safeLinkEnable, let newUrl = getUnsafeTipUrl(url: url) {
            var url = url
            if url.path.isEmpty {
                url = url.appendingPathComponent("/")
            }
            self.unsafeUrlArray.insert(url)
            return newUrl
        }
        return nil
    }

    func seclinkPrecheck(url: URL, checkReuslt: @escaping (Bool) -> Swift.Void) {
        let isNeedDetect = self.isNeedToDetect(url: url)
        if isNeedDetect {
            self.judgeURL(url.absoluteString)
                .observeOn(queueScheduler)
                .subscribe(onNext: { [weak self] (res) in
                    if res {
                        self?.cacheSafeLinkFor30Min(url)
                    }
                    checkReuslt(res)
                }, onError: { error in
                    URLDetectServiceImpl.logger.error("seclink precheck error = \(error)")
                    checkReuslt(true)
            }).disposed(by: self.disposeBag)
        } else {
            checkReuslt(true)
        }
    }
    // 获取中间页（恶意提醒）的url
    private func getUnsafeTipUrl(url: URL) -> URL? {
        guard let prefix = self.prefix else { return nil }
        let target = encodeURIComponent(url.absoluteString)
        let params = encodeURIComponent("{location: 'messenger_chat'}")
        let finalURL = prefix + "?target=\(target)" + "&scene=messenger" + "&logParams=\(params)"
        let newUrl = URL(string: finalURL)
        return newUrl
    }

    private func encodeURIComponent(_ string: String) -> String {
        var set = CharacterSet()
        set.formUnion(CharacterSet.alphanumerics)
        set.formUnion(CharacterSet(charactersIn: "-_.!~*'()"))
        return string.addingPercentEncoding(withAllowedCharacters: set) ?? string
    }

    // 当提醒用户恶意后，判断用户是否点击继续访问
    private func isContinueToAccessUnsafeUrl(_ url: URL) -> Bool {
        if self.safeUrlArray.contains(url) {
            return false
        }
        return self.unsafeUrlArray.contains(url)
    }

    // 当请求返回200时的回调方法
    // 在这里可选择 继续/取消 加载
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, isAsync: Bool = false) {
        guard self.safeLinkEnable,
            let url = navigationResponse.response.url,
            self.isNeedToDetect(url: url) else {
                Self.logger.info("SecLink check skip, seclink disable or no need check")
                self.secLinkResultSubject.onNext(true)
                return
            }
        if let webview = webView as? LarkWebView {
            webview.monitorSeclinkService(url: url)
        }
        // 当提醒用户恶意后，判断用户是否点击继续访问
        if self.isContinueToAccessUnsafeUrl(url) {
            Self.logger.info("SecLink check skip, user access request")
            self.secLinkResultSubject.onNext(true)
            self.unsafeUrlArray = self.unsafeUrlArray.filter { (link) -> Bool in
                return link != url
            }
            self.safeUrlArray.insert(url)
            return
        }
        Self.logger.info("SecLink check processing, isAsync:\(isAsync)")
        if (Self.isTemporarilyCancelSyncDetect == false) && (isAsync == false) {
            // 开启同步检测
            self.judgeURL(url.absoluteString)
                .observeOn(queueScheduler)
                .subscribe(onNext: { [weak self] (res) in
                    self?.publishSubject.onNext(ProcessResult(type: .sync, isSafe: res))
                }, onError: { error in
                    Self.logger.error("judgeURL error, error = \(error)")
            }).disposed(by: self.disposeBag)
        }
        // 只处理第一个结果， 决定同步检测/异步检测
        self.publishSubject.asObservable()
            .subscribeOn(queueScheduler)
            .take(1)
            .flatMap({ [weak self] (res) -> Observable<Bool> in
                guard let `self` = self else { return .empty() }
                switch res.type {
                case .sync:
                    // 同步得到结果直接处理
                    if res.isSafe == false {
                        self.secLinkResultSubject.onNext(false)
                        return .just(false)
                    }
                    self.secLinkResultSubject.onNext(true)
                    return .just(true)
                case .async:
                    if res.isTimeOut {
                        self.processTimeOut()
                    }
                    // 先直接访问目标URL，然后开启异步检测
                    self.secLinkResultSubject.onNext(true)
                    return self.judgeURL(url.absoluteString)
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isSafe) in
                if isSafe {
                    // 将检测为安全的链接caceh30分钟
                    self?.cacheSafeLinkFor30Min(url)
                    return
                }
                guard let newUrl = self?.processUrl(url) else { return }
                let newRequset = URLRequest(url: newUrl)
                webView.load(newRequset)
            }, onError: { error in
                Self.logger.error("judgeURL error, error = \(error)")
            }).disposed(by: self.disposeBag)
        //如果本次检测是异步，立马发起异步检测,否则同步检测超时500ms后开启异步检测
        if isAsync {
            _ = Observable<Void>.empty().subscribeOn(queueScheduler).subscribe {[weak self] (_) in
                self?.publishSubject.onNext(ProcessResult(type: .async, isTimeOut: false))
            }
        } else {
            _ = Observable<Void>.empty().delay(.milliseconds(500), scheduler: queueScheduler)
                    .subscribe { [weak self] (_) in
                        self?.publishSubject.onNext(ProcessResult(type: .async, isTimeOut: true))
                    }
        }
    }

    private func cacheSafeLinkFor30Min(_ url: URL) {
        guard !Self.safeLinkFor30MinCache.contains(url) else { return }
        Self.logger.info("cache safe link for 30 min")
        Self.safeLinkFor30MinCache.insert(url)
        // 加速机制：缓存30分钟内检测成功的url
        let canOptimize = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.web.seclinkprecheck.enable"))
        if canOptimize {
            return
        }
        _ = Observable<Void>.empty().delay(.seconds(1800), scheduler: queueScheduler)
                .subscribe { (_) in
                    _ = Self.safeLinkFor30MinCache.remove(url)
                }
    }

    private func processTimeOut() {
        Self.logger.info("seclink async time out, is temporarily canceling sync detect:\(Self.isTemporarilyCancelSyncDetect)")
        guard Self.isTemporarilyCancelSyncDetect == false else { return }
        if Self.timeoutArray.count == 3 {
            Self.timeoutArray.removeFirst()
        }
        Self.timeoutArray.append(Int64(Date().timeIntervalSince1970))
        // 容错机制： 同步接口超过三次，暂时取消同步检测10分钟
        if Self.isTimeOut3TimesFor30Min {
            Self.logger.info("seclink time out 3 times for 30min, canceling sync detect")
            Self.isTemporarilyCancelSyncDetect = true
            _ = Observable<Void>.empty().delay(.seconds(600), scheduler: queueScheduler)
                    .subscribe { (_) in
                        Self.isTemporarilyCancelSyncDetect = false
                    }
        }
    }

    func webViewDidFinish(url: URL?) {
        // when the link of user click will load finish or click back tab, detectingLinkArray should be removed
        guard self.safeLinkEnable else { return }
        Self.logger.info("seclink webView did finish, detecting link array is cleared")
        if let prefix = self.prefix, let url = url, !url.absoluteString.hasPrefix(prefix) {
            self.unsafeUrlArray.removeAll()
        }
    }

    func webViewDidFailProvisionalNavigation(error: Error, url: URL?) {
        guard self.safeLinkEnable else { return }
        Self.logger.info("seclink webView did fail provisional nav, detecting link array is cleared")
        if let prefix = self.prefix, let url = url, !url.absoluteString.hasPrefix(prefix) {
            self.unsafeUrlArray.removeAll()
        }
    }

    func webViewDidFail(error: Error, url: URL?) {
        guard self.safeLinkEnable else { return }
        Self.logger.info("seclink webView failed, detecting link array is cleared")
        if let prefix = self.prefix, let url = url, !url.absoluteString.hasPrefix(prefix) {
            self.unsafeUrlArray.removeAll()
        }
    }
}
