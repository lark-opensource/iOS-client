//
//  ViewController.swift
//  BanningSettingController
//
//  Created by kongkaikai on 2019/3/8.
//  Copyright © 2019 kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkNavigator
import LarkFeatureGating
import UniverseDesignColor
import FigmaKit
import LarkModel

final class BanningSettingController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {

    private var disposeBag = DisposeBag()
    private lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.separatorStyle = .none
        return tableView
    }()
    private var viewModel: BanningSettingViewModel
    private lazy var rightItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkChatSetting.Lark_Legacy_LarkConfirm, fontStyle: .medium)
        item.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.addTarget(self, action: #selector(makeSure), for: .touchUpInside)
        return item
    }()

    init(viewModel: BanningSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
        viewModel.targetViewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewWidth = self.navigationController?.view.bounds.width ?? view.bounds.width
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

        let chatTitle = BundleI18n.LarkChatSetting.Lark_Group_GroupSettings_MsgRestriction_Title
        titleString = (viewModel.chat.chatMode == .threadV2) ?
            BundleI18n.LarkChatSetting.Lark_Groups_Settings_MsgRestriction_Title :
            chatTitle
        navigationItem.rightBarButtonItem = rightItem
        addCancelItem()

        viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        viewModel.loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @objc
    private func makeSure() {
        navigationController?.dismiss(animated: true)
        viewModel.confirmOption()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewModel.viewWidth = size.width
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.datas.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return item(for: viewModel.datas, at: section)?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let sectionDatas = item(for: viewModel.datas, at: indexPath.section),
            let item = item(for: sectionDatas.items, at: indexPath.item),
            let cell = tableView.dequeueReusableCell(withIdentifier: item.identifier, for: indexPath) as? BanningSettingCell & UITableViewCell {
            cell.set(item: item)
            return cell
        }

        return UITableViewCell()
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard let cell = tableView.cellForRow(at: indexPath) as? BanningSettingCell, let item = cell.item else { return }

        if let item = item as? BanningSettingOptionItem<Chat.PostType> {
            viewModel.setOption(item.seletedType)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }

    func item<T>(for items: [T], at index: Int) -> T? {
        return index < items.count ? items[index] : nil
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

extension BanningSettingController: BanningSettingViewModelDelegate {
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
            var body = GroupChatterSelectBody(chatId: viewModel.chat.id,
                                              allowSelectNone: true,
                                              showSelectedView: false)
            // 默认选中的人员过滤掉所有的管理员
            body.defaultSelectedChatterIds = viewModel.chatterIds.filter({ (id) -> Bool in
                !viewModel.adminItems.contains { (item) -> Bool in
                    item.id == id
                }
            })
            // 管理员默认选中不可取消
            body.defaultUnableCancelSelectedIds = viewModel.adminItems.map({ $0.id })
            body.title = viewModel.chat.chatMode == .threadV2 ?
                BundleI18n.LarkChatSetting.Lark_Group_Topic_GroupSettings_MsgRestriction_SelectMember_Title :
                    BundleI18n.LarkChatSetting.Lark_Legacy_SelectLabel
            body.onSelected = { [weak self] (chatters) in
                self?.viewModel.updateSeletedChatters(chatters)
            }
            self.viewModel.navigator.push(body: body, from: self)
        }
    }
}
