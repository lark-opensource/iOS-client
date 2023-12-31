//
//  DescriptionEditViewController.swift
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
import EditTextView
import LarkKeyboardKit
import UniverseDesignToast

class DescriptionEditViewController: BaseUIViewController {

    var finishEdit: ((_ text: String) -> Void)?

    var maxLength: Int = 400
    var countLabel: UILabel = UILabel.cd.subTitleLabel(fontSize: 12)

    private let textLabel = UILabel.cd.textLabel()
    private let textView = LarkEditTextView()
    private let doneButtonItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Save, fontStyle: .medium)

    private let contentTextBeforeEditing: String
    private let canEdit: Bool
    private let bag = DisposeBag()

    override var navigationBarStyle: NavigationBarStyle { .custom(.ud.bgBase) }

    init(text: String, canEdit: Bool) {
        contentTextBeforeEditing = text
        self.canEdit = canEdit
        super.init(nibName: nil, bundle: nil)
        title = I18n.Calendar_Setting_CalendarDescription

        guard canEdit else {
            textLabel.numberOfLines = 0
            textLabel.text = text.isEmpty ? I18n.Calendar_Detail_NoDescription : text
            textLabel.backgroundColor = .ud.bgBase
            return
        }

        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.textTitle
        ]
        textView.defaultTypingAttributes = defaultTypingAttributes
        textView.font = font
        textView.autocapitalizationType = .none
        textView.text = text
        textView.placeholder = I18n.Calendar_Setting_EnterDescription
        textView.showsVerticalScrollIndicator = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .ud.bgFloat
        textView.delegate = self

        doneButtonItem.button.tintColor = .ud.primaryContentDefault
        doneButtonItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self, let text = self.textView.text else { return }
                guard text.count <= self.maxLength else {
                    UDToast.showTips(with: I18n.Calendar_Setting_CharacterLimitExceeded, on: self.view)
                    return
                }
                self.finishEdit?(text)
                self.view.endEditing(true)
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: bag)
        navigationItem.rightBarButtonItem = doneButtonItem

        updateComponentsStatus(with: text.count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard canEdit else {
            view.addSubview(textLabel)
            textLabel.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview().inset(16)
                make.bottom.lessThanOrEqualTo(-view.safeAreaInsets.bottom)
            }
            return
        }
        let container = UIView()
        container.layer.cornerRadius = 12
        container.backgroundColor = .ud.bgFloat
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(Layout.containerTopMargin)
        }

        container.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.top.equalTo(Layout.textViewTopMargin)
            make.height.greaterThanOrEqualTo(72)
            make.height.lessThanOrEqualTo(316)
        }
        textView.maxHeight = 316

        container.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(Layout.labelTopMargin)
            make.trailing.equalTo(-12)
            make.bottom.equalTo(-Layout.labelBottomMargin)
        }
        observeKeyboard()
    }

    private var appearFirstTime = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard appearFirstTime else { return }
        textView.becomeFirstResponder()
        appearFirstTime = false
    }

    override func backItemTapped() {
        if canEdit, let text = textView.text, text != contentTextBeforeEditing {
            EventAlert.showDismissModifiedCalendarAlert(controller: self) { [unowned self] in
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            super.backItemTapped()
        }
    }

    private func updateComponentsStatus(with currentTextLength: Int?) {
        let textLength = currentTextLength ?? 0
        counterRefresh(with: textLength)

        doneButtonItem.button.tintColor = textLength > maxLength ? .ud.textDisabled : .ud.primaryContentDefault
    }

    private func observeKeyboard() {
        KeyboardKit.shared.keyboardHeightChange(for: self.view).debounce(.milliseconds(30)).drive(onNext: { [weak self] (height) in
            guard let self = self else { return }
            let bottomHolderHeight = height > 0 ? height + Layout.keyboardTopMargin : self.view.safeAreaInsets.bottom
            let maxH = self.view.bounds.height - self.countLabel.bounds.height - Layout.totalMargin - bottomHolderHeight
            if maxH > 0 {
                self.textView.maxHeight = maxH
                self.textView.snp.updateConstraints { (make) in
                    make.height.lessThanOrEqualTo(maxH)
                }
            }

            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }).disposed(by: bag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Layout {
        static let containerTopMargin: CGFloat = 12
        static let labelTopMargin: CGFloat = 4
        static let labelBottomMargin: CGFloat = 8
        static let textViewTopMargin: CGFloat = 10
        static let keyboardTopMargin: CGFloat = 16
        static var totalMargin: CGFloat {
            return containerTopMargin + labelTopMargin + labelBottomMargin + textViewTopMargin
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        updateComponentsStatus(with: textView.text.count)
    }
}

extension DescriptionEditViewController: TextCounterDelegate, UITextViewDelegate { }
