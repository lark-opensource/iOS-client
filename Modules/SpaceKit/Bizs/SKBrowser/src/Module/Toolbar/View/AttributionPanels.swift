//
//  AttributionPanels.swift
//  SpaceKit
//
//  Created by Webster on 2019/1/24.
//  swiftlint:disable file_length

import Foundation
import UIKit
import SKCommon
import SKResource
import SKUIKit
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation

/// 加减值调节面板

public protocol AdjustAttributionPanelDelegate: AnyObject {
    func nextBiggerValue(in panel: AdjustAttributionPanel, value: String) -> String
    func nextSmallValue(in panel: AdjustAttributionPanel, value: String) -> String
    func canBiggerNow(in panel: AdjustAttributionPanel, value: String) -> Bool
    func canSmallNow(in panel: AdjustAttributionPanel, value: String) -> Bool
    func hasUpdateValue(value: String, in panel: AdjustAttributionPanel)
}

public final class AdjustAttributionPanel: UIView {

    public struct PanelLayout {
        public var displayIcon: Bool = false
        public var leftPadding: CGFloat = 16 //总体的左边间距
        public var rightPadding: CGFloat = 16 //总体的左边间距
        public var iconSize: CGFloat = 20
        public var iconRightPadding: CGFloat = 12 // icon -（iconRightPadding）- text
        public var buttonSize: CGFloat = 32
        public var buttonRadius: CGFloat = 6
        public var valueFont: CGFloat = 16
        public var titleFont: CGFloat = 16

        public init() {}
    }

    public weak var delegate: AdjustAttributionPanelDelegate?
    private var title: String
    private var panelLayout: PanelLayout = PanelLayout()
    private var currentValue: String

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    public lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    public var isEnable: Bool = true {
        didSet {
            titleLabel.textColor = isEnable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            valueLabel.textColor = isEnable ? UIColor.ud.textTitle : UIColor.ud.textDisabled
            downButton.isEnabled = isEnable
            upButton.isEnabled = isEnable
        }
    }

    public lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: panelLayout.titleFont)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: panelLayout.valueFont)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.text = "0"
        return label
    }()

    var disposeBag = DisposeBag()
    
    private lazy var downButton: UIButton = {
        let btn = UIButton(frame: .zero)
        let downEnableImage = UDIcon.reduceOutlined
        btn.setImage(downEnableImage.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        btn.setImage(downEnableImage.ud.withTintColor(UIColor.ud.iconDisabled), for: .disabled)
        btn.imageEdgeInsets = UIEdgeInsets(edges: 8)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = panelLayout.buttonRadius
        btn.layer.borderWidth = 1
        btn.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(_touchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(_touchUpInside(_:)), for: .touchUpInside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchUpOutside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchCancel)
        btn.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        return btn
    }()

    private lazy var upButton: UIButton = {
        let btn = UIButton(frame: .zero)
        let upEnableImage = UDIcon.addOutlined
        btn.setImage(upEnableImage.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        btn.setImage(upEnableImage.ud.withTintColor(UIColor.ud.iconDisabled), for: .disabled)
        btn.imageEdgeInsets = UIEdgeInsets(edges: 8)
        btn.backgroundColor = .clear
        btn.layer.cornerRadius = panelLayout.buttonRadius
        btn.layer.borderWidth = 1
        btn.layer.ud.setBorderColor(UDColor.lineBorderComponent)
        btn.layer.masksToBounds = true
        btn.addTarget(self, action: #selector(_touchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(_touchUpInside(_:)), for: .touchUpInside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchUpOutside)
        btn.addTarget(self, action: #selector(_touchCancelled(_:)), for: .touchCancel)
        btn.docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        return btn
    }()

    public init(frame: CGRect,
                value: String,
                title: String = "",
                layout: PanelLayout? = nil,
                showsBottomLine: Bool = true,
                bgColor: UIColor = UDColor.bgBody) {
        self.panelLayout = layout ?? PanelLayout()
        self.title = title
        self.currentValue = value
        super.init(frame: frame)
        self.backgroundColor = bgColor
        //init title label
        titleLabel.text = title
        self.addSubview(iconView)
        self.addSubview(titleLabel)
        self.addSubview(downButton)
        self.addSubview(upButton)
        self.addSubview(valueLabel)
        self.addSubview(lineView)
        lineView.isHidden = !showsBottomLine

        upButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-panelLayout.rightPadding)
            make.width.height.equalTo(panelLayout.buttonSize)
            make.centerY.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { (make) in
            make.width.equalTo(panelLayout.buttonSize) // 避免数字变化时宽度变化
            make.centerY.equalToSuperview()
            make.right.equalTo(upButton.snp.left).offset(-7)
        }

        downButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(panelLayout.buttonSize)
            make.centerY.equalToSuperview()
            make.right.equalTo(valueLabel.snp.left).offset(-7)
        }

        if panelLayout.displayIcon {
            iconView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(panelLayout.leftPadding)
                make.width.height.equalTo(panelLayout.iconSize)
                make.centerY.equalToSuperview()
            }
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalTo(iconView.snp.right).offset(panelLayout.iconRightPadding)
                make.right.lessThanOrEqualTo(downButton.snp.left).offset(-panelLayout.leftPadding)
                make.centerY.equalToSuperview()
            }
        } else {
            iconView.removeFromSuperview()
            titleLabel.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(panelLayout.leftPadding)
                make.right.lessThanOrEqualTo(downButton.snp.left).offset(-panelLayout.leftPadding)
                make.centerY.equalToSuperview()
            }
        }

        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(panelLayout.leftPadding)
            make.height.equalTo(0.5)
            make.right.bottom.equalToSuperview()
        }

        updateValue(value: value)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateValue(value: String) {
        valueLabel.text = value
        currentValue = value
    }

    public func updateButtonStatus() {
        upButton.isEnabled = delegate?.canBiggerNow(in: self, value: currentValue) ?? false
        downButton.isEnabled = delegate?.canSmallNow(in: self, value: currentValue) ?? false
    }
    
    @objc
    private func _touchDown(_ sender: UIButton) {
        sender.backgroundColor = UDColor.fillPressed
    }
    
    @objc
    private func _touchCancelled(_ sender: UIButton) {
        sender.backgroundColor = .clear
    }

    @objc
    private func _touchUpInside(_ sender: UIButton) {
        sender.backgroundColor = .clear
        guard let delegate = delegate else { return }
        var nextValue = currentValue
        if sender === upButton {
            guard delegate.canBiggerNow(in: self, value: currentValue) else { return }
            if isEnable {
                nextValue = delegate.nextBiggerValue(in: self, value: currentValue)
            }
        } else if sender === downButton {
            guard delegate.canSmallNow(in: self, value: currentValue) else { return }
            if isEnable {
                nextValue = delegate.nextSmallValue(in: self, value: currentValue)
            }
        }
        updateValue(value: nextValue)
        delegate.hasUpdateValue(value: nextValue, in: self)
        updateButtonStatus()
    }
}


