//
//  ApproveViewController.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/3/29.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignEmpty
import FigmaKit

final class ApproveViewController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private let disposeBag = DisposeBag()
    private let content = UIView()
    private let messageLabel = UILabel()
    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: UDEmptyConfig(type: .defaultPage))
        emptyView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.addSubview(emptyView)
        emptyView.snp.makeConstraints({ (make) in
            make.top.equalToSuperview().offset(16)
            make.left.width.height.equalToSuperview()
        })
        return emptyView
    }()

    private let switchButton = LoadingSwitch(behaviourType: .normal)
    private let tableView = InsetTableView(frame: .zero)
    private let viewModel: ApproveViewModel
    // headerView 作为TableView的tableHeaderView，用来描述一些信息
    private lazy var headerView: UIView = {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = true
        return headerView
    }()

    // headerLabel被添加到headerView内
    private lazy var headerLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.textColor = UIColor.ud.textPlaceholder
        headerLabel.font = UIFont.systemFont(ofSize: 14)
        return headerLabel
    }()

    init(viewModel: ApproveViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
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
        view.backgroundColor = UIColor.ud.bgFloatBase
        view.addSubview(tableView)
        view.addSubview(content)

        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 92
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in self?.loadMoreNew() }

        tableView.register(ApproveCell.self, forCellReuseIdentifier: ApproveCell.lu.reuseIdentifier)
        tableView.register(
                    UITableViewHeaderFooterView.self,
                    forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")

        tableView.snp.makeConstraints { (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.top.equalTo(content.snp.bottom).offset(16)
        }

        if !viewModel.isOn {
            headerView.addSubview(headerLabel)
            headerLabel.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview().offset(16)
                maker.right.equalToSuperview().offset(-16)
                maker.top.equalToSuperview()
                maker.bottom.equalToSuperview().offset(-8)
            }
            updateHeader()
        }

        content.backgroundColor = UIColor.ud.bgFloat

        content.snp.makeConstraints { (maker) in
            maker.left.equalTo(tableView.insetLayoutGuide.snp.left)
            maker.right.equalTo(tableView.insetLayoutGuide.snp.right)
            maker.top.equalToSuperview().offset(16)
            maker.height.equalTo(48)
        }
        content.layer.cornerRadius = 10

        messageLabel.text = (viewModel.chat.chatMode == .threadV2) ?
            BundleI18n.LarkChatSetting.Lark_Groups_ApproveInvitation :
            BundleI18n.LarkChatSetting.Lark_Group_ApproveInvitation
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor.ud.textTitle
        content.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().inset(16)
        }

        switchButton.setOn(viewModel.isOn, animated: false)
        switchButton.onTintColor = UIColor.ud.colorfulBlue
        switchButton.rx.isOn.asDriver().skip(1).drive(onNext: { [weak self] (isOn) in
            self?.viewModel.switchStatus(isOn)
        }).disposed(by: disposeBag)
        content.addSubview(switchButton)
        switchButton.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().inset(12)
        }

        viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.setViewStatus()
        }).disposed(by: disposeBag)

        viewModel.deleteItem.drive(onNext: { [weak self] (_, index) in
            self?.deleteCellAtIndex(index)
        }).disposed(by: disposeBag)

        self.loadingPlaceholderView.isHidden = false
        self.title = BundleI18n.LarkChatSetting.Lark_Group_GroupEnterVerification

        viewModel.loadData()
    }

    private func setViewStatus() {
        self.tableView.reloadData()
        self.tableView.endTopLoadMore(hasMore: true)
        self.tableView.endBottomLoadMore(hasMore: viewModel.hasMore)
        self.switchButton.setOn(self.viewModel.isOn, animated: true)
        self.loadingPlaceholderView.isHidden = true
        self.emptyView.isHidden = !self.viewModel.datas.isEmpty
        self.updateHeader()
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ApproveCell.lu.reuseIdentifier, for: indexPath)
        if indexPath.row < viewModel.datas.count, let approveCell = cell as? ApproveCell {
            var item = viewModel.datas[indexPath.item]
            item.isShowBorderLine = indexPath.row != viewModel.datas.count - 1
            approveCell.item = item
            approveCell.onReject = { [weak self] (_) in self?.viewModel.reject(item) }
            approveCell.onAccept = { [weak self] (_) in self?.viewModel.accept(item) }
            approveCell.navi = self.viewModel.navigator
        }
        return cell
    }

    private func deleteCellAtIndex(_ index: Int) {
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

}

private extension ApproveViewController {
    // 上拉
    func loadMoreNew() {
        viewModel.loadData(true)
    }
}

private extension ApproveViewController {
    // 更新header高度
    func updateHeader() {
        guard let title = viewModel.headerTitle, !title.isEmpty else {
            self.tableView.tableHeaderView = nil
            return
        }
        headerLabel.text = title
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = height
        self.headerView.frame = frame
        tableView.tableHeaderView = headerView
    }
}
