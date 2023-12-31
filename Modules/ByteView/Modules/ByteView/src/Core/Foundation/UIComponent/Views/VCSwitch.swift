//
//  VCSwitch.swift
//  ByteView
//
//  Created by yangfukai on 2020/9/2.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit

enum VCSwitchDisplayMode {
    case normal
    case disable
    case hidden
}

class VCSwitch: UISwitch {

    static let defaultSize = CGSize(width: 51, height: 31)

    override var isEnabled: Bool {
        didSet {
            if oldValue != isEnabled {
//                alpha = isEnabled ? 1.0 : 0.3
                isUserInteractionEnabled = isEnabled
            }

            if !isEnabled {
                self.onTintColor = UIColor.ud.primaryFillSolid03 // 打开状态下的背景颜色
                self.tintColor = UIColor.ud.lineBorderCard // 关闭状态下的背景空色 无用
                self.thumbTintColor = UIColor.ud.primaryOnPrimaryFill // 滑块的颜色
            } else {
                self.onTintColor = UIColor.ud.primaryContentDefault // 打开状态下的背景颜色
                self.tintColor = UIColor.ud.lineBorderComponent // 关闭状态下的背景空色 无用
                self.thumbTintColor = UIColor.ud.primaryOnPrimaryFill // 滑块的颜色
            }
        }
    }

    // 用于截获点击事件, 主要是为了实现开关状态不变，又要获取到点击事件的作用
    private lazy var button: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleButtonTouch), for: .touchUpInside)
        button.backgroundColor = UIColor.clear
        button.isHidden = true
        return button
    }()

    var displayMode: VCSwitchDisplayMode = .normal {
        didSet {
            if displayMode == .normal {
                self.onTintColor = UIColor.ud.primaryContentDefault // 打开状态下的背景颜色
                self.tintColor = UIColor.ud.lineBorderComponent // 关闭状态下的背景空色 无用
                self.thumbTintColor = UIColor.ud.primaryOnPrimaryFill // 滑块的颜色
                button.isHidden = true
            } else if displayMode == .disable {
                self.onTintColor = UIColor.ud.primaryFillSolid03 // 打开状态下的背景颜色
                self.tintColor = UIColor.ud.lineBorderCard // 关闭状态下的背景空色 无用
                self.thumbTintColor = UIColor.ud.primaryOnPrimaryFill // 滑块的颜色
                button.isHidden = false
            }
        }
    }
    var valueChanged: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        button.frame = self.frame
        addSubview(button)
        self.addTarget(self, action: #selector(handleChange), for: .valueChanged)
        self.transform = CGAffineTransform(scaleX: 48.0 / self.frame.width, y: 28.0 / self.frame.height)
    }

    @objc private func handleChange() {
        self.valueChanged?(self.isOn)
    }

    @objc private func handleButtonTouch() {
        self.valueChanged?(self.isOn)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setWidth(_ width: CGFloat) {
        let scale = width / Self.defaultSize.width
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    func setHeight(_ height: CGFloat) {
        let scale = height / Self.defaultSize.height
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
