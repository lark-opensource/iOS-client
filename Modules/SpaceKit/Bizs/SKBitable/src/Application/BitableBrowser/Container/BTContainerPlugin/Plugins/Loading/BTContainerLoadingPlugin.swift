//
//  BTContainerLoadingPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/8.
//

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import UniverseDesignEmpty

final class BTContainerLoadingPlugin: BTContainerBasePlugin {
    
    enum LoadingType {
        case main // 显示header 和 body 的loading
        case onlyHeader // 只显示header
        case onlyBody // 只显示body
        case all // 所有loading， 在隐藏的时候用
    }
    
    var firsLoading: Bool = true
    
    private var emptyView: BTContainerEmptyView?
    
    lazy var stateContainer: StateContainer = {
        let view = StateContainer()
        view.hiddenChangedCallback = { [weak self] in
            guard let self = self else {
                return
            }
            self.updateContainerState()
        }
        return view
    }()
    
    override func load(service: BTContainerService) {
        super.load(service: service)
        service.browserViewController?.editor.browserViewLifeCycleEvent.addObserver(self)
    }
    
    override func setupView(hostView: UIView) {
        if let topContainer = service?.browserViewController?.topContainer {
            hostView.insertSubview(stateContainer, belowSubview: topContainer)
        }
        self.updateContainerState()
    }
    
    private func updateContainerState() {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.setContainerState(containerState: stateContainer.isHidden ? .normal : .statePgae)
        if !stateContainer.isHidden {
            // 显示错误页，应当隐藏所有 Loading
            hideAllSkeleton(from: "stateContainerShow")
        }
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        if stage == .finalStage {
            if old?.containerState != new.containerState, new.containerState == .statePgae {
                // 正在显示无权限页或错误页
                if let presentedViewController = service?.browserViewController?.presentedViewController {
                    // 有正在显示的模态视图，主动隐藏
                    presentedViewController.dismiss(animated: false)
                } else {
                    // 如果有高级权限设置页，需要关掉
                    service?.getPlugin(BTContainerAdPermPlugin.self)?.hideAdPermVCIfNeeded()
                }
            }
        }
    }
    
    func showSkeletonLoading(from: String, loadingType: LoadingType) {
        switch loadingType {
        case .main:
            showMainSkeleton(from: from)
            showTitleSkeleton(from: from)
        case .onlyBody:
            showMainSkeleton(from: from)
        case .onlyHeader:
            showTitleSkeleton(from: from)
        case .all:
            break
        }
    }
    
    func hideSkeletonLoading(from: String, loadingType: LoadingType) {
        switch loadingType {
        case .main:
            hideMainSkeleton(from: from)
            hideTitleSkeleton(from: from)
        case .onlyBody:
            hideMainSkeleton(from: from)
        case .onlyHeader:
            hideTitleSkeleton(from: from)
        case .all:
            hideMainSkeleton(from: from)
            hideMainSkeleton(from: from)
        }
    }
    
    func hideAllSkeleton(from: String) {
        hideMainSkeleton(from: from)
        hideTitleSkeleton(from: from)
    }
    
