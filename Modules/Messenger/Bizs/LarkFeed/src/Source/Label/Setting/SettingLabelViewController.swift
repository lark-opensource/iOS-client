//
//  SettingLabelViewController.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/18.
//

import Foundation
import LarkUIKit
import UIKit
import RxSwift
import LKCommonsLogging
import UniverseDesignToast
import LarkSDKInterface
import LarkRustClient

final class SettingLabelViewController: BaseUIViewController {

    private static let logger = Logger.log(
        SettingLabelViewController.self,
        category: "LarkFeed.SettingLabelViewController")

    private(set) var disposeBag = DisposeBag()
    private var vm: SettingLabelViewModel

    lazy var titleLabel = UILabel()
    lazy var errorLabel = UILabel()

    private let textMaxLength = 60
    lazy var labelInputView = SettingLabelInputView(textMaxLength: textMaxLength,
                                                   placeholder: BundleI18n.LarkFeed.Lark_Core_CreateLabel_PlsEnterLabelName_Placeholder)
    private(set) var createButton: UIButton?

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(vm: SettingLabelViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
        self.vm.targetVC = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCancelItem()
        view.backgroundColor = UIColor.ud.bgFloatBase

        self.addNavigationBarRightItem()

        self.title = self.vm.title

        addTitleLabel()
        addLabelInputView()
        addErrorTipLabel()
        bindViewModel()
        self.vm.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        labelInputView.becomeFirstResponder()
    }

    override func closeBtnTapped() {
        self.dismiss(animated: true, completion: { [weak self] in
            self?.closeCallback?()
        })
        self.vm.leftItemClick()
    }

    private func addTitleLabel() {
        let attributes: [NSAttributedString.Key: Any] =
        [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textCaption
        ]
        let title = BundleI18n.LarkFeed.Lark_Core_CreateLabel_LabelName
        var attributedTitle = NSMutableAttributedString(string: title, attributes: attributes)
        attributedTitle.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.ud.colorfulRed]))
        titleLabel.attributedText = attributedTitle
        view.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(20)
            make.top.equalToSuperview().offset(16)
        }
    }

    private func addLabelInputView() {
        labelInputView.layer.cornerRadius = 10.0
        labelInputView.textFieldDidChangeHandler = { [weak self] (textField) in
            guard let self = self else { return }
            let newLabel = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
            let textCount = newLabel.count
            self.createButton?.isEnabled = textCount > 0
            self.errorLabel.isHidden = true
        }
        self.view.addSubview(labelInputView)

        labelInputView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        labelInputView.text = self.vm.textFieldText
    }

    private func addErrorTipLabel() {
        errorLabel.isHidden = true
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        errorLabel.textColor = UIColor.ud.functionDangerContentDefault
        errorLabel.numberOfLines = 0
        errorLabel.lineBreakMode = .byWordWrapping
        view.addSubview(errorLabel)

        errorLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(labelInputView.snp.bottom).offset(4)
        }
    }

    fileprivate func addNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: self.vm.rightItemTitle, fontStyle: .medium)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        rightItem.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.createButton = rightItem.button
        self.navigationItem.rightBarButtonItem = rightItem
        self.createButton?.isEnabled = false
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        let newLabel = (self.labelInputView.text ?? "").trimmingCharacters(in: .whitespaces)
        let textCount = newLabel.count
        guard textCount <= self.textMaxLength else {
            if let window = self.view.window {
                let limitExceededTip = BundleI18n.LarkFeed.Lark_Group_DescriptionCharacterLimitExceeded
                UDToast.showTips(with: limitExceededTip, on: window)
            }
            return
        }
        self.vm.rightItemClick(label: newLabel)
    }

    fileprivate func endEditting() {
        if self.view.canResignFirstResponder {
            self.view.endEditing(true)
        }
    }

    private func bindViewModel() {
       self.vm.resultObservable.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (labelName, error) in
                guard let self = self else { return }
                if let error = error {
                    if let e = error.underlyingError as? RCError,
                       let errorCode = self.rcErrorCode(rcError: e),
                       errorCode == FeedSDKErrorCode.duplicateLabelName {
                        self.errorLabel.isHidden = false
                        self.errorLabel.text = BundleI18n.LarkFeed.Lark_Core_LabelNameExistsPleaseRename_ErrorMessage
                    } else {
                        UDToast.showFailure(with: self.vm.errorTip, on: self.view, error: error.transformToAPIError())
                        Self.logger.error("label name server error:\(error.localizedDescription)")
                    }
                    self.createButton?.isEnabled = false
                } else if let name = labelName, self.vm.needShowResultToast {
                    // edit success, and need to show toast
                    var tip = BundleI18n.LarkFeed.Lark_Feed_Label_CreateLabel_SuccessToast(name)
                    UDToast.showSuccess(with: tip, on: self.view.window ?? self.view)
                    self.dismiss(animated: true)
                } else {
                    // edit success
                    self.dismiss(animated: true)
                }
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                Self.logger.error("label name request error:\(error.localizedDescription)")
            }).disposed(by: disposeBag)
    }

    private func rcErrorCode(rcError: RCError) -> Int32? {
        switch rcError {
        case .businessFailure(let errorInfo):
            return errorInfo.code
        default:
            return nil
        }
    }
}
