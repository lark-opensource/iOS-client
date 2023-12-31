//
//  MailGroupRemarkViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkFoundation
import RichLabel
import LarkModel
import LKCommonsLogging
import EENavigator
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import EditTextView
import LarkKeyboardKit
import LarkFeatureGating
import UniverseDesignEmpty

final class MailGroupRemarkViewController: BaseUIViewController, EditTextViewTextDelegate {
    private let disposeBag = DisposeBag()
    private(set) var rightItem: LKBarButtonItem?
    private var editView: GroupDescriptionEditView?
    private(set) var groupId: Int

    private let groupDescription: String
    private let nameCardAPI: NamecardAPI

    private let maxTextCount = 200

    init(groupId: Int, groupDescription: String, nameCardAPI: NamecardAPI) {
        self.groupId = groupId
        self.groupDescription = groupDescription
        self.nameCardAPI = nameCardAPI
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubviews()
    }

    func setupSubviews() {
        self.view.backgroundColor = UIColor.ud.bgFloatBase

        // edit view
        let editView = GroupDescriptionEditView(frame: CGRect.zero)
        editView.backgroundColor = UIColor.clear
        self.view.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        editView.inputTextView.textDelegate = self
        self.editView = editView
        self.editView?.set(content: groupDescription)
        let attr = NSAttributedString(string: "\((groupDescription as NSString).length)/\(maxTextCount)",
                                      attributes: [.foregroundColor: UIColor.ud.N500])
        self.editView?.set(textCount: attr)

        self.setupNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.editView?.inputTextView.becomeFirstResponder()
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    func setupNavigationBar() {
        self.title = BundleI18n.LarkContact.Mail_MailingList_Note

        let item = LKBarButtonItem()
        item.setProperty(alignment: .right)
        item.setBtnColor(color: UIColor.ud.colorfulBlue)
        item.button.setTitleColor(UIColor.ud.iconDisable, for: .disabled)
        item.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = item
        self.rightItem = item
        // navigaton
        let font = LKBarButtonItem.FontStyle.medium.font
        self.updateRightItem(title: BundleI18n.LarkContact.Mail_MailingList_SaveButton, color: UIColor.ud.colorfulBlue, font: font)
    }

    func updateRightItem(title: String, color: UIColor, font: UIFont) {
        self.rightItem?.resetTitle(title: title, font: font)
        self.rightItem?.setBtnColor(color: color)
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        let text = editView?.inputTextView.text ?? ""
        if text.count > maxTextCount {
            UDToast.showTips(with: BundleI18n.LarkContact.Mail_MailingList_NoteLimit, on: view)
        } else {
            self.editView?.inputTextView.resignFirstResponder()
            self.saveNewDescription()
            MailGroupStatistics
                .groupEditClick(value: "edit_remark")
        }
    }

    private func saveNewDescription() {
        let new = self.editView?.inputTextView.text ?? ""
        guard new != groupDescription else {
            self.dismissSelf()
            return
        }

        let hud = UDToast.showLoading(on: view)

        nameCardAPI.updateMailRemark(groupId, description: new)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                if let self = self {
                    MailGroupEventBus.shared.fireRequestGroupDetail()
                    self.dismissSelf()
                }
            }, onError: { [weak self] (error) in
                if let self = self {
                    hud.showFailure(
                        with: BundleI18n.LarkContact.Lark_Legacy_ActionFailedTryAgainLater,
                        on: self.view,
                        error: error
                    )
                }
            }).disposed(by: disposeBag)
    }

    private func dismissSelf() {
        if self.presentingViewController != nil {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func textChange(text: String, textView: LarkEditTextView) {
        let count = (text as NSString).length
        if count > maxTextCount {
            self.rightItem?.setBtnColor(color: UIColor.ud.N400)
            let attr = NSMutableAttributedString(string: "\(count)",
                                                 attributes: [.foregroundColor: UIColor.ud.colorfulRed])
            attr.append(NSAttributedString(string: "/\(maxTextCount)",
                                           attributes: [.foregroundColor: UIColor.ud.N500]))
            editView?.set(textCount: attr)
        } else {
            self.rightItem?.setBtnColor(color: UIColor.ud.colorfulBlue)
            let attr = NSAttributedString(string: "\(count)/\(maxTextCount)",
                                          attributes: [.foregroundColor: UIColor.ud.N500])
            editView?.set(textCount: attr)
        }
        self.rightItem?.button.isEnabled = text != groupDescription
    }
}

extension MailGroupRemarkViewController: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {

    }

    func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {

    }
}

