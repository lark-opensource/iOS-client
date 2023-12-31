//
//  UDEmptyView.swift
//  UniverseDesignEmpty
//
//  Created by 姚启灏 on 2021/6/1.
//

import Foundation
import SnapKit
import UIKit

public final class UDEmptyView: UIView {
    public var topToWindow: CGFloat { UIScreen.main.bounds.height / 3 }

    ///UI配置
    public var config: UDEmptyConfig {
        return empty.config
    }

    // empty content 默认使用 距离windows顶部 1/3 的布局
    // 当把 useCenterConstraints 设置为 true 的时候 content 使用中心布局
    public var useCenterConstraints: Bool = false {
        didSet {
            empty.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.top.greaterThanOrEqualToSuperview().offset(10)
            }
        }
    }

    public var clickHandler: (() -> Void)?

    var empty: UDEmpty

    ///初始化方法
    public init(config: UDEmptyConfig) {
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

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window,
            !self.useCenterConstraints else { return }
        empty.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(10)
            make.top.equalTo(window).offset(self.topToWindow).priority(.medium)
        }
    }

    ///更新当前空状态
    public func update(config: UDEmptyConfig) {
        self.empty.update(config: config)
    }

    @objc
    private func clickAction() {
        clickHandler?()
    }
}
