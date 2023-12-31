//
//  UtilPowerConsumptionTrackService.swift
//  SKBrowser
//
//  Created by chensi(陈思) on 2022/9/4.
//  


import Foundation
import SKCommon
import SKFoundation
import SKInfra
import Heimdallr
import LarkContainer
import SpaceInterface
import LKCommonsTracker

class UtilPowerConsumptionTrackService: BaseJSService, DocsJSServiceHandler {
    
    private let scrollObserver = ScrollObserver()
    
    private var fepkgVersion: String? // 暂存, 避免重复计算
    
    private var h5RecordCodingOpt = false // 暂存, 避免重复计算
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
        model.scrollProxy?.addObserver(self)
        scrollObserver.scrollStateChanged = { [weak self] (oldValue, newValue) in
            guard let viewId = self?.model?.jsEngine.editorIdentity else { return }
            let scene = PowerConsumptionStatisticScene.docScroll(contextViewId: viewId)
            if oldValue, !newValue {
                PowerConsumptionExtendedStatistic.markEnd(scene: scene)
            } else if !oldValue, newValue {
                PowerConsumptionExtendedStatistic.markStart(scene: scene)
                
                let type = self?.model?.browserInfo.docsInfo?.inherentType.name ?? ""
                let key1 = PowerConsumptionStatisticParamKey.docType
                PowerConsumptionExtendedStatistic.updateParams(type, forKey: key1, scene: scene)
                
                let key2 = PowerConsumptionStatisticParamKey.isUserScroll
                let isTracking = self?.model?.scrollProxy?.getScrollView()?.isTracking ?? false
                PowerConsumptionExtendedStatistic.updateParams(isTracking, forKey: key2, scene: scene)
                
                let key3 = PowerConsumptionStatisticParamKey.isInVC
                let isInVC = self?.model?.browserInfo.isInVideoConference ?? false
                PowerConsumptionExtendedStatistic.updateParams(isInVC, forKey: key3, scene: scene)
            }
        }
        PowerConsumptionExtendedStatistic.shared.docsMSContext = self
        
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let enable = ur.docs.staticFG(CCMFGKeys.CS.h5RecordCodingOpt)
        h5RecordCodingOpt = enable
    }
    
    var handleServices: [DocsJSService] {
        [.reportSendEvent,
         .utilOpenImage,
         .closeImageViewer,
         .openImageForComment,
         .simulateCloseCommentImage,
         .commentShowCards]
    }
    
    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.reportSendEvent.rawValue:
            handleSaveDocsMeta(params: params)
        case DocsJSService.utilOpenImage.rawValue, DocsJSService.openImageForComment.rawValue:
            handleOpenImage()
        case DocsJSService.commentShowCards.rawValue:
            handleShowComment()
        default:
            break
        }
    }
    
    private func handleSaveDocsMeta(params: [String: Any]) {
        guard let data = params["data"] as? [String: Any] else { return }
        let blockCount = (data["total_block_count"] as? Int) ?? 0
        guard blockCount > 0 else {
            return
        }
        if let token = model?.browserInfo.docsInfo?.token, let scene = getPowerStatisticScene() {
            let key1 = PowerConsumptionStatisticParamKey.blockCount
            PowerConsumptionStatistic.updateParams(blockCount, forKey: key1, token: token, scene: scene)
            HMDInjectedInfo.default().setCustomFilterValue(blockCount, forKey: InjectedCCMInfoKey.blockCount.rawValue)
        }
    }
    
    private func handleOpenImage() {
        let name = PowerConsumptionStatisticEventName.assetBrowseEnter
        PowerConsumptionExtendedStatistic.addEvent(name: name, params: nil)
    }
    
    private func handleShowComment() {
        let name = PowerConsumptionStatisticEventName.commentShow
        PowerConsumptionExtendedStatistic.addEvent(name: name, params: nil)
    }
    
    private func updateHMDBizInfo() {
        guard let docsInfo = model?.browserInfo.docsInfo else { return }
        let defaultInfo = HMDInjectedInfo.default()
        
        defaultInfo.setCustomFilterValue(docsInfo.inherentType.name, forKey: InjectedCCMInfoKey.docType.rawValue)
        defaultInfo.setCustomFilterValue(docsInfo.token, forKey: InjectedCCMInfoKey.docToken.rawValue)
        let inMS = model?.browserInfo.isInVideoConference ?? false
        defaultInfo.setCustomFilterValue(inMS, forKey: InjectedCCMInfoKey.isMagicshare.rawValue)
        if fepkgVersion == nil {
            fepkgVersion = DocsSDK.getCurUsingPkgInfo().version
        }
        defaultInfo.setCustomFilterValue(UserScopeNoChangeFG.HYF.asideCommentHeightOptimize, forKey: InjectedCCMInfoKey.asidecommentHeightOptFG.rawValue)
        defaultInfo.setCustomFilterValue(fepkgVersion ?? "unknown", forKey: InjectedCCMInfoKey.fepkgVersion.rawValue)
        defaultInfo.setCustomFilterValue(msWebviewReuseFGEnable, forKey: InjectedCCMInfoKey.msWebviewReuseFG.rawValue)
        defaultInfo.setCustomFilterValue(msWebviewReuseABEnable, forKey: InjectedCCMInfoKey.msWebviewReuseAB.rawValue)
        
        let downgradeEnable: Bool
        if let optConfig = try? model?.userResolver.resolve(assert: PowerOptimizeConfigProvider.self) {
            downgradeEnable = optConfig.vcPowerDowngradeEnable
        } else {
            downgradeEnable = false
        }
        defaultInfo.setCustomFilterValue(downgradeEnable, forKey: InjectedCCMInfoKey.vcPowerDowngrade.rawValue)
    }
}

