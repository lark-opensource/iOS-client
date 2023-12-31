//
//  WAOfflineLoader.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import SKFoundation

class WAOfflineLoader: WALoader {
    
    var renderAfterPreloadReady = false
    
    override init(_ viewModel: WAContainerViewModel) {
        super.init(viewModel)
        bindPreloadReady()
    }
    
    override func load(forceLoadUrl: Bool = false) {
        guard let viewModel = self.viewModel else {
            return
        }
        renderAfterPreloadReady = false
        let supportPreload = viewModel.config.preloadConfig?.policy == .preloadTemplate
        let timeout = viewModel.config.loadingTimeout
        let showLoading = viewModel.config.openConfig?.showLoading ?? false
        
        Self.logger.info("(offline) load start, forceLoadUrl:\(forceLoadUrl),loadStatus:\(loadStatus) preloadStatus:\(self.preloadStatus.value), loading:\(showLoading),timout:\(timeout)", tag: LogTag.open.rawValue)
        
        if showLoading {
            self.perform(#selector(onOpenTimeout), with: nil, afterDelay: timeout)
        }
        
        if forceLoadUrl {
            realLoadUrl()
        } else if supportPreload, self.preloadStatus.value.isReady {
            render()
        } else if self.loadStatus.isPreloading, !self.preloadStatus.value.isFail {
            Self.logger.info("try load url but is preloading, wait", tag: LogTag.open.rawValue)
            renderAfterPreloadReady = true
        } else {
            Self.logger.warn("direct load url in offline loader", tag: LogTag.open.rawValue)
            realLoadUrl()
        }
    }
    
    override func preload(_ preloadUrl: URL) {
        guard let config = self.viewModel?.config else {
            Self.logger.error("preloadurl is invalid", tag: LogTag.open.rawValue)
            return
        }
        let necessaryCookieKeys = config.resInterceptConfig?.necessaryCookieKeys
        guard WAContainerPreloader.checkCookieFor(preloadUrl.absoluteString, checkCookies: necessaryCookieKeys) else {
            Self.logger.error(" check cookie failed, dont preload, key: \(String(describing: necessaryCookieKeys))", tag: LogTag.open.rawValue)
            return
        }
        guard let pkgStatus = self.viewModel?.offlineManager?.status.value else {
            Self.logger.error("offlineManager is invalid", tag: LogTag.open.rawValue)
            return
        }
        self.updatePreloadStatus(.none)
        switch pkgStatus {
        case .none:
            //离线包未就绪，待检测完成后再preload
            Self.logger.info("pause preload wait for offlinePackge ready", tag: LogTag.open.rawValue)
            self.updatePreloadStatus(.checkPkg)
            self.viewModel?.timing.unzipState.updateStart(WAPerformanceTiming.getTimeStamp())
            self.viewModel?.offlineManager?.status.bind(target: self) { [weak self] newPkgStatus in
                guard let self = self else { return }
                guard self.preloadStatus.value == .checkPkg else {
                    Self.logger.error("offlinePackge status:\(newPkgStatus),invalid preloadStatus:\(self.preloadStatus.value)", tag: LogTag.open.rawValue)
                    return
                }
                switch newPkgStatus {
                case .failed:
                    Self.logger.error("offlinePackge is unavaliable, stop preload", tag: LogTag.open.rawValue)
                    self.updatePreloadStatus(.fail)
                case .ready:
                    Self.logger.info("offlinePackge is ready, start preload", tag: LogTag.open.rawValue)
                    self.viewModel?.timing.unzipState.updateEnd(WAPerformanceTiming.getTimeStamp())
                    DispatchQueue.safetyAsyncMain { [weak self] in
                        self?.preloadTemplate(config: config, preloadUrl: preloadUrl)
                    }
                case .none:
                    break //ignore
                }
            }
        case .ready:
            preloadTemplate(config: config, preloadUrl: preloadUrl)
        case .failed:
            Self.logger.error("offline package is invalid", tag: LogTag.open.rawValue)
        }
    }
    
    override func onClear() {
        super.onClear()
        if self.viewModel?.config.supportWebViewReuse ?? false {
            Self.logger.info("clear: eval tt_open_clear", tag: LogTag.open.rawValue)
            self.viewModel?.bridge.eval("window.tt_open_clear();")
        } else {
            Self.logger.info("clear: empty", tag: LogTag.open.rawValue)
        }
        renderAfterPreloadReady = false
        updateLoadStatus(.start) //重置状态
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(onPreloadTimeout), object: nil)
    }
    
    override func onTemplateReady() {
        Self.logger.info("onTemplateReady", tag: LogTag.open.rawValue)
        updatePreloadStatus(.complete)
    }
    
    @objc
    func onPreloadTimeout() {
        Self.logger.error("onPreloadTimeout", tag: LogTag.open.rawValue)
        updatePreloadStatus(.fail)
        self.preloadStatus.bind(target: self, block: nil)
    }
    
}

extension WAOfflineLoader {
    
    private func render() {
        guard let url = self.viewModel?.currentURL else {
            return
        }
        self.loadType = .offline
        self.updateLoadStatus(.loading(.render))
        Self.logger.info("render: eval tt_open_render", tag: LogTag.open.rawValue)
        let params = ["url": url.absoluteString]
        self.viewModel?.bridge.eval("window.tt_open_render", params: params)
    }
    
    private func preloadTemplate(config: WebAppConfig, preloadUrl: URL) {
        let timeout = config.preloadTimeout
        Self.logger.info("start preload Template webview:\(preloadUrl.absoluteString), timeout:\(timeout)", tag: LogTag.open.rawValue)
        self.updatePreloadStatus(.loading)
        _ = webView?.load(URLRequest(url: preloadUrl))
        self.perform(#selector(onPreloadTimeout), with: nil, afterDelay: timeout)
    }
    
    private func bindPreloadReady() {
        self.preloadStatus.bind(target: self) { [weak self] preloadStatus in
            guard let self, preloadStatus.isReady else { return }
            Self.logger.info("on preload ready", tag: LogTag.open.rawValue)
            self.preloadStatus.bind(target: self, block: nil)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(onPreloadTimeout), object: nil)
            if renderAfterPreloadReady {
                Self.logger.info("render after preload ok", tag: LogTag.open.rawValue)
                self.render()
            }
        }
    }
    
    func updatePreloadStatus(_ newStatus: WAPreloadStatus) {
        if self.preloadStatus.value.isFail {
            Self.logger.warn("Preload is fail, cannot update status:\(newStatus)", tag: LogTag.open.rawValue)
            return
        }
        Self.logger.info("PreloadStatus change: \(self.preloadStatus.value) -> \(newStatus)", tag: LogTag.open.rawValue)
        
        //根据状态更新打点时间
        if newStatus == .none {
            self.viewModel?.timing.preloadState.updateStart(WAPerformanceTiming.getTimeStamp())
        } else if newStatus == .complete {
            self.viewModel?.timing.preloadState.updateEnd(WAPerformanceTiming.getTimeStamp())
        }
        
        let oldStatus = self.preloadStatus.value
        guard oldStatus != newStatus else {
            return
        }
        if newStatus.isLoading {
            //同步更新加载状态
            self.updateLoadStatus(.loading(.preload))
        }
        
        self.preloadStatus.value = newStatus
    }
}
