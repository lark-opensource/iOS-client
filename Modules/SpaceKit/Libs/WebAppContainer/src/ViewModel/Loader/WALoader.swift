//
//  WALoader.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/15.
//

import Foundation
import LKCommonsLogging
import SKFoundation
import WebKit


public class WALoader: NSObject, WABridgeLoaderDelegate {
    static let logger = Logger.log(WALoader.self, category: WALogger.TAG)
    weak var viewModel: WAContainerViewModel?
    
    private(set) var loadStatus: WALoadStatus = .start
    private(set) var preloadStatus = ObserableWrapper<WAPreloadStatus>(.none)
    var loadType: LoadType = .online
    
    var webView: WAWebView? {
        viewModel?.webView
    }
    
    var preloadURL: URL? {
        viewModel?.preloadURL
    }
    
    init(_ viewModel: WAContainerViewModel) {
        self.viewModel = viewModel
        super.init()
        viewModel.lifeCycleObserver.addListener(self)
    }
    
    func load(forceLoadUrl: Bool = false) {  
        guard let viewModel = self.viewModel else {
            return
        }
        let timeout = viewModel.config.loadingTimeout
        let showLoading = viewModel.config.openConfig?.showLoading ?? false
        Self.logger.info("load start, forceLoadUrl:\(forceLoadUrl), loading:\(showLoading),timout:\(timeout)", tag: LogTag.open.rawValue)
        if showLoading {
            self.perform(#selector(onOpenTimeout), with: nil, afterDelay: timeout)
        }
        realLoadUrl()
    }
    
    func preload(_ preloadUrl: URL) {
        spaceAssertionFailure("loader not support preload")
    }

    func onClear() {
        Self.logger.info("onClear", tag: LogTag.open.rawValue)
        self.preloadStatus.bind(target: self, block: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(onOpenTimeout), object: nil)
    }
    
    @objc
    func onOpenTimeout() {
        Self.logger.info("onOpenTimeout", tag: LogTag.open.rawValue)
        self.updateLoadStatus(.overtime)
    }
    
    public func onTemplateReady() {
        //WABridgeLoaderDelegate
    }
}

extension WALoader {
    func realLoadUrl() {
        guard let url = self.viewModel?.currentURL else {
            return
        }
        self.loadType = .online
        self.updateLoadStatus(.loading(.loadUrl))
        Self.logger.info("webview realLoadUrl", tag: LogTag.open.rawValue)
        _ = webView?.load(URLRequest(url: url))
    }
    
    func updateLoadStatus(_ newStatus: WALoadStatus) {
        Self.logger.info("loadStatus change: \(self.loadStatus) -> \(newStatus)", tag: LogTag.open.rawValue)
        let oldStatus = self.loadStatus
        guard oldStatus != newStatus else {
            return
        }
        if newStatus == .success {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(onOpenTimeout), object: nil)
        }
        
        self.loadStatus = newStatus
        
        //根据状态更新打点时间
        if case let .loading(loadingStage) = newStatus {
            if loadingStage == .loadUrl || loadingStage == .render {
                let startLoadUrlTime = WAPerformanceTiming.getTimeStamp()
                self.viewModel?.timing.startLoadUrl = startLoadUrlTime
                self.viewModel?.timing.renderState.updateStart(startLoadUrlTime)
            }
        }
        else if newStatus.isFinish {
            self.viewModel?.timing.renderState.updateEnd(WAPerformanceTiming.getTimeStamp())
            self.viewModel?.tracker.reportOpenFinishEvent()
        }
        
        self.viewModel?.delegate?.onLoadStatusChange(old: oldStatus, new: newStatus)
    }
    
    func injectEnvInfo() {
//        let firstStartLoadUrlTS = self.viewModel?.timing.firstStartLoadUrlTS ?? 0
//        Self.logger.info("injectEnvInfo,\(firstStartLoadUrlTS)", tag: LogTag.open.rawValue)
//        self.viewModel?.bridge.eval("window.__webviewCreateTime = \(firstStartLoadUrlTS)")
    }
}

extension WALoader: WAContainerLifeCycleListener {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        injectEnvInfo()
    }
}

extension WATracker {
    func reportOpenFinishEvent() {
        guard let container, let loadStatus = container.loader?.loadStatus else { return }
        var result = ""
        var code = 0
        switch loadStatus {
        case .error(let error):
            code = error.errorCode
            result = "failed"
        case .success:
            result = "success"
        case .cancel:
            result = "cancel"
            code = LoadErrorCode.cancel.rawValue
        case .overtime:
            result = "timeout"
            code = LoadErrorCode.overtime.rawValue
        default:
            spaceAssertionFailure("unknow loadStatus")
            result = "\(loadStatus)"
        }
        let preloadType = self.config.preloadConfig?.policy ?? .none
        let loadType = container.loader?.loadType ?? .online
        let timing = container.timing
        
        let params: [String: Any] = [ReportKey.result.rawValue: result,
                                     ReportKey.code.rawValue: code,
                                     ReportKey.preload_type.rawValue: preloadType.rawValue,
                                     ReportKey.load_type.rawValue: loadType.rawValue,
                                     ReportKey.unzip_stage_start.rawValue: timing.unzipState.start - timing.routeState.start,
                                     ReportKey.unzip_stage_cost.rawValue: timing.unzipState.cost,
                                     ReportKey.preload_stage_start.rawValue: timing.preloadState.start - timing.routeState.start,
                                     ReportKey.preload_stage_cost.rawValue: timing.preloadState.cost,
                                     ReportKey.render_stage_start.rawValue: timing.renderState.start - timing.routeState.start,
                                     ReportKey.render_stage_cost.rawValue: timing.renderState.cost,
                                     ReportKey.cost.rawValue: timing.openCostTime]
       Self.logger.info("reportOpenFinish, \(String(describing: params.toJSONString()))")
        self.log(event: .openFinish, parameters: params)
    }
}
