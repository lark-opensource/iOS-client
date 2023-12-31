//
//  BTContainerBackgroundPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import UniverseDesignTheme

final class BTContainerBackgroundPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            return backgroundView
        }
    }
    
    override func setupView(hostView: UIView) {
        hostView.insertSubview(backgroundView, at: 0)
    }
    
    private lazy var backgroundView: BackgroundView = {
        var view = BackgroundView()
        return view
    }()
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        func shouldHideBackground() -> Bool {
            return (new.hostType != .templatePreview) && (new.fullScreenType != .none)
        }
        let shouldHideBackground = shouldHideBackground()
        
        // 仪表盘全屏情况下，需要隐藏渐变背景色，而采用默认的白色，减少割裂
        backgroundView.isHidden = shouldHideBackground
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        
        if new.darkMode != old?.darkMode {
            backgroundView.updateDarkMode()
        }
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        guard backgroundView.superview != nil else {
            return
        }
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
