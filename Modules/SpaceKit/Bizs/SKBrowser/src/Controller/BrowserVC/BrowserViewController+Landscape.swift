//
//  BrowserViewController+ForceLandscape.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/9/11.
//  

import SKFoundation
import SnapKit
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignShadow
import UIKit
import SKInfra

// MARK: - BrowserOrientationManagerDelegate
extension BrowserViewController: BrowserOrientationObserver {
    func statusBarWillChangeOrientation(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        editor.browserWillChangeOrientation(from: oldOrientation, to: newOrientation)
    }

    func statusBarDidChangeOrientation(from oldOrientation: UIInterfaceOrientation, to newOrientation: UIInterfaceOrientation) {
        editor.browserDidChangeOrientation(from: oldOrientation, to: newOrientation)
        hideForceOrientationTip()
        changePopGestureRecognizer(forbidden: newOrientation.isLandscape)
    }

    func motionSensorUpdatesOrientation(to newOrientation: UIInterfaceOrientation) {
    }
    
    //swiftlint:disable cyclomatic_complexity
    func showForceOrientationTip(_ targetOrientation: UIInterfaceOrientation) -> Bool {
        // ms 下不显示转屏按钮
        if isInVideoConference {
            return false
        }
        if forceFull {
            DocsLogger.error("forceFull, not open OrientationTip")
            return false
        }
        if isEmbedMode {
            // 嵌入模式不需要显示自己的横屏
            return false
        }
        // 修复iOS16系统缺陷
        if LKFeatureGating.ccmios16Orientation {
            DocsLogger.error("system orientation, not open OrientationTip")
            return false
        }
        if forceOrientationTip?.targetOrientation == targetOrientation {
            return false // 说明这个时候已经有一个相同目的的 orientation tip 显示了，就不要重新创建一份了，返回 false 告诉外面不需要埋点汇报
        } else { // 要么是有一个不同目的的 orientation tip，要么是没有 tip
            hideForceOrientationTip()
        }
        forceOrientationTip = ForceOrientationTip(toOrientation: targetOrientation)
        guard let tip = forceOrientationTip else { return false }
        guard shouldShowTip() else { return false }

        if #available(iOS 13, *) {
            UIMenuController.shared.hideMenu()
        } else {
            UIMenuController.shared.setMenuVisible(false, animated: false)
        }
        view.addSubview(tip)
        tip.didClick = { [weak self] in
            if targetOrientation.isLandscape {
                self?.orientationDirector?.dynamicOrientationMask = .allButUpsideDown
                if #available(iOS 16.0, *) {
                    self?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            }
            self?.orientationDirector?.forceSetOrientation(targetOrientation,
                                                           action: targetOrientation.isPortrait ? .exitLandscape : .enterLandscape,
                                                           source: targetOrientation.isPortrait ? .forcePortraitTip : .forceLandscapeTip)
            self?.updatePhoneUI(for: targetOrientation)
            self?.hideForceOrientationTip()
            self?.reportOrientationTipEvent(targetOrientation)
            if targetOrientation.isLandscape {
                let showCount = CCMKeyValue.globalUserDefault.integer(forKey: UserDefaultKeys.enterSheetLandscapeToastShowCount)
                if showCount < 3 {
                    guard let hostView = self?.view else { return }
                    let hud = UDToast.showTips(with: BundleI18n.SKResource.Doc_Sheet_ReadOnlyLandscape, on: hostView)
                    hud.setCustomBottomMargin(60) // copied from SKBaseToastPlugin
                    CCMKeyValue.globalUserDefault.set(showCount + 1, forKey: UserDefaultKeys.enterSheetLandscapeToastShowCount)
                } else {
                    DocsLogger.info("用户已经看过 3 次 sheet 横屏查看 toast 了，不再播放了")
                }
            }
        }
        tip.snp.remakeConstraints { (make) in
            make.width.height.equalTo(48)
            switch (UIApplication.shared.statusBarOrientation, targetOrientation) {
            case (.landscapeRight, .portrait):
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(36)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).inset(24)
            case (.landscapeLeft, .portrait):
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(36)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(24)
            case (.portrait, .landscapeRight):
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(84)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(24)
            case (.portrait, .landscapeLeft):
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(84)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).inset(24)
            default:
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(36)
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(24)
            }
        }
        return true
    }
    
    private func reportOrientationTipEvent(_ targetOrientation: UIInterfaceOrientation) {
        guard editor.docsInfo?.inherentType.supportLandscapeShow ?? false else { return }
        let isVerion: String = editor.docsInfo?.isVersion ?? false ? "true" : "false"
        if targetOrientation.isLandscape {
            logNavBarEvent(.docXSwitchHorizontalClick, click: "horizontal_screen", extraParam: ["is_version": isVerion])
        } else {
            logNavBarEvent(.docXSwitchVerticalClick, click: "vertical_screen", extraParam: ["button_location": "float", "is_version": isVerion])
        }
    }

    public func hideForceOrientationTip() {
        forceOrientationTip?.removeFromSuperview()
        forceOrientationTip = nil
    }
    
    public func changePopGestureRecognizer(forbidden: Bool) {
        if UserScopeNoChangeFG.GXY.landscapePopGestureEnable, SKDisplay.phone, !isInVideoConference,
           isViewDidShow
        {
            DocsLogger.info("BrowserViewController setPopGestureRecognizer enable：\(!forbidden)")
            if forbidden {
                // 记录横屏之前手势返回的可用标记
                if hasForbiddenPopGestureRecognizer == false {
                    preInteractivePopGestureRecognizerEnable = self.navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
                    hasForbiddenPopGestureRecognizer = true
                }
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            } else {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = preInteractivePopGestureRecognizerEnable
            }
        }
    }

    /// 一些情况不应该显示横竖屏 Tip
    private func shouldShowTip() -> Bool {
        // 当上面存在其他界面时
        if let topMost = UIViewController.docs.topMost(of: self),
            topMost != self {
            return false
        }
        // 当正在编辑时不需要显示
        return !(orientationDirector?.isKeyboardShow ?? true)
    }
}

