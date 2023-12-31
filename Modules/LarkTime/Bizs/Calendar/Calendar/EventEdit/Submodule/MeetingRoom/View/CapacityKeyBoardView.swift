//
//  CapacityInputView.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/5.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift

extension CapacityInputView: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !string.isEmpty else {
            if let text = textField.text,
               text.utf16.count < range.upperBound {
                // 输入上限与 undo 的 bug https://developer.apple.com/forums/thread/652500
                textField.text = ""
                return false
            }
            return true
        }
        if let value = Int(string), value >= 0 {
            return true
        }
        return false
    }
}

final class CapacityInputView: UIView {
    var confirmTapped: ((Int) -> Void)?

    private(set) lazy var backgourdView = initBackgourdView()
    private let inputField = UITextField()
    private let disposeBag = DisposeBag()
    private let confirmButton = UIButton.cd.button(type: .system)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        inputField.keyboardType = .numberPad
        inputField.placeholder = "0"
        setupViews()
        inputField.delegate = self
        inputField.font = UIFont.cd.regularFont(ofSize: 17)
        inputField.rx.controlEvent(.editingChanged).bind { [weak self] () in
            guard let self = self else { return }
            if self.inputField.text?.count ?? 0 > 4, let str = self.inputField.text {
                let start = String.Index(utf16Offset: 0, in: str)
                let end = String.Index(utf16Offset: 4, in: str)
                self.inputField.text = String(str[start..<end])
            }
        }.disposed(by: disposeBag)
    }

    func reset() {
        inputField.text = nil
    }

    func beginEdit(capacity: String? = nil) {
        inputField.text = capacity ?? ""
        inputField.becomeFirstResponder()
    }

    private func setupViews() {
        addSubview(backgourdView)
        backgourdView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let headerContanier = UIView()
        headerContanier.backgroundColor = UIColor.ud.bgBody
        let titleView = makeTitleView()
        headerContanier.addSubview(titleView)
        titleView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(48.5)
        }

        let inputView = makeInputView()
        headerContanier.addSubview(inputView)
        inputView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(titleView.snp.bottom)
        }

        backgourdView.addSubview(headerContanier)
        headerContanier.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }
    }

    private func makeInputView() -> UIView {
        let contentView = UIView()

        let borderView = UIView()
        borderView.layer.borderWidth = 1
        borderView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        borderView.layer.cornerRadius = 2

        contentView.addSubview(borderView)
        borderView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.height.equalTo(36)
            $0.top.bottom.equalToSuperview().inset(13.5)
        }

        borderView.addSubview(inputField)
        inputField.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }

        return contentView
    }

    private func makeTitleView() -> UIView {
        let contentView = UIView()

        confirmButton.setTitle(BundleI18n.Calendar.Calendar_Common_Confirm, for: .normal)
        confirmButton.titleLabel?.font = UIFont.ud.headline(.fixed)
        confirmButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        confirmButton.setTitleColor(UIColor.ud.primaryContentLoading, for: .disabled)
        confirmButton.addTarget(self, action: #selector(confirmOnClick), for: .touchUpInside)
        confirmButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        let cancelButton = UIButton.cd.button(type: .system)
        cancelButton.setTitle(BundleI18n.Calendar.Calendar_Common_Cancel, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.N800, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelOnClick), for: .touchUpInside)
        cancelButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        let titleLable = UILabel.cd.titleLabel(fontSize: 17)
        titleLable.text = BundleI18n.Calendar.Calendar_Edit_CapacityMinimum
        titleLable.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }

        contentView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
        }

        contentView.addSubview(titleLable)
        titleLable.snp.makeConstraints {
            $0.centerY.centerX.equalToSuperview()
            $0.left.greaterThanOrEqualTo(cancelButton.snp.right)
            $0.right.lessThanOrEqualTo(confirmButton.snp.left)
        }

        contentView.addBottomSepratorLine()
        return contentView
    }

    @objc
    func confirmOnClick() {
        confirmTapped?(Int(inputField.text ?? "0") ?? 0)
        isHidden = true
        inputField.resignFirstResponder()
    }

    @objc
    func cancelOnClick() {
        isHidden = true
        inputField.resignFirstResponder()
    }

    private func initBackgourdView() -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(backgroundTapped))
        view.backgroundColor = UIColor.ud.bgMask
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        return view
    }

    @objc
    func backgroundTapped() {
        self.cancelOnClick()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
