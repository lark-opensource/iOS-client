//
//  MosaicFunctionView.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/6.
//

import UIKit
import Foundation
import LarkUIKit
import LarkBlur

enum EditMosaicType {
    case mosaic
    case gaussan
}

enum MosaicGestureType {
    case smear
    case rect

    fileprivate var config: (normalImage: UIImage, highlightImage: UIImage, title: String) {
        switch self {
        case .smear:
            return (Resources.edit_draw_pixelate, Resources.edit_draw_pixelate_highlight,
                    BundleI18n.LarkImageEditor.Lark_ImageViewer_DrawPixelate)
        case .rect:
            return (Resources.edit_select_pixelate, Resources.edit_select_pixelate_highlight,
                    BundleI18n.LarkImageEditor.Lark_ImageViewer_SelectPixelate)
        }
    }
}

protocol MosaicFunctionViewDelegate: EditorToolBarDelegate {
    func aeroButtonDidClicked()
    func blurButtonDidClicked()
}

final class MosaicFunctionView: UIView {
    private let mosaicSlider = ImageEditorSlideView(maxValue: 60, minValue: 30)
    private let bottomContainerView = LarkBlurEffectView(radius: 40, color: .ud.N00, colorAlpha: 0.7)
    private let selectButtonStack = UIStackView()
    private let mosaicButtonStack = UIStackView()
    private let finishButton = UIButton(type: .custom)
    private(set) var currentMosaic = EditMosaicType.mosaic
    private(set) var currentSelectType = MosaicGestureType.smear
    private let minViewWidthForPad = CGFloat(510)
    private let containerStackView = UIStackView()
    private let verticalImageView = UIImageView(image: Resources.edit_text_vertical)

    weak var delegate: MosaicFunctionViewDelegate?
    var currentSliderValue: CGFloat { CGFloat(mosaicSlider.currentValue) }

    // swiftlint:disable function_body_length
    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(bottomContainerView)
        bottomContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(UIDevice.current.userInterfaceIdiom == .pad ? 96 : 132)
        }
        bottomContainerView.alpha = 0

        let aeroButton = MosaicTypeStackButton(buttonImage: Resources.edit_aero)
        aeroButton.isSelected = true
        aeroButton.addTarget(self, action: #selector(aeroButtonDidClicked), for: .touchUpInside)
        let blurButton = MosaicTypeStackButton(buttonImage: Resources.edit_blur)
        blurButton.addTarget(self, action: #selector(blurButtonDidClicked), for: .touchUpInside)
        mosaicButtonStack.spacing = 20
        mosaicButtonStack.alignment = .center
        mosaicButtonStack.addArrangedSubview(aeroButton)
        mosaicButtonStack.addArrangedSubview(blurButton)

        selectButtonStack.spacing = 30
        selectButtonStack.alignment = .center
        let smearButton = selectTypeButton(type: .smear)
        smearButton.isSelected = true
        smearButton.addTarget(self, action: #selector(smearButtonDidClicked), for: .touchUpInside)
        selectButtonStack.addArrangedSubview(smearButton)
        let rectButton = selectTypeButton(type: .rect)
        rectButton.addTarget(self, action: #selector(rectButtonDidClicked), for: .touchUpInside)
        selectButtonStack.addArrangedSubview(rectButton)

        if UIDevice.current.userInterfaceIdiom == .pad {
            setUpUIForIPad()
        } else {
            setUpUIForIPhoneOrIpadNarrow()
        }

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
            make.centerY.equalTo(selectButtonStack)
        }

        addSubview(mosaicSlider)
        mosaicSlider.delegate = self
        mosaicSlider.snp.makeConstraints { make in
            make.bottom.equalTo(bottomContainerView.snp.top)
            make.height.equalTo(50)
            make.leading.trailing.top.equalToSuperview()
        }
        mosaicSlider.alpha = 0
    }
    // swiftlint:enable function_body_length

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUIForIPhoneOrIpadNarrow() {
        bottomContainerView.addSubview(mosaicButtonStack)
        bottomContainerView.addSubview(selectButtonStack)
        mosaicButtonStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.centerX.equalToSuperview()
        }
        selectButtonStack.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(54)
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
        containerStackView.addArrangedSubview(selectButtonStack)

        verticalImageView.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(24)
        }
        containerStackView.addArrangedSubview(verticalImageView)
        containerStackView.addArrangedSubview(mosaicButtonStack)
    }

    private func disableButtonStack(_ stack: UIStackView) {
        stack.subviews.forEach {
            if let button = $0 as? UIButton {
                button.isSelected = false
            }
        }
    }

    @objc
    private func finishButtonDidClicked() {
        delegate?.eventOccured(eventName: "public_pic_edit_mosaic_click",
                               params: ["click": "confirm", "target": "public_pic_edit_view"])
        delegate?.finishButtonDidClicked(in: self)
    }

    @objc
    private func smearButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        delegate?.eventOccured(eventName: "public_pic_edit_mosaic_click",
                               params: ["click": "brush_mosaic", "target": "none"])

        mosaicSlider.isHidden = false
        disableButtonStack(selectButtonStack)
        sender.isSelected = true
        currentSelectType = .smear
    }

    @objc
    private func rectButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        delegate?.eventOccured(eventName: "public_pic_edit_mosaic_click",
                               params: ["click": "frame_mosaic", "target": "none"])

        mosaicSlider.isHidden = true
        disableButtonStack(selectButtonStack)
        sender.isSelected = true
        currentSelectType = .rect
    }

    @objc
    private func aeroButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        delegate?.eventOccured(eventName: "public_pic_edit_mosaic_click",
                               params: ["click": "mosaic_style", "target": "none"])

        disableButtonStack(mosaicButtonStack)
        sender.isSelected = true
        delegate?.aeroButtonDidClicked()
        currentMosaic = .mosaic
    }

    @objc
    private func blurButtonDidClicked(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        delegate?.eventOccured(eventName: "public_pic_edit_mosaic_click",
                               params: ["click": "frosted_glass_style", "target": "none"])

        disableButtonStack(mosaicButtonStack)
        sender.isSelected = true
        delegate?.blurButtonDidClicked()
        currentMosaic = .gaussan
    }

    private func selectTypeButton(type: MosaicGestureType) -> UIButton {
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

    private func setSelectButtonHighlighted(with current: UIButton) {
        self.selectButtonStack.subviews.forEach {
            guard let button = $0 as? UIButton else { return }

            if button === current {
                button.isSelected = true
            } else {
                button.isSelected = false
            }
        }
    }
}

