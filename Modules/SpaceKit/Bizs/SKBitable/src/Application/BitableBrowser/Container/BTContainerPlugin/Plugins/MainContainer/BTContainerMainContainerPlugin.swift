//
//  BTContainerMainContainerPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation

final class BTContainerMainContainerPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            return mainContainer
        }
    }
    
    override func setupView(hostView: UIView) {
        hostView.insertSubview(mainContainer, at: 0)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.getOrCreatePlugin(BTContainerPluginSet.blockCatalogueContainer).setupView(hostView: mainContainer)
        service.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer).setupView(hostView: mainContainer)
        service.getOrCreatePlugin(BTContainerPluginSet.viewContainer).setupView(hostView: mainContainer)
        service.getOrCreatePlugin(BTContainerPluginSet.fab).setupView(hostView: mainContainer)
    }
    
    lazy var mainContainer: UIView = {
        let view = MainContainer()
        view.clipsToBounds = true
        view.layoutSubviewsCallback = { [weak self] (frame) in
            self?.service?.setMainContainerSize(mainContainerSize: frame.size)
        }
        return view
    }()
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        if stage == .finalStage {
            if new.fullScreenType != old?.fullScreenType {
                remakeConstraints(status: new)
            } else if new.orientation != old?.orientation {
                remakeConstraints(status: new)
            }
        }
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard let hostView = service.browserViewController?.view else {
            DocsLogger.error("invalid hostView")
            return
        }
        if mainContainer.superview != nil {
            if status.fullScreenType == .webFullScreen {
                mainContainer.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                return
            } else if status.fullScreenType == .webFullScreenShowNaviBar {
                guard let topPlaceHolder = service.browserViewController?.topPlaceholder else {
                    DocsLogger.error("invalid topPlaceholder")
                    return
                }
                mainContainer.snp.remakeConstraints { make in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(topPlaceHolder.snp.bottom)
                }
                return
            }
            switch status.orientation {
            case .landscapeLeft: // notch right
                let leadingConstraint = hostView.safeAreaLayoutGuide.snp.leading
                let trailingConstraint = hostView.safeAreaLayoutGuide.snp.trailing
                mainContainer.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    make.leading.equalTo(leadingConstraint)
                    make.trailing.equalTo(trailingConstraint)
                    make.bottom.equalToSuperview()
                }
            case .landscapeRight: // notch left
                let leadingConstraint = hostView.safeAreaLayoutGuide.snp.leading
                let trailingConstraint = hostView.safeAreaLayoutGuide.snp.trailing
                mainContainer.snp.remakeConstraints { make in
                    make.top.equalToSuperview()
                    make.leading.equalTo(leadingConstraint)
                    make.trailing.equalTo(trailingConstraint)
                    make.bottom.equalToSuperview()
                }
            default:
                guard let statusBar = service.browserViewController?.statusBar else {
                    DocsLogger.error("invalid statusBar")
                    return
                }
                mainContainer.snp.remakeConstraints { make in
                    make.top.equalTo(statusBar.snp.bottom)
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
            }
        }
    }
}
