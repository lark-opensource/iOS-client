//
//  MailGroupMemberViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkCore
import EENavigator
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LarkActionSheet
import LarkFeatureGating
import RxRelay
import UniverseDesignToast
import UniverseDesignActionPanel
import RustPB
import UniverseDesignIcon
import LarkContainer

enum MailGroupMemberVCAccess {
    case addAndDelete
    case delete
    case noPermission
}

final class MailGroupMemberViewController: BaseUIViewController, UserResolverWrapper {
    static let logger = Logger.log(MailGroupMemberViewController.self, category: "NamecardList")
    var userResolver: LarkContainer.UserResolver
    private var table: MailGroupMemberTableViewController

    // 移除按钮
    private lazy var rightRemoveItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkContact.Mail_MailingList_RemoveMobile)
        item.button.tintColor = UIColor.ud.functionDangerContentDefault
        item.button.addTarget(self, action: #selector(rightRemoveButtonDidClick), for: .touchUpInside)
        return item
    }()

    // 取消按钮
    private lazy var leftCancelItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkContact.Mail_MailingList_CancelMobile)
        item.button.tintColor = UIColor.ud.textTitle
        item.button.addTarget(self, action: #selector(leftCancelDidClick), for: .touchUpInside)
        return item
    }()

    // ... 按钮
    private lazy var rightMoreItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: UDIcon.moreOutlined, title: nil)
        item.addTarget(self, action: #selector(moreItemTapped), for: .touchUpInside)
        return item
    }()

    // ... 用于计数
    private var multiSelectCounter: PublishSubject = PublishSubject<Int>()

    private var isRemove: Bool = false

    var tranferAction: ((String, UIViewController) -> Void)?
    var canSildeRelay = BehaviorRelay<Bool>(value: true)
    var displayMode: MailGroupMemberTableViewController.DisplayMode?
    var accessType: MailGroupMemberVCAccess

    init(viewModel: MailGroupMemberTableVM,
         accessType: MailGroupMemberVCAccess,
         resolver: UserResolver,
         displayMode: MailGroupMemberTableViewController.DisplayMode? = nil
    ) {
        self.displayMode = displayMode
        self.table = MailGroupMemberTableViewController(viewModel: viewModel)
        self.accessType = accessType
        self.userResolver = resolver

        super.init(nibName: nil, bundle: nil)
        self.addChild(table)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(table.view)
        table.view.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.bottom.left.right.equalToSuperview()
        }

        setupNavigationBar()

        bandingTableEvent()
        if let model = displayMode {
            switch model {
            case .multiselect:
                switchToRemove()
                isRemove.toggle()
            case .display:
                break
            }
        }
    }

    private func setupNavigationBar() {
        self.title = MailGroupHelper.createTitle(role: table.viewModel.groupRole)

        if accessType == .delete {
            navigationItem.rightBarButtonItem = rightRemoveItem
        } else if accessType == .addAndDelete {
            navigationItem.rightBarButtonItem = rightMoreItem
        } else if accessType == .noPermission {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc
    private func moreItemTapped() {
        guard let moreView = self.rightMoreItem.customView else {
            return
        }
        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: false,
                popSource: UDActionSheetSource(sourceView: moreView, sourceRect: moreView.bounds, arrowDirection: .up)))
        actionSheet.addDefaultItem(text: BundleI18n.LarkContact.Mail_MailingList_AddMobile) { [weak self] in
            self?.addGroupMember()
        }
        actionSheet.addDestructiveItem(text: BundleI18n.LarkContact.Mail_MailingList_RemoveMobile) { [weak self] in
            guard let `self` = self else { return }
            if !self.isRemove {
                self.switchToRemove()
                self.isRemove.toggle()
            }
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Mail_MailingList_CancelMobile) {
        }
        self.present(actionSheet, animated: true, completion: nil)
    }

    private func addGroupMember() {
        // 跳转打开picker
        var type: MailGroupChatterPickerBody.GroupRole = .manager
        switch self.table.viewModel.groupRole {
        case .manager:
            type = .manager
        case .member:
            type = .member
        case .permission:
            type = .permission
        @unknown default:
            break
        }
        var body = MailGroupChatterPickerBody(groupId: self.table.viewModel.groupId,
                                              groupRoleType: type,
                                              accountID: self.table.viewModel.accountId)
        body.selectedCallback = { [weak self] (vc, res) in
            self?.table.viewModel.handlePickerResult(res: res)
            vc?.dismiss(animated: true, completion: nil)
        }
        navigator.present(
            body: body,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { vc in
                vc.modalPresentationStyle = .formSheet
            })
    }

    @objc
    private func addItemTapped() {
        self.addGroupMember()
    }

    @objc
    private func toggleViewSelectStatus() {
        if isRemove {
            switchToDisplay()
        } else {
            switchToRemove()
        }
        isRemove.toggle()
    }

    @objc
    private func rightRemoveButtonDidClick() {
        confirmRemove()
    }

    @objc
    private func leftCancelDidClick() {
        toggleViewSelectStatus()
    }
}

private extension MailGroupMemberViewController {
    func confirmRemove() {
        if table.removeSelectedItems() {
            toggleViewSelectStatus()
        }
    }

    func switchToRemove() {
        self.table.cancelEditting()
        rightRemoveItem.isEnabled = false
        navigationItem.rightBarButtonItem = rightRemoveItem
        navigationItem.titleView = MailGroupMemberNaviTitleView(title: MailGroupHelper.createTitle(role: table.viewModel.groupRole),
                                                                observable: multiSelectCounter,
                                                                shouldDisplayCountTitle: true)
        navigationItem.leftBarButtonItem = leftCancelItem

        table.view.snp.remakeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview()
        }

        table.displayMode = .multiselect
    }

    func switchToDisplay() {
        addBackItem()
        navigationItem.rightBarButtonItem = rightMoreItem
        navigationItem.titleView = nil
        self.title = MailGroupHelper.createTitle(role: table.viewModel.groupRole)

        table.view.snp.remakeConstraints { (maker) in
            maker.top.bottom.left.right.equalToSuperview()
        }

        table.displayMode = .display
    }

    func bandingTableEvent() {
        table.onSelected = { [weak self] (_, items) in
            self?.multiSelectCounter.onNext(items.count)
            self?.rightRemoveItem.isEnabled = !items.isEmpty
        }

        table.onDeselected = { [weak self] (_, items) in
            self?.multiSelectCounter.onNext(items.count)
            self?.rightRemoveItem.isEnabled = !items.isEmpty
        }

        table.onTap = { _ in
            // TODO:
        }
    }
}
