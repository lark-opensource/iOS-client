//
//  VisualButton.swift
//  ByteView
//
//  Created by huangshun on 2019/5/29.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

public enum VisualButtonEdgeInsetStyle {
    case none
    case top, left, bottom, right
}

public protocol VisualButtonEventDelegate: AnyObject {
    func didHighlighted()
    func didUnhighlighted()
}

open class VisualButton: UIButton {

    private lazy var maskOutView: UIView = {
        let maskOutView = UIView(frame: .zero)
        maskOutView.isUserInteractionEnabled = false
        self.addSubview(maskOutView)
        maskOutView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return maskOutView
    }()

    private lazy var redPointView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    private var borderColorMap: [UInt: UIColor] = [UIControl.State.normal.rawValue: UIColor.clear]
    private var maskColorMap: [UInt: UIColor] = [UIControl.State.normal.rawValue: UIColor.clear]
    private var backgroundColorMap: [UInt: UIColor] = [:]
    private var shadowColorMap: [UInt: UIColor] = [UIControl.State.normal.rawValue: UIColor.clear]

    open weak var delegate: VisualButtonEventDelegate?

    // 文字、图片边距设置默认none, 非none titleEdgeInsets, imageEdgeInsets 失效
    open var edgeInsetStyle: VisualButtonEdgeInsetStyle = .none {
        didSet {
            guard edgeInsetStyle != .none else {
                return
            }
            titleLabel?.textAlignment = .center
        }
    }
    open var space: CGFloat = 0.0
    open var customInsets: UIEdgeInsets?
    open var isNeedExtend: Bool = false // 按钮是否需要根据内容自动扩展