/// 面板选择器
public protocol PickerAttributionPanelDelegate: AnyObject {
    func pickerAttributionWillWakeColorPickerUp(panel: PickerAttributionPanel)
}

public class PickerAttributionPanel: UIView {
    public weak var delegate: PickerAttributionPanelDelegate?
    
    private let colorsDrawingOutline: Set<String> = ["#ffffff", "#f5f5f5"]
    
    public var title: String {
        didSet {
            self.titleLabel.text = title
        }
    }
    
    private(set) var desc: String = ""

    private let normalBgColor: UIColor
    
    private let highlightedBgColor: UIColor
    
    let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        return label
    }()

    private let iconView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4.0
        return view
    }()

    private let aIcon: UIImageView = UIImageView(image: BundleResources.SKResource.Common.Tool.icon_tool_highlight_nor)

    let arrowView: UIImageView = {
        let view = UIImageView(image: UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate))
        view.tintColor = UIColor.ud.textPlaceholder
        view.backgroundColor = .clear
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private let colorPreview: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.ud.setBorderColor(UIColor.ud.N300 & UIColor.ud.N400.alwaysDark)
        return view
    }()

    var disposeBag = DisposeBag()
    
    public init(frame: CGRect,
                value: String,
                title: String = "",
                showsBottomLine: Bool = true,
                normalBgColor: UIColor = UDColor.bgBody,
                highlightedBgColor: UIColor = UDColor.fillPressed) {
        self.title = title
        self.normalBgColor = normalBgColor
        self.highlightedBgColor = highlightedBgColor
        super.init(frame: frame)
        self.backgroundColor = normalBgColor
        self.docs.addHover(with: UDColor.fillHover, disposeBag: disposeBag)
        self.addSubview(titleLabel)
        self.addSubview(arrowView)
        self.addSubview(colorPreview)
        self.addSubview(lineView)
        self.addSubview(iconView)
        iconView.addSubview(aIcon)
        colorPreview.isHidden = true
        iconView.isHidden = true
        lineView.isHidden = !showsBottomLine
        //init title label
        titleLabel.text = title
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        arrowView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
        }

        iconView.snp.makeConstraints { (make) in
            make.right.equalTo(arrowView.snp.left).offset(-20)
            make.width.height.equalTo(36)
            make.centerY.equalToSuperview()
        }

        aIcon.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(24)
        }

        colorPreview.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(16)
            make.right.equalTo(arrowView.snp.left).offset(-12)
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
        }

        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.height.equalTo(0.5)
            make.right.bottom.equalToSuperview()
        }
    }

    public func update(desc: String, color: UIColor) {
        self.desc = desc
        let shouldDrawOutline = colorsDrawingOutline.contains(desc) || desc.elementsEqual(ColorPaletteItemType.clear.mappedValue())
        if shouldDrawOutline {
            colorPreview.layer.ud.setBorderColor(UIColor.ud.N300 & UIColor.ud.N400.alwaysDark)
        } else {
            colorPreview.layer.ud.setBorderColor(UIColor.clear & UIColor.ud.N400.alwaysDark)
        }
        colorPreview.layer.masksToBounds = true
        colorPreview.backgroundColor = color
        colorPreview.isHidden = false
        iconView.isHidden = true
    }

    func updateHighlightPanel(info: [String: Any]) {
        guard let type = info["type"] as? String,
            let colorJSONInfo = info["value"] as? [String: CGFloat] else {
                return
        }
        let colorInfo = ColorPaletteItemV2.ColorInfo(colorJSONInfo)
        let image = BundleResources.SKResource.Common.Tool.icon_tool_highlight_nor
        if type == ColorPaletteItemCategory.text.rawValue {
            aIcon.image = image.ud.withTintColor(colorInfo.color ?? UIColor.ud.iconN1)
            iconView.backgroundColor = UIColor.ud.bgBody
            iconView.layer.borderWidth = 1
            iconView.layer.borderColor = UIColor.ud.N300.cgColor
        } else if type == ColorPaletteItemCategory.background.rawValue {
            aIcon.image = image.ud.withTintColor(UIColor.ud.iconN1)
            iconView.backgroundColor = colorInfo.color
            iconView.layer.borderWidth = 0
        }
        colorPreview.isHidden = true
        iconView.isHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        backgroundColor = highlightedBgColor
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = normalBgColor
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.randomElement()
        if let endLocation = touch?.location(in: self.superview), self.frame.contains(endLocation) {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) { [weak self] in
                guard let self = self else { return }
                self.backgroundColor = self.normalBgColor
                self.delegate?.pickerAttributionWillWakeColorPickerUp(panel: self)
            }
        } else {
            self.backgroundColor = normalBgColor
        }
    }
}

