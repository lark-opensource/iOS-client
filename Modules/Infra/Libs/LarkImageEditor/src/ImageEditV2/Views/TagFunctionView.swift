//
//  TagFunctionView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/10/11.
//

import Foundation
import LarkUIKit
import LarkBlur
import UIKit

enum TagType {
    case rect
    case circle
    case arrow

    fileprivate var config: (normalImage: UIImage, highlightImage: UIImage, title: String) {
        switch self {
        case .rect:
            return (Resources.edit_shape_rect, Resources.edit_shape_rect_highlight,
                    BundleI18n.LarkImageEditor.Lark_ImageViewer_Rectangle)
        case .circle:
            return (Resources.edit_shape_circle, Resources.edit_shape_circle_highlight,
                    BundleI18n.LarkImageEditor.Lark_ImageViewer_Oval)
        case .arrow:
            return (Resources.edit_shape_arrow, Resources.edit_shape_arrow_highlight,
                    BundleI18n.LarkImageEditor.Lark_ImageViewer_Arrow)
        }
    }
}

protocol TagFunctionViewDelegate: EditorToolBarDelegate {
    func shapeButtonDidClicked(type: TagType)
}

final class TagFunctionView: UIView {
    private let tagSlider = ImageEditorSlideView(maxValue: 13, minValue: 3)
    private let colorStack = ImageEditColorStack()
    private let shapeButtonStack = UIStackView()
    private let bottomContainerView = LarkBlurEffectView(radius: 40, color: .ud.N00, colorAlpha: 0.7)
    private let finishButton = UIButton(type: .custom)
    private let minViewWidthForPad = CGFloat(510)
    private let verticalImageView = UIImageView(image: Resources.edit_text_vertical)
    private let containerStackView = UIStackView()
    private let rectButton: UIButton
    private let circleButton: UIButton
    private let arrowButton: UIButton

    private var sliderDisabled = false

    weak var delegate: TagFunctionViewDelegate?

    // swiftlint:disable function_body_length
    init() {
        rectButton = Self.shapeTypeButton(type: .rect)
        circleButton = Self.shapeTypeButton(type: .circle)
        arrowButton = Self.shapeTypeButton(type: .arrow)

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(bottomContainerView)
        bottomContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(50)
        }
        bottomContainerView.alpha = 0

        bottomContainerView.addSubview(finishButton)
        finishButton.backgroundColor = .ud.primaryContentDefault
        finishButton.layer.cornerRadius = 6
        finishButton.layer.masksToBounds = true
        finishButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_Confirm, for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 14)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonDidClicked), for: .touchUpInside)
        finishButton.snp.makeConstraints { make in
            make.height.equalTo(36)
            make.width.equalTo(68)
            make.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(38)
        }

        colorStack.delegate = self
        shapeButtonStack.spacing = 30
        shapeButtonStack.alignment = .center

        rectButton.isSelected = true
        rectButton.addTarget(self, action: #selector(rectButtonDidClicked), for: .touchUpInside)
        shapeButtonStack.addArrangedSubview(rectButton)
        circleButton.addTarget(self, action: #selector(circleButtonDidClicked), for: .touchUpInside)
        shapeButtonStack.addArrangedSubview(circleButton)
        arrowButton.addTarget(self, action: #selector(arrowButtonDidClicked), for: .touchUpInside)
        shapeButtonStack.addArrangedSubview(arrowButton)

        if UIDevice.current.userInterfaceIdiom == .pad {
            setUpUIForIPad()
        } else {
            setUpUIForIPhoneOrIPadNarrow()
        }

        addSubview(tagSlider)
        tagSlider.delegate = self
        tagSlider.snp.makeConstraints { make in
            make.bottom.equalTo(bottomContainerView.snp.top)
            make.height.equalTo(50)
            make.leading.trailing.top.equalToSuperview()
        }
    }
    // swiftlint:enable function_body_length

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func shapeTypeButton(type: TagType) -> UIButton {
        let config = type.config

        let button = PanelButton()
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.setImage(config.normalImage, for: .normal)
        button.setImage(config.highlightImage, for: .highlighted)
        button.setImage(config.highlightImage, for: .selected)
        button.setTitle(config.title, for: .normal)
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.setTitleColor(.ud.primaryContentDefault, for: .highlighted)
        button.setTitleColor(.ud.primaryContentDefault, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 10)
        button.titleLabel?.textAlignment = .center

        return button
    }

    private func setUpUIForIPhoneOrIPadNarrow() {
        bottomContainerView.addSubview(colorStack)
        bottomContainerView.addSubview(shapeButtonStack)
        colorStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(90)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.width.greaterThanOrEqualTo(colorStack.minimumWidth).priority(900)
            make.left.equalToSuperview().inset(UIDevice.current.userInterfaceIdiom == .pad ? 48 : 68).priority(800)
        }
        shapeButtonStack.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(34)
            make.left.equalToSuperview().inset(20)
        }
    }

    private func setUpUIForIPad() {
        bottomContainerView.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.center.equalToSuperview().priority(600)
            make.right.lessThanOrEqualToSuperview().offset(-108)
        }

        containerStackView.alignment = .center
        containerStackView.spacing = 30
        containerStackView.addArrangedSubview(shapeButtonStack)

        verticalImageView.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(24)
        }
        containerStackView.addArrangedSubview(verticalImageView)
        containerStackView.addArrangedSubview(colorStack)
    }

    private func disableButtonStack(_ stack: UIStackView) {
        stack.subviews.forEach {
            if let button = $0 as? UIButton {
                button.isSelected = false
            }
        }
    }

    private func animateHideSlider() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.tagSlider.alpha = 0
        })
    }

    private func animateShowSlider() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.tagSlider.alpha = 1
        })
    }

    @objc
    private func rectButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }

        delegate?.eventOccured(eventName: "public_pic_edit_graph_click",
                               params: ["click": "rectangle", "target": "none"])
        disableButtonStack(shapeButtonStack)
        sender.isSelected = true
        delegate?.shapeButtonDidClicked(type: .rect)
    }

    @objc
    private func circleButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }

        delegate?.eventOccured(eventName: "public_pic_edit_graph_click",
                               params: ["click": "oval", "target": "none"])
        disableButtonStack(shapeButtonStack)
        sender.isSelected = true
        delegate?.shapeButtonDidClicked(type: .circle)
    }

    @objc
    private func arrowButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }

        delegate?.eventOccured(eventName: "public_pic_edit_graph_click",
                               params: ["click": "arrow", "target": "none"])
        disableButtonStack(shapeButtonStack)
        sender.isSelected = true
        delegate?.shapeButtonDidClicked(type: .arrow)
    }

    @objc
    private func finishButtonDidClicked() {
        delegate?.eventOccured(eventName: "public_pic_edit_graph_click",
                               params: ["click": "confirm", "target": "public_pic_edit_view"])
        delegate?.finishButtonDidClicked(in: self)
    }
}