    open var showRedPoint: Bool = false {
        didSet {
            redPointView.isHidden = !showRedPoint
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(redPointView)
    }

    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image, for: state)
        // 针对iOS 12 toolbar item布局不对此处强制刷新
        guard #available(iOS 13.0, *) else {
            setNeedsLayout()
            layoutIfNeeded()
            return
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = imageView {
            let newFrame = CGRect(x: imageView.frame.maxX - 4, y: imageView.frame.minY - 4, width: 8, height: 8)
            if redPointView.frame != newFrame {
                redPointView.frame = newFrame
            }
            if imageView.alpha != imageAlpha {
                imageView.alpha = imageAlpha
            }
        }
    }

    open override var isHighlighted: Bool {
        didSet {
            setUpColors(isHighlighted ? .highlighted : .normal)
            if isHighlighted {
                delegate?.didHighlighted()
            } else {
                delegate?.didUnhighlighted()
            }
        }
    }

    public override var backgroundColor: UIColor? {
        didSet {
            guard let backgroundColor = backgroundColor else {
                return
            }
            if backgroundColorMap[UIControl.State.normal.rawValue] == nil {
                backgroundColorMap[UIControl.State.normal.rawValue] = backgroundColor
            }
        }
    }

    public override var isEnabled: Bool {
        didSet {
            setUpColors(isEnabled ? .normal : .disabled)
        }
    }

    public override var isSelected: Bool {
        didSet {
            setUpColors(isSelected ? .selected : .normal)
        }
    }

    open var extendEdge: UIEdgeInsets = .zero

    open var imageAlpha: CGFloat = 1 {
        didSet {
            imageView?.alpha = imageAlpha
        }
    }

    open var touchUpInsideAction: (() -> Void)? {
        didSet {
            if actions(forTarget: self, forControlEvent: .touchUpInside) == nil {
                addTarget(self, action: #selector(touchUpInsideAction(_:)), for: .touchUpInside)
            }
        }
    }

    @objc private func touchUpInsideAction(_ sender: Any) {
        touchUpInsideAction?()
    }

    /// for conflict of point(inside:with:)
    public func isInside(_ point: CGPoint) -> Bool {
        bounds.inset(by: extendEdge).contains(point)
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: extendEdge).contains(point)
    }

    open func setUpColors(_ state: UIControl.State?) {
        if let raw = state?.rawValue,
            let border = borderColorMap[raw] {
            layer.ud.setBorderColor(border)
        }

        if let raw = state?.rawValue,
            let mask = maskColorMap[raw] {
            maskOutView.backgroundColor = mask
        }

        if let raw = state?.rawValue,
            let background = backgroundColorMap[raw] {
            backgroundColor = background
        }

        if let raw = state?.rawValue,
           let shadow = shadowColorMap[raw] {
            layer.ud.setShadowColor(shadow)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open func setBorderColor(_ color: UIColor?, for state: UIControl.State) {
        borderColorMap[state.rawValue] = color
        setUpColors(self.state)
    }

    open func setMaskColor(_ color: UIColor?, for state: UIControl.State) {
        maskColorMap[state.rawValue] = color
        setUpColors(self.state)
    }

    open func setBGColor(_ color: UIColor?, for state: UIControl.State) {
        backgroundColorMap[state.rawValue] = color
        setUpColors(self.state)
    }

    open func setShadowColor(_ color: UIColor?, for state: UIControl.State) {
        shadowColorMap[state.rawValue] = color
        setUpColors(self.state)
    }

    open override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.titleRect(forContentRect: contentRect)
        let imageRect = super.imageRect(forContentRect: contentRect)
        let imageWidth = imageRect.size.width
        let imageHeight = imageRect.size.height

        let rectHeight = rect.height
        let space = imageWidth > 0 ? self.space : 0
        var heightOffset = (contentRect.height - (imageHeight + rectHeight + space)) / 2
        let widthOffset: CGFloat
        if isNeedExtend {
            var insets = contentEdgeInsets
            // image+space+title若能放的下，则整体居中偏移
            // image+space+title若不能放的下，则image+title居中偏移,并通过contentEdgeInsets扩展button
            if contentRect.width >= imageWidth + rect.width + space, insets.left == insets.right {
                widthOffset = (contentRect.width - (imageWidth + rect.width + space)) / 2
            } else {
                widthOffset = (contentRect.width - (imageWidth + rect.width)) / 2
                if insets.left == insets.right {
                    insets.right += imageWidth + rect.width + space - contentRect.width
                    contentEdgeInsets = insets
                }
            }
        } else {
            widthOffset = (contentRect.width - (imageWidth + rect.width + space)) / 2
        }
        if let insets = customInsets {
            heightOffset = heightOffset > insets.top ? heightOffset : insets.top
        }

        switch edgeInsetStyle {
        case .top:
            if let customInsets = customInsets {
                return CGRect(x: customInsets.left,
                              y: heightOffset + imageHeight + space,
                              width: contentRect.width - customInsets.left - customInsets.right,
                              height: rectHeight)
            } else {
                return CGRect(x: contentEdgeInsets.left,
                              y: heightOffset + imageHeight + space,
                              width: contentRect.width,
                              height: rectHeight)
            }
        case .left:
            return CGRect(x: widthOffset + imageWidth + space + contentEdgeInsets.left,
                              y: (contentRect.height - rectHeight) / 2,
                              width: rect.width,
                              height: rectHeight)
        case .bottom:
            return CGRect(x: 0,
                          y: heightOffset,
                          width: contentRect.width,
                          height: rectHeight)
        case .right:
            return CGRect(x: widthOffset,
                          y: (contentRect.height - rectHeight) / 2,
                          width: rect.width,
                          height: rectHeight)
        case .none:
            return rect
        }
    }

    open override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let rect = super.imageRect(forContentRect: contentRect)
        let titleRect = self.titleRect(forContentRect: contentRect)

        switch edgeInsetStyle {
        case .top:
            var y = titleRect.minY - space - rect.height
            return CGRect(x: contentRect.width / 2.0 - rect.width / 2.0 + contentEdgeInsets.left,
                          y: y,
                          width: rect.width,
                          height: rect.height)
        case .left:
            return CGRect(x: titleRect.minX - space - rect.width,
                          y: (contentRect.height - rect.height) / 2,
                          width: rect.width,
                          height: rect.height)
        case .bottom:
            return CGRect(x: contentRect.width / 2.0 - rect.width / 2.0,
                          y: titleRect.maxY + space,
                          width: rect.width, height: rect.height)
        case .right:
            return CGRect(x: titleRect.maxX + space,
                          y: (contentRect.height - rect.height) / 2,
                          width: rect.width, height: rect.height)
        case .none:
            return rect
        }
    }
}
