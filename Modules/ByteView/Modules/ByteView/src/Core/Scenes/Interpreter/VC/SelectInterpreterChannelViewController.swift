//
//  SelectInterpreterChannelViewController.swift
//  ByteView
//
//  Created by wulv on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Action
import RxCocoa
import RxSwift
import ByteViewUI
import ByteViewTracker
import UIKit
import UniverseDesignIcon

extension SelectInterpreterChannelViewController {
    enum Layout {
        static let tableViewSectionHeaderH: CGFloat = 16.0
        static let tableViewRowH: CGFloat = 48
        static let tableViewTopOffset: CGFloat = 0.0
    }
}

class SelectInterpreterHeaderView: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .ud.bgBase
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SelectInterpreterChannelViewController: VMViewController<SelectInterpreterChannelViewModel>, UITableViewDataSource, UITableViewDelegate {

    private let cellIdentifier = "InterpreterChannelCell"

    // MARK: UI
    private lazy var barCloseButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)),
                        for: .normal)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)),
                        for: .highlighted)
        button.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), 8.0))
        return button
    }()

    private lazy var headerLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = UIColor.clear
        label.text = I18n.View_G_SelectChannel
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var tableView: UITableView = {
        let tableView = BaseGroupedTableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = Layout.tableViewRowH
        tableView.register(InterpreterChannelCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.register(SelectInterpreterHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: SelectInterpreterHeaderView.self))
        return tableView
    }()

    private var channels: [InterpreterChannelCellSectionModel] = []

    override func bindViewModel() {
        setupNavigation()
        setupTableView()
        viewModel.hostVC = self
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBase
        edgesForExtendedLayout = .bottom
        layoutTableView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private func layoutTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.top.equalTo(Layout.tableViewTopOffset)
            maker.left.bottom.right.equalToSuperview()
        }
    }

    private func setupNavigation() {
        title = I18n.View_G_Interpretation
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: barCloseButton)
        barCloseButton.rx.action = viewModel.closeAction
        setNavigationBarBgColor(UIColor.ud.bgBase)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self

        viewModel.channelsObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] channels in
            self?.channels = channels
            self?.tableView.reloadData()
        }).disposed(by: rx.disposeBag)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        channels.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        channels[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rawCell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        if let cell = rawCell as? InterpreterChannelCell {
            let item = channels[indexPath.section].items[indexPath.row]
            cell.config(with: item)
            if item.cellType == .cellTypeMute {
                cell.muteSwitch.rx.isOn.do(onNext: { [weak self] item in
                    guard item != self?.viewModel.isMuteOriginChannel else { return }
                    VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: item ? "mute_original" : "unmute_original"])
                })
                .distinctUntilChanged().subscribe(onNext: { [weak self] isMuted in
                    self?.viewModel.interpretation.muteOriginChannel(isMuted)
                })
                .disposed(by: self.rx.disposeBag)
            }
            cell.bottomLine.isHidden = indexPath.row == channels[indexPath.section].items.count - 1
        }
        return rawCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Layout.tableViewSectionHeaderH
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let identifier = String(describing: SelectInterpreterHeaderView.self)
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: identifier) as? SelectInterpreterHeaderView {
            return headerView
        }
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = channels[indexPath.section].items[indexPath.row]
        if model.cellType == .cellTypeChannel {
            viewModel.selectChannel(model)
            InterpreterTrack.switchLanguage()
            tableView.reloadData() // 现在不关闭页面，因为有联动所以需要刷新tableview
        } else if model.cellType == .cellTypeManage {
            viewModel.manageInterpreterAction()
        }
    }
}
