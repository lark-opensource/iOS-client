//
//  MailGroupPermissionViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/26.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkNavigator
import LKCommonsLogging
import FigmaKit
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignDialog
import LarkContainer

final class MailGroupPermissionViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    private var disposeBag = DisposeBag()
    private lazy var tableView = InsetTableView(frame: .zero)
    private static let logger = Logger.log(
        MailGroupPermissionViewController.self,
        category: "NameCardList")

    private var viewModel: MailGroupPermissionViewModel
    var userResolver: LarkContainer.UserResolver
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(viewModel: MailGroupPermissionViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkContact.Mail_MailingList_WhoCanSendToMailingList
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.lu.register(cellSelf: MailGroupPermissionCell.self)
        tableView.lu.register(cellSelf: MailGroupPickerRouterCell.self)
        tableView.lu.register(cellSelf: MailGroupPermissionMemberCell.self)
        viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.router.drive(onNext: { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .showLoading:
                UDToast.showLoading(on: self.view)
            case .hideLoading:
                UDToast.removeToast(on: self.view)
            case .errorToast(let msg, let err):
                if let toast = msg {
                    UDToast.showFailure(with: toast, on: self.view)
                } else if let error = err {
                    let mailError = MailGroupHelper.mailGroupErrorIfNeed(error: error)
                    mailError.tipsAction(from: self)
                }
            case .dialog(let content):
                let dialog = UDDialog()
                dialog.setContent(text: content)
                dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
                self.present(dialog, animated: true, completion: nil)
            case .none:
                break
            }
        }).disposed(by: disposeBag)
        viewModel.refreshData()
        // 减少数据不一致的case
        viewModel.fetchData()
    }

    @objc
    override func backItemTapped() {
        if viewModel.enableBackCheck() {
            popSelf()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isMember = viewModel.getPermissionType(indexPath: indexPath) == .specificUser
        if viewModel.isRouterCell(indexPath: indexPath),
           let cell = tableView.dequeueReusableCell(withIdentifier: MailGroupPickerRouterCell.lu.reuseIdentifier) as? MailGroupPickerRouterCell {
            cell.titleLabel.text = viewModel.getItemBaseInfo(indexPath: indexPath).title
            return cell
        } else {
            var cell: MailGroupPermissionCell?
            if isMember {
                cell = tableView.dequeueReusableCell(withIdentifier: MailGroupPermissionMemberCell.lu.reuseIdentifier) as? MailGroupPermissionMemberCell
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: MailGroupPermissionCell.lu.reuseIdentifier) as? MailGroupPermissionCell
            }
            if let cell = cell {
                if viewModel.dataItemsCount - 1 == indexPath.row {
                    cell.layoutSeparater(.none)
                } else {
                    cell.layoutSeparater(.auto)
                }
                let info = viewModel.getItemBaseInfo(indexPath: indexPath)
                let shouldShowMember = viewModel.checkShowShouldMembersView(indexPath: indexPath)
                cell.titleLabel.text = info.title
                cell.checkBox.isSelected = info.isSelected
                cell.checkBox.isEnabled = !viewModel.isDisable
                if let cell = cell as? MailGroupPermissionMemberCell,
                   let member = viewModel.getItemMemberInfo(indexPath: indexPath) {
                    let avatarKeys = member.memberInfos.map({ $0.avatarKey })
                    cell.setMembers(editable: !viewModel.isDisable, memberCount: member.count,
                                    memberItems: member.memberInfos) { [weak self] _ in
                        self?.showPicker()
                    } deleteClick: { [weak self] _ in
                        guard let self = self else { return }
                        let vm = MailGroupPermissionMemberTableManagerVM(groupId: self.viewModel.groupId,
                                                                         accountId: self.viewModel.accountId,
                                                                         nameCardAPI: self.viewModel.dataAPI,
                                                                         resolver: self.userResolver)
                        vm.delegate = self
                        let vc = MailGroupMemberViewController(viewModel: vm, accessType: .delete, resolver: self.userResolver, displayMode: .multiselect)
                        self.navigator.push(vc, from: self)
                    }
                }
                return cell
            }
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 防止越界
        return viewModel.dataItemsCount
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard !viewModel.isDisable else { return }
        if viewModel.isRouterCell(indexPath: indexPath) {
            showPicker()
        } else {
            let type = viewModel.getPermissionType(indexPath: indexPath)
            if type == .specificUser,
               let member = viewModel.getItemMemberInfo(indexPath: indexPath)?.memberInfos,
               !member.isEmpty {
                let vm = MailGroupPermissionMemberTableManagerVM(groupId: self.viewModel.groupId,
                                                                 accountId: self.viewModel.accountId,
                                                                 nameCardAPI: self.viewModel.dataAPI,
                                                                 resolver: userResolver)
                vm.delegate = self
                let vc = MailGroupMemberViewController(viewModel: vm, accessType: .addAndDelete, resolver: userResolver, displayMode: .display)
                navigator.push(vc, from: self)
            } else {
                viewModel.requestUpdatePermission(type)
            }
        }
    }
}

extension MailGroupPermissionViewController {
    private func showPicker() {
        var body = MailGroupChatterPickerBody(groupId: viewModel.groupId,
                                              groupRoleType: .permission,
                                              accountID: viewModel.accountId)
        body.selectedCallback = { [weak self] (vc, res) in
            self?.viewModel.handlePickerResult(res: res)
            // 做完之后要自己手动dismiss
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
}

extension MailGroupPermissionViewController: MailGroupMemberTableVMDelegate {
    func canLeftSlide() -> Bool {
        false
    }

    func onRemoveEnd(_ error: Error?) {
        guard error == nil else { return }
        viewModel.fetchData()
    }

    func didAddMembers(_ error: Error?) {
        guard error == nil else { return }
        viewModel.fetchData()
    }

    func didLimitMembers(member: [GroupInfoMemberItem]) {}

    func noDepartmentPermission() {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkContact.Mail_MailingList_UnableToAddDepartmentsIOS)
        dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
        navigator.present(dialog, from: self)
    }
}
