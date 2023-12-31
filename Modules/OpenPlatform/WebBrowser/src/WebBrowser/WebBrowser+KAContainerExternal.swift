//
//  WebBrowser+KAWebContainer.swift
//  WebBrowser
//
//  Created by jiangzhongping on 2023/11/2.
//

import LarkSetting
import OPFoundation
#if canImport(LKWebContainerExternal)
import LKWebContainerExternal
#endif

public extension WebBrowser {
    
#if canImport(LKWebContainerExternal)
    
    private static let kWebContainerExternalTimeoutTime = 30.0
    
    //MARK: 处理多实例onOpen
    func handleMultiExternalOnOpen(url: URL) -> Bool {
        
        let containers = KAWebContainerExternal.shared.containers
        let containersCount = containers.count
        if containersCount <= 0 {
            Self.logger.info("[webext] containers is empty, return false")
            return false
        }
        
        let multiExternalHandleEnable = self.multiExternalHandleEnable()
        if (multiExternalHandleEnable) {
            // 超时加载处理
            if self.externalTimeoutHandleEnable() {
                self.startExternalTimeoutTimer(url: url)
            }
            
            var onSuccessCount = 0
            var hasOnOpenFail = false
            containers.forEach { (container) in
                Self.logger.info("[webext] container onopen:\(container), kaid:\(container.kaIdentity()) ")
                container.onOpen(url: url.absoluteString, onSuccess: { [weak self, weak container] in
                    onSuccessCount = onSuccessCount + 1
                    if let weakContainer = container {
                        Self.logger.info("[webext] container onsuccess:\(weakContainer), successcount:\(onSuccessCount), totalcount:\(containersCount)")
                    }
                    if(containersCount == onSuccessCount) {
                        OPFoundation.executeOnMainQueueAsync {
                            self?.externalOnOpenSuccess(url: url)
                        }
                    }
                }, onFail: {  [weak self, weak container] errCode in
                    if let weakContainer = container {
                        Self.logger.info("[webext] container onfail:\(weakContainer)")
                    }
                    if (!hasOnOpenFail) {
                        hasOnOpenFail = true
                        OPFoundation.executeOnMainQueueAsync {
                            self?.externalOnOpenFail(code: NSNumber(value: errCode), container: container)
                        }
                    }
                })
            }
        }
        return multiExternalHandleEnable
    }
    
    //MARK: 处理多实例OnClose
    func handleMultiExternalOnClose() -> Bool {
       
        let containers = KAWebContainerExternal.shared.containers
        if containers.count <= 0 {
            Self.logger.info("[webext] containers is empty, return")
            return false
        }
        
        let multiExternalHandleEnable = self.multiExternalHandleEnable()
        if multiExternalHandleEnable {
            if self.externalTimeoutHandleEnable() {
                self.stopExternalTimeoutTimer()
            }
            containers.forEach { (container) in
                Self.logger.info("[webext] container onclose:\(container), kaid:\(container.kaIdentity()) ")
                container.onClose(url: self.browserLastestURL?.absoluteString ?? "")
            }
        } else {
            Self.logger.info("[webext] container onclose nothing to do")
        }
        return multiExternalHandleEnable
    }

    private func startExternalTimeoutTimer(url: URL) {
        
        Self.logger.info("[webext] startExternalTimeoutTimer")
        let timer = Timer(timeInterval: WebBrowser.kWebContainerExternalTimeoutTime, repeats: false, block: { [weak self] (_) in
            guard let self = self else { return }
            self.externalFinalLoadURL(url: url)
        })
        RunLoop.current.add(timer, forMode: .common)
        sdpTimeoutTimer = timer
    }
    
    private func stopExternalTimeoutTimer() {
        
        if (sdpTimeoutTimer != nil) {
            Self.logger.info("[webext] stopExternalTimeoutTimer")
            sdpTimeoutTimer?.invalidate()
            sdpTimeoutTimer = nil
        }
    }
    
    @objc
    private func externalOnOpenSuccess(url: URL) {
    
        Self.logger.info("[webext] externalOnOpenSuccess")
        if self.multiExternalHandleEnable() {
            self.stopExternalTimeoutTimer()
        }
        self.externalFinalLoadURL(url: url)
    }
    
    @objc
    private func externalFinalLoadURL(url: URL) {

        Self.logger.info("[webext] final loadURL")
        loadURL(url, originRefererURL: originRefererURL)
    }
    
    @objc
    private func externalOnOpenFail(code: NSNumber, container: KAWebContainerProtocol?) {
        // code为预留参数, 用于打印外部入参情况, 暂不作为定制错误页有效值使用
        Self.logger.info("[webext] externalOnOpenFail, code: \(code.intValue)")
        if self.externalTimeoutHandleEnable() {
            self.stopExternalTimeoutTimer()
        }
        
        self.handleWebCustomError(container: container)
    }
    
    //处理错误页
    private func handleWebCustomError(container: KAWebContainerProtocol?) {
        guard let errorPageItem = extensionManager.resolve(ErrorPageExtensionItem.self) else {
            errorpageLogger.info("error page item is nil")
            return
        }
        guard let navigationDelegate = errorPageItem.navigationDelegate as? ErrorPageWebBrowserNavigation else {
            errorpageLogger.info("error page item delegate is nil")
            return
        }

        let customConfig = self.getSDPErrorPageConfig(container: container)
        navigationDelegate.handleWebCustomError(browser: self, forCustom: customConfig)
    }
    
    private func getSDPErrorPageConfig(container: KAWebContainerProtocol?) -> String? {
        guard let container = container, let config = container.errorPageConfig() else {
            errorpageLogger.info("errorPageConfig is nil")
            return nil
        }
        let configDict: [String: Any] = ["customTitle": config.title ?? "",
                                         "customContentTitle": config.contentTitle ?? "",
                                         "customContent": config.content ?? "",
                                         "hideBigImage": config.hideBigImage ?? false,
                                         "customVPNBtnConfig": ["hideBtn": config.vpnConfig?.hide ?? false,
                                                                "customText": config.vpnConfig?.text ?? "",
                                                                "customEvent": config.vpnConfig?.eventName ?? "",
                                                                "customExtraString": config.vpnConfig?.eventExtra ?? ""],
                                         "customRefreshBtnConfig": ["hideBtn": config.refreshConfig?.hide ?? false,
                                                                    "customText": config.refreshConfig?.text ?? "",
                                                                    "customEvent": config.refreshConfig?.eventName ?? "",
                                                                    "customExtraString": config.refreshConfig?.eventExtra ?? ""]]
        guard JSONSerialization.isValidJSONObject(configDict) else {
            errorpageLogger.error("error page config dict is not valid json")
            return nil
        }
        guard let data = try? JSONSerialization.data(withJSONObject: configDict, options: []) else {
            errorpageLogger.error("error page config can not produce data")
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    
    /// MARK - FG
    private func multiExternalHandleEnable() -> Bool {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.webrowser.multiexternal.enable")
    }
    
    private func externalTimeoutHandleEnable() -> Bool {
        return FeatureGatingManager.realTimeManager.featureGatingValue(with: "openplatform.webbrowser.sdp.handletimeout.enable")
    }
    
#else
    func handleMultiExternalOnOpen(url: URL) -> Bool {
        return false
    }
    
    func handleMultiExternalOnClose()  -> Bool {
        return false
    }
#endif
}