    private func showMainSkeleton(from: String) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        let plugin = service.getOrCreatePlugin(BTContainerPluginSet.viewContainer)
        plugin.showLoading(from: from)
    }
    
    private func hideMainSkeleton(from: String, force: Bool = false) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.viewContainerPlugin.hideLoading(from: from)
    }
    
    func showTitleSkeleton(from: String) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        let plugin = service.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer)
        plugin.showLoading(from: from)
    }
    
    private func hideTitleSkeleton(from: String, force: Bool = false) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        let plugin = service.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer)
        plugin.hideLoading(from: from)
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard stateContainer.superview != nil,
              let statusBar = service.browserViewController?.statusBar,
                statusBar.superview == stateContainer.superview else {
            DocsLogger.error("invalid view")
            return
        }
        stateContainer.snp.remakeConstraints { make in
            make.top.equalTo(statusBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    override func didUpdateContainerSceneModel(containerSceneModel: ContainerSceneModel) {
        super.didUpdateContainerSceneModel(containerSceneModel: containerSceneModel)
        checkHideMainSkeleton(from: "didUpdateContainerSceneModel")
    }
    
    override func didUpdateViewContainerModel(viewContainerModel: BTViewContainerModel) {
        super.didUpdateViewContainerModel(viewContainerModel: viewContainerModel)
        checkHideMainSkeleton(from: "didUpdateViewContainerModel")
    }
    
    /// webview 区域加载 ready
    private var browserLoadedReady: Bool = false
    
    private func checkHideMainSkeleton(from: String, timeout: Bool = false) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard service.viewContainerPlugin.isLoading() else {
            // 已经没有 Loading 了
            return
        }
        if timeout {
            DocsLogger.info("hideMainSkeleton timeout from:\(from)")
            hideMainSkeleton(from: from)
            return
        }
        guard browserLoadedReady else {
            DocsLogger.info("browserLoadedReady not ready from:\(from)")
            return
        }
        if service.isAddRecord {
            DocsLogger.info("ignore checkHideMainSkeleton for add record:\(from)")
            return
        }
        if service.isIndRecord {
            // 记录分享页不依赖 isViewContainerReady
            hideMainSkeleton(from: from)
            return
        }
        guard model.isViewContainerReady else {
            DocsLogger.info("viewContainerReady not ready from:\(from)")
            return
        }
        hideMainSkeleton(from: from)
    }
    
    func showEmptyView(empty: UDEmpty) {
        empty.removeFromSuperview()
        emptyView?.removeFromSuperview()
        
        let emptyView = BTContainerEmptyView(empty: empty)
        stateContainer.addSubview(emptyView)
        emptyView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.emptyView = emptyView
    }
    
    func hideEmptyView() {
        emptyView?.removeFromSuperview()
    }
}

extension BTContainerLoadingPlugin: BrowserViewLifeCycleEvent {
    
    public func browserDidHideLoading() {
        browserLoadedReady = true
        if service?.isIndRecord == true {
            // 记录分享页不依赖 isViewContainerReady
            self.service?.setRecordNoHeader(recordNoHeader: true)
            hideAllSkeleton(from: "browserDidHideLoadingForRecord")
            return
        }
        if service?.isAddRecord == true {
            // 记录新建的 Loading 隐藏完全由端上自己控制，不受 webview 状态影响
            DocsLogger.info("ignore browser hide loading for add record")
            return
        }
        // 这里是文档加载完成的时机，只需要隐藏 MainSkeleton 即可，Base 头有可能出的比文档慢
        checkHideMainSkeleton(from: "browserDidHideLoading")
        // 5秒后再检查一次，容器数据是否 ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else {
                return
            }
            // 如果超过 5s 还没有加载出来 ViewContainer，无论如何也要隐藏 Loading
            self.checkHideMainSkeleton(from: "viewContainerTimout", timeout: true)
            
            if !self.model.isMainContainerReady {
                // conntainer 框架加载超时了
                self.service?.setContainerTimeout(containerTimeout: true)
            }
        }
    }
    
    public func browserLoadStatusChange(_ status: LoadStatus) {
        DocsLogger.info("BTContainerLoadingPlugin.loadStatusChange:\(status.description)")
        if service?.isAddRecord == true {
            // 记录新建的 Loading 隐藏完全由端上自己控制，不受 webview 状态影响
            DocsLogger.info("ignore browser loading status change for add record")
            return
        }
        switch status {
        case .cancel:
            hideAllSkeleton(from: "browserLoadStatusCancel")
        case .fail:
            hideAllSkeleton(from: "browserLoadStatusFail")
        case .overtime:
            hideAllSkeleton(from: "browserLoadStatusOvertime")
        default:
            break
        }
    }
}
