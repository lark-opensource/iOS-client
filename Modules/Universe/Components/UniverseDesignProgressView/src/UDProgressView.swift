//
//  UDProgressView.swift
//  UniversalDesignProgressView
//
//  Created by CJ on 2020/12/23.
//
// swiftlint:disable line_length trailing_whitespace

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

public final class UDProgressView: UIView {
    /// 0.0 .. 1.0, default is 0.0. values outside are pinned.
    private(set) var progress: CGFloat = 0.0
    /// progressView  UI Config
    private let config: UDProgressViewUIConfig
    public var observedProgress: Progress?
    
    /// progressView type
    private var type: UDProgressViewType {
        return config.type
    }
    /// progressView metrics
    private var barMetrics: UDProgressViewBarMetrics {
        return config.barMetrics
    }
    /// progressView layout direction
    private var layoutDirection: UDProgressViewLayoutDirection {
        return config.layoutDirection
    }
    /// progressView themeColor
    private var themeColor: UDProgressViewThemeColor {
        return config.themeColor
    }
    /// whether to display  progress value, default false
    private var showValue: Bool {
        return config.showValue
    }
    
    private var progressBarViewWidthConstraint: Constraint?
    private var backgroundLayer: CAShapeLayer?
    private var frameLayer: CAShapeLayer?
    private var progressingView: UIView?
    /// progressView component layout config
    private let layoutConfig: UDProgressViewLayoutConfig
    private var contentHeight: CGFloat = 16
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.N500
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "0%"
        return label
    }()
    
    public init(config: UDProgressViewUIConfig = UDProgressViewUIConfig(),
                layoutConfig: UDProgressViewLayoutConfig = UDProgressViewLayoutConfig()) {
        self.config = config
        self.layoutConfig = layoutConfig
        super.init(frame: .zero)
        setupUI()
    }

    public init(config: UDProgressViewUIConfig = UDProgressViewUIConfig()) {
        self.config = config
        self.layoutConfig = UDProgressViewLayoutConfig()
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        addSubview(contentView)
        addSubview(valueLabel)
        contentView.backgroundColor = (type == .linear) ? themeColor.bgColor : .clear
        contentView.layer.cornerRadius = (barMetrics == .default)
            ? layoutConfig.linearSmallCornerRadius
            : layoutConfig.linearBigCornerRadius
        valueLabel.textAlignment = (layoutDirection == .horizontal) ? .left : .center
        valueLabel.textColor = themeColor.textColor
        switch type {
        case .linear:
            contentHeight = (barMetrics == .default)
                ? layoutConfig.linearProgressDefaultHeight
                : layoutConfig.linearProgressRegularHeight
            setupLinearConstraints()
            setupProgressBarView()
        case .circular:
            contentHeight = layoutConfig.circleProgressWidth
            setupCircularConstraints()
            setupShapeLayers()
        }
    }
    
    /// setupLinearConstraints
    private func setupLinearConstraints() {
        switch layoutDirection {
        case .horizontal:
            valueLabel.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview()
                make.width.equalTo(showValue ? layoutConfig.valueLabelWidth : 0)
                make.height.equalTo(showValue ? layoutConfig.valueLabelHeight : 0)
            }
            contentView.snp.makeConstraints { (make) in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
                make.height.equalTo(contentHeight)
                make.trailing.equalTo(valueLabel.snp.leading).offset(showValue ? -layoutConfig.linearHorizontalMargin : 0)
            }
        case .vertical:
            let valueLabelHeight = showValue ? layoutConfig.valueLabelHeight : 0
            let margin = showValue ? layoutConfig.linearVerticalMargin : 0
            let centerOffY = (valueLabelHeight + margin) / 2
            valueLabel.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(contentView.snp.bottom).offset(margin)
                make.width.equalTo(showValue ? layoutConfig.valueLabelWidth : 0)
                make.height.equalTo(valueLabelHeight)
            }
            contentView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-centerOffY)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(contentHeight)
            }
        }
    }
    
    /// setupCircularConstraints
    private func setupCircularConstraints() {
        switch layoutDirection {
        case .horizontal:
            contentView.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.centerX.equalToSuperview().offset(showValue ? -20 : 0)
                make.width.equalTo(contentHeight)
                make.height.equalTo(contentHeight)
            }
            valueLabel.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.width.equalTo(showValue ? layoutConfig.valueLabelWidth : 0)
                make.height.equalTo(showValue ? layoutConfig.valueLabelHeight : 0)
                make.leading.equalTo(contentView.snp.trailing).offset(showValue ? layoutConfig.circularHorizontalMargin : 0)
            }
        case .vertical:
            contentView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(showValue ? -12 : 0)
                make.width.equalTo(contentHeight)
                make.height.equalTo(contentHeight)
            }
            valueLabel.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalTo(contentView.snp.bottom).offset(showValue ? layoutConfig.circularverticalMargin : 0)
                make.width.equalTo(showValue ? layoutConfig.valueLabelWidth : 0)
                make.height.equalTo(showValue ? layoutConfig.valueLabelHeight : 0)
            }
        }
    }
    
    ///setupProgressBarView
    private func setupProgressBarView() {
        let progressingView = UIView()
        contentView.addSubview(progressingView)
        progressingView.backgroundColor = themeColor.indicatorColor
        progressingView.layer.cornerRadius = contentView.layer.cornerRadius
        progressingView.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            progressBarViewWidthConstraint = make.width.equalTo(0).constraint
        }
        self.progressingView = progressingView
    }
    
    private func setupShapeLayers() {
        self.backgroundLayer = createShapeLayer(strokeColor: themeColor.bgColor, strokeEnd: 1.0)
        layer.addSublayer(self.backgroundLayer ?? CAShapeLayer())
        self.frameLayer = createShapeLayer(strokeColor: themeColor.indicatorColor, strokeEnd: 0.0)
        layer.addSublayer(self.frameLayer ?? CAShapeLayer())
    }
    
    ///createShapeLayer
    private func createShapeLayer(strokeColor: UIColor, strokeEnd: CGFloat = 0.0) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = layoutConfig.circleProgressLineWidth
        shapeLayer.strokeStart = 0.0
        shapeLayer.strokeEnd = strokeEnd
        return shapeLayer
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        layoutShapeLayer()
    }
    
    private func layoutShapeLayer() {
        let center = CGPoint(x: contentView.center.x, y: contentView.center.y)
        let radius: CGFloat = layoutConfig.circleProgressWidth / 2
        let startAngle = CGFloat.pi * 1.5
        let endAngle = CGFloat.pi * 2 + startAngle
        let bezierPath = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: true)
        self.backgroundLayer?.path = bezierPath.cgPath
        self.frameLayer?.path = bezierPath.cgPath
    }
    
    public func setProgressLoadFailed() {
        if type == .linear {
            progressingView?.backgroundColor = themeColor.errorIndicatorColor
        }
    }
    
    public func setProgress(_ progress: CGFloat, animated: Bool) {
        self.progress = max(0, min(progress, 1.0))
        observedProgress?.completedUnitCount = Int64(max(0, min(progress * 100, 100)))
        let progressWith = self.progress * contentView.bounds.width
        if self.progress <= 1 {
            valueLabel.text = "\(Int(self.progress * 100))%"
            UIView.animate(withDuration: TimeInterval(animated ? 0.25 : 0),
                           delay: 0,
                           options: .curveEaseInOut,
                           animations: {
                            if self.type == .linear {
                                self.progressBarViewWidthConstraint?.update(offset: progressWith)
                            } else {
                                self.frameLayer?.strokeEnd = progress
                            }
                           })
        }
        
        if self.progress >= 1 {
            progressingView?.backgroundColor = themeColor.successIndicatorColor
        } else {
            progressingView?.backgroundColor = themeColor.indicatorColor
        }
    }
}
