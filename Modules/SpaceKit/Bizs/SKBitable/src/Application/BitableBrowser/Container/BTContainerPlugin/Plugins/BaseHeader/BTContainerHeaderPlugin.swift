//
//  BTContainerHeaderPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import Foundation
import SKFoundation
import SKCommon
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import SpaceInterface
import SkeletonView

final class BTContainerHeaderPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            baseHeaderContainer
        }
    }
    
    var headerTitleView: BaseHeaderTitleView {
        baseHeaderTitleView
    }
    
    override func load(service: BTContainerService) {
        super.load(service: service)
    }
    
    override func setupView(hostView: UIView) {
        hostView.addSubview(baseHeaderContainer)
    }
    
    private lazy var baseHeaderTitleView: BaseHeaderTitleView = {
        let view = BaseHeaderTitleView()
        view.delegate = self
        view.isUserInteractionEnabled = true
        
        view.addTarget(self, action: #selector(switchBlockContainerDelay), for: .touchUpInside)
        return view
    }()
    
    private lazy var skeletonLoading: BaseHeaderTitleView = {
        let view = BaseHeaderTitleView(true)
        return view
    }()
    
    private lazy var baseHeaderContainer: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.addSubview(baseHeaderTitleView)
        baseHeaderTitleView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        view.addSubview(skeletonLoading)
        skeletonLoading.isHidden = true
        skeletonLoading.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if UserScopeNoChangeFG.LYL.disableAllViewAnimation {
            // 创建滑动手势识别器
            let upSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            upSwipeGesture.direction = .up
            view.addGestureRecognizer(upSwipeGesture)

            let downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            downSwipeGesture.direction = .down
            view.addGestureRecognizer(downSwipeGesture)
        }
        
        return view
    }()
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        baseHeaderContainer.isHidden = (new.fullScreenType != .none) || (new.headerMode == .fixedHidden)
        
        let isSwitchBlockCatalogue = old?.blockCatalogueHidden != new.blockCatalogueHidden
        
        // 动画开始时的特殊处理
        if stage == .animationBeginStage, let old = old {
            let isBaseHeaderSwitchedTop = old.baseHeaderHidden
            let isBlockContainerHidden = old.blockCatalogueHidden
            let isRegularMode = old.isRegularMode
            if isBaseHeaderSwitchedTop {
                if isBlockContainerHidden {
                    if !isRegularMode {
                        if isSwitchBlockCatalogue {
                            self.baseHeaderTitleView.transform = CGAffineTransform(translationX: -new.blockCatalogueWidth, y: 0)
                            self.baseHeaderContainer.transform.ty = -new.topContainerHeight
                        } else {
                            self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: -self.baseHeaderTitleHeight)
                            self.baseHeaderContainer.transform.ty = 0
                        }
                    }
                }
            }
        }
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        // 动画目标中再执行 updateBaseHeaderContainerConstraints
        if stage == .animationEndStage, let old = old {
            if old.baseHeaderHidden && old.blockCatalogueHidden {
                if !old.isRegularMode {
                    remakeTitleConstraints(status: new)
                    baseHeaderContainer.layoutIfNeeded()
                }
            }
        }
        
        let isBaseHeaderSwitchedTop = new.baseHeaderHidden
        let isBlockContainerHidden = new.blockCatalogueHidden
        let isRegularMode = new.isRegularMode
        
        if new.topContainerHeight != old?.topContainerHeight {
            remakeConstraints(status: new)
        }
        
        if stage == .finalStage {
            if new.blockCatalogueHidden != old?.blockCatalogueHidden, !new.baseHeaderHidden {
                remakeTitleConstraints(status: new)
            } else if new.isRegularMode != old?.isRegularMode {
                remakeTitleConstraints(status: new)
            }
        }
        
        if isBaseHeaderSwitchedTop {
            if isBlockContainerHidden {
                    if isRegularMode {
                        self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: -self.baseHeaderTitleHeight)
                        self.baseHeaderContainer.transform.ty = 0
                    } else {
                        if isSwitchBlockCatalogue {
                            self.baseHeaderTitleView.transform = CGAffineTransform(translationX: -new.blockCatalogueWidth, y: 0)
                            self.baseHeaderContainer.transform.ty = -new.topContainerHeight
                        } else {
                            self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: -self.baseHeaderTitleHeight)
                            self.baseHeaderContainer.transform.ty = 0
                        }
                    }
            } else {
                if isRegularMode {
                    self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: -self.baseHeaderTitleHeight)
                    self.baseHeaderContainer.transform.ty = 0
                } else {
                    self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: 0)
                    self.baseHeaderContainer.transform.ty = -new.topContainerHeight
                }
            }
        } else {
            if isBlockContainerHidden {
                self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: 0)
                self.baseHeaderContainer.transform.ty = 0
            } else {
                if isRegularMode {
                    self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: 0)
                    self.baseHeaderContainer.transform.ty = 0
                } else {
                    self.baseHeaderTitleView.transform = CGAffineTransform(translationX: 0, y: 0)
                    self.baseHeaderContainer.transform.ty = -new.topContainerHeight
                }
            }
        }
        
        if !UserScopeNoChangeFG.YY.bitableContainerViewSearchFixDisable {
            // FG 全量删除时，保留代码
            if isBaseHeaderSwitchedTop, isRegularMode {
                // 这种情况已经不再展示 baseHeader，为防止残留的空壳容器影响点击表搜索框，设置其不可点击
                self.baseHeaderContainer.isUserInteractionEnabled = false
            } else {
                self.baseHeaderContainer.isUserInteractionEnabled = true
            }
        }
    }
    
    private var baseHeaderTitleHeight: CGFloat {
        get {
            baseHeaderTitleView.frame.height
        }
    }
    
    @objc
    private func switchBlockContainerDelay() {
        DocsLogger.info("switchBlockContainerDelay")
        guard model.blockCatalogueModel?.hasValidData() == true else {
            DocsLogger.warning("switchBlockContainer but blockCatalogueModel not ready")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let service = self?.service, let status = self?.status else {
                return
            }
            service.setBlockCatalogueHidden(blockCatalogueHidden: !status.blockCatalogueHidden, animated: true)
            service.trackContainerEvent(.bitableCalloutSidebarClick,
                                        params: ["click": "callout_sidebar",
                                                 "sidebar_type": "table_list"])
        }
    }
    
    // 处理滑动手势的方法
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        DocsLogger.info("handleSwipe")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard status.headerMode == .canSwitch || status.headerMode == .canSwitchFixBottom else {
            DocsLogger.info("headerMode not canSwitch")
            return  // 不允许用户上滑
        }
        guard status.mainViewContainerEnable else {
            DocsLogger.info("!mainViewContainerEnable not canSwitch")
            return  // 不允许用户上滑
        }
        let isBaseHeaderSwitchedTop = status.baseHeaderHidden
        
        if gesture.direction == .up, !isBaseHeaderSwitchedTop {
            DocsLogger.info("handleSwipe up")
            service.setBaseHeaderHidden(baseHeaderHidden: true, animated: true)
        } else if gesture.direction == .down, isBaseHeaderSwitchedTop {
            DocsLogger.info("handleSwipe down")
            service.setBaseHeaderHidden(baseHeaderHidden: false, animated: true)
        }
    }
    
    func trySwitchHeader(baseHeaderHidden: Bool) {
        DocsLogger.info("trySwitchHeader")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        guard status.headerMode == .canSwitch || status.headerMode == .canSwitchFixBottom else {
            DocsLogger.info("headerMode not canSwitch")
            return  // 不允许用户上滑
        }
        guard status.mainViewContainerEnable else {
            DocsLogger.info("!mainViewContainerEnable not canSwitch")
            return  // 不允许用户上滑
        }
        if baseHeaderHidden != status.baseHeaderHidden {
            DocsLogger.info("trySwitchHeader:\(baseHeaderHidden)")
            service.setBaseHeaderHidden(baseHeaderHidden: baseHeaderHidden, animated: true)
        }
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard baseHeaderContainer.superview != nil else {
            return
        }
        guard baseHeaderTitleView.superview == baseHeaderContainer else {
            return
        }
        let topContainerHeight = status.topContainerHeight
        baseHeaderContainer.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(topContainerHeight)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(baseHeaderTitleView)
        }
    }
    
    private func remakeTitleConstraints(status: BTContainerStatus) {
        let isRegularMode = status.isRegularMode
        let isBlockContainerHidden = status.blockCatalogueHidden
        let isBaseHeaderSwitchedTop = status.baseHeaderHidden
        let paddingRight = (!isRegularMode && !isBlockContainerHidden && isBaseHeaderSwitchedTop)
        baseHeaderTitleView.remakeConstraints(paddingRightEx: paddingRight ? BTContainer.Constaints.viewContainerRemainWidth : 0)
    }
    
    override func didUpdateHeaderModel(headerModel: BaseHeaderModel) {
        super.didUpdateHeaderModel(headerModel: headerModel)
        guard headerModel.hasValidData() else {
            DocsLogger.warning("BTContainerHeaderPlugin.didUpdateHeaderModel but no valid data")
            return  // subTitle 空，认为是无效信息
        }
        DocsLogger.info("BTContainerHeaderPlugin.didUpdateHeaderModel")
        let title: String
        if let mainTitle = headerModel.mainTitle, !mainTitle.isEmpty {
            title = mainTitle
        } else {
            DocsLogger.warning("BTContainerHeaderPlugin.didUpdateHeaderModel but title is empty")
            title = DocsType.bitable.untitledString
        }
        baseHeaderTitleView.setTitle(title: title)
        baseHeaderTitleView.setSubTitle(title: headerModel.subTitle)
        baseHeaderTitleView.setSubIcon(icon: headerModel.tableIcon)
        if let icon = headerModel.icon {
            baseHeaderTitleView.setIcon(icon: icon) { [weak self] in
                if self?.isShowLoading() == true {
                    self?.hideLoading(from: "iconLoaded") // 图片加载有结果了，就立即 hideLoading
                }
            }
        } else {
            DocsLogger.warning("BTContainerHeaderPlugin.didUpdateHeaderModel but icon is empty")
        }
        
        if isShowLoading() {
            // 图片加载超过 2 秒还没有结果，也 hideLoading
            DispatchQueue.main.asyncAfter(deadline: .now() + 2){ [weak self] in
                self?.hideLoading(from: "iconLoadOvertime")
            }
        }
    }
    
    private func isShowLoading() -> Bool {
        return !self.skeletonLoading.isHidden
    }
    
    func showLoading(from: String) {
        DocsLogger.info("BTContainerHeaderPlugin.showLoading from:\(from)")
        skeletonLoading.isHidden = false
        headerTitleView.alpha = 0
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        skeletonLoading.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        skeletonLoading.startSkeletonAnimation()
    }
    
    func isLoading() -> Bool {
        return self.skeletonLoading.isHidden == false
    }
    
    func hideLoading(from: String) {
        guard isLoading() else {
            return
        }
        DocsLogger.info("BTContainerHeaderPlugin.hideLoading from:\(from)")
        UIView.animate(withDuration: BTContainer.Constaints.animationDuration) {
            self.headerTitleView.alpha = 1
            self.skeletonLoading.alpha = 0
        } completion: { _ in
            self.headerTitleView.alpha = 1
            self.skeletonLoading.isHidden = true
            self.skeletonLoading.hideSkeleton()
        }
    }
    
    private lazy var templateTag = AutoFontLableTag(text: BundleI18n.SKResource.Doc_Create_File_ByTemplate, backgroundColor: UDColor.udtokenTagBgPurple, textColor: UDColor.udtokenTagTextSPurple)
    
    private var lastExternalTag: AutoFontLableTag?
    
    func setShowTemplateTag(_ showTemplateTag: Bool) {
        baseHeaderTitleView.templateTag = showTemplateTag ? templateTag : nil
    }
    
    func setShowExternalTag(needDisPlay: Bool, tagValue: String) {
        func getExternalTag() -> AutoFontLableTag {
            let extenrnalTag: AutoFontLableTag
            if let lastExternalTag = lastExternalTag, lastExternalTag.text == tagValue {
                extenrnalTag = lastExternalTag
            } else {
                extenrnalTag = AutoFontLableTag(text: tagValue, backgroundColor: UDColor.udtokenTagBgBlue, textColor: UDColor.udtokenTagTextSBlue)
                lastExternalTag = extenrnalTag
            }
            return extenrnalTag
        }
        baseHeaderTitleView.extenrnalTag = needDisPlay ? getExternalTag() : nil
    }
}

