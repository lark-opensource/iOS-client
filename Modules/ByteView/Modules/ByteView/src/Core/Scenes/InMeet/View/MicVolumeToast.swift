//
//  MicVolumeToast.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/11/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewUI

class MicVolumeToast: UIView {
    lazy var micView: MicIconView = {
        let iconView = MicIconView(iconSize: 32, normalColor: UIColor.ud.primaryOnPrimaryFill)
        iconView.setMicState(.on())
        return iconView
    }()

    private let containerView = UIView()
    private let textLabel = UILabel()

    private static var _window: UIWindow?
    private static var window: UIWindow {
        if let w = _window {
            return w
        }
        let window = VCScene.createWindow(UIWindow.self, tag: .toast)
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindow.Level.alert
        window.rootViewController = PuppetWindowRootViewController(allowsToInteraction: false)
        _window = window
        return window
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        containerView.backgroundColor = UIColor.ud.bgMask
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 10
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide).inset(24)
            make.width.height.greaterThanOrEqualTo(96)
        }

        let innerView = UIView()
        containerView.addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(17)
        }

        innerView.addSubview(micView)
        micView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(32)
            make.left.right.equalToSuperview().priority(.high)
            make.right.lessThanOrEqualToSuperview()
            make.left.greaterThanOrEqualToSuperview()
        }

        textLabel.text = I18n.View_G_UnmuteForNow_BoxToast
        textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        textLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textLabel.font = .systemFont(ofSize: 12, weight: .medium)
        textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        innerView.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(micView.snp.bottom).offset(10)
            make.height.equalTo(13)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().priority(.high)
            make.right.lessThanOrEqualToSuperview()
            make.left.greaterThanOrEqualToSuperview()
        }
    }

    func show() {
        let view = MicVolumeToast.window
        if #available(iOS 13.0, *), let ws = VCScene.windowScene, MicVolumeToast.window.windowScene != ws {
            MicVolumeToast.window.windowScene = ws
        }

        if self.superview != view {
            view.addSubview(self)
            if self.frame != view.bounds {
                self.frame = view.bounds
                self.vc.updateKeyboardLayout()
            }
            self.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        view.layoutIfNeeded()
        MicVolumeToast.window.isHidden = false
    }

    func hide() {
        MicVolumeToast.window.isHidden = true
    }

    func destroy() {
        MicVolumeToast.window.isHidden = true
        MicVolumeToast._window = nil
    }
}
