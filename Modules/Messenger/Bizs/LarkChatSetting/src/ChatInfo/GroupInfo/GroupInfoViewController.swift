//
//  GroupInfoViewController.swift
//  Lark
//
//  Created by K3 on 2018/5/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LKCommonsLogging
import LarkModel
import RxSwift
import LarkAlertController
import EENavigator
import FigmaKit

final class GroupInfoViewController: BaseSettingController, UITableViewDataSource, UITableViewDelegate {
    private(set) var disposeBag = DisposeBag()
    static let logger = Logger.log(GroupInfoViewController.self, category: "Module.IM.GroupInfo")
    var tableView: InsetTableView?
    private(set) var viewModel: GroupInfoViewModel

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(viewModel: GroupInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        configViewModel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ChatSettingTracker.trackerInfoIMDeitGroupInfoView(chat: self.viewModel.chatModel)
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        // Do any additional setup after loading the view.
        commInit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.getGroupMailAddress()
    }

    private func commInit() {
        commInitNavi()
        commTableView()
    }

    private func commInitNavi() {
        title = viewModel.navigationTitle
    }

    private func commTableView() {
        let tableView = InsetTableView(frame: .zero)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.lu.register(cellSelf: GroupInfoPhotoCell.self)
        tableView.lu.register(cellSelf: GroupInfoNameCell.self)
        tableView.lu.register(cellSelf: GroupInfoDescriptionCell.self)
        tableView.lu.register(cellSelf: GroupInfoMailAddressCell.self)
        tableView.lu.register(cellSelf: GroupInfoQRCodeCell.self)

        tableView.register(GroupSettingSectionEmptyView.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        tableView.register(GroupSettingSectionView.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionView.self)
        )

        self.tableView = tableView
        self.viewModel.updateHeight
            .drive(onNext: { [weak self]  in
                UIView.performWithoutAnimation {
                    self?.tableView?.beginUpdates()
                    self?.tableView?.endUpdates()
                }
            }).disposed(by: self.disposeBag)
    }

    // MARK: - UITableViewDelegate
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < viewModel.items.count,
              let sectionItem = viewModel.items.section(at: section),
              !sectionItem.items.isEmpty else {
            return tableView.dequeueReusableHeaderFooterView(
                withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
        }
        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < viewModel.items.count, let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionView.self)) as? GroupSettingSectionView else {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: GroupSettingSectionView.self))
        }
        footer.setTitleHorizontalMargin(16)
        if let desc = viewModel.items[section].description {
            footer.titleLabel.text = desc
            footer.titleLabel.isHidden = false
        } else {
            footer.titleLabel.isHidden = true
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section < viewModel.items.count, let desc = viewModel.items[section].description else {
            return CGFloat.leastNormalMagnitude
        }
        return GroupSettingSectionView.titleTopMarigin +
            desc.getHeight(withConstrainedWidth: view.bounds.width - 32, font: GroupSettingSectionView.titleFont) +
            GroupSettingSectionView.titleBottomMarigin
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < viewModel.items.count,
              let sectionItem = viewModel.items.section(at: section),
              !sectionItem.items.isEmpty else {
                  return CGFloat.leastNormalMagnitude
        }
        return 16
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = viewModel.items.item(at: indexPath),
            var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? CommonCellProtocol {
            cell.item = item
            return (cell as? UITableViewCell) ?? .init()
        }
        return UITableViewCell()
    }
}

// viewModel config
private extension GroupInfoViewController {
    func configViewModel() {
        self.viewModel.targetVC = self

        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                self?.tableView?.reloadData()
            })
            .disposed(by: disposeBag)

        viewModel.cannotEditAlert
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                let alertController = LarkAlertController()
                let content = BundleI18n.LarkChatSetting.Lark_Legacy_OnlyGOGAEditGroupInfo
                alertController.setContent(text: content)
                alertController.addPrimaryButton(text: BundleI18n.LarkChatSetting.Lark_Legacy_Sure)
                self.viewModel.navigator.present(alertController, from: self)
            }).disposed(by: disposeBag)
    }
}
