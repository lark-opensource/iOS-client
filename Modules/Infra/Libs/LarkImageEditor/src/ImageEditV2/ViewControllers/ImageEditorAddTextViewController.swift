//
//  ImageEditorAddTextViewController.swift
//  LarkImageEditor
//
//  Created by 王元洵 on 2021/7/7.
//

import Foundation
import UIKit
import LarkUIKit
import LarkBlur

struct ImageEditorText {
    let text: String
    let textColor: ColorPanelType
    let backgroundColor: ColorPanelType?
    let fontSize: Int
    let numberOfLines: Int

    init(text: String,
         textColor: ColorPanelType?,
         backgroundColor: ColorPanelType?,
         fontSize: Int = 12,
         numberOfLines: Int = 0) {
        self.text = text
        self.textColor = textColor ?? .red
        self.backgroundColor = backgroundColor
        self.fontSize = fontSize
        self.numberOfLines = numberOfLines
    }

    static var `default`: ImageEditorText = .init(text: "",
                                                  textColor: nil,
                                                  backgroundColor: nil)
}

final class ImageEditorAddTextViewController: BaseUIViewController,
                                        UITextViewDelegate,
                                        ImageEditColorStackDelegate {

    private enum ColorTarget {
        case background
        case text
    }

    var cancelEditBlock: ((ImageEditorAddTextViewController) -> Void)?
    var finishEditBlock: ((ImageEditorAddTextViewController, ImageEditorText) -> Void)?
    var eventBlock: ((ImageEditEvent) -> Void)?

    private let keyBoardBlurView = LarkBlurEffectView(radius: 40, color: .ud.N00, colorAlpha: 0.7)
    private let textBackgroundEnableButton = UIButton(type: .custom)
    private let verticalImageView = UIImageView(image: Resources.edit_text_vertical)
    private let backButton = UIButton(type: .custom)
    private let finishButton = UIButton(type: .custom)
    private let textView: UITextView
    private let layoutManager = EditLayoutManager()
    private let colorStack = ImageEditColorStack()
    private let blurView = LarkBlurEffectView(radius: 24, color: .ud.N1000, colorAlpha: 0.25)
    private let maxCharacterCount = 75
    private let minKeyboardWidth = CGFloat(500)

    private var currentColorTarget = ColorTarget.text
    private var currentTextColor = ColorPanelType.default
    private var currentBackgroundColor: ColorPanelType?

    init(editText: ImageEditorText) {
        let storge = NSTextStorage()
        storge.append(.init(string: editText.text))
        storge.addLayoutManager(layoutManager)
        let container = NSTextContainer()
        container.lineFragmentPadding = 15
        layoutManager.addTextContainer(container)
        textView = UITextView(frame: .zero, textContainer: container)

        currentTextColor = editText.textColor
        currentBackgroundColor = editText.backgroundColor

        super.init(nibName: nil, bundle: nil)

        addAttributes(numberOfLines: editText.numberOfLines)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        finishButton.removeFromSuperview()
        setUpFinishButton(with: size)
    }

    private func setUpFinishButton(with size: CGSize) {
        if size.width < minKeyboardWidth {
            view.addSubview(finishButton)
            finishButton.snp.makeConstraints { make in
                make.centerY.equalTo(backButton)
                make.right.equalToSuperview().inset(20)
                make.width.equalTo(68)
                make.height.equalTo(36)
            }
        } else {
            keyBoardBlurView.addSubview(finishButton)
            finishButton.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(20)
                make.top.equalToSuperview().inset(12)
                make.width.equalTo(68)
                make.height.equalTo(36)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var prefersStatusBarHidden: Bool { return true }

    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        textView.inputAccessoryView = keyBoardBlurView
        textView.font = .systemFont(ofSize: 24)
        textView.textColor = currentTextColor.color()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.isScrollEnabled = false
        layoutManager.useColor = currentBackgroundColor?.color() ?? .clear
        textView.textContainerInset = .init(top: 160, left: 0, bottom: 0, right: 0)
        textView.selectedRange = .init(location: textView.attributedText.length, length: 0)
        view.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(10)
        }

        keyBoardBlurView.frame = .init(x: 0, y: 0, width: view.bounds.width, height: 60)

        view.addSubview(backButton)
        backButton.setImage(Resources.edit_back, for: .normal)
        backButton.addTarget(self, action: #selector(backButtonDidClicked), for: .touchUpInside)
        backButton.snp.makeConstraints { (make) in
            make.size.equalTo(48)
            make.left.equalToSuperview().inset(6)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(12)
        }

        finishButton.addTarget(self, action: #selector(finishButtonDidClicked), for: .touchUpInside)
        finishButton.backgroundColor = .ud.primaryContentDefault
        finishButton.layer.cornerRadius = 6
        finishButton.layer.masksToBounds = true
        finishButton.setTitle(BundleI18n.LarkImageEditor.Lark_ImageViewer_Done, for: .normal)
        finishButton.titleLabel?.font = .systemFont(ofSize: 14)
        finishButton.setTitleColor(.white, for: .normal)

        textBackgroundEnableButton.setImage(Resources.edit_text_bg_disable, for: .normal)
        textBackgroundEnableButton.setImage(Resources.edit_text_bg_enable, for: .selected)
        textBackgroundEnableButton.addTarget(self,
                                             action: #selector(backgroundButtonDidClicked), for: .touchUpInside)

        if currentBackgroundColor != nil {
            textBackgroundEnableButton.isSelected = true
            colorStack.currentColor = currentBackgroundColor ?? .default
            currentColorTarget = .background
        } else {
            colorStack.currentColor = currentTextColor
            currentColorTarget = .text
        }
        colorStack.delegate = self
        setUpFinishButton(with: view.bounds.size)

        if UIDevice.current.userInterfaceIdiom == .pad {
            let containerStackView = UIStackView()
            containerStackView.alignment = .center
            containerStackView.distribution = .equalSpacing
            keyBoardBlurView.addSubview(containerStackView)
            containerStackView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(333).priority(600)
                make.left.greaterThanOrEqualToSuperview().offset(5)
                make.right.lessThanOrEqualToSuperview()
            }

            textBackgroundEnableButton.snp.makeConstraints { make in
                make.size.equalTo(24)
            }
            verticalImageView.snp.makeConstraints { make in
                make.width.equalTo(1)
                make.height.equalTo(24)
            }
            colorStack.snp.makeConstraints { make in
                make.width.equalTo(263).priority(600)
            }

            containerStackView.addArrangedSubview(textBackgroundEnableButton)
            containerStackView.addArrangedSubview(verticalImageView)
            containerStackView.addArrangedSubview(colorStack)
        } else {
            keyBoardBlurView.addSubview(textBackgroundEnableButton)
            textBackgroundEnableButton.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(18)
                make.left.equalToSuperview().inset(20)
                make.size.equalTo(24)
            }

            keyBoardBlurView.addSubview(verticalImageView)
            verticalImageView.snp.makeConstraints { make in
                make.top.equalToSuperview().inset(18)
                make.left.equalTo(textBackgroundEnableButton.snp.right).offset(24)
                make.width.equalTo(1)
                make.height.equalTo(24)
            }

            keyBoardBlurView.addSubview(colorStack)
            colorStack.snp.makeConstraints { make in
                make.left.equalTo(verticalImageView.snp.right).inset(-22)
                make.centerY.equalTo(textBackgroundEnableButton)
                make.right.equalToSuperview().inset(20)
            }
        }
    }
    // swiftlint:enable function_body_length

    private func setColor(_ color: ColorPanelType) {
        switch currentColorTarget {
        case .background:
            layoutManager.useColor = color.color()
            currentTextColor = colorStack.currentColor != .white ? .white : .black
            textView.textColor = currentTextColor.color()
            currentBackgroundColor = color
        case .text:
            textView.textColor = color.color()
            layoutManager.useColor = .clear
            currentTextColor = color
        }
    }

    @objc
    private func backButtonDidClicked() {
        textView.resignFirstResponder()
        cancelEditBlock?(self)
    }

    @objc
    private func finishButtonDidClicked() {
        textView.resignFirstResponder()
        eventBlock?(.init(event: "public_pic_edit_text_click",
                          params: ["click": "confirm", "target": "public_pic_edit_view"]))
        finishEditBlock?(self, .init(text: textView.text,
                                     textColor: currentTextColor,
                                     backgroundColor: currentColorTarget == .background ?
                                        currentBackgroundColor : nil,
                                     numberOfLines: layoutManager.numberOfLines))
    }

    @objc
    private func backgroundButtonDidClicked(_ sender: UIButton) {
        eventBlock?(.init(event: "public_pic_edit_text_click",
                          params: ["click": "text_box", "target": "none"]))
        sender.isSelected = !sender.isSelected
        currentColorTarget = sender.isSelected ? .background : .text
        setColor(colorStack.currentColor)
    }

    private func addAttributes(numberOfLines: Int) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8
        style.alignment = numberOfLines > 1 ? .left : .center
        textView.textAlignment = numberOfLines > 1 ? .left : .center
        textView.textStorage.addAttributes([.paragraphStyle: style, .font: UIFont.systemFont(ofSize: 24)],
                                           range: .init(location: 0, length: textView.textStorage.length))
    }

    func didSelectColor(_ selectedColor: ColorPanelType) {
        eventBlock?(.init(event: "public_pic_edit_text_click",
                          params: ["click": "color", "target": "none"]))
        setColor(selectedColor)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.attributedText.length - range.length + text.count > maxCharacterCount {
            return false
        }
        return true
    }

    func textViewDidChange(_ textView: UITextView) {
        addAttributes(numberOfLines: layoutManager.numberOfLines)
    }
}
