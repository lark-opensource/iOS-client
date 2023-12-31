//
//  BTContainerOnboardingPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/8.
//

import Foundation
import SKCommon
import LarkStorage
import LarkAccountInterface
import SKBrowser
import LarkUIKit
import SKFoundation
import SKResource

private enum OnboardingStage {
    case none
    case step1Started
    case step1Finished
    case step2Started
    case step2Finished
}

final class BTContainerOnboardingPlugin: BTContainerBasePlugin {
    
    private static let domain = Domain.biz.ccm.child("bitable").child("onboarding")
    private static let keyHasOpenedBitable = "hasOpenedBitable"
    
    private lazy var store: KVStore = {
        return KVStores.udkv(space: .user(id: AccountServiceAdapter.shared.currentChatterId), domain: Self.domain)
    }()
    
    private lazy var mainContainerMaskView: UIView = {
        let view = UIControl()
        view.addTarget(self, action: #selector(tipsBackgroundViewClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var topContainerMaskView: UIView = {
        let view = UIControl()
        view.addTarget(self, action: #selector(tipsBackgroundViewClicked), for: .touchUpInside)
        return view
    }()
    
    private lazy var tooltipsView: OnboardingTooltipsView = {
        let view = OnboardingTooltipsView()
        view.lable.text = BundleI18n.SKResource.Bitable_Mobile_ClickToReopen_Tooltip
        view.closeButton.addTarget(self, action: #selector(tipsViewCloseButtonClicked), for: .touchUpInside)
        return view
    }()
    
    private var hasOpenedBitable: Bool {
        get {
            return store.bool(forKey: Self.keyHasOpenedBitable)
        }
        set {
            store.set(newValue, forKey: Self.keyHasOpenedBitable)
        }
    }
    
    private var canShowOnBoardingTipsView: Bool {
        get {
            guard let service = service else {
                return false
            }
            if status.fullScreenType != .none {
                // 当前全屏模式不展示
                return false
            }
            if status.baseHeaderHidden {
                // 当前 baseHeaderHidden 不显示
                return false
            }
            if Display.phone, status.orientation.isLandscape {
                // 横屏不显示
                return false
            }
            if status.hostType != .normal {
                // 模板中心等其他场景不显示
                return false
            }
            if !status.blockCatalogueHidden {
                // 当前 !blockCatalogueHidden 不显示
                return false
            }
            if let url = service.browserViewController?.docsURL.value, DocsUrlUtil.isBaseRecordUrl(url) {
                // 记录分享不执行此 Onboarding
                return false
            }
            if let url = service.browserViewController?.docsURL.value, !url.docs.isCommentAnchorLink.commentId.isEmpty {
                // 跳转评论不执行此 Onboarding
                return false
            }
            if status.containerState != .normal {
                // 正在显示错误页/权限申请页，不执行此 Onboarding
                return false
            }
            return true
        }
    }
    
    override func load(service: BTContainerService) {
        super.load(service: service)
        service.browserViewController?.editor.browserViewLifeCycleEvent.addObserver(self)
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        if stage == .finalStage, let old = old {
            if !new.blockCatalogueHidden, old.blockCatalogueHidden {
                // 从目录收起到目录展开
                if onboardingStage == .step1Started {
                    finishOnboardingStep1()    // Step1 完成
                } else if onboardingStage == .step2Finished {
                    removeTipsView(from: "blockCatalogueShowAfterStep2Finished")
                }
            } else if new.blockCatalogueHidden, !old.blockCatalogueHidden {
                // 从目录展开到目录收起
                if onboardingStage == .step1Finished {
                    startOnboardingStep2()
                }
            }
        }
        
        if onboardingStage == .step2Finished, tooltipsView.superview != nil, let old = old {
            if !new.blockCatalogueHidden, old.blockCatalogueHidden {
                // 永久移除
                removeTipsView(from: "finalRemove")
            }
            
            if canShowOnBoardingTipsView {
                // 从不可见到可见过程，等动画完成再出现
                if stage == .finalStage {
                    tooltipsView.isHidden = false
                    mainContainerMaskView.isHidden = false
                    topContainerMaskView.isHidden = false
                }
            } else {
                // 从可见到不可见过程，立即执行
                tooltipsView.isHidden = true
                mainContainerMaskView.isHidden = true
                topContainerMaskView.isHidden = true
            }
        }
        
    }
    
    private var onboardingStage: OnboardingStage = .none
    private func tryStartOnboardingStep1() {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard hasOpenedBitable else {
            DocsLogger.info("tryStartOnboardingStep1 return !hasOpenedBitable")
            return
        }
        guard !OnboardingManager.shared.hasFinished(.baseNewArchMobile) else {
            DocsLogger.info("tryStartOnboardingStep1 return hasFinished")
            return
        }
        guard canShowOnBoardingTipsView else {
            // 此场景不支持显示
            DocsLogger.info("tryStartOnboardingStep1 return !canShowOnBoardingTipsView")
            return
        }
        guard onboardingStage == .none else {
            DocsLogger.info("tryStartOnboardingStep1 return onboardingStage not none")
            return
        }
        DocsLogger.info("startOnboardingStep1")
        // 显示 BlockCatalogue
        onboardingStage = .step1Started   // 开始 Step1
        service.setBlockCatalogueHidden(blockCatalogueHidden: false, animated: true)
    }
    
    private func finishOnboardingStep1() {
        DocsLogger.info("finishOnboardingStep1")
        onboardingStage = .step1Finished    // Step1 完成
    }
    
    private func startOnboardingStep2() {
        DocsLogger.info("startOnboardingStep2")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        
        guard let mainContainerView = service.getPlugin(BTContainerMainContainerPlugin.self)?.view,
              let headerView = service.getPlugin(BTContainerHeaderPlugin.self)?.view,
                headerView.superview == mainContainerView else {
            DocsLogger.error("mainContainerView or headerView is not ready")
            return
        }
        
        // 显示 Tips
        onboardingStage = .step2Started   // 开始 Step2
        
        if let topContainer = service.browserViewController?.topContainer, topContainer.superview != nil {
            topContainerMaskView.removeFromSuperview()
            topContainer.addSubview(topContainerMaskView)
            topContainerMaskView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        mainContainerMaskView.removeFromSuperview()
        mainContainerView.addSubview(mainContainerMaskView)
        mainContainerMaskView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
        }
        
        tooltipsView.removeFromSuperview()
        mainContainerView.addSubview(tooltipsView)
        tooltipsView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(-20)
            make.left.equalTo(headerView.snp.left).offset(68)
        }
        
        // 显示出来就算结束了
        finishOnboardingStep2()
    }
    
    private func finishOnboardingStep2() {
        DocsLogger.info("finishOnboardingStep2")
        onboardingStage = .step2Finished    // Step2 完成
        OnboardingManager.shared.markFinished(for: [.baseNewArchMobile])
    }
    
    private func removeTipsView(from: String) {
        DocsLogger.info("removeTipsView from:\(from)")
        if tooltipsView.superview != nil {
            tooltipsView.removeFromSuperview()
        }
        if mainContainerMaskView.superview != nil {
            mainContainerMaskView.removeFromSuperview()
        }
        if topContainerMaskView.superview != nil {
            topContainerMaskView.removeFromSuperview()
        }
    }
    
    @objc
    private func tipsViewCloseButtonClicked() {
        removeTipsView(from: "tipsViewCloseButtonClicked")
    }
    
    @objc func tipsBackgroundViewClicked() {
        removeTipsView(from: "tipsBackgroundViewClicked")
    }
    
    override func didUpdateBlockCatalogueModel(blockCatalogueModel: BlockCatalogueModel, baseContext: BaseContext) {
        super.didUpdateBlockCatalogueModel(blockCatalogueModel: blockCatalogueModel, baseContext: baseContext)
        if blockCatalogueModel.hasValidData() {
            tryStartOnboardingStep1()
        }
    }
}

extension BTContainerOnboardingPlugin: BrowserViewLifeCycleEvent {
    
    public func browserDidHideLoading() {
        guard onboardingStage == .none else {
            return
        }
        // 加载成功
        if !hasOpenedBitable {
            // 本机首次打开，记录状态
            hasOpenedBitable = true
        }
    }
    
    func browserLoadStatusChange(_ status: LoadStatus) {
        switch status {
        case .cancel, .fail, .overtime, .loading:
            removeTipsView(from: "browserLoadStatusChange")
        default:
            break
        }
    }
}
