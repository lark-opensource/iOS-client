//
//  LineFunctionView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/1.
//

import UIKit
import Foundation
import LarkUIKit
import LarkBlur

final class LineFunctionView: UIView {
    private let lineSlider = ImageEditorSlideView(maxValue: 32, minValue: 16)
    private let colorStack = ImageEditColorStack()
    private let bottomContainerView = LarkBlurEffectView(radius: 40, color: .ud.N00, colorAlpha: 0.7)
    private let finishButton = UIButton(type: .custom)

    weak var delegate: EditorToolBarDelegate?
    var currentSeletedColor: UIColor { colorStack.currentColor.color() }
    var currentSliderValue: CGFloat { CGFloat(lineSlider.currentValue) }

    // swiftlint:disable function_body_length
    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(bottomContainerView)
        bottomContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(92)
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
            make.right.equalToSuperview().inset(Display.width < 375 ? 15 : 20)
            make.bottom.equalToSuperview().inset(38)
        }

        bottomContainerView.addSubview(colorStack)
        colorStack.delegate = self
        if UIDevice.current.userInterfaceIdiom == .pad {
            colorStack.snp.makeConstraints { make in
                make.centerX.equalToSuperview().priority(600)
                make.width.equalTo(263).priority(600)
                make.right.lessThanOrEqualTo(finishButton.snp.left).offset(-20).priority(700)
                make.left.greaterThanOrEqualToSuperview()
                make.centerY.equalTo(finishButton)
            }
        } else {
            colorStack.snp.makeConstraints { make in
                make.centerY.equalTo(finishButton)
                make.width.equalTo(237).priority(800)
                make.right.lessThanOrEqualTo(finishButton.snp.left).offset(-10)
                make.left.equalToSuperview().inset(Display.width < 375 ? 13 : 20)
            }
        }

        addSubview(lineSlider)
        lineSlider.delegate = self
        lineSlider.snp.makeConstraints { make in
            make.bottom.equalTo(bottomContainerView.snp.top)
            make.height.equalTo(50)
            make.leading.trailing.top.equalToSuperview()
        }
        lineSlider.alpha = 0
    }
    // swiftlint:enable function_body_length

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func finishButtonDidClicked() {
        delegate?.eventOccured(eventName: "public_pic_edit_draw_click",
                               params: ["click": "confirm", "target": "public_pic_edit_view"])
        delegate?.finishButtonDidClicked(in: self)
    }
}

extension LineFunctionView: ImageEditorSlideViewDelegate {
    func sliderDidChangeValue(to newValue: Int) {
        delegate?.eventOccured(eventName: "public_pic_edit_draw_click",
                               params: ["click": "thickness", "target": "none"])
        delegate?.changeWidth(with: CGFloat(newValue), defaultWidth: CGFloat(lineSlider.defaultValue))
    }

    func sliderTimerTicked() { delegate?.sliderTimerTicked() }
}

extension LineFunctionView: ImageEditColorStackDelegate {
    func didSelectColor(_ color: ColorPanelType) {
        delegate?.eventOccured(eventName: "public_pic_edit_draw_click",
                               params: ["click": "color", "target": "none"])
        delegate?.changeColor(with: color)
    }
}

extension LineFunctionView: EditorToolBar {
    var heightForIphone: CGFloat { 142 }
    var heightForIpad: CGFloat { 142 }

    func updateCurrentViewWidth(_ width: CGFloat) {}

    func animateHideToolBar(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.bottomContainerView.alpha = 0
            self?.lineSlider.alpha = 0
        }, completion: { [weak self] _ in
            completion?()
            self?.isHidden = true
        })
    }

    func animateShowToolBar() {
        isHidden = false
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.bottomContainerView.alpha = 1
            self?.lineSlider.alpha = 1
        })
    }
}