extension TagFunctionView: ImageEditorSlideViewDelegate {
    func sliderDidChangeValue(to newValue: Int) {
        delegate?.eventOccured(eventName: "public_pic_edit_graph_click",
                               params: ["click": "thickness", "target": "none"])
        delegate?.changeWidth(with: CGFloat(newValue), defaultWidth: CGFloat(tagSlider.defaultValue))
    }

    func sliderTimerTicked() { delegate?.sliderTimerTicked() }
}

extension TagFunctionView: ImageEditColorStackDelegate {
    func didSelectColor(_ color: ColorPanelType) {
        delegate?.eventOccured(eventName: "public_pic_edit_graph_click",
                               params: ["click": "color", "target": "none"])
        delegate?.changeColor(with: color)
    }
}

extension TagFunctionView: EditorToolBar {
    var heightForIphone: CGFloat { 182 }
    var heightForIpad: CGFloat { 146 }

    func animateHideToolBar(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.tagSlider.alpha = 0
            self?.bottomContainerView.alpha = 0
        }, completion: { [weak self] _ in
            completion?()
            self?.isHidden = true
        })
    }

    func animateShowToolBar() {
        isHidden = false
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            guard let self = self else { return }
            if !self.sliderDisabled { self.tagSlider.alpha = 1 }
            self.bottomContainerView.alpha = 1
        })
    }

    func updateCurrentViewWidth(_ width: CGFloat) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        containerStackView.removeFromSuperview()
        verticalImageView.removeFromSuperview()
        shapeButtonStack.removeFromSuperview()
        colorStack.removeFromSuperview()
        if width < minViewWidthForPad {
            setUpUIForIPhoneOrIPadNarrow()
            snp.updateConstraints { make in make.height.equalTo(heightForIphone) }
        } else {
            setUpUIForIPad()
            snp.updateConstraints { make in make.height.equalTo(heightForIpad) }
        }

        finishButton.snp.remakeConstraints { make in
            make.height.equalTo(36)
            make.width.equalTo(68)
            make.right.equalToSuperview().inset(20)
            make.centerY.equalTo(shapeButtonStack)
        }
    }
}

// internal apis
extension TagFunctionView {
    func updateSlider(_ value: CGFloat) {
        if arrowButton.isSelected {
            sliderDisabled = true
            animateHideSlider()
        } else {
            sliderDisabled = false
            animateShowSlider()
            tagSlider.setSliderValue(value)
        }
    }

    func updateColor(_ color: ColorPanelType) { colorStack.currentColor = color }

    func updateType(_ type: TagType) {
        disableButtonStack(shapeButtonStack)
        switch type {
        case .rect: rectButton.isSelected = true
        case .circle: circleButton.isSelected = true
        case .arrow: arrowButton.isSelected = true
        }
    }
}
