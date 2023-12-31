//
//  DocsReactionMenuViewController.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/5/6.
//  


import SKUIKit
import Foundation
import SKFoundation
import LarkMenuController

open class DocsReactionMenuViewController: MenuViewController {
    
    /// 转屏时，是否自动dismiss
    public var autoDismissOnOrientationChange = false
    
    public override init(viewModel: MenuBarViewModel, layout: MenuBarLayout, trigerView: UIView, trigerLocation: CGPoint? = nil) {
        
        var adjustedTrigerView = trigerView
        var adjustedTrigerLocation = trigerLocation
        // 在phone横屏时，显示在中间来保证表情显示完全
        if UIDevice.current.orientation.isLandscape, SKDisplay.phone {
            if let window = trigerView.window {
                adjustedTrigerView = window
                adjustedTrigerLocation = CGPoint(x: window.bounds.width / 2, y: window.bounds.height / 2)
                DocsLogger.info("DocsReactionMenuVC: triger by window:\(window)")
            } else {
                DocsLogger.info("DocsReactionMenuVC: cannot get window of trigerView:\(trigerView)")
            }
        }
        
        super.init(viewModel: viewModel, layout: layout, trigerView: adjustedTrigerView, trigerLocation: adjustedTrigerLocation)
        
        let selector = #selector(handleOrientationChange)
        let name = UIApplication.didChangeStatusBarOrientationNotification
        NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func handleOrientationChange() {
        let orientation = UIDevice.current.orientation
        let autoDismiss = autoDismissOnOrientationChange
        DocsLogger.info("DocsReactionMenuVC: orientation:\(orientation), autoDismissOnOrientationChange:\(autoDismiss)")
        if autoDismiss {
            dismiss()
        }
    }
    
    public func dismiss() {
        dismiss(animated: true, params: nil, completion: nil)
    }
}
