//
//  GuideCustomViewController.swift
//  LarkGuideUI
//
//  Created by zhenning on 2020/08/13.
//

import Foundation
final class GuideCustomViewController: BaseMaskController {
    private var customView: GuideCustomView
    private var customConfig: GuideCustomConfig

    init(customConfig: GuideCustomConfig) {
        self.customConfig = customConfig
        self.customView = customConfig.customView
        super.init()
        self.customView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        // 蒙层背景阴影设置
        let shadowAlpha = customConfig.shadowAlpha ?? BaseMaskController.Layout.shadowAlpha
        self.shadowAlpha = shadowAlpha
        /// 默认背景可以响应
        self.enableBackgroundTap = customConfig.enableBackgroundTap ?? true

        self.view.addSubview(self.customView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.customView.frame = self.customConfig.viewFrame
    }

    func closeCustomView() {
        removeFromWindow(window: self.view.window)
    }
}

extension GuideCustomViewController: GuideCustomViewDelegate {
    func didCloseView(customView: GuideCustomView) {
        closeCustomView()
        self.customConfig.delegate?.didCloseView(customView: customView)
    }
}
