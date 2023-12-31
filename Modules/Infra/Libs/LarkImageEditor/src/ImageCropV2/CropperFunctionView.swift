//
//  CropperFunctionView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/8.
//

import Foundation
import FigmaKit
import UIKit
import LarkUIKit

protocol CropperFunctionViewDelegate: AnyObject {
    func cancelButtonDidClicked()
    func finishButtonDidClicked()
    func resetButtonDidClicked()
    func rotateButtonDidClicked()
    func ratioButtonDidClicked(_ ratio: CGFloat?)
}

final class CropperFunctionView: UIView {
    private enum CropperButtonType {
        case rotate
        case reset
        case free
        case oneOverOne
        case threeOverFour
        case fourOverThree
        case nineOverSixteen
        case sixteenOverNine

        var config: (normalImage: UIImage, highlightImage: UIImage, title: String) {
            switch self {
            case .rotate:
                return (Resources.edit_cropper_rotate, Resources.edit_cropper_rotate_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Rotate)
            case .reset:
                return (Resources.edit_cropper_reset, Resources.edit_cropper_reset_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Revert)
            case .free:
                return (Resources.edit_cropper_free, Resources.edit_cropper_free_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Free)
            case .oneOverOne:
                return (Resources.edit_cropper_one_to_one, Resources.edit_cropper_one_to_one_highlight,
                        "1:1")
            case .threeOverFour:
                return (Resources.edit_cropper_three_to_four, Resources.edit_cropper_three_to_four_highlight,
                        "3:4")
            case .fourOverThree:
                return (Resources.edit_cropper_four_to_three, Resources.edit_cropper_four_to_three_highlight,
                        "4:3")
            case .nineOverSixteen:
                return (Resources.edit_cropper_nine_to_sixteen, Resources.edit_cropper_nine_to_sixteen_highlight,
                        "9:16")
            case .sixteenOverNine:
                return (Resources.edit_cropper_sixteen_to_nine, Resources.edit_cropper_sixteen_to_nine_highlight,
                        "16:9")
            }
        }
    }

