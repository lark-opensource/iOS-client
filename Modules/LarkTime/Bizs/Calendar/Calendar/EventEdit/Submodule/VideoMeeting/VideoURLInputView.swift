//
//  VideoURLInputView.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/9.
//

import UIKit
import UniverseDesignIcon
import Foundation
import SnapKit

protocol VideoURLInputViewDataType {
    var customSummary: String? { get }
    var summaryPlaceHolder: String? { get }
    var url: String? { get }
    var icon: UIImage { get }
    var isVisible: Bool { get }
    var urlLengthLimit: Int { get }
}

final class VideoURLInputView: UIView, UITextViewDelegate, ViewDataConvertible {

    private lazy var titleLable = initTitleLable()
    private lazy var customSummaryTextField = initCustomSummaryTextField()
    private lazy var customURLTextView = initCustomURLTextView()
    private lazy var customVideoIcon = UIImageView()

    var urlLengthExceedsLimitHandler: (() -> Void)?
    var videoTypeClickHandler: (() -> Void)?
    var viewData: VideoURLInputViewDataType? {
        didSet {
            isHidden = viewData?.isVisible == false
            if isHidden { endEditing(true) }
            if let summary = viewData?.customSummary, !summary.isEmpty {
                customSummaryTextField.text = summary
            } else {
                customSummaryTextField.text = viewData?.summaryPlaceHolder ?? ""
            }
            customSummaryTextField.attributedPlaceholder =
                NSAttributedString(string: viewData?.summaryPlaceHolder ?? "",
                                   attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
            customURLTextView.text = viewData?.url
            customVideoIcon.image = viewData?.icon.renderColor(with: .n2)
        }
    }

    var customURL: String {
        return customURLTextView.text ?? ""
    }

    var customSummary: String {
        if customSummaryTextField.text == viewData?.summaryPlaceHolder {
            return ""
        }
        return customSummaryTextField.text ?? ""
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        titleLable.text = BundleI18n.Calendar.Calendar_Edit_Preview
        snp.makeConstraints { $0.height.equalTo(182) }
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(titleLable)
        titleLable.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(EventBasicCellLikeView.Style.leftInset)
            $0.top.equalToSuperview().inset(8)
        }

        let titleContainerView = containerView()
        addSubview(titleContainerView)
        titleContainerView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(EventBasicCellLikeView.Style.leftInset)
            $0.height.equalTo(44)
            $0.top.equalTo(titleLable.snp.bottom).offset(17)
        }

        let videoTypeView = customVideoTypeView()
        titleContainerView.addSubview(videoTypeView)
        videoTypeView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoTypeOnClick))
        videoTypeView.addGestureRecognizer(tapGesture)

        titleContainerView.addSubview(customSummaryTextField)
        customSummaryTextField.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview().inset(10)
            $0.left.equalTo(videoTypeView.snp.right).offset(8)
            $0.right.equalToSuperview().inset(12)
        }

        addSubview(customURLTextView)
        customURLTextView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(EventBasicCellLikeView.Style.leftInset)
            $0.height.equalTo(44)
            $0.top.equalTo(titleContainerView.snp.bottom).offset(13)
        }

    }

    @objc func videoTypeOnClick() {
        videoTypeClickHandler?()
    }

    private func customVideoTypeView() -> UIView {
        let view = UIView()
        view.addSubview(customVideoIcon)

        customVideoIcon.snp.makeConstraints {
            $0.left.equalToSuperview().inset(12)
            $0.width.height.equalTo(20)
            $0.centerY.equalToSuperview()
        }

        let arrowImage = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.downOutlined).renderColor(with: .n3))
        view.addSubview(arrowImage)
        arrowImage.snp.makeConstraints {
            $0.left.equalTo(customVideoIcon.snp.right).offset(8)
            $0.right.equalToSuperview().inset(12)
            $0.width.height.equalTo(16)
            $0.centerY.equalToSuperview()
        }

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineBorderComponent
        view.addSubview(lineView)
        lineView.snp.makeConstraints {
            $0.right.centerY.equalToSuperview()
            $0.width.equalTo(1)
            $0.top.bottom.equalToSuperview().inset(8)
        }

        return view
    }

    private func containerView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgFiller
        containerView.layer.cornerRadius = 8
        return containerView
    }

    private func initCustomURLTextView() -> KMPlaceholderTextView {
        let textView = KMPlaceholderTextView()

        textView.placeholder = BundleI18n.Calendar.Calendar_Edit_EnterURLPlaceholder
        textView.font = UIFont.cd.regularFont(ofSize: 16)
        textView.placeholderColor = UIColor.ud.textCaption
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textColor = UIColor.ud.textTitle
        textView.layer.cornerRadius = 8
        textView.backgroundColor = UIColor.ud.bgFiller
        textView.layer.masksToBounds = true
        textView.delegate = self

        return textView
    }

    private func initCustomSummaryTextField() -> UITextField {
        let textField = UITextField(frame: .zero)

        textField.font = UIFont.cd.regularFont(ofSize: 16)
        textField.textColor = UIColor.ud.textTitle
        textField.returnKeyType = .done
        textField.addTarget(textField, action: #selector(resignFirstResponder), for: .editingDidEndOnExit)
        textField.clearButtonMode = .whileEditing

        return textField
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == " " {
            return false
        }
        if let limit = viewData?.urlLengthLimit, textView.text.count + (text.count - range.length) > limit {
            urlLengthExceedsLimitHandler?()
            return false
        }
        return true
    }

    private func initTitleLable() -> UILabel {
        let titleLable = UILabel()

        titleLable.font = UIFont.cd.regularFont(ofSize: 16)
        titleLable.textColor = UIColor.ud.textTitle

        return titleLable
    }

}
