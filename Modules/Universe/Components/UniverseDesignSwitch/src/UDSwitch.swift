//
//  UDSwitch.swift
//  Pods
//
//  Created by CJ on 2020/10/14.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

/// When is waitCallback，value does not  changed immediately
public enum SwitchBehaviourType {
    case normal
    case waitCallback
}

/// Switch state
public enum SwitchState {
    /// normal
    case normal
    /// disabled
    case disabled
    /// loading
    case loading
}

/// Switch default layout config
private struct UDSwitchLayoutConfig {
    let contentWidth: CGFloat = 48
    let contentHeight: CGFloat = 28
    let circleWidth: CGFloat = 24
    let circleLeftMargin: CGFloat = 2
    let circleRightMargin: CGFloat = 2
    let indicatorWidth: CGFloat = 12
}

public final class UDSwitch: UIView {
    /// Switch Component UI Config
    public var uiConfig: UDSwitchUIConfig {
        didSet {
            updateThemeColor()
        }
    }
    /// Default is YES. if NO, ignores touch events and subclasses may draw differently
    public var isEnabled: Bool = true {
        didSet {
            update(enabled: isEnabled)
        }
    }
    /// Switch Component BehaviourType, default normal
    public var behaviourType: SwitchBehaviourType = .normal {
        didSet {
            updateThemeColor()
        }
    }
    /// switch value will change callback
    public var valueWillChanged: ((_ to: Bool) -> Void)?
    /// switch value changed callback
    public var valueChanged: ((Bool) -> Void)?
    /// A Boolean value indicating whether the switch is tapped, regardless of `isEnabled` state.
    public var tapCallBack: ((UDSwitch) -> Void)?
    /// duration
    private let animationDuration: TimeInterval = 0.25
    /// Switch Component layout Config
    private let layoutConfig = UDSwitchLayoutConfig()
    /// Default is normal
    private var state: SwitchState = .normal {
        didSet {
            updateThemeColor()
        }
    }
    /// Switch current status
    public private(set) var isOn: Bool = false
    private var contentView: UIView = UIView()
    private var circleView: UIView = UIView()
    private let indicator: UDActivityIndicatorView = UDActivityIndicatorView(frame: .zero)
    public init(config: UDSwitchUIConfig = UDSwitchUIConfig.defaultConfig,
                behaviourType: SwitchBehaviourType = .normal) {
        self.uiConfig = config
        self.behaviourType = behaviourType
        super.init(frame: .zero)
        setupUI()
        setupLayout()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupUI() {
        addSubview(contentView)
        contentView.addSubview(circleView)
        circleView.addSubview(indicator)
        contentView.layer.cornerRadius = layoutConfig.contentHeight * 0.5
        contentView.clipsToBounds = true
        circleView.layer.cornerRadius = layoutConfig.circleWidth * 0.5
        circleView.clipsToBounds = true
        updateThemeColor()
        addGesture()
    }
    private func setupLayout() {
        contentView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.edges.equalToSuperview()
            make.width.equalTo(layoutConfig.contentWidth)
            make.height.equalTo(layoutConfig.contentHeight)
        }
        let leftMargin = isOn
            ? layoutConfig.contentWidth - layoutConfig.circleWidth - layoutConfig.circleRightMargin
            : layoutConfig.circleLeftMargin
        circleView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(leftMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(layoutConfig.circleWidth)
        }
        indicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(layoutConfig.indicatorWidth)
        }
    }
    private func addGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapAction(_:)))
        contentView.addGestureRecognizer(tap)
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeAction(_:)))
        swipe.direction = [.left, .right]
        contentView.addGestureRecognizer(swipe)
        // The background tap gesture responds to tap action when UDSwitch is disabled.
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTapAction(_:)))
        addGestureRecognizer(backgroundTap)
    }
    private func update(enabled: Bool) {
        state = isEnabled ? .normal : .disabled
        indicator.stopAnimating()
        contentView.isUserInteractionEnabled = enabled
        circleView.isUserInteractionEnabled = enabled
    }
    private func updateThemeColor() {
        var themeColor: UDSwitchUIConfig.ThemeColor?
        switch state {
        case .normal:
            themeColor = isOn ? uiConfig.onNormalTheme : uiConfig.offNormalTheme
        case .disabled:
            themeColor = isOn ? uiConfig.onDisableTheme : uiConfig.offDisableTheme
        case .loading:
            themeColor = isOn ? uiConfig.onLoadingTheme : uiConfig.offLoadingTheme
        }
        contentView.backgroundColor = themeColor?.tintColor
        circleView.backgroundColor = themeColor?.thumbColor
        if let loadingColor = themeColor?.loadingColor {
            indicator.color = loadingColor
        }
    }
    @objc
    private func handleTapAction(_ recognizer: UIGestureRecognizer) {
        sendTapAction()
        handleSwitchAction()
    }
    @objc
    private func handleSwipeAction(_ recognizer: UIGestureRecognizer) {
        sendTapAction()
        handleSwitchAction()
    }
    @objc
    private func handleBackgroundTapAction(_ recognizer: UIGestureRecognizer) {
        sendTapAction()
    }
    private func handleSwitchAction() {
        switch behaviourType {
        case .normal:
            valueWillChanged?(!isOn)
            if state != .normal {
                state = .normal
            }
            setOn(!isOn, animated: true)
        case .waitCallback:
            if !indicator.isAnimating {
                valueWillChanged?(!isOn)
                if state != .loading {
                    state = .loading
                }
                indicator.startAnimating()
            }
        }
    }
    private func sendTapAction() {
        tapCallBack?(self)
    }
    /// change switch status
    public func setOn(_ on: Bool, animated: Bool) {
        setOn(on, animated: animated, ignoreValueChanged: false)
    }

    /// change switch status
    /// - Parameters:
    ///   - on: status
    ///   - animated: animated
    ///   - ignoreValueChanged: ignore valueChanged 
    public func setOn(_ on: Bool, animated: Bool, ignoreValueChanged: Bool) {
        if isOn == on {
            return
        }
        isOn = on
        let leftMargin = isOn
            ? layoutConfig.contentWidth - layoutConfig.circleWidth - layoutConfig.circleRightMargin
            : layoutConfig.circleLeftMargin
        circleView.snp.updateConstraints { (make) in
            make.leading.equalToSuperview().offset(leftMargin)
        }
        if animated {
            UIView.animate(withDuration: animationDuration, animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                if !ignoreValueChanged {
                    self.valueChanged?(self.isOn)
                }
            })
        } else {
            if !ignoreValueChanged {
                valueChanged?(self.isOn)
            }
        }
        stopAnimating()
        state = isEnabled ? .normal : .disabled
    }
    /// Only behaviourType is waitCallback effect
    public func stopAnimating() {
        if indicator.isAnimating {
            indicator.stopAnimating()
        }
    }
}
