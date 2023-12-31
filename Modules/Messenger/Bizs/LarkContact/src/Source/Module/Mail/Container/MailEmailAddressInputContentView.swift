//
//  MailEmailAddressContentView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/12.
//

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
import LarkSearchCore
import UIKit
import LarkContainer

final class MailEmailAddressInputContentView: BaseUIViewController, EditTextViewTextDelegate {
    private let disposeBag = DisposeBag()
    private(set) var rightItem: LKBarButtonItem?
    private var editView: EmailAddressEditView?
    private var groupId: Int
    private let nameCardAPI: NamecardAPI
    weak var selectionSource: SelectionDataSource?
    private let userResolver: UserResolver

    private let maxTextCount = 200

    init(groupId: Int, nameCardAPI: NamecardAPI, resolver: UserResolver) {
        self.groupId = groupId
        self.nameCardAPI = nameCardAPI
        self.userResolver = resolver
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
        let editView = EmailAddressEditView()
        editView.backgroundColor = UIColor.clear
        self.view.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        editView.inputTextView.textDelegate = self
        self.editView = editView

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
        let item = LKBarButtonItem()
        item.setProperty(alignment: .right)
        item.button.tintColor = UIColor.ud.primaryContentDefault
        item.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = item
        self.title = BundleI18n.LarkContact.Mail_MailingList_EnterEmailAddress
        self.rightItem = item
        self.rightItem?.button.isEnabled = false

        // navigaton
        let font = LKBarButtonItem.FontStyle.medium.font
        self.updateRightItem(title: BundleI18n.LarkContact.Lark_Legacy_Save, color: UIColor.ud.colorfulBlue, font: font)
    }

    func updateRightItem(title: String, color: UIColor, font: UIFont) {
        self.rightItem?.resetTitle(title: title, font: font)
        self.rightItem?.setBtnColor(color: color)
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        self.saveNewDescription()
    }

    private func saveNewDescription() {
        let new = self.editView?.inputTextView.text ?? ""
        guard isValidMailAddress(address: new) else {
            UDToast.showFailure(with: BundleI18n.LarkContact.Mail_MailingList_AddressFormatWrong, on: self.view)
            self.editView?.inputTextView.becomeFirstResponder()
            return
        }

        let hud = UDToast.showLoading(on: view)
        nameCardAPI
            .checkEmailIsAlreadyInGroupMembers(groupId: groupId, email: new)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isMember in
                guard let self = self, let selectionSource = self.selectionSource else { return }
                if isMember {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Mail_MailingList_AddressFormatWrong, on: self.view)
                    self.editView?.inputTextView.becomeFirstResponder()
                } else {
                    let model = OptionIdentifier.mailContact(id: new)
                    if !selectionSource.state(for: model, from: self).selected {
                        selectionSource.toggle(option: model, from: self)
                    }
                    UDToast.removeToast(on: self.view)
                    self.userResolver.navigator.pop(from: self)
                }
            }) { [weak self] _ in
                if let self = self {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Mail_MailingList_AddFailed, on: self.view)
                    self.editView?.inputTextView.becomeFirstResponder()
                }
            }.disposed(by: disposeBag)
    }

    private func dismissSelf() {
        if self.presentingViewController != nil {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func textChange(text: String, textView: LarkEditTextView) {
        self.rightItem?.button.isEnabled = !text.isEmpty
    }

    func isValidMailAddress(address: String) -> Bool {
        let test = address
        let regex = "^\\w+([-.]\\w+)*@\\w+([-.]\\w+)*\\.\\w{2,6}$"
        do {
            let RE = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let matchs = RE.matches(in: test, options: .reportProgress, range: NSRange(location: 0, length: test.count))
            return !matchs.isEmpty
        } catch {
            return false
        }
    }
}

private final class EmailAddressEditView: UIView {
    private(set) var inputTextView: LarkEditTextView = .init()
    private(set) var wrapperView: UIView = .init()
    private let disposeBag = DisposeBag()
    private var inputTextViewMaxH: CGFloat = 124 {
        didSet {
            guard inputTextViewMaxH > 0 else { return }
            inputTextView.maxHeight = inputTextViewMaxH
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let childPoint = convert(point, to: inputTextView)
        if inputTextView.hitTest(point, with: event) != nil {
            return inputTextView
        }
        return nil
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
        inputTextView.placeholder = BundleI18n.LarkContact.Mail_MailingList_EnterMultipleAddressDesc
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

        KeyboardKit.shared.keyboardHeightChange.distinctUntilChanged().debounce(.milliseconds(300)).drive(onNext: { [weak self] height in
            self?.updateEditView(by: height)
        }).disposed(by: disposeBag)

        DispatchQueue.main.async {
            let maxH = self.bounds.height - Layout.totalMargin
            self.inputTextViewMaxH = maxH
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateEditView(by keyboardH: CGFloat) {
        let maxH = self.bounds.height - Layout.totalMargin - keyboardH
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
}

private extension EmailAddressEditView {
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
