//
//  PreventMessageWhiteListController.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/5/9.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkNavigator
import UniverseDesignColor
import FigmaKit
import LarkAlertController
import UniverseDesignToast

class PreventMessageWhiteListController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private var disposeBag = DisposeBag()
    private lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.separatorStyle = .none
        return tableView
    }()
    private let viewModel: PreventMessageWhiteListViewModel
    private lazy var rightItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_LarkConfirm, fontStyle: .medium)
        item.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        item.addTarget(self, action: #selector(makeSure), for: .touchUpInside)
        return item
    }()

    override func addCancelItem() -> UIBarButtonItem {
        let item = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_Cancel, fontStyle: .medium)
        item.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = item
        return item
    }

    private var inConfirm: Bool = false
    init(viewModel: PreventMessageWhiteListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.ud.bgFloatBase

        for cellClass in [BanningSettingOptionCell.self,
                          BanningSettingChattersCell.self] {
                            tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
        }
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")

        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        titleString = BundleI18n.LarkChatSetting.Lark_Group_WhoBypassRestrictedMode_Title
        navigationItem.rightBarButtonItem = rightItem
        _ = addCancelItem()

        viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        self.viewModel.setup(viewWidth: self.navigationController?.view.bounds.width ?? view.bounds.width)
    }

    @objc
    private func makeSure() {
        guard self.viewModel.beChanged() else {
            self.navigationController?.dismiss(animated: true)
            return
        }
        guard !inConfirm else {
            return
        }
        inConfirm = true
        if self.viewModel.currentSelectType == .whiteList, self.viewModel.selectedChatterIds?.isEmpty ?? true {
            if self.viewModel.selectedChatterIds == nil {
                assertionFailure()
            }
            _ = self.viewModel.setOption(.noBody)
        }
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.confirm(success: { [weak self] in
                self?.inConfirm = false
                self?.navigationController?.dismiss(animated: true)
            }, failed: { [weak self] error in
                self?.inConfirm = false
                PreventMessageWhiteListViewModel.logger.error("preventMessageWhiteList trace confirm fail", error: error)
                UDToast.showFailure(with: "", on: self?.view ?? UIView(), error: error)
            }, showLoadingIn: self?.view)
        }
    }

    @objc
    private func goBack() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChatSetting.Lark_Group_WhoBypassRestrictedMode_EditsUnsaved_Title,
                                 alignment: .center)
        alertController.addSecondaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_WhoBypassRestrictedMode_EditsUnsaved_KeepEditing_Button)
        alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Group_WhoBypassRestrictedMode_EditsUnsaved_Quit_Button,
                                         dismissCompletion: { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        })
        self.navigationController?.present(alertController, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewModel.update(viewWidth: size.width)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.optionsSection.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.viewModel.optionsSection.items[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.identifier, for: indexPath) as? BanningSettingCell & UITableViewCell {
            cell.set(item: item)
            return cell
        }
        return UITableViewCell()
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // swiftlint:disable did_select_row_protection
        let item = self.viewModel.optionsSection.items[indexPath.row]
        if let item = item as? BanningSettingOptionItem<PreventMessageWhiteListViewModel.SelectedType> {
            if viewModel.setOption(item.seletedType) {
                // 如果之前没有选任何人，自动唤起选人列表
                if item.seletedType == .whiteList, self.viewModel.selectedEmptyWhiteList() {
                    DispatchQueue.main.async {
                        self.showGroupChatterSelectVC()
                    }
                }
            } else {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
        // swiftlint:enable did_select_row_protection
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }
}

extension PreventMessageWhiteListController: PreventMessageWhiteListViewModelDelegate {
    func onChatterItemSelected(item: BanningSettingItem) {
        if let item = item as? BanningSettingAvatarItem {
            let body = PersonCardBody(chatterId: item.id,
                                        chatId: viewModel.chat.id,
                                        source: .chat)
            self.viewModel.navigator.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: self,
                prepareForPresent: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        } else if item is BanningSettingEditItem {
            self.showGroupChatterSelectVC()
        }
    }

    func showGroupChatterSelectVC() {
        var body = GroupChatterSelectBody(chatId: viewModel.chat.id,
                                          allowSelectNone: true,
                                          showSelectedView: false,
                                          isOwnerCanSelect: true)
        // 默认选中的人员过滤掉所有的管理员
        body.defaultSelectedChatterIds = Array(viewModel.selectedChatterIds ?? viewModel.defaultWhiteListChatterIds)
        body.title = BundleI18n.LarkChatSetting.Lark_Group_WhoBypassRestrictedMode_Title
        body.maxSelectModel = (20, BundleI18n.LarkChatSetting.Lark_Group_WhoBypassRestrictedMode_Desc(20))
        body.onSelected = { [weak self] (chatters) in
            self?.viewModel.updateSeletedChatters(chatters)
        }
        self.viewModel.navigator.push(body: body, from: self)
    }
}
