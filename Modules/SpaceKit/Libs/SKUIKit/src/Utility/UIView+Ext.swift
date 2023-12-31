//
//  UIView+Ext.swift
//  SpaceKit
//
//  Created by weidong fu on 13/3/2018.
//
//  Included OSS: WavesWallet-iOS
//  Copyright (c) 2018 WavesPlatform
//  spdx license identifier: MIT

import Foundation
import SKFoundation
import UniverseDesignColor

public extension UIView {
    func dingOut() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    func dongOut() {
        setNeedsLayout()
        layoutIfNeeded()
    }
}

public extension UIView {
    enum ViewSide {
        case top
        case right
        case bottom
        case left
    }

    /// Add a border to this view by adding a subview to this view.
    ///
    /// - The `offset`'s are used to customize the frame of the border. The default value of `offset`'s is `0`.
    ///   However, invalid offsets won’t do anything (if you set a left offset on a right sided border, for example). You can set left, right and top offsets for a top-sided border.
    ///
    /// - Parameters:
    ///   - side: The side of the border of interest.
    ///   - thickness: The thickness (`height` or `width`) of the border.
    ///   - color: The color of the border.
    func addViewBackedBorder(side: ViewSide, thickness: CGFloat, color: UIColor, leftOffset: CGFloat = 0, rightOffset: CGFloat = 0, topOffset: CGFloat = 0, bottomOffset: CGFloat = 0) {
        switch side {
        case .top:
            let border: UIView = _getViewBackedOneSidedBorder(frame: CGRect(x: 0 + leftOffset,
                                                                            y: 0 + topOffset,
                                                                            width: self.frame.size.width - leftOffset - rightOffset,
                                                                            height: thickness), color: color)
            border.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            self.addSubview(border)

        case .right:
            let border: UIView = _getViewBackedOneSidedBorder(frame: CGRect(x: self.frame.size.width - thickness - rightOffset,
                                                                            y: 0 + topOffset, width: thickness,
                                                                            height: self.frame.size.height - topOffset - bottomOffset), color: color)
            border.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
            self.addSubview(border)

        case .bottom:
            let border: UIView = _getViewBackedOneSidedBorder(frame: CGRect(x: 0 + leftOffset,
                                                                            y: self.frame.size.height - thickness - bottomOffset,
                                                                            width: self.frame.size.width - leftOffset - rightOffset,
                                                                            height: thickness), color: color)
            border.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            self.addSubview(border)
        case .left:
            let border: UIView = _getViewBackedOneSidedBorder(frame: CGRect(x: 0 + leftOffset,
                                                                            y: 0 + topOffset,
                                                                            width: thickness,
                                                                            height: self.frame.size.height - topOffset - bottomOffset), color: color)
            border.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
            self.addSubview(border)
        }
    }

    fileprivate func _getViewBackedOneSidedBorder(frame: CGRect, color: UIColor) -> UIView {
        let border: UIView = UIView(frame: frame)
        border.backgroundColor = color
        return border
    }
}

extension UIView: PrivateFoundationExtensionCompatible {}

public extension PrivateFoundationExtension where BaseType: UIView {
    var height: CGFloat {
        get {
            return base.frame.size.height
        }
        set {
            base.frame = CGRect(origin: base.frame.origin, size: CGSize(width: base.frame.size.width, height: newValue))
        }
    }

    var width: CGFloat {
        get {
            return base.frame.size.width
        }
        set {
            base.frame = CGRect(origin: base.frame.origin, size: CGSize(width: newValue, height: base.frame.size.height))
        }
    }

    var origin: CGPoint {
        get {
            return base.frame.origin
        }
        set {
            base.frame = CGRect(origin: newValue, size: base.frame.size)
        }
    }

    var boundsOrigin: CGPoint {
        get {
            return base.bounds.origin
        }
        set {
            base.bounds = CGRect(origin: newValue, size: base.bounds.size)
        }
    }

    var size: CGSize {
        get {
            return base.frame.size
        }
        set {
            base.frame = CGRect(origin: base.frame.origin, size: newValue)
        }
    }

    var boundsSize: CGSize {
        get {
            return base.bounds.size
        }
        set {
            base.bounds = CGRect(origin: base.bounds.origin, size: newValue)
        }
    }

    func screenshot() -> UIImage? {
        let transform = self.base.transform
        self.base.transform = .identity
        var screenshot: UIImage?
        var imgSize = self.base.frame.size
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, SKDisplay.scale)
        if let context = UIGraphicsGetCurrentContext() {
            self.base.layer.render(in: context)
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        self.base.transform = transform
        return screenshot
    }
}

extension UIView {
    // 拿到这个 UIView 所隶属的 UIViewController (如果有的话)
    public var affiliatedViewController: UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.affiliatedViewController
        } else {
            return nil
        }
    }
    
    // 拿view的window
    public var affiliatedWindow: UIWindow? {
        guard !UserScopeNoChangeFG.ZJ.windowNotFoundFixDisable else {
            return self.window
        }
        
        if self.window != nil {
            return self.window
        } else {
            return self.affiliatedViewController?.parent?.view.affiliatedWindow
        }
    }
}

extension UIView {
    public var containFirstResponder: Bool {
        if self.isFirstResponder {
            return true
        }
        for view in self.subviews where view.containFirstResponder {
            return true
        }
        return false
    }
}

private class GradientView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradientLayer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGradientLayer()
    }

    private func setupGradientLayer() {
        gradientLayer.colors = [
            UDColor.N900.withAlphaComponent(0.05).cgColor,
            UDColor.N900.withAlphaComponent(0.08).cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.75, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

extension UIView {
    
    public func addGradientLoadingView(cornerRadius: CGFloat = 0) -> UIView {
        let gradientView = GradientView()
        gradientView.layer.cornerRadius = cornerRadius
        gradientView.layer.masksToBounds = true
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(gradientView)
        return gradientView
    }
    
    public func hideGradientLoadingView() {
        if let gradientView = self.subviews.first(where: { view in
            view.isKind(of: GradientView.self)
        }) {
            gradientView.isHidden = true
        }
    }
}
