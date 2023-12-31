//
//  FollowVcWindow.swift
//  ByteView
//
//  Created by kiri on 2021/2/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

/// 为一直跟随vc的window提供基类，此类window在所在scene关闭的时候会转移到其他可见的scene上显示
open class FollowVcWindow: UIWindow {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            setupSceneListeners()
        }
    }

    @available(iOS 13.0, *)
    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        setupSceneListeners()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        if #available(iOS 13.0, *) {
            setupSceneListeners()
        }
    }

    @available(iOS 13.0, *)
    private func setupSceneListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(vcSceneDidChange(_:)),
                                               name: VCScene.didChangeVcSceneNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @available(iOS 13.0, *)
    @objc private func vcSceneDidChange(_ notification: Notification) {
        if let window = notification.object as? UIWindow, let ws = window.windowScene {
            self.windowScene = ws
        }
    }
}