extension BTContainerHeaderPlugin: BaseHeaderTitleViewDelegate {
    func baseHeaderTitleFrameDidChanged() {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.setHeaderTitleHeight(headerTitleHeight: baseHeaderTitleView.frame.height)
    }
}

extension BTContainerHeaderPlugin {
    func setBaseHeaderHiddenForWeb(_ model: BTShowHeaderModel) {
        guard UserScopeNoChangeFG.LYL.disableAllViewAnimation else {
            return
        }
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        // 是否是惯性滚动到顶部
        if model.isTopInertia == true {
            guard canChangeHeaderForWeb(false) else {
                return
            }
            DocsLogger.btError("[BTContainer] baseHeaderShow because inertia")
            service.setBaseHeaderHidden(baseHeaderHidden: false, animated: true)
            return
        }

        guard model.type == .end else {
            return
        }
        guard let lastPoints = model.lastPoints,
              let lastPointIndex = model.lastPointIndex,
              let lastTimePoints = model.lastTimePoints,
              let lastTimePointIndex = model.lastTimePointIndex else {
            DocsLogger.btInfo("[BTContainer] model lastPoints or lastPointIndex is nil")
            return
        }
        let (isValid, yDiff) = BTContainerHeaderUtils.checkPointsValid(lastPoints: lastPoints, lastPointIndex: lastPointIndex)
        let (isTimeValid, yTimeDiff) = BTContainerHeaderUtils.checkPointsValid(lastPoints: lastTimePoints, lastPointIndex: lastTimePointIndex)

        var isValidTouch = false
        var isTop = false
        if isValid, let yDiff = yDiff {
            isValidTouch = true
            isTop = yDiff < 0
        }
        if !isValidTouch, isTimeValid, let yTimeDiff = yTimeDiff {
            isValidTouch = true
            isTop = yTimeDiff < 0
        }
        guard isValidTouch else {
            DocsLogger.btInfo("[BTContainer] isValidTouch is false \(isValid) \(yDiff ?? 0) \(isTimeValid) \(yTimeDiff ?? 0)")
            return
        }
        if isTop {
            guard canChangeHeaderForWeb(isTop) else {
                return
            }
            service.setBaseHeaderHidden(baseHeaderHidden: isTop, animated: true)
        } else {
            guard model.scrollY ?? 0 < 1 else {
                return
            }
            guard canChangeHeaderForWeb(isTop) else {
                return
            }
            service.setBaseHeaderHidden(baseHeaderHidden: isTop, animated: true)
        }
    }

    private func canChangeHeaderForWeb(_ isTop: Bool) -> Bool {
        // 这里如果 headerMode 已经固定模式，则不再接受外部设置 baseHeaderHidden
        if status.headerMode == .fixedShow, isTop {
            return false
        } else if status.headerMode == .fixedHidden, !isTop {
            return false
        }
        return true
    }
}