extension MosaicFunctionView: ImageEditorSlideViewDelegate {
    func sliderDidChangeValue(to newValue: Int) {
        delegate?.changeWidth(with: CGFloat(newValue), defaultWidth: CGFloat(mosaicSlider.defaultValue))
    }

    func sliderTimerTicked() {
        delegate?.sliderTimerTicked()
    }
}

fileprivate extension MosaicFunctionView {
    final class MosaicTypeStackButton: UIButton {
        private let borderView = UIView()
        private let innerView = UIImageView()

        init(buttonImage: UIImage) {
            super.init(frame: CGRect.zero)

            addSubview(borderView)
            borderView.layer.masksToBounds = true
            borderView.layer.cornerRadius = 4
            borderView.backgroundColor = .clear
            borderView.isUserInteractionEnabled = false
            borderView.layer.ud.setBorderColor(.ud.colorfulBlue)
            borderView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
                make.width.equalTo(46)
                make.height.equalTo(26)
            }

            addSubview(innerView)
            innerView.layer.masksToBounds = true
            innerView.layer.cornerRadius = 2
            innerView.image = buttonImage
            innerView.isUserInteractionEnabled = false
            innerView.snp.makeConstraints { (make) in
                make.edges.equalTo(borderView).inset(3)
            }
        }

        required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override var isSelected: Bool {
            didSet {
                if isSelected {
                    borderView.layer.borderWidth = 2
                } else {
                    borderView.layer.borderWidth = 0
                }
            }
        }
    }
}

extension MosaicFunctionView: EditorToolBar {
    var heightForIphone: CGFloat { 182 }
    var heightForIpad: CGFloat { 146 }

    func animateHideToolBar(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.bottomContainerView.alpha = 0
            self?.mosaicSlider.alpha = 0
        }, completion: { [weak self] _ in
            completion?()
            self?.isHidden = true
        })
    }

    func animateShowToolBar() {
        isHidden = false
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.bottomContainerView.alpha = 1
            self?.mosaicSlider.alpha = 1
        })
    }

    func updateCurrentViewWidth(_ width: CGFloat) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        containerStackView.removeFromSuperview()
        verticalImageView.removeFromSuperview()
        mosaicButtonStack.removeFromSuperview()
        selectButtonStack.removeFromSuperview()
        if width < minViewWidthForPad {
            setUpUIForIPhoneOrIpadNarrow()
            snp.updateConstraints { make in make.height.equalTo(heightForIphone) }
        } else {
            setUpUIForIPad()
            snp.updateConstraints { make in make.height.equalTo(heightForIpad) }
        }

        finishButton.snp.remakeConstraints { make in
            make.height.equalTo(36)
            make.width.equalTo(68)
            make.right.equalToSuperview().inset(20)
            make.centerY.equalTo(selectButtonStack)
        }
    }
}
