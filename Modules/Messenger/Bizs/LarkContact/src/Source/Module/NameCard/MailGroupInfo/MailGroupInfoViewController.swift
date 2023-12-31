//
//  MailGroupInfoViewController.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/19.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import LarkModel
import LKCommonsLogging
import LarkCore
import LarkMessengerInterface
import EENavigator
import LarkFeatureGating
import LarkSplitViewController
import UniverseDesignToast
import UniverseDesignDialog
import LarkAlertController
import FigmaKit
import LarkContainer

final class MailGroupInfoViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {

    // UI
    private let naviBar = TitleNaviBar(titleString: BundleI18n.LarkContact.Mail_MailingList_ViewMailingList)
    var tableView: InsetTableView?

    // Logic
    private let disposeBag = DisposeBag()
    private(set) var viewModel: MailGroupInfoViewModel
    private var items: [GroupInfoSectionModel] = []
    private var maxWidth: CGFloat?
    override var navigationBarStyle: NavigationBarStyle {
        return .none
    }
    var userResolver: LarkContainer.UserResolver

    init(viewModel: MailGroupInfoViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        isNavigationBarHidden = true
        setupNavi()
        setupTableView()
        bindViewModel()
        MailGroupStatistics.groupInfoView()
    }

    private func setupNavi() {
        if Display.pad {
            naviBar.addCloseButton()
        } else {
            naviBar.addBackButton()
        }
        naviBar.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
    }

    private func setupTableView() {
        let tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.sectionHeaderHeight = 16
        tableView.sectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(naviBar.snp.bottom)
        }
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.lu.register(cellSelf: MailGroupInfoNameCell.self)
        tableView.lu.register(cellSelf: MailGroupInfoMemberCell.self)
        tableView.lu.register(cellSelf: MailGroupInfoCommonCell.self)

        tableView.register(
            MailGroupInfoSectionView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: MailGroupInfoSectionView.self)
        )

        self.tableView = tableView
    }

    func bindViewModel() {
        viewModel.state.drive(onNext: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .loading:
                // TODO
                break
            case .infoData(items: let value):
                self.items = value
                self.tableView?.reloadData()
            case .error:
                // TODO
                break
            @unknown default: break
            }
        }).disposed(by: disposeBag)

        viewModel.router.drive(onNext: { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .memberList(viewModel: let vm, isRemove: let isRemove):
                var accessType: MailGroupMemberVCAccess = isRemove ? .delete : .addAndDelete
                if self.viewModel.isDisable {
                    accessType = .noPermission
                }
                let vc = MailGroupMemberViewController(viewModel: vm,
                                                       accessType: accessType,
                                                       resolver: self.userResolver,
                                                       displayMode: isRemove ? .multiselect : .display)
                self.navigator.push(vc, from: self)
            case .permission(viewModel: let viewModel):
                let vc = MailGroupPermissionViewController(viewModel: viewModel, resolver: self.userResolver)
                self.navigator.push(vc, from: self)
            case .addMemberPicker(groupId: let id, accountId: let accountID, type: let role, let maxCount, callback: let callback):
                var type: MailGroupChatterPickerBody.GroupRole = .member
                switch role {
                case .member:
                    type = .member
                case .manager:
                    type = .manager
                case .permission:
                    type = .permission
                @unknown default: break
                }
                var body = MailGroupChatterPickerBody(groupId: id, groupRoleType: type, accountID: accountID)
                if let count = maxCount {
                    body.maxSelectCount = count
                }
                body.selectedCallback = { (vc, res) in
                    callback(res)
                    // 做完之后要自己手动dismiss
                    vc?.dismiss(animated: true, completion: nil)
                }
                self.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: self,
                    prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            case .remark(groupId: let id, groupDescription: let desc, nameCardAPI: let api):
                let vc = MailGroupRemarkViewController(groupId: id, groupDescription: desc, nameCardAPI: api)
                self.navigator.push(vc, from: self)
            case .reachManagerLimit(let limitItems):
                self.showReachLimitAlert(limitItems: limitItems)
            case .mailError(let error):
                error.tipsAction(from: self)
            case .toast(let msg):
                if let window = self.view.window {
                    UDToast.showTips(with: msg, on: window)
                }
            case .noDepartmentPermission:
                self.showNoDepartment()
            case .none:
                assert(false, "@liutefeng")
                break
            @unknown default: break
            }
        }).disposed(by: disposeBag)

        viewModel.loadGroupInfo()
    }

    func showReachLimitAlert(limitItems: [GroupInfoMemberItem]) {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkContact.Mail_MailingList_PartAdminAddFailed)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkContact.Mail_MailingList_View) { [weak self] in
            guard let self = self else { return }
            let vc = MailGroupReachLimitManagerVC(datas: limitItems)
            self.navigator.push(vc, from: self)
        }
        self.navigator.present(dialog, from: self)
    }

    func showNoDepartment() {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkContact.Mail_MailingList_UnableToAddDepartmentsIOS)
        dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
        self.navigator.present(dialog, from: self)
    }

    // MARK: tableView
    private func item<T>(for items: [T], at index: Int) -> T? {
        guard index > -1, index < items.count else { return nil }
        return items[index]
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.item(for: self.items, at: section)?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let section = self.item(for: self.items, at: indexPath.section),
            var item = section.item(at: indexPath.row),
            var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MailGroupInfoCell {
                cell.updateAvailableMaxWidth(self.view.bounds.width)
                cell.item = item
                return (cell as? UITableViewCell) ?? .init()
        } else {
            assert(false, "未找到对应的Item or cell")
        }
        return UITableViewCell()
    }
}
