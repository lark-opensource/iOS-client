//
//  CornerRadiusView.swift
//  AsyncComponent
//
//  Created by 姚启灏 on 2019/9/2.
//

import UIKit
import Foundation
import UniverseDesignTheme
import LKCommonsTracker

public struct BorderRadius {
    public var topLeft: CGFloat {
        get {
            return self._topLeft ?? 0
        }
        set {
            self._topLeft = newValue
        }
    }

    public var topRight: CGFloat {
        get {
            return self._topRight ?? self.topLeft
        }
        set {
            self._topRight = newValue
        }
    }

    public var bottomRight: CGFloat {
        get {
            return self._bottomRight ?? self.topLeft
        }
        set {
            self._bottomRight = newValue
        }
    }

    public var bottomLeft: CGFloat {
        get {
            return self._bottomLeft ?? self.topRight
        }
        set {
            self._bottomLeft = newValue
        }
    }

    private var _topLeft: CGFloat?
    private var _topRight: CGFloat?
    private var _bottomRight: CGFloat?
    private var _bottomLeft: CGFloat?

    public init(topLeft: CGFloat) {
        self._topLeft = topLeft
    }

    public init(topLeft: CGFloat,
                topRight: CGFloat) {
        self._topLeft = topLeft
        self._topRight = topRight
    }

    public init(topLeft: CGFloat,
                topRight: CGFloat,
                bottomRight: CGFloat) {
        self._topLeft = topLeft
        self._topRight = topRight
        self._bottomRight = bottomRight
    }

    public init(topLeft: CGFloat,
                topRight: CGFloat,
                bottomRight: CGFloat,
                bottomLeft: CGFloat) {
        self._topLeft = topLeft
        self._topRight = topRight
        self._bottomLeft = bottomLeft
        self._bottomRight = bottomRight
    }
}

open class CornerRadiusView: UIView {
    private var fillColor: UIColor?
    private var strokeColor: UIColor?
    private var showBoder: Bool = false

    public var config: BorderRadius = BorderRadius(topLeft: 0) {
        didSet {
            self.path = self.getRadiusPath().cgPath
            self.maskPath = self.getRadiusPath().cgPath
        }
    }

    public var path: CGPath?

    public var maskPath: CGPath?

