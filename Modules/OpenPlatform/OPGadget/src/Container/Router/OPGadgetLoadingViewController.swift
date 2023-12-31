//
//  OPGadgetLoadingViewController.swift
//  OPGadget
//
//  Created by Nicholas Tau on 2020/12/23.
//

import Foundation
import CoreGraphics
import OPFoundation
import TTMicroApp

protocol OPGadgetLoadingProtocol: AnyObject {
    func setupLoadingView(appName: String?, icon: String?)
    func updateLoadingViewWithError(failState: BDPLoadingViewState, info: String)
    /// 当触发可重试错误时loadingView需要展示对应的界面
    func updateLoadingViewWithRecoverableRefresh(info: String, uniqueID: OPAppUniqueID)
    func hideLoadingView(hideToolBar: Bool, completionBlock:@escaping () -> (Void))
}

extension OPGadgetLoadingViewController: OPGadgetLoadingProtocol {
    func setupLoadingView(appName: String?, icon: String?) {
        self.loadingView.update(withIconUrl: icon ?? "", appName: appName ?? "")
    }
    
    func updateLoadingViewWithError(failState: BDPLoadingViewState, info: String) {
        self.loadingView.change(toFailState: Int32(failState.rawValue), withTipInfo: info)
    }
    
    
    func hideLoadingView(hideToolBar: Bool, completionBlock:@escaping () -> (Void)) {
        self.loadingView.alpha = 1.0
        self.toolbarView.ready = true
        
        let loadingViewDismissAnimationDuration = BDPTimorClient.shared().appearanceConfg.loadingViewDismissAnimationDuration
        UIView.animate(withDuration: loadingViewDismissAnimationDuration) {
            self.loadingView.alpha = 0.0
            if hideToolBar {
                self.toolbarView.alpha = 0.0
            }
            self.toolbarView.toolBarStyle = self.toolbarView.toolBarStyle
        } completion: { finished in
            if hideToolBar {
                self.toolbarView.removeFromSuperview()
            }
            self.loadingView.removeFromSuperview()
            completionBlock()
        }
        self.loadingView.stopAnimation()
    }

    /// 当触发可重试错误时loadingView需要展示对应的界面
    func updateLoadingViewWithRecoverableRefresh(info: String, uniqueID: OPAppUniqueID) {
        self.loadingView.changeToFailRetryState(with: info, uniqueID: uniqueID)
    }
    
    
    /// 将加载页状态切换至统一错误页
    /// - Parameters:
    ///   - errorStyle: 错误配置样式
    ///   - uniqueID: 透传参数，小程序id
    func makeLoadingViewUnifyErrotState(errorStyle: UnifyExceptionStyle, uniqueID: OPAppUniqueID) {
        self.loadingView.changeToErrorState(errorStyle: errorStyle, uniqueID: uniqueID)
    }
}

class OPGadgetLoadingViewController: UIViewController {
    
    private let loadingView: OPLoadingView = OPLoadingView.init(frame: .zero)
    private var toolbarView: BDPToolBarView
    private let uniqueID: OPAppUniqueID?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    init(uniqueID: OPAppUniqueID?) {
        self.toolbarView = BDPToolBarView.init(uniqueID: uniqueID)
        self.uniqueID = uniqueID
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        //initilized loading view and toolbar view
        if self.loadingView.superview == nil {
            self.view.addSubview(self.loadingView)
        }
        if self.toolbarView.superview == nil {
            self.view.addSubview(self.toolbarView)
        }
        self.toolbarView.toolBarStyle = .unspecified    // 跟随系统
    }
    //toolbar initialized here
    func setupToolbarView() {
        var isLandscape = (UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft) || (UIDevice.current.orientation == UIDeviceOrientation.landscapeRight)
        isLandscape  = !BDPDeviceHelper.isPadDevice() && isLandscape

        if OPSDKFeatureGating.gadgetUseStatusBarOrientation() {
            // 这边使用UIApplication的statuBarOrientation替换UIDevice的方向
            // 小程序预期获取的是界面是否为横屏
            isLandscape = !OPGadgetRotationHelper.isPad() && OPGadgetRotationHelper.isLandscape()
        }

        let safeAreaTop = BDPResponderHelper.safeAreaInsets(self.view.window).top
        var adaptTop = isLandscape ? 15 : safeAreaTop == 0 ? 26 : safeAreaTop
        
        //半屏模式下，这个辅助的loading也需要下移
        if BDPXScreenManager.isXScreenMode(uniqueID) {
            adaptTop = BDPXScreenManager.xScreenAppropriateMaskHeight(uniqueID)
        }
        
        self.toolbarView.frame = CGRect(x: self.view.op_width - self.toolbarView.op_width - 6, y: adaptTop, width: self.toolbarView.op_width, height: self.toolbarView.op_height)
        self.toolbarView.setNeedsLayout()
        self.toolbarView.layoutIfNeeded()
    }
    
    override func viewWillLayoutSubviews() {
        if BDPXScreenManager.isXScreenMode(uniqueID) {
            let viewHeight = BDPXScreenManager.xScreenAppropriatePresentationHeight(uniqueID)
            let maskHeight = BDPXScreenManager.xScreenAppropriateMaskHeight(uniqueID)
            self.loadingView.frame = CGRect(x: 0, y: maskHeight, width: self.view.bounds.size.width, height: viewHeight);
        } else {
            self.loadingView.frame = self.view.bounds;
        }
        
        self.loadingView.setNeedsLayout()
        self.loadingView.layoutIfNeeded()
        
        setupToolbarView()
    }
    
    public func updateLoadingView(appName: String, iconUrl: String) {
        self.loadingView.update(withIconUrl: iconUrl, appName: appName)
    }
    
    public func updateLoadingViewFailState(state: BDPLoadingViewState, info: String) {
        if state == .slow || state == .slowDebug {
            self.toolbarView.forcedMoreEnable = true
            self.loadingView.change(toFailState: Int32(state.rawValue), withTipInfo: info)
        } else {
            self.toolbarView.forcedMoreEnable = false
            self.loadingView.change(toFailState: Int32(state.rawValue), withTipInfo: info)
            if (BDPTimorClient.shared().appearanceConfg.hideAppWhenLaunchError) {
                //[self dismissSelf:GDMonitorCode.auto_dismiss_when_load_failed]; // Lark 定制：启动失败时直接退出小程序，并Toast提示
            }
        }
    }
}