private extension UtilPowerConsumptionTrackService {
    
    func getPowerStatisticScene() -> PowerConsumptionStatisticScene? {
        if let viewId = model?.jsEngine.editorIdentity {
            return .docView(contextViewId: viewId)
        }
        return nil
    }
    
    var msWebviewReuseFGEnable: Bool {
        return UserScopeNoChangeFG.CS.msWebviewReuseEnable
    }
    
    var msWebviewReuseABEnable: Bool {
        let abEnable: Bool
        if let value = Tracker.experimentValue(key: "docs_ms_webview_reuse_enable_ios", shouldExposure: true) as? Int, value == 1 {
            abEnable = true
        } else {
            abEnable = false
        }
        return abEnable
    }
}

extension UtilPowerConsumptionTrackService: BrowserViewLifeCycleEvent {
    
    func browserDidAppear() {
        // TODO.chensi clientVar大小
        if let token = model?.browserInfo.docsInfo?.token, let scene = getPowerStatisticScene() {
            PowerConsumptionStatistic.markStart(token: token, scene: scene)
            
            let commentHeightOptKey = "asidecomment_height_opt"
            let commentHeightOptValue = UserScopeNoChangeFG.HYF.asideCommentHeightOptimize
            PowerConsumptionStatistic.updateParams(commentHeightOptValue, forKey: commentHeightOptKey, token: token, scene: scene)
            
            let netLevelKey = PowerConsumptionStatisticParamKey.startNetLevel
            let netLevel = PowerConsumptionExtendedStatistic.ttNetworkQualityRawValue
            PowerConsumptionStatistic.updateParams(netLevel, forKey: netLevelKey, token: token, scene: scene)
            
            let isInVCKey = PowerConsumptionStatisticParamKey.isInVC
            let isInVC = model?.browserInfo.isInVideoConference ?? false
            PowerConsumptionStatistic.updateParams(isInVC, forKey: isInVCKey, token: token, scene: scene)
            
            let codingOptKey = "h5_coding_opt_enable"
            PowerConsumptionStatistic.updateParams(h5RecordCodingOpt, forKey: codingOptKey, token: token, scene: scene)
            
            let evaluateJSOptEnableKey = PowerConsumptionStatisticParamKey.evaluateJSOptEnable
            let dateFormatOptEnableKey = PowerConsumptionStatisticParamKey.dateFormatOptEnable
            let pathsMapOptEnableKey = PowerConsumptionStatisticParamKey.fePkgFilePathsMapOptEnable
            let downgradeEnableKey = PowerConsumptionStatisticParamKey.vcPowerDowngradeEnable
            let evaluateJSOptEnable: Bool
            let dateFormatOptEnable: Bool
            let fePkgFilePathsMapOptEnable: Bool
            let downgradeEnable: Bool
            if let optConfig = try? model?.userResolver.resolve(assert: PowerOptimizeConfigProvider.self) {
                evaluateJSOptEnable = optConfig.evaluateJSOptEnable
                dateFormatOptEnable = optConfig.dateFormatOptEnable
                fePkgFilePathsMapOptEnable = optConfig.fePkgFilePathsMapOptEnable
                downgradeEnable = optConfig.vcPowerDowngradeEnable
            } else {
                evaluateJSOptEnable = false
                dateFormatOptEnable = false
                fePkgFilePathsMapOptEnable = false
                downgradeEnable = false
            }
            PowerConsumptionStatistic.updateParams(evaluateJSOptEnable, forKey: evaluateJSOptEnableKey, token: token, scene: scene)
            PowerConsumptionStatistic.updateParams(dateFormatOptEnable, forKey: dateFormatOptEnableKey, token: token, scene: scene)
            PowerConsumptionStatistic.updateParams(fePkgFilePathsMapOptEnable, forKey: pathsMapOptEnableKey, token: token, scene: scene)
            PowerConsumptionStatistic.updateParams(downgradeEnable, forKey: downgradeEnableKey, token: token, scene: scene)
            
            let webviewReuseFGKey = PowerConsumptionStatisticParamKey.msWebviewReuseFG
            let webviewReuseABKey = PowerConsumptionStatisticParamKey.msWebviewReuseAB
            PowerConsumptionStatistic.updateParams(msWebviewReuseFGEnable, forKey: webviewReuseFGKey, token: token, scene: scene)
            PowerConsumptionStatistic.updateParams(msWebviewReuseABEnable, forKey: webviewReuseABKey, token: token, scene: scene)
            
            if let docType = model?.browserInfo.docsInfo?.inherentType.name {
                let key = PowerConsumptionStatisticParamKey.docType
                PowerConsumptionStatistic.updateParams(docType, forKey: key, token: token, scene: scene)
            }
        }
        updateHMDBizInfo()
    }
    
