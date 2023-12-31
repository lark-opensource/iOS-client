//
//  ListEditViewController.swift
//  Todo
//
//  Created by baiyantao on 2022/11/15.
//

import Foundation
import LarkUIKit
import UniverseDesignInput
import RxSwift
import RxCocoa
import UniverseDesignFont

final class ListEditViewController: BaseViewController {

    var saveHandler: ((String) -> Void)?

    // MARK: dependencies
    private let viewModel: ListEditViewModel
    private let disposeBag = DisposeBag()

    // MARK: views
    private lazy var titleLabel = initTitleLabel()
    private lazy var textField = initTextField()
    private lazy var saveItem = initSaveItem()

    init(viewModel: ListEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNaviItem()
        bindViewData()
        bindViewAction()

        textField.becomeFirstResponder()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBase
        switch viewModel.scene {
        case .create:
            title = I18N.Todo_CreateNewList_Title
        case .edit:
            title = I18N.Todo_List_Rename_MenuItem
        }

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.top.right.equalToSuperview().inset(16)
        }

        view.addSubview(textField)
        textField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(7)
            $0.left.right.equalToSuperview().inset(16)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackGroundClick))
        view.addGestureRecognizer(tap)
    }

    private func setupNaviItem() {
        let cancelItem = LKBarButtonItem(title: I18N.Todo_Common_Cancel, fontStyle: .regular)
        cancelItem.button.titleLabel?.textColor = UIColor.ud.textTitle
        cancelItem.button.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        navigationItem.setLeftBarButton(cancelItem, animated: false)

        navigationItem.setRightBarButton(saveItem, animated: false)
    }

    private func bindViewData() {
        viewModel.rxIsSaveEnable.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] isSaveEnable in
                self?.saveItem.isEnabled = isSaveEnable
            })
            .disposed(by: disposeBag)
        viewModel.rxTextFieldStatus.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] status in
                self?.textField.setStatus(status)
            })
            .disposed(by: disposeBag)
    }

    private func bindViewAction() {
        textField.input.rx.text
            .subscribe(onNext: { [weak self] str in
                self?.viewModel.doUpdateText(str)
            }).disposed(by: disposeBag)
        viewModel.isTextFieldActive = { [weak self] in
            self?.textField.isFirstResponder ?? false
        }
    }

    @objc
    private func savePressed() {
        guard let text = textField.text, !text.isEmpty else {
            assertionFailure()
            return
        }
        saveHandler?(text)
        dismiss(animated: true)
    }

    @objc
    private func cancelPressed() {
        dismiss(animated: true)
    }

    @objc
    private func onBackGroundClick() {
        textField.resignFirstResponder()
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        let attr = NSMutableAttributedString(
            string: I18N.Todo_CreateNewList_ListTitle_Text,
            attributes: [
                .font: UDFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.ud.textCaption
            ]
        )
        attr.append(NSAttributedString(
            string: " *",
            attributes: [
                .font: UDFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.ud.red
            ]
        ))
        label.attributedText = attr
        return label
    }

    private func initTextField() -> UDTextField {
        let textField = UDTextField()
        textField.config.isShowBorder = true
        textField.config.errorMessege = I18N.Todo_CreateNewList_ListTitleCharactersExceedLimit_Error
        textField.config.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        textField.placeholder = I18N.Todo_CreateNewList_ListTitle_Placeholder
        textField.setStatus(viewModel.rxTextFieldStatus.value)
        if let content = viewModel.content() {
            textField.text = content
        }
        return textField
    }

    private func initSaveItem() -> LKBarButtonItem {
        let title: String
        switch viewModel.scene {
        case .create: title = I18N.Todo_CreateNewListCreate_Button
        case .edit: title = I18N.Todo_common_Save
        }
        let saveItem = LKBarButtonItem(image: nil, title: title, fontStyle: .medium)
        saveItem.button.tintColor = UIColor.ud.bgPricolor
        saveItem.isEnabled = viewModel.rxIsSaveEnable.value
        saveItem.button.addTarget(self, action: #selector(savePressed), for: .touchUpInside)
        return saveItem
    }
}
