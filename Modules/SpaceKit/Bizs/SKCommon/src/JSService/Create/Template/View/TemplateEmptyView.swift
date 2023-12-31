//
//  TemplateEmptyView.swift
//  SKCommon
//
//  Created by huayufan on 2022/5/24.
//  

import Foundation
import SnapKit
import UIKit
import UniverseDesignEmpty
import UniverseDesignButton
import SKUIKit

class TemplateEmptyView: UIView {
    public var topToWindow: CGFloat { SKDisplay.windowBounds(self).height / 3 }

    ///UI配置
    var config: UDEmptyConfig {
        return empty.config
    }

    // empty content 默认使用 距离windows顶部 1/3 的布局
    // 当把 useCenterConstraints 设置为 true 的时候 content 使用中心布局
    var useCenterConstraints: Bool = false {
        didSet {
            empty.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview().inset(16)
                make.right.lessThanOrEqualToSuperview().inset(16)
                make.top.greaterThanOrEqualToSuperview().offset(10)
            }
        }
    }

    public var clickHandler: (() -> Void)?

    var empty: UDEmpty
    
    var primaryButtonConfig: UDButtonUIConifg? {
        get {
            empty.primaryButtonConfig
        }
        set {
            empty.primaryButtonConfig = newValue
        }
    }

    ///初始化方法
    init(config: UDEmptyConfig) {
        empty = UDEmpty(config: config)
        super.init(frame: .zero)

        self.addSubview(empty)
        addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                          action: #selector(clickAction)))
        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window,
            !self.useCenterConstraints else { return }
        empty.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(16)
            make.right.lessThanOrEqualToSuperview().inset(16)
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.top.equalTo(window).offset(self.topToWindow).priority(.medium)
        }
    }

    @objc
    private func clickAction() {
        clickHandler?()
    }
}