private final class GroupDescriptionEditView: UIView {
    private(set) var inputTextView: LarkEditTextView = .init()
    private(set) var wrapperView: UIView = .init()
    private(set) var textCountLabel: UILabel = .init()
    private let disposeBag = DisposeBag()
    private var inputTextViewMaxH: CGFloat = 124 {
        didSet {
            guard inputTextViewMaxH > 0 else { return }
            inputTextView.maxHeight = inputTextViewMaxH
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgFloat
        self.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(Layout.wrapperTopMargin)
        }
        wrapperView.layer.cornerRadius = 10.0
        self.wrapperView = wrapperView

        let inputTextView = LarkEditTextView()
        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.N900
        ]
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
        inputTextView.isScrollEnabled = false
        inputTextView.font = font
        inputTextView.textAlignment = .left
        inputTextView.textContainerInset = .zero
        inputTextView.placeholder = BundleI18n.LarkContact.Mail_MailingList_NotesDesc
        inputTextView.placeholderTextColor = UIColor.ud.N500
        inputTextView.maxHeight = inputTextViewMaxH
        inputTextView.backgroundColor = UIColor.clear
        self.wrapperView.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(Layout.inputTextViewTopMargin)
            make.height.greaterThanOrEqualTo(124)
        }
        self.inputTextView = inputTextView

        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        wrapperView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(inputTextView.snp.bottom).offset(Layout.labelTopMargin)
            make.trailing.equalTo(inputTextView)
            make.bottom.equalToSuperview().offset(-Layout.labelBottomMargin)
        }
        textCountLabel = label

        KeyboardKit.shared
            .keyboardHeightChange
            .distinctUntilChanged()
            .debounce(.milliseconds(300)).drive(onNext: { [weak self] height in
            self?.updateEditView(by: height)
        }).disposed(by: disposeBag)

        DispatchQueue.main.async {
            let maxH = self.bounds.height - self.textCountLabel.bounds.height - Layout.totalMargin
            self.inputTextViewMaxH = maxH
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateEditView(by keyboardH: CGFloat) {
        let maxH = self.bounds.height - self.textCountLabel.bounds.height - Layout.totalMargin - keyboardH
        if keyboardH > 0, maxH > 0 {
            self.inputTextViewMaxH = maxH
            self.inputTextView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.top.equalToSuperview().offset(Layout.inputTextViewTopMargin)
                make.height.greaterThanOrEqualTo(124)
                make.height.lessThanOrEqualTo(maxH)
            }
        }
        self.superview?.layoutIfNeeded()
    }

    func set(content: String) {
        self.inputTextView.text = content
    }

    func set(textCount: NSAttributedString) {
        textCountLabel.attributedText = textCount
    }
}

private extension GroupDescriptionEditView {
    enum Layout {
        static let wrapperTopMargin: CGFloat = 16
        static let labelTopMargin: CGFloat = 4
        static let labelBottomMargin: CGFloat = 8
        static let inputTextViewTopMargin: CGFloat = 14
        static let inputTextViewBottomMargin: CGFloat = 16
        static var totalMargin: CGFloat {
            return wrapperTopMargin + labelTopMargin + labelBottomMargin + inputTextViewBottomMargin + inputTextViewTopMargin
        }
    }
}
