//
//  LKBarButtonItem.swift
//  Lark
//
//  Created by 吴子鸿 on 2017/8/1.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkInteraction
import UniverseDesignFont

open class LKBarSpaceItem: UIBarButtonItem {
    public var spaceView: UIView = UIView()
    public init(width: CGFloat = 0) {
        super.init()
        spaceView.frame = CGRect(x: 0, y: 0, width: width, height: 24)
        self.width = width
        self.customView = UIView(frame: spaceView.frame)
        self.customView?.addSubview(spaceView)
        spaceView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.equalTo(spaceView.frame.width)
            maker.height.equalTo(spaceView.frame.height)
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class LKBarButtonItem: UIBarButtonItem {
    public static let minWidth: CGFloat = 24
    public static let normalHeight: CGFloat = 24

    open var button: UIButton = UIButton(type: .system)

    open override var isEnabled: Bool {
        didSet {
            button.isEnabled = isEnabled
        }
    }

    public enum FontStyle {
        /// 一般用于左上角 BarButtonItem，对应 font = UDFont.body0
        case regular
        /// 一般用于右上角 BarButtonItem，对应 font = UDFont.headline
        case medium

        public var font: UIFont {
            switch self {
            case .regular:
                return UIFont.systemFont(ofSize: 16, weight: .regular)
            case .medium:
                return UIFont.systemFont(ofSize: 16, weight: .medium)
            }
        }
    }

    public init(
        image: UIImage? = nil,
        title: String? = nil,
        fontStyle: FontStyle = .regular,
        buttonType: UIButton.ButtonType = .system
    ) {
        super.init()
        button = UIButton(type: buttonType)
        _init(image: image, title: title, fontStyle: fontStyle)
    }

    public init(image: UIImage? = nil, title: String? = nil, fontStyle: FontStyle = .regular) {
        super.init()
        _init(image: image, title: title, fontStyle: fontStyle)
    }

    public init(image: UIImage? = nil, title: String? = nil) {
        super.init()
        _init(image: image, title: title)
    }

    private func _init(image: UIImage? = nil, title: String? = nil, fontStyle: FontStyle = .regular) {
        button.contentHorizontalAlignment = .left

        button.setImage(image, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit

        button.setTitle(title, for: .normal)
        let font = fontStyle.font
        button.titleLabel?.font = font

        self.customView = UIView(frame: button.frame)
        self.customView?.addSubview(button)

        setBtn(width: getButtonWidth(image: image, title: title, font: font))
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func resetTitle(title: String, font: UIFont = FontStyle.regular.font) {
        button.titleLabel?.text = title
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font
        let title = button.titleLabel?.text
        let buttonWidth = getButtonWidth(image: button.imageView?.image, title: title, font: font)
        setBtn(width: buttonWidth)
    }

    open func reset(title: String? = nil, image: UIImage? = nil, font: UIFont = FontStyle.regular.font) {
        button.titleLabel?.text = title
        button.titleLabel?.font = font
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        let buttonWidth = getButtonWidth(image: image, title: title, font: font)
        setBtn(width: buttonWidth)
    }

    open func setProperty(font: UIFont = FontStyle.regular.font, alignment: UIControl.ContentHorizontalAlignment = .left) {
        let buttonWidth = getButtonWidth(image: button.image(for: .normal), title: button.titleLabel?.text, font: font)
        setBtn(width: buttonWidth)
        button.titleLabel?.font = font
        button.contentHorizontalAlignment = alignment
    }

    open func setBtn(width: CGFloat, height: CGFloat = LKBarButtonItem.normalHeight) {
        if width < LKBarButtonItem.minWidth {
            button.frame = CGRect(x: 0, y: 0, width: LKBarButtonItem.minWidth, height: height)
        } else {
            button.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        button.snp.remakeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.equalTo(button.frame.size.width)
            maker.height.equalTo(button.frame.size.height)
        }

        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 20, height: 36), 8)
                    })
                )
            )
            button.addLKInteraction(pointer)
        }
    }

    open func setBtnColor(color: UIColor) {
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color.withAlphaComponent(0.6), for: .highlighted)
    }

    open func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvents)
    }

    public func addTarget(_ target: AnyObject?, action: @escaping () -> Void, for controlEvents: UIControl.Event) {
        _ = button.rx.controlEvent(controlEvents)
            .asObservable()
            .subscribe(onNext: { [weak target] _ in
                if target != nil {
                    action()
                }
            })
    }

    private func getButtonWidth(image: UIImage?, title: String?, font: UIFont) -> CGFloat {
        var buttonWidth: CGFloat = 0
        if let image = image, image.size.height > 0 {
            let imageWidth = image.size.width / image.size.height * LKBarButtonItem.normalHeight
            buttonWidth += imageWidth
        }
        if title != nil {
            let statusLabelText = title! as NSString
            let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 24)
            let dic = [NSAttributedString.Key.font: font]
            let strSize = statusLabelText.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: dic, context: nil).size
            buttonWidth += strSize.width
        }

        /// 由于 NavbarItem 在 iPad 上存在重复添加到 window 的场景，需要设置约束保证 customView 大小
        /// 如果不设置的话 size 在多次添加时 存在被压为 zero 的情况
        /// 但是 UIButtonLabel 在显示的时候，某些情况存在宽度存在大于计算宽度的场景，造成文字显示不全
        /// 这里使用 ceil 向上取整保证宽度足够显示文字
        return ceil(buttonWidth)
    }
}