//sheet工具栏改版
public final class PickerAttributionPanelBorder: PickerAttributionPanel {
    
    public var borderImageView = UIImageView().construct { (it) in
        it.image = UDIcon.getIconByKey(.bordersOutlined, renderingMode: .alwaysTemplate, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20))
    }
    
    public override init(frame: CGRect,
                         value: String,
                         title: String = "",
                         showsBottomLine: Bool = true,
                         normalBgColor: UIColor = UDColor.bgBody,
                         highlightedBgColor: UIColor = UDColor.fillPressed) {
        super.init(frame: frame,
                   value: value,
                   title: title,
                   showsBottomLine: showsBottomLine,
                   normalBgColor: normalBgColor,
                   highlightedBgColor: highlightedBgColor)
        addSubview(borderImageView)
        borderImageView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(16)
            make.right.equalTo(arrowView.snp.left).offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateBorder(_ border: String?) {
        guard let border = border else {
            return
        }
        if let type = BorderType(rawValue: border) {
            borderImageView.image = type.normalImage
        }
    }
}

public protocol StyleBasePanelDelegate: AnyObject {
    func didClickStyleBasePanel(panel: StyleBasePanel, button: AttributeButton)
}

public class StyleBasePanel: UIView {

    var disposeBag = DisposeBag()
    
    public weak var delegate: StyleBasePanelDelegate?
    
    var containerView = UIStackView().construct { (it) in
        it.axis = .horizontal
        it.distribution = .fillEqually
        it.alignment = .fill
        it.spacing = 1
        it.layer.cornerRadius = 8
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.backgroundColor = .clear
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        setupSubview()
    }
    
    func setupSubview() {
        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func clear() {
        containerView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class FontStylePanel: StyleBasePanel {
    public func update(_ infos: [ToolBarItemInfo]) {
        clear()
        for info in infos {
            let button = AttributeButton(frame: .zero, info: info)
            button.loadStatus()
            button.delegate = self
            containerView.addArrangedSubview(button)
        }
    }
}





public final class AlignmentPanel: StyleBasePanel {
    public func update(_ infos: [[ToolBarItemInfo]]) {
        clear()
        containerView.spacing = 8
        for info in infos {
            let stackView = UIStackView().construct { (it) in
                it.axis = .horizontal
                it.distribution = .fillEqually
                it.alignment = .fill
                it.spacing = 1
                it.layer.cornerRadius = 8
                it.layer.masksToBounds = true
                it.clipsToBounds = true
            }
            let count = info.count
            for (index, item) in info.enumerated() {
                let button = AttributeButton(frame: .zero, info: item)
                button.delegate = self
                button.loadStatus()
                if index == 0 || index == count - 1 {
                    button.layer.cornerRadius = 8
                    if index == 0 && index != count - 1 {
                        button.layer.maskedCorners = .left
                    } else if index == count - 1 && index != 0 {
                        button.layer.maskedCorners = .right
                    }
                    button.layer.masksToBounds = true
                }
                stackView.addArrangedSubview(button)
            }
            containerView.addArrangedSubview(stackView)
        }
    }
}

extension StyleBasePanel: AttributeButtonDelegate {
    func didClickAttributeButton(_ btn: AttributeButton) {
        self.delegate?.didClickStyleBasePanel(panel: self, button: btn)
    }
}