    public var masksToBounds: Bool = false {
        didSet {
            self.setMasksToBounds(masksToBounds)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var maskLayer: CAShapeLayer = {
        let maskLayer = CAShapeLayer()
        maskLayer.borderColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.clear.cgColor
        maskLayer.lineWidth = 1
        maskLayer.lineJoin = .round
        maskLayer.frame = bounds
        maskLayer.path = maskPath
        return maskLayer
    }()

    public lazy var cornerRadiusLayer: CAShapeLayer = {
        let cornerRadiusLayer = CAShapeLayer()
        cornerRadiusLayer.borderColor = UIColor.clear.cgColor
        cornerRadiusLayer.fillColor = UIColor.clear.cgColor
        cornerRadiusLayer.strokeColor = UIColor.clear.cgColor
        cornerRadiusLayer.lineWidth = 1
        cornerRadiusLayer.lineJoin = .round
        cornerRadiusLayer.isHidden = true
        cornerRadiusLayer.frame = bounds
        cornerRadiusLayer.path = self.getRadiusPath().cgPath
        layer.insertSublayer(cornerRadiusLayer, at: 0)
        return cornerRadiusLayer
    }()

    open func updateConfig(_ config: BorderRadius) {
        self.config = config
        cornerRadiusLayer.path = path
        maskLayer.path = maskPath
    }

    open func updateLayer(strokeColor: UIColor = UIColor.black,
                          fillColor: UIColor? = nil,
                          lineWidth: CGFloat = 1,
                          showBoder: Bool = false) {
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.getRealUserInterfaceStyle()
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.showBoder = showBoder
        cornerRadiusLayer.strokeColor = strokeColor.cgColor
        if showBoder {
            self.path = self.getRadiusPath().cgPath
            self.maskPath = self.getRadiusPath(margin: lineWidth / 2).cgPath
        } else {
            self.path = self.getRadiusPath().cgPath
            self.maskPath = self.getRadiusPath().cgPath
        }
        if let fillColor = fillColor {
            cornerRadiusLayer.fillColor = fillColor.cgColor
        }
        cornerRadiusLayer.lineWidth = lineWidth
        cornerRadiusLayer.path = path
        maskLayer.path = maskPath

        if masksToBounds, path != nil {
            self.layer.mask = maskLayer
        } else {
            self.layer.mask = nil
        }
        cornerRadiusViewThemeWrongAlertLogging()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        let lineWidth = cornerRadiusLayer.lineWidth
        if showBoder {
            cornerRadiusLayer.frame = CGRect(x: bounds.minX + lineWidth / 2,
                                             y: bounds.minY + lineWidth / 2,
                                             width: bounds.width - lineWidth,
                                             height: bounds.height - lineWidth)
            maskLayer.frame = CGRect(x: bounds.minX + lineWidth / 2,
                                     y: bounds.minY + lineWidth / 2,
                                     width: bounds.width - lineWidth,
                                     height: bounds.height - lineWidth)
        } else {
            cornerRadiusLayer.frame = bounds
            maskLayer.frame = bounds
        }
        cornerRadiusLayer.path = path
        maskLayer.path = maskPath
    }

    private func getRadiusPath(margin: CGFloat = 0) -> UIBezierPath {
        let topLeftRadius: CGFloat = config.topLeft
        let bottomLeftRadius: CGFloat = config.bottomLeft
        let topRightRadius: CGFloat = config.topRight
        let bottomRightRadius: CGFloat = config.bottomRight
        let path = UIBezierPath(arcCenter: CGPoint(x: topLeftRadius + margin, y: topLeftRadius + margin),
                                radius: topLeftRadius,
                                startAngle: 3 * CGFloat.pi / 2,
                                endAngle: CGFloat.pi,
                                clockwise: false)
        path.addArc(withCenter: CGPoint(x: bottomLeftRadius + margin, y: bounds.height - bottomLeftRadius - margin),
                    radius: bottomLeftRadius,
                    startAngle: CGFloat.pi,
                    endAngle: CGFloat.pi / 2,
                    clockwise: false)
        path.addArc(withCenter: CGPoint(x: bounds.width - bottomRightRadius - margin,
                                        y: bounds.height - bottomRightRadius - margin),
                    radius: bottomRightRadius,
                    startAngle: CGFloat.pi / 2,
                    endAngle: 0,
                    clockwise: false)
        path.addArc(withCenter: CGPoint(x: bounds.width - topRightRadius - margin, y: topRightRadius + margin),
                    radius: topRightRadius,
                    startAngle: 0,
                    endAngle: 3 * CGFloat.pi / 2,
                    clockwise: false)
        path.close()
        return path
    }

    private func setMasksToBounds(_ masksToBounds: Bool) {
        self.layer.masksToBounds = masksToBounds
        /// 当masksToBounds且path不为空时才去使用自定义的mask
        /// 否则外面使用时如果没有初始化path则会出现视图被遮挡的情况
        if masksToBounds, path != nil {
            self.layer.mask = maskLayer
        } else {
            self.layer.mask = nil
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cornerRadiusLayer.strokeColor = strokeColor?.cgColor
        if let fillColor = fillColor {
            cornerRadiusLayer.fillColor = fillColor.cgColor
        }
    }
}

// 气泡颜色异常修复及日志上报
private extension CornerRadiusView {
    // swiftlint:disable all
    func cornerRadiusViewThemeWrongAlertLogging() {
        guard #available(iOS 13.0, *) else { return }
        let realStyle = UDThemeManager.getRealUserInterfaceStyle()
        // 气泡DM显示错误报警检测
        if self.traitCollection.userInterfaceStyle != realStyle {
            self.findAllSuperViewsAndPostToSlardar(view: self, realStyle: realStyle)
        }
    }

    @available (iOS 13.0, *)
    private func findAllSuperViewsAndPostToSlardar(view: UIView, realStyle: UIUserInterfaceStyle) {
        var superView = view.superview
        var res: String = addViewDescription(view: view, realStyle: realStyle)
        while let topView = superView {
            res += "\n" + addViewDescription(view: topView, realStyle: realStyle)
            superView = topView.superview
        }
        Tracker.post(SlardarEvent(name: "bubble_dm_issue",
                                  metric: ["parents_tree": res],
                                  category: ["view": "CornerRadiusView"],
                                  extra: [:]))
    }

    @available (iOS 13.0, *)
    private func addViewDescription(view: UIView, realStyle: UIUserInterfaceStyle) -> String {
        return "className - [ui, oui, real]: " + String(describing: type(of: view.self)) + " [" + view.traitCollection.userInterfaceStyle.rawValue.description + "," + view.overrideUserInterfaceStyle.rawValue.description + "," + realStyle.rawValue.description + "]"
    }
    // swiftlint:enable all
}
