//
//  UDCheckBox.swift
//  Pods-UniverseDesignCheckBoxDev
//
//  Created by 姚启灏 on 2020/8/18.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit

/// Check Box Type
public enum UDCheckBoxType {
    /// single selected
    case single
    /// multiple selected
    case multiple
    /// mixed
    case mixed
    /// list
    case list
}

/// Check Box UI Config
public struct UDCheckBoxUIConfig {
    /// Check Box Style
    public enum Style {
        /// Round corner 10
        case circle
        /// Square corner 2
        case square
    }

    /// Checkbox Unselected Border Enabled Color
    public var borderEnabledColor: UIColor

    /// Checkbox Unselected Border Disabled Color
    public var borderDisabledColor: UIColor

    /// Checkbox Selected Background Disabled Color
    public var selectedBackgroundDisableColor: UIColor

    /// Checkbox Unselected Background Disabled Color
    public var unselectedBackgroundDisableColor: UIColor

    /// Checkbox Unselected Background Enabled Color
    public var unselectedBackgroundEnabledColor: UIColor

    /// Checkbox Selected Background Enabled Color
    public var selectedBackgroundEnabledColor: UIColor

    /// Check Box Style
    public var style: Style

    /// init
    public init(borderEnabledColor: UIColor = UDCheckBoxColorTheme.borderEnabledColor,
                borderDisabledColor: UIColor = UDCheckBoxColorTheme.borderDisabledColor,
                selectedBackgroundDisableColor: UIColor = UDCheckBoxColorTheme.selectedBackgroundDisabledColor,
                unselectedBackgroundDisableColor: UIColor = UDCheckBoxColorTheme.unselectedBackgroundDisabledColor,
                selectedBackgroundEnabledColor: UIColor = UDCheckBoxColorTheme.selectedBackgroundEnabledColor,
                unselectedBackgroundEnabledColor: UIColor = UDCheckBoxColorTheme.unselectedBackgroundEnabledColor,
                style: Style = .circle) {
        self.borderEnabledColor = borderEnabledColor
        self.borderDisabledColor = borderDisabledColor
        self.selectedBackgroundDisableColor = selectedBackgroundDisableColor
        self.unselectedBackgroundDisableColor = unselectedBackgroundDisableColor
        self.selectedBackgroundEnabledColor = selectedBackgroundEnabledColor
        self.unselectedBackgroundEnabledColor = unselectedBackgroundEnabledColor
        self.style = style
    }
}

public final class UDCheckBox: UIView {

    /// 表示是否在 `UDCheckBox.isEnabled = false` 的状态下，仍然回调 `tapCallBack`。
    /// - NOTE: 适用于业务方需要获知禁用态点击事件的场景，默认为 false。
    public var respondsToUserInteractionWhenDisabled: Bool = false {
        didSet {
            setTapGestureEnabledIfNeeded(isEnabled)
        }
    }

    public var isSelected: Bool {
        get {
            wrapperView.isSelected
        }
        set {
            wrapperView.isSelected = newValue
            self.updateUI()
        }
    }

    public var isEnabled: Bool {
        get {
            wrapperView.isEnabled
        }
        set {
            wrapperView.isEnabled = newValue
            setTapGestureEnabledIfNeeded(newValue)
            self.updateUI()
        }
    }

    public var tapCallBack: ((UDCheckBox) -> Void)?

    public private(set) var boxType: UDCheckBoxType
    public private(set) var config: UDCheckBoxUIConfig

    private var centerIconView: UIImageView = UIImageView()

    private var wrapperView: UIControl = UIControl()

    /// 根据 UDCheckBox 组件状态，设置是否可以响应点击事件
    private lazy var tapGesture = UITapGestureRecognizer(target: self,
                                                         action: #selector(handleTapCheckBox))

    private func setTapGestureEnabledIfNeeded(_ isEnabled: Bool) {
        tapGesture.isEnabled = isEnabled || respondsToUserInteractionWhenDisabled
    }

    private var hotAreaInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    /// CheckBox Init
    /// - Parameters:
    ///   - boxType: CheckBox Type
    ///   - config: UI Config
    ///   - tapCallBack: Tap Callback
    public init(boxType: UDCheckBoxType = .single,
                config: UDCheckBoxUIConfig = UDCheckBoxUIConfig(),
                tapCallBack: ((UDCheckBox) -> Void)? = nil) {
        self.boxType = boxType
        self.config = config

        super.init(frame: .zero)

        self.tapCallBack = tapCallBack
        self.commonInit(boxType: boxType, config: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let minLength = min(bounds.width, bounds.height)
        wrapperView.layer.cornerRadius = self.config.style == .circle ? minLength / 2 : 4
    }

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        let hotArea = CGRect(x: self.bounds.origin.x - hotAreaInsets.left,
                             y: self.bounds.origin.y - hotAreaInsets.top,
                             width: self.bounds.size.width + hotAreaInsets.left + hotAreaInsets.right,
                             height: self.bounds.size.height + hotAreaInsets.top + hotAreaInsets.bottom)
        return hotArea.contains(point)
    }

    /// Update UI Config.
    /// - Parameters:
    ///   - boxType: CheckBox Type
    ///   - config: UI Config
    public func updateUIConfig(boxType: UDCheckBoxType, config: UDCheckBoxUIConfig) {
        if self.boxType != boxType {
            switch boxType {
            case .list:
                centerIconView.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            case .multiple:
                centerIconView.snp.remakeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.width.height.equalToSuperview().multipliedBy(0.9)
                }
            case .mixed, .single:
                centerIconView.snp.remakeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.width.height.equalToSuperview().multipliedBy(0.6)
                }
            }
        }
        self.boxType = boxType
        self.config = config

