//
//  TitleEditViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/28/23.
//

import Foundation
import UIKit
import LarkInteraction
import UniverseDesignIcon
import LarkUIKit
import RxSwift
import UniverseDesignToast

class TitleEditViewController: BaseUIViewController {

    var finishEdit: ((_ text: String) -> Void)?

    var maxLength: Int = 100
    var countLabel: UILabel = UILabel.cd.subTitleLabel(fontSize: 12)

    private let clearBtn = UIButton()
    private let titleTextField = UITextField()
    private let titleTextLabel = UILabel.cd.textLabel()
    private let doneButtonItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Save, fontStyle: .medium)
    private let clearIcon = UDIcon.getIconByKey(.closeFilled, size: CGSize(width: 20, height: 20))

    private let contentTextBeforeEditing: String
    private let canEdit: Bool
    private let bag = DisposeBag()

    override var navigationBarStyle: NavigationBarStyle { .custom(.ud.bgBase) }

    init(text: String, canEdit: Bool) {
        contentTextBeforeEditing = text
        self.canEdit = canEdit
        super.init(nibName: nil, bundle: nil)
        title = I18n.Calendar_Setting_CalendarTitle

        guard canEdit else {
            titleTextLabel.numberOfLines = 0
            titleTextLabel.text = text.isEmpty ? "Error happened! title shouldn't be empty!" : text
            titleTextLabel.backgroundColor = .ud.bgBase
            return
        }

        titleTextField.returnKeyType = .done
        titleTextField.font = UIFont.systemFont(ofSize: 16)
        titleTextField.text = text
        titleTextField.textColor = .ud.textTitle
        titleTextField.attributedPlaceholder = NSAttributedString(
            string: I18n.Calendar_Setting_EnterCalendarName,
            attributes: [.foregroundColor: UIColor.ud.textPlaceholder]
        )

        titleTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        titleTextField.rightViewMode = .whileEditing

        doneButtonItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self, let text = self.titleTextField.text else { return }

                guard !text.isEmpty else {
                    UDToast.showTips(with: I18n.Calendar_Setting_AddNameThenSave, on: self.view)
                    return
                }

                guard text.count <= self.maxLength else {
                    UDToast.showTips(with: I18n.Calendar_Setting_CharacterLimitExceeded, on: self.view)
                    return
                }

                self.view.endEditing(true)
                self.finishEdit?(text)
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: bag)
        navigationItem.rightBarButtonItem = doneButtonItem

        updateComponentsStatus(with: text.count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard canEdit else {
            view.addSubview(titleTextLabel)
            titleTextLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview().inset(16)
                make.bottom.lessThanOrEqualTo(-view.safeAreaInsets.bottom)
            }
            return
        }

        let rightView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 32, height: 22)))
        clearBtn.setImage(clearIcon.renderColor(with: .n3), for: .normal)
        clearBtn.addTarget(self, action: #selector(handleClearText), for: .touchUpInside)

        rightView.addSubview(clearBtn)
        clearBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.bottom.trailing.top.equalToSuperview()
        }
        titleTextField.rightView = rightView

        let container = UIView()
        container.layer.cornerRadius = 12
        container.backgroundColor = .ud.bgFloat
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(72)
        }

        container.addSubview(titleTextField)
        titleTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.top.equalTo(16)
        }

        container.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.trailing.equalTo(-12)
            make.bottom.equalTo(-8)
        }
    }

    private var appearFirstTime = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard appearFirstTime else { return }
        titleTextField.becomeFirstResponder()
        appearFirstTime = false
    }

    override func backItemTapped() {
        if canEdit, titleTextField.text != contentTextBeforeEditing {
            EventAlert.showDismissModifiedCalendarAlert(controller: self) { [unowned self] in
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            super.backItemTapped()
        }
    }

    private func updateComponentsStatus(with currentTextLength: Int?) {
        let textLength = currentTextLength ?? 0
        let isEmpty = textLength <= 0
        let overSizeLimit = textLength > maxLength
        clearBtn.setImage(clearIcon.renderColor(with: isEmpty ? .n4 : .n3), for: .normal)

        doneButtonItem.button.tintColor = (isEmpty || overSizeLimit) ? .ud.textDisabled : .ud.primaryContentDefault
        counterRefresh(with: textLength)
    }

    @objc
    private func handleClearText() {
        guard let text = titleTextField.text, !text.isEmpty else {
            return
        }
        titleTextField.text = ""
        titleTextField.sendActions(for: .allEditingEvents)
    }

    @objc
    private func textFieldDidChange(_ textField: UITextField) {
        updateComponentsStatus(with: textField.text?.count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TitleEditViewController: TextCounterDelegate { }
