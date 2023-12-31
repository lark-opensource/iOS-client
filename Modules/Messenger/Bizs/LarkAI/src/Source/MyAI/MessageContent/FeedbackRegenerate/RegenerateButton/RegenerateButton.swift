//
//  RegenerateButton.swift
//  LarkAI
//
//  Created by 李勇 on 2023/5/26.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkExtensions
import UniverseDesignIcon
import UniverseDesignColor

public final class RegenerateButton: UIButton {
    private let iconView: UIImageView

    public override init(frame: CGRect) {
        self.iconView = UIImageView(frame: CGRect(origin: CGPoint(x: 2.auto(), y: 2.auto()), size: CGSize(width: 16.auto(), height: 16.auto())))
        // UIImageView和气泡是左对齐的，但是视觉上没有对齐；以为是图片contentMode的问题，但是设置scaleToFill后还是视觉没对齐，后面发现是图片本身有padding的问题
        self.iconView.contentMode = .scaleToFill
        super.init(frame: frame)
        self.addSubview(self.iconView)
        self.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        // 设置按压态背景色：长按会立即就执行touchesCancelled手势，点击立马松手不会看到背景变灰；不过UX最新设计已经不需要背景色变化了，所以也就没问题了
        // self.setBackgroundImage(UIColor.ud.image(with: UIColor.ud.udtokenBtnSeBgNeutralPressed, size: CGSize(width: 1, height: 1), scale: 1), for: .highlighted)
        // self.setBackgroundImage(UIColor.ud.image(with: UIColor.ud.bgFloat, size: CGSize(width: 1, height: 1), scale: 1), for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
    }

    /// 设置内容，内部不持有RegenerateButtonComponentProps，做到单项数据流
    public func setup(props: RegenerateButtonComponentProps) {
        self.isEnabled = props.buttonEnable
        self.iconView.image = UDIcon.getIconByKey(props.iconKey, iconColor: props.iconColor)
        // reloadCell时animation(forKey: "lu.rotateAnimation")稳定为nil，导致动画被移除了，用UDLoading也不行；目前还不知道原因
        if props.iconRotate, self.iconView.layer.animation(forKey: "lu.rotateAnimation") == nil { self.iconView.lu.addRotateAnimation() }
        // 取消loading动画
        if !props.iconRotate { self.iconView.lu.removeRotateAnimation() }
    }
}
