//
//  BTContainerViewContainerPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import Foundation
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import SkeletonView
import SKUIKit

final class BTContainerViewContainerPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            return mainViewContainer
        }
    }
    
    private var loadingView: MainContainerLoadingView = {
        return MainContainerLoadingView(frame: .zero)
    }()
    
    private lazy var maskView: UIView = {
        let view = UIControl()
        view.addTarget(self, action: #selector(maskViewClicked), for: .touchUpInside)
        return view
    }()
    
    override func setupView(hostView: UIView) {
        hostView.addSubview(mainViewContainer)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.getOrCreatePlugin(BTContainerPluginSet.toolBar).setupView(hostView: mainViewContainer)
        service.getOrCreatePlugin(BTContainerPluginSet.viewCatalogueBanner).setupView(hostView: mainViewContainer)
        
        updateDarkMode()
        
        hostView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalTo(mainViewContainer)
        }
        loadingView.isHidden = true
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        let isSwitchBlockCatalogue = old?.blockCatalogueHidden != new.blockCatalogueHidden
        
        if !new.isRegularMode, !new.blockCatalogueHidden, new.fullScreenType == .none {
            leftSwipeGesture.isEnabled = true
        } else {
            leftSwipeGesture.isEnabled = false
        }
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        if new.darkMode != old?.darkMode {
            updateDarkMode()
        }
        
        if stage == .finalStage {
            if new.headerMode != old?.headerMode {
                remakeConstraints(status: new)
            } else if new.headerTitleHeight != old?.headerTitleHeight {
                remakeConstraints(status: new)
            } else if new.fullScreenType != old?.fullScreenType {
                remakeConstraints(status: new)
            } else if new.containerSize != old?.containerSize {
                remakeConstraints(status: new)
            } else if new.headerMode == .canSwitchFixBottom, new.baseHeaderHidden != old?.baseHeaderHidden {
                remakeConstraints(status: new)
            } else if new.viewContainerType != old?.viewContainerType {
                if !UserScopeNoChangeFG.LYL.disableFixViewContainerConstraints {
                    remakeConstraints(status: new)
                }
            }
        }
        
        // 切换视图时需要重置 scrolledToTop
        if new.sceneModel.blockType != old?.sceneModel.blockType {
            service?.gesturePlugin?.resetToTop()
        } else if new.sceneModel.viewType != old?.sceneModel.viewType {
            service?.gesturePlugin?.resetToTop()
        }
        
        if stage == .finalStage {
            if new.mainViewContainerEnable {
                removeMask()
            } else {
                showMask()
            }
        }
        
        if new.fullScreenType != .none {
            self.mainViewContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            shadowView.alpha = 0
            shadowView.layer.cornerRadius = 0
            return
        }
        
        let isBaseHeaderSwitchedTop = new.baseHeaderHidden
        let isBlockContainerHidden = new.blockCatalogueHidden
        let isRegularMode = new.isRegularMode
        
        if isRegularMode, isSwitchBlockCatalogue {
            remakeConstraints(status: new)
            if stage == .animationEndStage {
                mainViewContainer.superview?.layoutIfNeeded()   // 让动画立即生效
            }
        } else if new.headerMode == .canSwitchFixBottom,
                    new.baseHeaderHidden != old?.baseHeaderHidden,
                  /*
                   1. 日历视图横向滚动 x 轴在松手时会执行一个动画回到原点，同时 native 显示/隐藏 header 时会 resize 日历视图,
                      resize 是个耗时操作会导致 web 动画执行卡顿, 导致产生 x 轴抖动
                   2. 所以这里延迟执行日历视图的 resize
                   */
                    new.sceneModel.viewType != .calendar
        {
            remakeConstraints(status: new)
            if stage == .animationEndStage {
                mainViewContainer.superview?.layoutIfNeeded()   // 让动画立即生效
            }
        }
        
        if isBaseHeaderSwitchedTop {
            if isBlockContainerHidden {
                self.mainViewContainer.transform = CGAffineTransform(translationX: 0, y: -new.headerTitleHeight)
            } else {
                self.mainViewContainer.transform = CGAffineTransform(translationX: new.blockCatalogueWidth, y: -new.headerTitleHeight)
            }
        } else {
            if isBlockContainerHidden {
                self.mainViewContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            } else {
                self.mainViewContainer.transform = CGAffineTransform(translationX: new.blockCatalogueWidth, y: 0)
            }
        }
        
        if isRegularMode {
            shadowView.alpha = 1
            shadowView.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
        } else {
            if isBlockContainerHidden {
                if isBaseHeaderSwitchedTop {
                    shadowView.alpha = 0
                    shadowView.layer.cornerRadius = 0
                } else {
                    shadowView.alpha = 1
                    shadowView.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
                }
            } else {
                shadowView.alpha = 1
                shadowView.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
            }
        }
    }
    
    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.isUserInteractionEnabled = false
        shadowView.clipsToBounds = false
        shadowView.layer.borderWidth = 1.0
        shadowView.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowOffset = CGSize(width: -2, height: 50)
        shadowView.layer.maskedCorners = .top
        shadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return shadowView
    }()
    
    func updateDarkMode() {
        shadowView.layer.ud.setBorderColor(UIColor.dynamic(light: UDColor.N00.withAlphaComponent(0.4), dark: UDColor.rgb(0x3B3E40)))
        shadowView.layer.ud.setShadowColor(UIColor.dynamic(light: UIColor.black, dark: UIColor.white))
        
        if BTContainerStatus.isDarkMode() {
            shadowView.layer.shadowOpacity = 0.4
            shadowView.layer.shadowRadius = 11
        } else {
            shadowView.layer.shadowOpacity = 1
            shadowView.layer.shadowRadius = 8
        }
    }
    
    private lazy var leftSwipeGesture: UISwipeGestureRecognizer = {
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(switchBlockContainerPerform))
        leftSwipeGesture.direction = .left
        return leftSwipeGesture
    }()
    
    private lazy var mainViewContainer: UIView = {
        let view = UIView()
        
        view.addSubview(shadowView)
        
        view.addGestureRecognizer(leftSwipeGesture)
        
        return view
    }()
    
    @objc
    private func switchBlockContainerPerform() {
        DocsLogger.info("switchBlockContainerPerform")
        guard let service = self.service else {
            DocsLogger.error("invalid service")
            return
        }
        service.setBlockCatalogueHidden(blockCatalogueHidden: true, animated: true)
    }
    
    private func showMask() {
        if maskView.superview == nil {
            DocsLogger.info("showMask")
            mainViewContainer.addSubview(maskView)
            maskView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func removeMask() {
        if maskView.superview != nil {
            DocsLogger.info("removeMask")
            maskView.removeFromSuperview()
        }
    }
    
    @objc
    func maskViewClicked() {
        DocsLogger.info("maskViewClicked")
        switchBlockContainerPerform()
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard mainViewContainer.superview != nil else {
            DocsLogger.error("invalid mainViewContainer")
            return
        }
        guard let baseHeaderContainer = service.getOrCreatePlugin(BTContainerPluginSet.baseHeaderContainer).view,
                baseHeaderContainer.superview == mainViewContainer.superview else {
            DocsLogger.error("invalid baseHeaderContainer")
            return
        }
        if status.fullScreenType != .none {
            mainViewContainer.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
            return
        }
        let offsetWidth = -status.targetBlockAreaWidth
        let bottomOffset = status.webviewBottomOffset
        mainViewContainer.snp.remakeConstraints { make in
            make.top.equalTo(baseHeaderContainer.snp.bottom)
            make.bottom.equalToSuperview().offset(bottomOffset)
            make.width.equalToSuperview().offset(offsetWidth)
        }
    }
    
    func isLoading() -> Bool {
        return self.loadingView.isHidden == false
    }
    
    func showLoading(from: String) {
        DocsLogger.info("BTContainerViewContainerPlugin.showLoading from:\(from)")
        self.loadingView.alpha = 1
        self.loadingView.isHidden = false
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        self.loadingView.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        self.loadingView.startSkeletonAnimation()
    }
    
    func hideLoading(from: String) {
        guard isLoading() else {
            return
        }
        DocsLogger.info("BTContainerViewContainerPlugin.hideLoading from:\(from)")
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.loadingView.alpha = 0
        } completion: { [weak self] _ in
            self?.loadingView.isHidden = true
            self?.loadingView.hideSkeleton()
        }
    }
    
    func bringLoadingToFront() {
        DocsLogger.info("BTContainerViewContainerPlugin.bringLoadingToFront")
        loadingView.superview?.bringSubviewToFront(self.loadingView)
    }
}
