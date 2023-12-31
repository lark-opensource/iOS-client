//
//  DetectPageAPIs.swift
//  EcosystemWeb
//
//  Created by ByteDance on 2022/10/19.
//

import Foundation
import LKCommonsLogging
import AppContainer
import LarkContainer
import LarkRustClient
import RustPB
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import WebBrowser
import LarkFoundation
import TTMicroApp
import RxSwift
import LarkSetting
import ECOInfra

// MARK: DetectPagePlugin
final class DetectPagePlugin: OpenBasePlugin {
    private static let logger = Logger.ecosystemWebLog(DetectPagePlugin.self, category: "DetectPagePlugin")
    private var rustService: RustService?
    private var detectCallback: ((OpenAPIBaseResponse<OPWebDetectNetStatusResult>) -> Void)?
    private var disposeBag = DisposeBag()
    private var disposable: Disposable?
    private var hasRegisterNetConfigCommand: Bool = false
    private var isConnectPrivateNet: Bool? = nil
    private var timer: Timer?
    private var retryTimes: Int = 0
    
    deinit {
        cancelTimer()
        disposePushHandler()
        Self.logger.debug("DetectPagePlugin deinit")
    }
    
    required init(resolver: UserResolver) {
        rustService = try? resolver.resolve(assert: RustService.self)
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "getWebDetectNetStatus", pluginType: Self.self, resultType: OPWebDetectNetStatusResult.self) { (this, params, context, callback) in
            guard !FeatureGatingManager.realTimeManager.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.ecosystemweb.detectnetstatus.disable")) else {// user:global
                let errorMsg = "fg disable when call getWebDetectNetStatus api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let errorMsg = "gadgetContext is nil when call getWebDetectNetStatus api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let errorMsg = "apiContext.controller is not WebBrowser when call getWebDetectNetStatus api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            guard browser.webview.url?.scheme == BrowserInternalScheme else {
                let errorMsg = "url.scheme is not \(BrowserInternalScheme) when call getWebDetectNetStatus api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            // 检测办公网络环境
            this.handleHostsReachable()
            // 检测网络状态等情况
            this.handleWebDetectNetStatus(callback: callback)
        }
        
