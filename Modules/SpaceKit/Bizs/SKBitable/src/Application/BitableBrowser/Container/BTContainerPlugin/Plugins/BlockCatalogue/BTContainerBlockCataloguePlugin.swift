//
//  BTContainerBlockCataloguePlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation

final class BTContainerBlockCataloguePlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            blockCatalogueContainer
        }
    }
    
    override func setupView(hostView: UIView) {
        hostView.insertSubview(blockCatalogueContainer, at: 0)
    }
    
    private lazy var blockCatalogueContainer: BlockCatalogueContainer = {
        let view = BlockCatalogueContainer()
        view.isHidden = true    // 默认不可见
        view.delegate = self
        // 创建向上滑动手势识别器
        let upSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        upSwipeGesture.direction = .left
        view.addGestureRecognizer(upSwipeGesture)
        
        return view
    }()
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        if new.fullScreenType != .none {
            blockCatalogueContainer.isHidden = true
        } else if !new.blockCatalogueHidden {
            blockCatalogueContainer.isHidden = false
        }
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        if (!new.blockCatalogueHidden && new.blockCatalogueHidden != old?.blockCatalogueHidden) {
            // 打开block目录，定位到选中行
            blockCatalogueContainer.openBlockCatalogue()
        }
        
        if new.darkMode != old?.darkMode {
            blockCatalogueContainer.updateDarkMode()
        }
        
        if stage == .finalStage {
            if new.headerTitleHeight != old?.headerTitleHeight {
                remakeConstraints(status: new)
            } else if new.containerSize != old?.containerSize {
                remakeConstraints(status: new)
            }
        }
        if stage == .finalStage {
            blockCatalogueContainer.isHidden = new.blockCatalogueHidden
        }
        
        let isBaseHeaderSwitchedTop = new.baseHeaderHidden
        let isBlockContainerHidden = new.blockCatalogueHidden
        let isRegularMode = new.isRegularMode
        if isBlockContainerHidden {
            // Block 目录偏移到屏幕外
            remakeConstraints(status: new)
            if isBaseHeaderSwitchedTop {
                if isRegularMode {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: -new.blockCatalogueWidth, y: 0)
                } else {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: -new.blockCatalogueWidth, y: 0)
                }
            } else {
                if isRegularMode {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: -new.blockCatalogueWidth, y: 0)
                } else {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: -new.blockCatalogueWidth, y: 0)
                }
            }
        } else {
            remakeConstraints(status: new)
            if isBaseHeaderSwitchedTop {
                if isRegularMode {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: 0, y: 0)
                } else {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            } else {
                if isRegularMode {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: 0, y: 0)
                } else {
                    self.blockCatalogueContainer.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
        }
        if status.isRegularMode, stage == .animationEndStage {
            blockCatalogueContainer.superview?.layoutIfNeeded()
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
        
        let status = status
        let isBaseHeaderSwitchedTop = status.baseHeaderHidden
        let isRegularMode = status.isRegularMode
        if blockCatalogueContainer.superview != nil {
            var topOffset: CGFloat = 0
            if isRegularMode {
                if isBaseHeaderSwitchedTop {
                    topOffset = status.topContainerHeight
                } else {
                    topOffset = status.topContainerHeight + status.headerTitleHeight
                }
            } else {
                topOffset = status.headerTitleHeight
            }
            blockCatalogueContainer.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(topOffset)
                make.left.equalToSuperview()
                make.width.equalTo(status.blockCatalogueWidth)
                make.bottom.equalToSuperview().inset(max(hostView.safeAreaInsets.bottom, 24))
            }
        }
    }
    
    // 处理滑动手势的方法
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        DocsLogger.info("handleSwipe")
        if gesture.direction == .left {
            if !status.blockCatalogueHidden {
                switchBlockContainer()
            }
        }
    }
    
    private func switchBlockContainer() {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.setBlockCatalogueHidden(blockCatalogueHidden: !status.blockCatalogueHidden, animated: true)
    }
    
    override func didUpdateBlockCatalogueModel(blockCatalogueModel: BlockCatalogueModel, baseContext: BaseContext) {
        super.didUpdateBlockCatalogueModel(blockCatalogueModel: blockCatalogueModel, baseContext: baseContext)
        
        blockCatalogueContainer.setData(blockCatalogueModel, api: self.service, baseContext: baseContext)
    }
}

extension BTContainerBlockCataloguePlugin: BlockCatalogueContainerDelegate {
    func blockContainerRequestHide() {
        DocsLogger.info("blockContainerRequestHide")
        if !status.blockCatalogueHidden {
            switchBlockContainer()
        }
    }
}
