//
//  InlineAIPanelViewGragableViewController.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/4/25.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor

class InlineAIPanelViewGragableViewController: UIViewController {
    
    /// 动画时长
    let animateDuration: Double = 0.25
    
    var showAnimation: Bool = true

    // 手势拖动参数
    var lastPanelHeight: CGFloat = 0
    
    lazy var captureShieldUtil = CaptureShieldUtility()

    var vcWillDismiss = false

    /// 背景黑色遮罩view
    lazy var maskBgView: InlineAIBackgroudMaskView = {
        let maskview = InlineAIBackgroudMaskView(frame: .zero, delegate: self)
        maskview.backgroundColor = UDColor.bgMask
        return maskview
    }()
    
    /// 整个面板容器
    private lazy var containerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .red
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        return view
    }()
    
    var defaultHeight: CGFloat {
        self.view.frame.size.height * 0.6
    }
    
    var totalMaxHeight: CGFloat {
        self.view.frame.size.height * 0.8
    }
    
    var totalMinHeight: CGFloat {
        self.view.frame.size.height * 0.4
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupSubViews()
    }
    
    
    lazy var basicContainerView: UIView = {
        return captureShieldUtil.contentView
    }()

    private func setupSubViews() {
        view.addSubview(basicContainerView)
        basicContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        basicContainerView.addSubview(maskBgView)
        maskBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        basicContainerView.addSubview(currentContainerView())
    }
    
    func setCaptureAllowed(_ allow: Bool) {
        captureShieldUtil.setCaptureAllowed(allow)
    }
    
    func currentContainerView() -> UIView {
        return containerView
    }
    
    func didPresentCompletion() {
        self.maskBgView.isHidden = false
    }
    
    func didDismissCompletion() {
        
    }
    
    func willPresent() {
        vcWillDismiss = false
    }
    
    func willDismiss() {
        vcWillDismiss = true
    }
}


extension InlineAIPanelViewGragableViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        let duration: TimeInterval = showAnimation ? self.animateDuration : 0
        return InlineAIPanelPresentTransitioning(animateDuration: duration,
                                                 willPresent: { [weak self] in
            guard let self = self else { return }
            self.willPresent()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
                                                },
                                                 animation: { [weak self] in
            guard let self = self else { return }
            self.maskBgView.alpha = 1.0
        },
                                                 completion: { [weak self] in
            guard let self = self else { return }
            self.didPresentCompletion()
        })
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if self.modalPresentationStyle == .formSheet {
           // 当modalPresentationStyle为formSheet，转场动画交由系统负责
            return nil
        }
        return InlineAIPanelDismissTransitioning(animateDuration: self.animateDuration,
                                                 willDismiss: { [weak self] in
                                                    guard let self = self else { return }
                                                    self.willDismiss()
                                                    self.maskBgView.alpha = 0.0
                                                },
                                                 animation: nil,
                                                 completion: { [weak self] in
                                                    guard let self = self else { return }
                                                self.didDismissCompletion()
        })
    }
}

// MARK: InlineAIBackgroudMaskViewDelegate
extension InlineAIPanelViewGragableViewController: InlineAIBackgroudMaskViewDelegate {
    @objc
    func didClickMaskErea(gesture: UIGestureRecognizer) {
        dismiss(animated: true)
    }
}
