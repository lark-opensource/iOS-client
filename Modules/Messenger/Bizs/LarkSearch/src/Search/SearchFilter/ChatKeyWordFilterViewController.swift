//
//  ChatKeyWordFilterViewController.swift
//  LarkSearch
//
//  Created by SuPeng on 9/12/19.
///

import Foundation
import UIKit
import LarkUIKit
import EditTextView

final class ChatKeyWordFilterViewController: BaseUIViewController, UITableViewDelegate, UIViewControllerTransitioningDelegate, UITextViewDelegate {

    var didEnterKeyWord: ((String?, UIViewController) -> Void)?
    let colorBgView = UIView()
    private let titleLabel = UILabel()
    private let cancelButton = ExpandRangeButton()
    private let confirmButton = UIButton()
    let keywordView = UIView()
    let textView = BaseTextView()

    init(keyWord: String?) {
        textView.text = keyWord
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.delegate = self
        view.backgroundColor = UIColor.clear
        colorBgView.backgroundColor = UIColor.ud.bgMask
        view.addSubview(colorBgView)
        colorBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        keywordView.backgroundColor = UIColor.ud.bgFloat
        keywordView.roundCorners(corners: [.topLeft, .topRight], radius: 16.0)
        view.addSubview(keywordView)
        keywordView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.height.equalTo(239)
            make.width.equalToSuperview()
        }

        keywordView.addSubview(titleLabel)
        titleLabel.text = BundleI18n.LarkSearch.Lark_Search_SearchGroupByMessage
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(29)
            make.centerX.equalToSuperview()
        }

        keywordView.addSubview(textView)
        textView.layer.cornerRadius = 4.0
        textView.backgroundColor = UIColor.ud.bgFloatOverlay
        textView.isEditable = true
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textContainerInset = UIEdgeInsets(top: 8.5, left: 12.5, bottom: 0, right: 12.5)
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(25.5)
            make.left.equalTo(16.5)
            make.right.equalTo(-16.5)
            make.height.equalTo(75)
        }
        textView.placeholder = BundleI18n.LarkSearch.Lark_Search_EditQuery

        keywordView.addSubview(cancelButton)
        cancelButton.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)
        cancelButton.setImage(Resources.chat_filter_close, for: .normal)
        cancelButton.addedTouchArea = 20
        cancelButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16.9)
            make.right.equalToSuperview().inset(20.9)
        }

        keywordView.addSubview(confirmButton)
        confirmButton.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure, for: .normal)
        confirmButton.layer.cornerRadius = 4.0
        confirmButton.setTitleColor(UIColor.ud.bgBody, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        confirmButton.addTarget(self, action: #selector(sureButtonDidClick), for: .touchUpInside)
        confirmButton.backgroundColor = UIColor.ud.primaryContentDefault
        confirmButton.snp.makeConstraints { (make) in
            make.top.equalTo(textView.snp.bottom).offset(11.5)
            make.left.equalToSuperview().offset(16.5)
            make.right.equalToSuperview().offset(-16.5)
            make.height.equalTo(50)
        }
    }

    @objc
    private func cancelButtonDidClick() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc
    private func sureButtonDidClick() {
        didEnterKeyWord?(textView.text, self)
    }
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            keywordView.frame.bottom = keyboardFrame.top
        }
    }

    @objc
    private func keyboardWillHide(notification: NSNotification) {
        keywordView.frame.bottom = view.bounds.height
    }
    // MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        confirmButton.backgroundColor = UIColor.ud.primaryContentDefault
    }
    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatKeyWordFadeAnimator()
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ChatKeyWordDisapearAnimator()
    }
}

extension UIView {

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