    private lazy var contentLayoutGuide = UILayoutGuide()
    private let operationButtonStack = UIStackView()
    private let ratioButtonStack = UIStackView()
    private let finishButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .custom)
    private let blurView = VisualBlurView()

    weak var delegate: CropperFunctionViewDelegate?

    // swiftlint:disable function_body_length
    init(supportMoreRatio: CropperConfigure.RatioStyle, supportRotate: Bool = true) {
        super.init(frame: .zero)

        backgroundColor = .ud.N1000

        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.blurRadius = 40
        blurView.fillColor = UIColor.ud.N00
        blurView.fillOpacity = 0.7

        if supportMoreRatio == .more {
            addSubview(ratioButtonStack)
            ratioButtonStack.spacing = Cons.operationButtonSpacing
            ratioButtonStack.alignment = .center
            ratioButtonStack.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().inset(16)
            }
            let freeButton = cropperButton(type: .free)
            freeButton.addTarget(self, action: #selector(freeButtonDidClicked), for: .touchUpInside)
            freeButton.isSelected = true
            ratioButtonStack.addArrangedSubview(freeButton)
            let oneOverOneButton = cropperButton(type: .oneOverOne)
            oneOverOneButton.addTarget(self, action: #selector(oneOverOneButtonDidClicked), for: .touchUpInside)
            ratioButtonStack.addArrangedSubview(oneOverOneButton)
            let threeOverFourButton = cropperButton(type: .threeOverFour)
            threeOverFourButton.addTarget(self, action: #selector(threeOverFourButtonDidClicked), for: .touchUpInside)
            ratioButtonStack.addArrangedSubview(threeOverFourButton)
            let fourOverThreeButton = cropperButton(type: .fourOverThree)
            fourOverThreeButton.addTarget(self, action: #selector(fourOverThreeButtonDidClicked), for: .touchUpInside)
            ratioButtonStack.addArrangedSubview(fourOverThreeButton)
            let nineOverSixteenButton = cropperButton(type: .nineOverSixteen)
            nineOverSixteenButton.addTarget(self,
                                            action: #selector(nineOverSixteenButtonDidClicked),
                                            for: .touchUpInside)
            ratioButtonStack.addArrangedSubview(nineOverSixteenButton)
            let sixteenOverNineButton = cropperButton(type: .sixteenOverNine)
            sixteenOverNineButton.addTarget(self,
                                            action: #selector(sixteenOverNineButtonDidClicked),
                                            for: .touchUpInside)
            ratioButtonStack.addArrangedSubview(sixteenOverNineButton)
        }

        finishButton.addTarget(self, action: #selector(finishButtonDidClicked), for: .touchUpInside)
        finishButton.backgroundColor = .ud.primaryContentDefault
        finishButton.layer.cornerRadius = 6
        finishButton.layer.masksToBounds = true
        finishButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_Confirm, for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 16)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.setInsets(contentInsets: .init(horizontal: Cons.buttonTitleMargin * 2, vertical: 0))
        addSubview(finishButton)
        finishButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Cons.buttonLeftRightInset)
            make.bottom.equalToSuperview().inset(Cons.buttonBottomInset)
            make.height.equalTo(Cons.fixedButtonHeight)
            make.width.greaterThanOrEqualTo(Cons.minimumButtonWidth)
        }

        addSubview(cancelButton)
        cancelButton.setTitleColor(.ud.textTitle, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16)
        cancelButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_Cancel, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonDidClicked), for: .touchUpInside)
        cancelButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Cons.buttonLeftRightInset)
            make.bottom.equalToSuperview().inset(Cons.buttonBottomInset)
            make.height.equalTo(Cons.fixedButtonHeight)
            make.width.greaterThanOrEqualTo(Cons.minimumButtonWidth)
        }

        addLayoutGuide(contentLayoutGuide)
        contentLayoutGuide.snp.makeConstraints { make in
            make.top.bottom.equalTo(safeAreaLayoutGuide)
            make.left.equalTo(cancelButton.snp.right).offset(Cons.buttonSpacing)
            make.right.equalTo(finishButton.snp.left).offset(-Cons.buttonSpacing)
        }

        addSubview(operationButtonStack)
        operationButtonStack.snp.makeConstraints { make in
            make.centerX.equalTo(contentLayoutGuide)
            make.width.lessThanOrEqualTo(contentLayoutGuide)
            make.bottom.equalToSuperview().inset(Cons.operationButtonBottomInset)
        }

        operationButtonStack.spacing = Cons.operationButtonSpacing
        operationButtonStack.alignment = .center
        let resetButton = cropperButton(type: .reset)
        resetButton.addTarget(self, action: #selector(resetButtonDidClicked), for: .touchUpInside)
        operationButtonStack.addArrangedSubview(resetButton)
        if supportRotate {
            let rotateButton = cropperButton(type: .rotate)
            rotateButton.addTarget(self, action: #selector(rotateButtonDidClicked), for: .touchUpInside)
            operationButtonStack.addArrangedSubview(rotateButton)
        }
    }
    // swiftlint:enable function_body_length

    private func cropperButton(type: CropperButtonType) -> UIButton {
        let config = type.config

        let button = PanelButton()
        button.setImage(config.normalImage, for: .normal)
        button.setImage(config.highlightImage, for: .highlighted)
        button.setImage(config.highlightImage, for: .selected)
        button.setTitle(config.title, for: .normal)
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.setTitleColor(.ud.primaryContentDefault, for: .highlighted)
        button.setTitleColor(.ud.primaryContentDefault, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 10)
        button.titleLabel?.textAlignment = .center
        button.imageView?.contentMode = .scaleAspectFit

        return button
    }

    private func ratioButtonClicked(_ button: UIButton, ratio: CGFloat?) {
        disableAllRatioButtons()
        button.isSelected = true
        delegate?.ratioButtonDidClicked(ratio)
    }

    @objc
    private func rotateButtonDidClicked(_ sender: UIButton) { delegate?.rotateButtonDidClicked() }

    @objc
    private func resetButtonDidClicked() { delegate?.resetButtonDidClicked() }

    @objc
    private func cancelButtonDidClicked() { delegate?.cancelButtonDidClicked() }

    @objc
    private func finishButtonDidClicked() { delegate?.finishButtonDidClicked() }

    @objc
    private func freeButtonDidClicked(_ sender: UIButton) { ratioButtonClicked(sender, ratio: nil) }

    @objc
    private func oneOverOneButtonDidClicked(_ sender: UIButton) { ratioButtonClicked(sender, ratio: 1) }

    @objc
    private func threeOverFourButtonDidClicked(_ sender: UIButton) { ratioButtonClicked(sender, ratio: 3.0 / 4.0) }

    @objc
    private func fourOverThreeButtonDidClicked(_ sender: UIButton) { ratioButtonClicked(sender, ratio: 4.0 / 3.0) }

    @objc
    private func nineOverSixteenButtonDidClicked(_ sender: UIButton) { ratioButtonClicked(sender, ratio: 9.0 / 16.0) }

    @objc
    private func sixteenOverNineButtonDidClicked(_ sender: UIButton) { ratioButtonClicked(sender, ratio: 16.0 / 9.0) }

    private func disableAllRatioButtons() {
        ratioButtonStack.subviews.forEach {
            if let button = $0 as? UIButton {
                button.isSelected = false
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// internal apis
extension CropperFunctionView {
    func setToFree() {
        disableAllRatioButtons()
        if let freeButton = ratioButtonStack.subviews.first as? UIButton {
            freeButton.isSelected = true
        }
    }

    func setButtonEnable(_ enable: Bool) {
        ratioButtonStack.isUserInteractionEnabled = enable
        operationButtonStack.isUserInteractionEnabled = enable
    }
}

extension UIButton {

    func setInsets(iconTitleSpacing: CGFloat = 0, contentInsets: UIEdgeInsets = .zero) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.left,
            bottom: contentInsets.bottom,
            right: contentInsets.right + iconTitleSpacing
        )
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: iconTitleSpacing,
            bottom: 0,
            right: -iconTitleSpacing
        )
    }
}

// Constants

extension CropperFunctionView {

    enum Cons {
        static var fixedButtonHeight: CGFloat { 36 }
        static var minimumButtonWidth: CGFloat { 68 }
        static var buttonBottomInset: CGFloat { 38 }
        static var buttonLeftRightInset: CGFloat { 12 }
        static var buttonTitleMargin: CGFloat { 5 }
        static var operationButtonBottomInset: CGFloat { 34 }
        static var buttonSpacing: CGFloat { 6 }
        static var operationButtonSpacing: CGFloat { 24 }
    }
}