        registerAsyncHandler(for: "getWebDetectBaseInfo", resultType: OPWebDetectBaseInfoResult.self) { (params, context, callback) in
            guard let apiContext = context.additionalInfo["gadgetContext"] as? OPAPIContextProtocol else {
                let errorMsg = "gadgetContext is nil when call getWebDetectBaseInfo api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            guard let browser = apiContext.controller as? WebBrowser else {
                let errorMsg = "apiContext.controller is not WebBrowser when call getWebDetectBaseInfo api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                    .setMonitorMessage(errorMsg)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            guard browser.webview.url?.scheme == BrowserInternalScheme else {
                let errorMsg = "url.scheme is not \(BrowserInternalScheme) when call getWebDetectBaseInfo api"
                let error = OpenAPIError(errno: OpenAPICommonErrno.internalError)
                context.apiTrace.error(errorMsg)
                callback(.failure(error: error))
                return
            }
            let appVersion = "V\(LarkFoundation.Utils.appVersion)"
            var osVersion = "iOS \(UIDevice.current.systemVersion)"
            Self.logger.info("getWebDetectBaseInfo appVersion: \(appVersion), osVersion: \(osVersion)")
            callback(.success(data: OPWebDetectBaseInfoResult(appVersion: appVersion, osVersion: osVersion)))
        }
    }
    
    private func handleWebDetectNetStatus(callback: @escaping(OpenAPIBaseResponse<OPWebDetectNetStatusResult>) -> Void) {
        detectCallback = callback
        
        registerPushNetInterfaceConfigV2()
        
        var request = RustPB.Tool_V1_StarDetectingNetworkRequest()
        request.sessionID = randomSessionId(length: 9)
        rustService?.sendAsyncRequest(request).subscribe(onNext: { _ in }, onError: { _ in
        }).disposed(by: disposeBag)
    }
    
    private func registerPushNetInterfaceConfigV2() {
        guard !hasRegisterNetConfigCommand else {
            Self.logger.debug("already register pushNetInterfaceConfigV2 command return")
            return
        }
        
        disposable = SimpleRustClient.global.registerPushHandler(factories: [Command.pushNetInterfaceConfigV2: { RustWebDetectPushHandler(resolver: self.userResolver) }])
        try? userResolver.userPushCenter.observable(for: DetectPageNetConfig.self).subscribe(onNext: { [weak self] push in
            guard let self = self, let callback = self.detectCallback else {
                Self.logger.info("self is nil when pushNetInterfaceConfigV2 response")
                return
            }
            let isProxy: Bool = push.useProxy
            // 若网络诊断推送时内网判断结束, 则直接返回前端成功结果
            if let isConnectPrivateNet = self.isConnectPrivateNet {
                let isConnectNet: Bool = BDPNetworking.isNetworkConnected()
                let isPrivateNet: Bool = isConnectPrivateNet
                callback(.success(data: OPWebDetectNetStatusResult(connect: isConnectNet, privateNet: isPrivateNet, proxy: isProxy)))
                Self.logger.info("getWebDetectNetStatus connectNet: \(isConnectNet), connectPrivateNet: \(isPrivateNet), connectProxy: \(isProxy), normal")
            } else {
                DispatchQueue.main.async {
                    self.cancelTimer()
                    // 若网络诊断推送时内网判断进行, 则启动3秒轮询检查结果, 超过15秒按照默认内网返回前端结果
                    let timer = Timer.bdp_scheduledRepeatedTimer(withInterval: 3, target: self) { [weak self] timer in
                        Self.logger.debug("current timer \(self?.retryTimes) times")
                        guard let self = self else {
                            timer.invalidate()
                            Self.logger.info("self is nil when pushNetInterfaceConfigV2 response timer handler")
                            return
                        }
                        // 若定时器轮询时内网判断结束, 则直接返回前端成功结果
                        if let isConnectPrivateNet = self.isConnectPrivateNet {
                            timer.invalidate()
                            let isConnectNet: Bool = BDPNetworking.isNetworkConnected()
                            let isPrivateNet: Bool = isConnectPrivateNet
                            callback(.success(data: OPWebDetectNetStatusResult(connect: isConnectNet, privateNet: isPrivateNet, proxy: isProxy)))
                            Self.logger.info("getWebDetectNetStatus connectNet: \(isConnectNet), connectPrivateNet: \(isPrivateNet), connectProxy: \(isProxy), \(self.retryTimes) times")
                            return
                        }
                        if self.retryTimes >= 4 {
                            timer.invalidate()
                            let isConnectNet: Bool = BDPNetworking.isNetworkConnected()
                            var isPrivateNet: Bool = true
                            callback(.success(data: OPWebDetectNetStatusResult(connect: isConnectNet, privateNet: isPrivateNet, proxy: isProxy)))
                            Self.logger.info("getWebDetectNetStatus connectNet: \(isConnectNet), connectPrivateNet: \(isPrivateNet), connectProxy: \(isProxy), timeout")
                            return
                        }
                        self.retryTimes += 1
                    }
                    RunLoop.main.add(timer, forMode: .common)
                    self.timer = timer
                }
            }
        }).disposed(by: disposeBag)
        
        hasRegisterNetConfigCommand = true
    }
    
    private func disposePushHandler() {
        if let disposable = disposable {
            disposable.dispose()
        }
        hasRegisterNetConfigCommand = false
    }
    
    private func handleHostsReachable() {
        // 清理上次结果
        isConnectPrivateNet = nil
        // 若Settings下发的pingHost列表为空, 则保持默认true
        guard let errorPageInfo = ECOConfig.service().getDictionaryValue(for: "openplatform_error_page_info"),
              let pingHostsArr = errorPageInfo["pingHosts"] as? [String] else {
            isConnectPrivateNet = true
            return
        }
        
        var pingRequest = RustPB.Openplatform_V1_IsHostsReachableRequest()
        pingRequest.hosts = pingHostsArr
        var startTs = Date().timeIntervalSince1970
        rustService?.sendAsyncRequest(pingRequest).subscribe(onNext: { [weak self] (response: Openplatform_V1_IsHostsReachableResponse) in
            guard let self = self else { return }
            let isReachable = response.isReachable
            self.isConnectPrivateNet = isReachable
            let totalPingTs = (Date().timeIntervalSince1970 - startTs) * 1000
            Self.logger.info("getWebDetectNetStatus pingHost response, isReachable: \(isReachable), duration: \(totalPingTs)")
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            self.isConnectPrivateNet = false
            let totalPingTs = (Date().timeIntervalSince1970 - startTs) * 1000
            Self.logger.info("getWebDetectNetStatus pingHost response, error: \(error), duration: \(totalPingTs)")
        }).disposed(by: disposeBag)
    }
    
    private func randomSessionId(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in
            (letters.randomElement() ?? "a")
        })
    }
    
    private func cancelTimer() {
        retryTimes = 0
        guard timer != nil else {
            return
        }
        Self.logger.debug("timer did cancel")
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Detect Result
final class OPWebDetectNetStatusResult: OpenAPIBaseResult {
    public let connectNet: Bool
    public let connectPrivateNet: Bool
    public let connectProxy: Bool
    
    public init(connect net: Bool, privateNet: Bool, proxy: Bool) {
        self.connectNet = net
        self.connectPrivateNet = privateNet
        self.connectProxy = proxy
        super.init()
    }
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        [
            "connectNet": connectNet,
            "connectPrivateNet": connectPrivateNet,
            "connectProxy": connectProxy
        ]
    }
}

final class OPWebDetectBaseInfoResult: OpenAPIBaseResult {
    public let appVersion: String
    public let osVersion: String
    
    public init(appVersion: String, osVersion: String) {
        self.appVersion = appVersion
        self.osVersion = osVersion
        super.init()
    }
    
    public override func toJSONDict() -> [AnyHashable : Any] {
        [
            "appVersion": appVersion,
            "osVersion": osVersion
        ]
    }
}
