//
//  BTPresentAnimationController.swift
//  SKBitable
//
//  Created by qiyongka on 2023/7/24.
//

import Foundation
import SKFoundation
import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor

final class BTPresentAnimationController: NSObject, UIViewControllerAnimatedTransitioning {

    weak var presentController: BTController?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    weak var containerView: UIView?
    
    lazy var maskView = UIControl().construct { it in
        it.backgroundColor = .clear
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromController = transitionContext.viewController(forKey: .from),
            let toController = transitionContext.viewController(forKey: .to),
            let fromView = fromController.view, let toView = toController.view,
            let browserVC = presentController?.delegate?.cardGetBitableBrowserController(),
            let presentController = presentController else {
                DocsLogger.info("animateTransition presentTransition error")
                return
        }
        
        /// 获取 browerVC 和 card 的宽度
        let browserVCWidth = browserVC.view.frame.width
        let cardWidth: CGFloat
        let contentView = transitionContext.containerView
        let containerWidth: CGFloat
        if transitionContext.presentationStyle == .overFullScreen {
            containerWidth = contentView.affiliatedWindow?.frame.width ?? browserVCWidth
        } else {
            containerWidth = browserVCWidth
        }
        
        if SKDisplay.pad, BTNavigator.isReularSize(browserVC), presentController.nextCardPresentMode == .card {
            cardWidth = min(max(browserVCWidth * presentController.cardWidthPercentOnCardMode, presentController.cardMinWidthOnCardMode), browserVCWidth)
        } else {
            cardWidth = browserVCWidth
        }
        /// 关闭交互
        fromView.isUserInteractionEnabled = false
        toView.isUserInteractionEnabled = false
        
        contentView.backgroundColor = .clear
        contentView.addSubview(toView)
        
        if !UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
            contentView.insertSubview(maskView, at: 0)
            maskView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            toView.frame = CGRect(x: containerWidth, y: 0, width: cardWidth, height: contentView.bounds.size.height)
            contentView.layoutIfNeeded()
        } else {
            self.containerView = contentView
            
            contentView.frame = CGRect(x: browserVCWidth - cardWidth, y: 0, width: cardWidth, height: contentView.bounds.size.height)
            toView.frame = CGRect(x: browserVCWidth - cardWidth, y: 0, width: cardWidth, height: contentView.bounds.size.height)
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            let x = !UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable ? containerWidth - cardWidth : 0
            toView.frame = CGRect(x: x, y: 0, width: cardWidth, height: contentView.bounds.size.height)}){ completed in
            /// 开启用户交互
            fromView.isUserInteractionEnabled = true
            toView.isUserInteractionEnabled = true
            /// 动画完成提交
            transitionContext.completeTransition(completed)
        }
    }
}
