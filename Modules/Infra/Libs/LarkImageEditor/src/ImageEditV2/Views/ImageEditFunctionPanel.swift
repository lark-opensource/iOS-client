//
//  ImageEditFunctionPanel.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/6/25.
//

import Foundation
import LarkBlur
import UIKit

protocol ImageEditFunctionPanelDelegate: AnyObject {
    func lineButtonDidClicked()
    func tagButtonDidClicked()
    func textButtonDidClicked()
    func mosaicButtonDidClicked()
    func trimButtonDidClicked()
    func finishButtonDidClicked()
}

final class ImageEditFunctionPanel: UIView {
    private enum BottomButtonType {
        case line // 线
        case text // 文本
        case mosaic // 马赛克
        case trim // 裁剪
        case tag // 标注

        var config: (normalImage: UIImage, highlightImage: UIImage, title: String) {
            switch self {
            case .line:
                return (Resources.edit_draw_icon, Resources.edit_draw_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Draw)
            case .text:
                return (Resources.edit_text_icon, Resources.edit_text_icon_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Text)
            case .mosaic:
                return (Resources.edit_mosaic_icon, Resources.edit_mosaic_icon_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Pixelate)
            case .trim:
                return (Resources.edit_cut_icon, Resources.edit_cut_icon_highlight,
                        BundleI18n.LarkImageEditor.Lark_ImageViewer_Crop)
            case .tag:
                return (Resources.edit_tag_icon, Resources.edit_tag_highlight,
                       BundleI18n.LarkImageEditor.Lark_ImageViewer_Tag)
            }
        }
    }

    weak var delegate: ImageEditFunctionPanelDelegate?

    private let buttonStack = UIStackView()
    private let finishButton = UIButton(type: .custom)
    private let minViewWidthForPad = CGFloat(510)
    private let blurView = LarkBlurEffectView(radius: 40, color: .ud.N00, colorAlpha: 0.7)

    init() {
        super.init(frame: .zero)

        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(finishButton)
        finishButton.backgroundColor = .ud.primaryContentDefault
        finishButton.layer.cornerRadius = 6
        finishButton.layer.masksToBounds = true
        finishButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_Done, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonDidClicked), for: .touchUpInside)
        finishButton.titleLabel?.font = .systemFont(ofSize: 14)
        finishButton.setTitleColor(.white, for: .normal)
        finishButton.snp.makeConstraints { make in
            make.height.equalTo(36)
            make.width.equalTo(68)
            make.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(38)
        }

        addSubview(buttonStack)
        buttonStack.alignment = .center
        buttonStack.spacing = 30
        setUpStack()

        let lineButton = self.editButton(type: .line)
        lineButton.addTarget(self, action: #selector(lineButtonDidClicked), for: .touchUpInside)
        buttonStack.addArrangedSubview(lineButton)

        let tagButton = self.editButton(type: .tag)
        tagButton.addTarget(self, action: #selector(tagButtonDidClicked), for: .touchUpInside)
        buttonStack.addArrangedSubview(tagButton)

        let textButton = self.editButton(type: .text)
        textButton.addTarget(self, action: #selector(textButtonDidClicked), for: .touchUpInside)
        buttonStack.addArrangedSubview(textButton)

        let trimButton = self.editButton(type: .trim)
        trimButton.addTarget(self, action: #selector(trimButtonDidClicked), for: .touchUpInside)
        buttonStack.addArrangedSubview(trimButton)

        let mosaicButton = self.editButton(type: .mosaic)
        mosaicButton.addTarget(self, action: #selector(mosaicButtonDidClicked), for: .touchUpInside)
        buttonStack.addArrangedSubview(mosaicButton)
    }

    private func setUpStack() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            setUpStackForIPad()
        } else {
            setUpStackForIPhoneOrIpadNarrow()
        }
    }

    private func setUpStackForIPhoneOrIpadNarrow(with width: CGFloat? = nil) {
        buttonStack.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(16)
        }

        if let currentWidth = width {
            buttonStack.spacing = currentWidth < 375 ? 15 : 30
            finishButton.snp.updateConstraints { make in
                make.right.equalToSuperview().inset(currentWidth < 375 ? 15 : 20)
            }
        }
    }

    private func setUpStackForIPad() {
        buttonStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview().priority(600)
            make.right.lessThanOrEqualTo(finishButton.snp.left).inset(-20)
            make.top.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func editButton(type: BottomButtonType) -> UIButton {
        let config = type.config

        let button = PanelButton()
        button.setImage(config.normalImage, for: .normal)
        button.setImage(config.highlightImage, for: .highlighted)
        button.setTitle(config.title, for: .normal)
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.setTitleColor(.ud.primaryContentDefault, for: .highlighted)
        button.titleLabel?.font = .systemFont(ofSize: 10)
        button.titleLabel?.textAlignment = .center

        return button
    }

    @objc
    private func lineButtonDidClicked() { delegate?.lineButtonDidClicked() }

    @objc
    private func tagButtonDidClicked() { delegate?.tagButtonDidClicked() }

    @objc
    private func textButtonDidClicked() { delegate?.textButtonDidClicked() }

    @objc
    private func trimButtonDidClicked() { delegate?.trimButtonDidClicked() }

    @objc
    private func mosaicButtonDidClicked() { delegate?.mosaicButtonDidClicked() }

    @objc
    private func finishButtonDidClicked() { delegate?.finishButtonDidClicked() }
}

extension ImageEditFunctionPanel: EditorToolBar {
    func animateHideToolBar(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.2,
                       animations: { [weak self] in self?.alpha = 0 },
                       completion: { _ in completion?() })
    }

    func animateShowToolBar() { UIView.animate(withDuration: 0.2, animations: { [weak self] in self?.alpha = 1 }) }

    func updateCurrentViewWidth(_ width: CGFloat) {
        buttonStack.snp.removeConstraints()
        if UIDevice.current.userInterfaceIdiom == .pad, width >= minViewWidthForPad {
            setUpStackForIPad()
        } else {
            setUpStackForIPhoneOrIpadNarrow(with: width)
        }
    }

    var heightForIphone: CGFloat { 92 }
    var heightForIpad: CGFloat { 92 }
}
