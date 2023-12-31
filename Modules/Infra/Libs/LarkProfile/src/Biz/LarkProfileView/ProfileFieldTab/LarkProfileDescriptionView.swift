//
//  LarkProfileDescriptionView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/10/21.
//

import Foundation
import ByteWebImage
import EENavigator
import Homeric
import LarkAssetsBrowser
import LarkAvatar
import LarkUIKit
import LKCommonsTracker
import UniverseDesignDialog
import UniverseDesignInput
import UniverseDesignIcon
import UIKit

final class LarkProfileDescriptionView: UIView {
    weak var fromVC: LarkProfileAliasViewController?

    var text: String {
        set {
            self.descriptionMultilineTextField.text = newValue
            updateTextCount(getLength(forText: newValue))
        }
        get {
            return self.descriptionMultilineTextField.text ?? ""
        }
    }

    var hasChange: Bool = false

    var image: UIImage? {
        return self.imageView.image
    }

    var updateCallback: (() -> Void)?

    var tapImageViewCallback: (() -> Void)?

    var textViewDidChange: ((String) -> Void)?

    // 最大半角字符数
    private var maxLength = 400

    private let userID: String

    lazy var descriptionMultilineTextField: UDMultilineTextField = {
        let config = UDMultilineTextFieldUIConfig(textColor: UIColor.ud.textTitle,
                                                  font: Cons.descriptionFont,
                                                  minHeight: 22)
        let textField = UDMultilineTextField(config: config)
        textField.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textField.textContainerInset = .zero
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.placeholder = BundleI18n.LarkProfile.Lark_ProfileMemo_AddDescription_Placeholder
        return textField
    }()

    lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = Cons.countFont
        countLabel.textColor = UIColor.ud.textPlaceholder
        countLabel.textAlignment = .right
        countLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        countLabel.setContentHuggingPriority(.required, for: .vertical)
        countLabel.text = "0/\(maxLength)"
        return countLabel
    }()

    lazy var lineView = UIView()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.ud.bgContentBase
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var imageWrapperView: UIControl = {
        let control = UIControl()
        control.layer.cornerRadius = 4
        control.backgroundColor = UIColor.ud.bgContentBase
        return control
    }()

    lazy var placeholderWrapperView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()
    private var navigator: EENavigator.Navigatable
    init(userID: String, navigator: EENavigator.Navigatable) {
        self.navigator = navigator
        self.userID = userID

        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        self.layer.cornerRadius = 6

        self.addSubview(descriptionMultilineTextField)
        self.addSubview(countLabel)
        self.addSubview(lineView)
        self.addSubview(imageWrapperView)
        imageWrapperView.addSubview(placeholderWrapperView)
        imageWrapperView.addSubview(imageView)
        imageWrapperView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageWrapperView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.isHidden = true

        descriptionMultilineTextField.input.delegate = self
        descriptionMultilineTextField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(9)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(53)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionMultilineTextField.snp.bottom).offset(Cons.hMargin)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.height.equalTo(18)
        }

        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        lineView.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(8)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.height.equalTo(1)
        }

        imageWrapperView.addTarget(self, action: #selector(didTapImageWrapper), for: .touchUpInside)
        imageWrapperView.snp.makeConstraints { make in
            make.top.equalTo(lineView.snp.bottom)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.bottom.equalToSuperview()
        }

        placeholderWrapperView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(160)
        }

        let icon = UIImageView(image: UDIcon.cameraOutlined.ud.withTintColor(UIColor.ud.iconN2))

        let placeholderLabel = UILabel()
        placeholderLabel.text = BundleI18n.LarkProfile.Lark_ProfileMemo_AddNameCardOrImage_Placeholder
        placeholderLabel.textColor = UIColor.ud.textCaption
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.numberOfLines = 0

        placeholderWrapperView.addSubview(icon)
        placeholderWrapperView.addSubview(placeholderLabel)

        icon.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.width.equalTo(20)
        }

        placeholderLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMemoDescription(_ memoDescription: ProfileMemoDescription) {
        self.text = memoDescription.memoText

        let passThrough = ImagePassThrough.transform(passthrough: memoDescription.memoPicture)

        imageView.bt.setLarkImage(with: .default(key: memoDescription.memoPicture.key),
                                  passThrough: passThrough,
                                  completion: { [weak self] result in
                                      switch result {
                                      case .success(let imageResult):
                                          self?.updateImage(imageResult.image)
                                      case .failure:
                                          self?.updateImage(nil)
                                      }
                                  })
    }

    @objc
    private func didTapImageWrapper() {
        tapImageViewCallback?()
        if imageView.isHidden {
            imagePickerClicked()
        } else {
            previewClicked()
        }
    }

    private func imagePickerClicked() {
        guard let fromVC = fromVC else {
            return
        }

        self.trackImageClick(isDelete: false)
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1),
                                               isOriginButtonHidden: true)
        picker.showSingleSelectAssetGridViewController()
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in
            guard let `self` = self, let asset = result.selectedAssets.first else {
                picker.dismiss(animated: true, completion: nil)
                return
            }

            self.hasChange = true

            DispatchQueue.main.async {
                let width = self.imageWrapperView.frame.width
                let height = width / (CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight))
                let image = asset.imageWithSize(size: CGSize(width: width * UIScreen.main.scale, height: height * UIScreen.main.scale))
                DispatchQueue.main.async {
                    guard let image = image else { return }
                    self.updateImage(image)
                    picker.dismiss(animated: true, completion: nil)
                }
            }
        }
        self.navigator.present(picker, from: fromVC)
    }

    func updateMemo(text: String, image: UIImage?) {
        self.text = text
        self.updateImage(image)
    }

    func updateLayoutConstraints(contentSize: CGSize) {
        if let image = self.imageView.image {
            placeholderWrapperView.isHidden = true
            placeholderWrapperView.snp.removeConstraints()

            imageView.isHidden = false
            imageWrapperView.backgroundColor = UIColor.ud.bgContentBase
            let wrapperViewWidth = min(contentSize.width, (contentSize.height - self.lineView.frame.bottom)) - 2 * Cons.hMargin
            imageWrapperView.snp.remakeConstraints{ make in
                make.top.equalTo(lineView.snp.bottom).offset(Cons.hMargin)
                make.centerX.equalToSuperview()
                make.width.height.equalTo(wrapperViewWidth)
                make.bottom.equalToSuperview().offset(-Cons.hMargin)
            }
            let resultImageSize = calculateImageSize(imageSize: image.size, wrapperWidth: wrapperViewWidth)
            imageView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.size.equalTo(resultImageSize)
            }
        } else {
            imageView.isHidden = true
            imageWrapperView.backgroundColor = .clear
            imageView.snp.removeConstraints()
            placeholderWrapperView.isHidden = false
            placeholderWrapperView.snp.remakeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.centerX.equalToSuperview()
                make.height.equalTo(160)
            }
            imageWrapperView.snp.remakeConstraints{ make in
                make.top.equalTo(lineView.snp.bottom)
                make.left.equalToSuperview().offset(Cons.hMargin)
                make.right.equalToSuperview().offset(-Cons.hMargin)
                make.bottom.equalToSuperview()
            }
        }
        self.layoutIfNeeded()
    }

    private func updateImage(_ image: UIImage?) {
        self.imageView.image = image
        guard let fromVC = fromVC else { return }
        updateLayoutConstraints(contentSize: fromVC.descriptionViewContentSize)
    }

    private func calculateImageSize(imageSize: CGSize, wrapperWidth: CGFloat) -> CGSize {
        if imageSize.width <= imageSize.height {
            return CGSize(width: wrapperWidth * (imageSize.width / imageSize.height), height: wrapperWidth)
        } else {
            return CGSize(width: wrapperWidth, height: wrapperWidth * (imageSize.height / imageSize.width))
        }
    }

    private func previewClicked() {
        guard let fromVC = fromVC else {
            return
        }

        let asset = LKDisplayAsset()
        let vc = LarkProfileAliasPreivewViewController(assets: [asset],
                                                       pageIndex: 0)
        vc.isSavePhotoButtonHidden = true
        vc.getExistedImageBlock = { [weak self] (_) -> UIImage? in
            return self?.imageView.image
        }
        vc.addAction(title: BundleI18n.LarkProfile.Lark_ProfileMemo_ChangeImage_Option) { [weak self, weak vc] (_) in
            vc?.dismiss(animated: false, completion: nil)
            self?.imagePickerClicked()
        }

        vc.addAction(title: BundleI18n.LarkProfile.Lark_ProfileMemo_DeleteImage, titleColor: UIColor.ud.functionDangerContentDefault) { [weak vc] (_) in
            guard let vc = vc else { return }
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.LarkProfile.Lark_ProfileMemo_DeleteThisImage_PopupText)
            dialog.addSecondaryButton(text: BundleI18n.LarkProfile.Lark_ProfileMemo_DeleteThisImage_GoBack_Button)
            dialog.addPrimaryButton(text: BundleI18n.LarkProfile.Lark_ProfileMemo_DeleteThisImage_DeleteButton) { [weak self, weak vc] in
                vc?.dismiss(animated: false, completion: nil)
                self?.hasChange = true
                self?.updateImage(nil)
                self?.trackImageClick(isDelete: true)
            }
            self.navigator.present(dialog, from: vc)
        }

        self.navigator.present(vc, from: fromVC)
    }

    // 按照特定字符计数规则，获取字符串长度
    func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    // 按照特定字符计数规则，截取字符串
    private func getPrefix(_ maxLength: Int, forText text: String) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, 2)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }

    private func updateTextCount(_ textCount: Int) {
        let displayCount = Int(ceil(Float(textCount)))
        let totalCount = Int(ceil(Float(maxLength)))
        countLabel.text = "\(displayCount)/\(totalCount)"
    }

    private func trackImageClick(isDelete: Bool) {
    }
}

extension LarkProfileDescriptionView: UDMultilineTextFieldDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let limit = maxLength
        var selectedLength = 0
        if let range = textView.markedTextRange {
            selectedLength = textView.offset(from: range.start, to: range.end)
        }
        let contentLength = max(0, textView.text.count - selectedLength)
        let validText = String(textView.text.prefix(contentLength))
        if getLength(forText: validText) > limit {
            let trimmedText = getPrefix(limit, forText: textView.text)
            textView.text = trimmedText
            textViewDidChange?(trimmedText)
            updateTextCount(getLength(forText: trimmedText))
        } else {
            textViewDidChange?(validText)
            updateTextCount(getLength(forText: validText))
        }
        // Adjust content offset to avoid UI bug under iOS13
        if #available(iOS 13, *) {} else {
            let range = NSRange(location: (textView.text as NSString).length - 1, length: 1)
            textView.scrollRangeToVisible(range)
        }
    }
}

extension LarkProfileDescriptionView {
    enum Cons {
        static var hMargin: CGFloat { 12 }
        static var countFont: UIFont { UIFont.systemFont(ofSize: 12) }
        static var descriptionFont: UIFont { UIFont.systemFont(ofSize: 16) }
    }
}