// MARK: - ForceOrientationTip
class ForceOrientationTip: UIView {
    var targetOrientation: UIInterfaceOrientation
    var didClick: (() -> Void)?

    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()

    let iconImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.image = UDIcon.landscapeModeColorful.ud.withTintColor(UIColor.ud.iconN1)
        imgView.backgroundColor = UIColor.ud.bgBody
        imgView.contentMode = .center
        imgView.layer.cornerRadius = 24
        imgView.clipsToBounds = true
        return imgView
    }()

    init(toOrientation orientation: UIInterfaceOrientation) {
        targetOrientation = orientation
        super.init(frame: .zero)
        self.setupUI()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        iconImgView.backgroundColor = UIColor.ud.bgBody
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        iconImgView.backgroundColor = UIColor.ud.fillPressed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.randomElement()
        if let endLocation = touch?.location(in: self.superview), self.frame.contains(endLocation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
                guard let self = self else { return }
                self.didClick?()
            }
        }
        iconImgView.backgroundColor = UIColor.ud.bgBody
    }

    private func setupUI() {
        layer.cornerRadius = 24
        layer.ud.setShadowColor(UDShadowColorTheme.s4DownColor)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.borderWidth = 0.5
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        addSubview(backgroundView)
        addSubview(iconImgView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        iconImgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        switch (UIApplication.shared.statusBarOrientation, targetOrientation) {
        case (.landscapeLeft, .portrait):
            transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
//        case (.landscapeLeft, .landscapeRight):
//            transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        case (.landscapeRight, .portrait):
            transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi / 2))
//        case (.landscapeRight, .landscapeLeft):
//            transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi))
        case (.portrait, .landscapeLeft):
            transform = CGAffineTransform(rotationAngle: -CGFloat(Double.pi / 2))
        case (.portrait, .landscapeRight):
            transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        default: break
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
