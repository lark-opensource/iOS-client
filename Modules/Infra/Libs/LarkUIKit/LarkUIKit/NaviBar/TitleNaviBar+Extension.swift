//
//  TitleNaviBar+Extension.swift
//  LarkUIKit
//
//  Created by SuPeng on 9/8/19.
//

import UIKit
import Foundation
import LarkInteraction

public extension TitleNaviBar {
    /// 传入的leftButtons会自动添加到leftButtonStackView中
    var leftViews: [UIView] {
        get {
            return _leftStackView.arrangedSubviews
        }
        set {
            leftViews.forEach { $0.removeFromSuperview() }
            if !newValue.isEmpty {
                _leftStackView.isHidden = false
                _leftStackView.arrangedSubviews.forEach { _leftStackView.removeArrangedSubview($0) }
                newValue.forEach { _leftStackView.addArrangedSubview($0) }
            } else {
                _leftStackView.isHidden = true
            }
        }
    }

    /// 传入的rightButtons会自动添加到rightButtonStackView中
    var rightViews: [UIView] {
        get {
            return _rightStackView.arrangedSubviews.flatMap { $0 as? UIButton }
        }
        set {
            rightViews.forEach { $0.removeFromSuperview() }
            if !newValue.isEmpty {
                _rightStackView.isHidden = false
                _rightStackView.arrangedSubviews.forEach { _rightStackView.removeArrangedSubview($0) }
                newValue.forEach { _rightStackView.addArrangedSubview($0) }
            } else {
                _rightStackView.isHidden = true
            }
        }
    }

    /// 返回leftButtonStackView中最左边的button
    var leftView: UIView? {
        get {
            return leftViews.first
        }
        set {
            if let button = newValue {
                leftViews = [button]
            } else {
                leftViews = []
            }
        }
    }

    /// 返回rightButtonStackView中最右边的button
    var rightView: UIView? {
        get {
            return rightViews.last
        }
        set {
            if let button = newValue {
                rightViews = [button]
            } else {
                rightViews = []
            }
        }
    }

    /// 通过TitleNaviBarItem来生成UIButton，并设置进leftButtonsStackView中
    var leftItems: [TitleNaviBarItem] {
        get {
            return leftViews.flatMap { ($0 as? TitleNaviBarItemButton)?.item }
        }
        set {
            leftViews = newValue.map { TitleNaviBarItemButton(item: $0) }
        }
    }

    /// 通过TitleNaviBarItem来生成UIButton，并设置进rightButtonsStackView中
    var rightItems: [TitleNaviBarItem] {
        get {
            return rightViews.flatMap { ($0 as? TitleNaviBarItemButton)?.item }
        }
        set {
            rightViews = newValue.map { TitleNaviBarItemButton(item: $0) }
        }
    }

    /// 设置左边所有按钮enable状态
    func enableLeftItems(isEnable: Bool) {
        leftViews.forEach { ($0 as? UIControl)?.isEnabled = isEnable }
    }

    /// 设置右边所有按钮enable状态
    func enableRightItems(isEnable: Bool) {
        rightViews.forEach { ($0 as? UIControl)?.isEnabled = isEnable }
    }

    /// 在最左边插入一个返回按钮
    /// - Parameter action: 按钮点击时的action，如果为空，则默认执行当前navigationCotnroller pop操作
    func addBackButton(action: (() -> Void)? = nil) {
        leftViews.insert(BackOrCloseButton(style: .back, action: action), at: 0)
    }

    /// 在最左边插入一个关闭按钮
    /// - Parameter action: 按钮点击时候的action，如果为空，则默认执行当前viewcontroller的dismiss操作
    func addCloseButton(action: (() -> Void)? = nil) {
        leftViews.insert(BackOrCloseButton(style: .close, action: action), at: 0)
    }

    /// 在最左边插入一个小型关闭按钮
    /// - Parameter action: 按钮点击时候的action，如果为空，则默认执行当前viewcontroller的dismiss操作
    func addSmallCloseButton(action: (() -> Void)? = nil) {
        leftViews.insert(BackOrCloseButton(style: .smallClose, action: action), at: 0)
    }
}

private final class BackOrCloseButton: UIButton {
    enum Style {
        case back, close, smallClose
    }

    let style: Style
    let action: (() -> Void)?
    init(style: Style, action: (() -> Void)? = nil) {
        self.style = style
        self.action = action
        super.init(frame: .zero)
        imageEdgeInsets = .zero
        let image: UIImage
        switch style {
        case .back:
            image = Resources.navigation_back_light.withRenderingMode(.alwaysTemplate)
        case .close:
            image = Resources.navigation_close_outlined.withRenderingMode(.alwaysTemplate)
        case .smallClose:
            image = Resources.navigation_close_light.withRenderingMode(.alwaysTemplate)
        }
        tintColor = UIColor.ud.iconN1
        setImage(image, for: .normal)
        addTarget(self, action: #selector(buttonDidClick), for: .touchUpInside)
        if #available(iOS 13.4, *) {
            self.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 44, height: 36), 8)
                }))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonDidClick() {
        if let action = action {
            action()
        } else {
            switch style {
            case .back:
                viewController()?.navigationController?.popViewController(animated: true)
            case .close, .smallClose:
                viewController()?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension UIView {
    func viewController() -> UIViewController? {
        guard let next = next else { return nil }
        if let vc = next as? UIViewController {
            return vc
        }
        return (next as? UIView)?.viewController()
    }
}

private final class TitleNaviBarItemButton: UIButton {
    let item: TitleNaviBarItem
    init(item: TitleNaviBarItem) {
        self.item = item
        super.init(frame: .zero)

        setImage(item.image, for: .normal)
        setTitle(item.text?.text, for: .normal)
        setTitleColor(item.text?.color, for: .normal)
        titleLabel?.font = item.text?.font

        // LarkBadge
        if let path = item.badgePath {
            badge.observe(for: path)
        }

        // 目前只对有图片的 item 进行布局
        if item.image != nil {
            snp.makeConstraints({ (make) in
                make.width.height.equalTo(24)
            })
        }

        addTarget(self, action: #selector(buttonDidClick), for: .touchUpInside)

        if #available(iOS 13.4, *) {
            self.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (CGSize(width: 44, height: 36), 8)
                }))
        }

        if item.longPressAction != nil {
            lu.addLongPressGestureRecognizer(action: #selector(buttonLongPressed(gesture:)), duration: 1, target: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonDidClick() {
        item.action(self)
    }

    @objc
    private func buttonLongPressed(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            item.longPressAction?(self)
        default:
            break
        }
    }
}
