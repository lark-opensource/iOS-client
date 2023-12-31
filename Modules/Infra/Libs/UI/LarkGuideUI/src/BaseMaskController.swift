//
//  BaseMaskController.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/6/3.
//

import Foundation
import UIKit
import EENavigator

/// 提供引导组件的蒙层遮罩，带高亮区域
class BaseMaskController: UIViewController {
    private let maskView = UIView(frame: .zero)
    private let shapeLayer = CAShapeLayer()
    // 是否有点击背景事件
    var enableBackgroundTap: Bool = false
    // 是否有背景阴影
    var enableBackgroundMask: Bool {
        guard let shadowAlpha = shadowAlpha else { return false }
        return shadowAlpha > 0
    }
    // 阴影透明度
    var shadowAlpha: CGFloat?
    // window背景色
    var windowBackgroundColor: UIColor?
    // 快照视图
    var snapshotView: UIView?
    // 蒙层点击回调
    var maskTapHandler: (() -> Void)?
    // 引导消失回调
    var dismissHandler: (() -> Void)?

    private var maskBackgroundColor: UIColor {
        let shadowAlpha = self.shadowAlpha ?? Layout.shadowAlpha
        return UIColor.ud.bgMask.withAlphaComponent(shadowAlpha)
    }

    private lazy var backgroundMaskGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onBackgroundTapped(_:)))
        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayouts()
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shapeLayer.frame = maskView.bounds
        shapeLayer.isHidden = !enableBackgroundMask
        if enableBackgroundMask {
            shapeLayer.path = UIBezierPath(rect: view.bounds).cgPath
        }
    }

    /// @params: makeKey 是否makeKeyWindow,默认设为true
    public func showInWindow(to window: UIWindow, makeKey: Bool) {
        window.rootViewController = self
        window.backgroundColor = windowBackgroundColor ?? UIColor.ud.bgMask
        if #available(iOS 13.0, *) {
            if window.windowScene == nil {
                window.windowScene = Navigator.shared.mainSceneWindow?.windowScene //Global
            }
        }
        if makeKey {
            window.makeKeyAndVisible()
        } else {
            window.isHidden = false
        }
    }

    public func removeFromWindow(window: UIWindow? = nil) {
        let _window = window ?? view.window
        _window?.isHidden = true
        _window?.rootViewController = nil
        _window?.accessibilityIdentifier = nil
        view.removeFromSuperview()

        if let dismissHandler = self.dismissHandler {
            dismissHandler()
        }
    }
}

extension BaseMaskController {

    private func setupViews() {
        shapeLayer.fillRule = .evenOdd
        shapeLayer.fillColor = maskBackgroundColor.cgColor
        maskView.layer.addSublayer(shapeLayer)
        self.view.addSubview(maskView)
    }

    private func setupLayouts() {
        maskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        maskView.addGestureRecognizer(self.backgroundMaskGesture)
    }
}

extension BaseMaskController {
    /// 更新阴影的layout约束
    func addMaskLayoutGuide(layoutGuide: UILayoutGuide) {
        maskView.addLayoutGuide(layoutGuide)
    }

    /// 更新阴影的范围
    func updateMaskShadowPath(shadowPath: UIBezierPath) {
        shapeLayer.path = shadowPath.cgPath
    }

    @objc
    func onBackgroundTapped(_ sender: UITapGestureRecognizer) {
        guard enableBackgroundTap else { return }
        maskTapHandler?()
    }
}

extension BaseMaskController {
    enum Layout {
        static let shadowAlpha: CGFloat = 0.3
    }
}
