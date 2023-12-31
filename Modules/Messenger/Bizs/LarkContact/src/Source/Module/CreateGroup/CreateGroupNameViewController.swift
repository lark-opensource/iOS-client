//
//  CreateGroupNameViewController.swift
//  LarkContact
//
//  Created by 姚启灏 on 2019/2/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import LarkButton
import EditTextView
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import Swinject
import LarkKeyboardKit
import LarkMessengerInterface
import LarkNavigator

final class GroupNameVCRouter: UserTypedRouterHandler {

    func handle(_ body: GroupNameVCBody, req: Request, res: Response) throws {
        let viewController = CreateGroupNameViewController(chatAPI: body.chatAPI, isTopicGroup: body.isTopicGroup)
        viewController.nextBlock = body.nextFunc

        res.end(resource: viewController)
    }
}

final class CreateGroupNameViewController: BaseUIViewController, UITextFieldDelegate {
    private let chatAPI: ChatAPI
    private let isTopicGroup: Bool

    private var nameTextField: UITextField?
    private var nextButton: LarkButton.TypeButton?
    private var contentScroll: UIScrollView?

    private let realBottomHeight: CGFloat = 22
    private let wrapperViewHeight: CGFloat = 216

    private let disposeBag = DisposeBag()

    var nextBlock: ((CreateGroupNameViewController, String) -> Void)?

    private var contentWidth: CGFloat {
        return self.view.bounds.width
    }

    init(chatAPI: ChatAPI, isTopicGroup: Bool) {
        self.chatAPI = chatAPI
        self.isTopicGroup = isTopicGroup
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = isTopicGroup ? BundleI18n.LarkContact.Lark_Groups_CreateGroup
            : BundleI18n.LarkContact.Lark_Legacy_CreategroupTitle

        self.view.backgroundColor = UIColor.ud.bgBase

        let contentScroll = UIScrollView()
        contentScroll.showsVerticalScrollIndicator = false
        contentScroll.showsHorizontalScrollIndicator = false
        contentScroll.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        self.view.addSubview(contentScroll)
        contentScroll.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview()
        }
        self.contentScroll = contentScroll

        let wrapperView = UIView()

        let nameDescriptionLabel = UILabel()
        wrapperView.addSubview(nameDescriptionLabel)
        nameDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        nameDescriptionLabel.textColor = UIColor.ud.textPlaceholder
        nameDescriptionLabel.text = isTopicGroup ? BundleI18n.LarkContact.Lark_Groups_Name : BundleI18n.LarkContact.Lark_Group_CreateGroup_TypePublic_SetName_Mobile
        nameDescriptionLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
        }

        let nameWrapperView = UIView()
        nameWrapperView.backgroundColor = UIColor.ud.bgBody
        nameWrapperView.lu.addBottomBorder()
        nameWrapperView.lu.addTopBorder()
        wrapperView.addSubview(nameWrapperView)
        nameWrapperView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(nameDescriptionLabel.snp.bottom).offset(4)
        }

        let nameTextField = UITextField()
        nameTextField.placeholder = isTopicGroup ? BundleI18n.LarkContact.Lark_Groups_NameDescription : BundleI18n.LarkContact.Lark_Legacy_SetGroupName
        nameTextField.textAlignment = .left
        nameTextField.font = UIFont.systemFont(ofSize: 16)
        nameTextField.delegate = self
        nameTextField.returnKeyType = .done
        nameTextField.clearButtonMode = .whileEditing
        nameTextField
            .rx.value
            .subscribe(onNext: { [weak self] (value) in
                if let value = value, !value.isEmpty {
                    self?.nextButton?.isEnabled = true
                } else {
                    self?.nextButton?.isEnabled = false
                }
            }).disposed(by: self.disposeBag)

        nameWrapperView.addSubview(nameTextField)
        nameTextField.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 16, bottom: 15, right: 16))
        }
        self.nameTextField = nameTextField
        nameTextField.addTarget(self, action: #selector(nameTextDidChange), for: .editingChanged)
        nameTextField.becomeFirstResponder()

        contentScroll.addSubview(wrapperView)
        contentScroll.contentSize = CGSize(width: contentWidth, height: wrapperViewHeight)
        wrapperView.snp.makeConstraints { (make) in
            make.top.left.equalToSuperview()
            make.height.equalTo(wrapperViewHeight)
            make.width.equalToSuperview()
        }

        let nextButton = LarkButton.TypeButton(style: .largeA)
        nextButton.setTitle(
            BundleI18n.LarkContact.Lark_Group_CreateGroup_CreateGroup_TypePublic_CreateButton,
            for: .normal)
        nextButton.isEnabled = false
        nextButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)

        self.view.addSubview(nextButton)
        self.nextButton = nextButton

        nextButton.snp.makeConstraints({ (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(contentScroll.snp.bottom).offset(10)
            make.bottom.equalTo(self.view.lkKeyboardLayoutGuide.update(respectSafeArea: true).snp.top).offset(-self.realBottomHeight)
        })
        KeyboardKit.shared.keyboardHeightChange(for: self.view).drive(onNext: { [weak self] (height) in
            guard let `self` = self else { return }
            let nextButtonHeight: CGFloat = self.nextButton?.bounds.height ?? 0
            let topDis: CGFloat = 10

            if height > self.realBottomHeight,
                (height + nextButtonHeight + self.realBottomHeight + topDis) >
                    (self.view.bounds.height - self.wrapperViewHeight - 10) {
                self.contentScroll?.setNeedsLayout()
                self.contentScroll?.layoutIfNeeded()
                if let contentScroll = self.contentScroll,
                    contentScroll.bounds.size.height > 0,
                    contentScroll.contentSize.height > contentScroll.bounds.height {
                    let offset = contentScroll.contentSize.height - contentScroll.bounds.height
                    self.contentScroll?.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
                }
            }
        }).disposed(by: self.disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.contentScroll?.contentSize = CGSize(width: self.view.bounds.width, height: wrapperViewHeight)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.contentScroll?.contentSize = CGSize(width: size.width, height: wrapperViewHeight)
    }

    @objc
    private func tapButton() {
        self.chatAPI
            .checkPublicChatName(chatName: nameTextField?.text ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (isExist) in
                guard let `self` = self else { return }
                if !isExist {
                    let groupName = self.nameTextField?.text ?? ""
                    self.nextBlock?(self, groupName)
                } else {
                    var tips: UDToast?
                    if let window = self.view.window {
                        tips = UDToast.showTips(with: BundleI18n.LarkContact.Lark_Group_CreateGroup_TypePublic_SetName_NameTaken, on: window)
                    }
                    guard let nextButton = self.nextButton, let window = self.view.window else { return }
                    let minY = self.view.convert(nextButton.frame, to: window).minY
                    if (UIScreen.main.bounds.height - minY) > self.realBottomHeight {
                        // toast 位置显示在nextButton按钮上方20pt
                        tips?.setCustomBottomMargin((UIScreen.main.bounds.height - minY) + 20)
                    }
                }
            }).disposed(by: self.disposeBag)
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    @objc
    private func nameTextDidChange() {
        guard let text = nameTextField?.text else {
            return
        }
        if let selectedRange = nameTextField?.markedTextRange {
            let position = nameTextField?.position(from: selectedRange.start, offset: 0)
            if position == nil {
                if text.count > 80 {
                    nameTextField?.text = String(text[0..<80])
                }
            }
        } else {
            if text.count > 80 {
                nameTextField?.text = String(text[0..<80])
            }
        }
    }
}