        self.layoutViews()
    }

    private func commonInit(boxType: UDCheckBoxType,
                            config: UDCheckBoxUIConfig) {
        self.backgroundColor = UIColor.clear
        self.addGestureRecognizer(tapGesture)

        self.addSubview(wrapperView)
        self.wrapperView.addSubview(centerIconView)
        self.wrapperView.layer.borderColor = UIColor.clear.cgColor
        self.wrapperView.layer.borderWidth = 1.5

        wrapperView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.height.equalTo(20).priority(.high)
        }

        switch boxType {
        case .list:
            centerIconView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        case .multiple:
            centerIconView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalToSuperview().multipliedBy(0.9)
            }

        case .mixed, .single:
            centerIconView.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalToSuperview().multipliedBy(0.6)
            }
        }

        self.layoutViews()
    }

    @objc
    private func handleTapCheckBox(recognizer: UITapGestureRecognizer) {
        self.wrapperView.sendActions(for: .valueChanged)
        self.tapCallBack?(self)
    }

    private func layoutViews() {

        let minLength = min(bounds.width, bounds.height)
        wrapperView.layer.cornerRadius = self.config.style == .circle ? minLength / 2 : 4

        switch boxType {
        case .multiple:
            self.centerIconView.image = BundleResources.multiple
        case .mixed:
            self.centerIconView.image = BundleResources.mixed
        case .single:
            self.centerIconView.image = BundleResources.single
        case .list:
            if self.isEnabled {
                self.centerIconView.image = BundleResources.list
            } else {
                self.centerIconView.image = BundleResources.disabledlist
            }
        }

        updateUI()
    }

    private func updateUI() {
        switch self.boxType {
        case .list:
            centerIconView.isHidden = false
            wrapperView.backgroundColor = UIColor.clear
            wrapperView.layer.borderColor = UIColor.clear.cgColor
            if self.isEnabled {
                self.centerIconView.image = self.isSelected ? BundleResources.list : nil
            } else {
                self.centerIconView.image = BundleResources.disabledlist
            }
        case .mixed, .multiple, .single:
            centerIconView.isHidden = !self.isSelected
            centerIconView.contentMode = .scaleAspectFit
            wrapperView.contentMode = .scaleAspectFit
            if isEnabled {
                if isSelected {
                    wrapperView.backgroundColor = config.selectedBackgroundEnabledColor
                    wrapperView.layer.borderColor = UIColor.clear.cgColor
                } else {
                    wrapperView.backgroundColor = config.unselectedBackgroundEnabledColor
                    wrapperView.layer.borderColor = config.borderEnabledColor.cgColor
                }
                self.centerIconView.image = self.centerIconView.image?.ud.withTintColor(UDColor.primaryOnPrimaryFill)
            } else {
                if isSelected {
                    wrapperView.backgroundColor = config.selectedBackgroundDisableColor
                    wrapperView.layer.borderColor = UIColor.clear.cgColor
                } else {
                    wrapperView.backgroundColor = config.unselectedBackgroundDisableColor
                    wrapperView.layer.borderColor = config.borderDisabledColor.cgColor
                }
                self.centerIconView.image = self.centerIconView.image?.ud.withTintColor(UDColor.N200)
            }
        }
    }
}

// MARK: UIControl API Adaption

extension UDCheckBox {

    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        wrapperView.addTarget(target, action: action, for: controlEvents)
    }

    /// 兼容 LarkExtension 中 UIControl+TouchArea 的扩展
    public var hitTestEdgeInsets: UIEdgeInsets {
        get { hotAreaInsets }
        set { hotAreaInsets = newValue }
    }
}