    func browserDidDisappear() {
        if let token = model?.browserInfo.docsInfo?.token, let scene = getPowerStatisticScene() {
            let key = PowerConsumptionStatisticParamKey.endNetLevel
            let netLevel = PowerConsumptionExtendedStatistic.ttNetworkQualityRawValue
            PowerConsumptionStatistic.updateParams(netLevel, forKey: key, token: token, scene: scene)
            if let count = model?.jsEngine.fetchServiceInstance(UtilDowngradeService.self)?.downgradeCounter {
                PowerConsumptionStatistic.updateParams(count, forKey: "downgrade_count", token: token, scene: scene)
            }
            PowerConsumptionStatistic.markEnd(token: token, scene: scene)
        }
    }
    
    func browserDidChangeFloatingWindow(isFloating: Bool) {
        HMDInjectedInfo.default().setCustomFilterValue(isFloating, forKey: InjectedCCMInfoKey.isFloatWindow.rawValue)
        if isFloating { // 进入小窗
            let scene = PowerConsumptionStatisticScene.floatingWindow
            PowerConsumptionExtendedStatistic.markStart(scene: scene)
            
            var params = [String: Any]()
            params["rnAggregationEnabled"] = UserScopeNoChangeFG.LJY.enableRnAggregation
            params["msFloatWindowAudioEnabled"] = UserScopeNoChangeFG.CS.msFloatWindowAudioEnabled
            if let config = SettingConfig.magicShareFloatingWinConfig {
                params["ccm_ms_floating_window_config_keepWebviewActiveTime"] = config.keepWebviewActiveTime
                params["ccm_ms_floating_window_config_enableInAppBackground"] = config.enableInAppBackground
                params["ccm_ms_floating_window_config_monitorThermalState"] = config.monitorThermalState
            }
            PowerConsumptionExtendedStatistic.updateParams(params, scene: scene)
            if let docType = model?.browserInfo.docsInfo?.inherentType.name {
                let key = PowerConsumptionStatisticParamKey.docType
                PowerConsumptionExtendedStatistic.updateParams(docType, forKey: key, scene: .floatingWindow)
            }
        } else { // 回到大窗模式
            if let count = model?.jsEngine.fetchServiceInstance(UtilDowngradeService.self)?.downgradeCounter {
                PowerConsumptionExtendedStatistic.updateParams(count, forKey: "downgrade_count", scene: .floatingWindow)
            }
            PowerConsumptionExtendedStatistic.markEnd(scene: .floatingWindow)
        }
    }
}

extension UtilPowerConsumptionTrackService: EditorScrollViewObserver {
    
    func editorViewScrollViewDidScroll(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        scrollObserver.editorViewScrollViewDidScroll()
    }
    
    func editorViewScrollViewDidEndScrollingAnimation(_ editorViewScrollViewProxy: EditorScrollViewProxy) {
        scrollObserver.editorViewScrollViewDidEndScrollingAnimation()
    }
}

private class ScrollObserver: NSObject {
    
    /// 滚动状态变化回调 (oldValue, newValue)
    var scrollStateChanged: ((Bool, Bool) -> Void)?
    
    /// 是否正在滚动
    private(set) var isScrolling = false {
        didSet {
            if isScrolling != oldValue {
                scrollStateChanged?(oldValue, isScrolling)
            }
        }
    }
    
    @objc
    func editorViewScrollViewDidScroll() {
        isScrolling = true
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let selector = #selector(editorViewScrollViewDidEndScrollingAnimation)
        self.perform(selector, with: nil, afterDelay: 1.0)
    }
    
    @objc
    func editorViewScrollViewDidEndScrollingAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        isScrolling = false
    }
}

extension UtilPowerConsumptionTrackService: DocsPowerLogMagicShareContext {
    
    var isInMagicShareFloatingWindow: Bool? {
        if let value = model?.vcFollowDelegate?.isFloatingWindow {
            return value
        }
        return nil
    }
}

private enum InjectedCCMInfoKey: String {
    case docType = "pl_doc_type"
    case docToken = "pl_doc_token"
    case isMagicshare = "pl_is_ms"
    case isFloatWindow = "pl_is_msfloatwindow"
    case blockCount = "pl_doc_blockcount"
    case fepkgVersion = "pl_doc_fepkg"
    case msWebviewReuseFG = "pl_ms_webview_reuse_fg"
    case msWebviewReuseAB = "pl_ms_webview_reuse_ab"
    case asidecommentHeightOptFG = "pl_asidecomment_height_opt"
    case vcPowerDowngrade = "pl_vc_degrade"
}
