//
//  LanguageSettingViewController.swift
//  ByteViewSetting
//
//  Created by 陈乐辉 on 2023/6/25.
//

import Foundation
import SnapKit
import UniverseDesignColor
import ByteViewCommon
import ByteViewUI

class LanguageSettingViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    override var logger: Logger { viewModel.logger }
    let tableView = BaseTableView()
    let viewModel: BaseSettingViewModel
    /// tableView的数据源，只能主线程使用
    private(set) var sections: [SettingDisplaySection] = []

    init(viewModel: BaseSettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
        self.viewModel.hostViewController = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .ud.bgBody
        setNavigationBarBgColor(.ud.bgBody)
        title = viewModel.title

        tableView.estimatedRowHeight = 52
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        registerTableViewCells()
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 12))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 20))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        tableView.delegate = self
        tableView.dataSource = self
        self.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.trackPageAppear()
    }

    func updateLeftItem() {
        let isShowCloseButton = navigationController?.modalPresentationStyle != .popover
        if isShowCloseButton {
            navigationItem.leftBarButtonItem = nil
            title = viewModel.title
            hidesBackButton = false
        } else {
            hidesBackButton = true
            title = ""
            let label = UILabel()
            label.text = viewModel.title
            label.textColor = UIColor.ud.textTitle
            label.font = .boldSystemFont(ofSize: 17)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)
        }
    }

    func registerTableViewCells() {
        self.viewModel.supportedCellTypes.forEach {
            tableView.registerSettingCell($0)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        self.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellType.reuseIdentifier, for: indexPath)
        if let settingCell = cell as? BaseSettingCell {
            settingCell.config(for: row, indexPath: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = self.sections[indexPath.section].rows[indexPath.row]
        if row.isEnabled, row.cellType.supportSelection {
            logger.info("[\(self.viewModel.pageId)] click \(row.cellType) \(row.item)")
            row.action?(buildRowActionContext(row: row, indexPath: indexPath, isOn: row.isOn))
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        self.viewModel.supportsRotate ? .allButUpsideDown : .portrait
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
    }

    @RwAtomic private var shouldReloadData: Bool = true
    /// 当前是主线程时，实时刷新。当前是非主线程时，会在进入主线程时合并刷新（可合并一些同一个push message被分成多个callback处理的case）。
    /// - note: 不可延迟，后面可能会紧跟tableView的其他操作。
    func reloadData() {
        self.shouldReloadData = true
        Util.runInMainThread { [weak self] in
            self?.reloadDataIfNeeded()
        }
    }

    private func reloadDataIfNeeded() {
        guard self.shouldReloadData else { return }
        self.shouldReloadData = false
        self.sections = self.viewModel.sections
        self.tableView.reloadData()
    }

    private func buildRowActionContext(row: SettingDisplayRow, indexPath: IndexPath, isOn: Bool, anchorView: UIView? = nil) -> SettingRowActionContext {
        SettingRowActionContext(source: self.viewModel.pageId, service: self.viewModel.service,
                                row: row, indexPath: indexPath, from: self, updator: self, isOn: isOn, anchorView: anchorView)
    }

    override var description: String {
        "\(super.description) \(viewModel.pageId)"
    }
}

extension LanguageSettingViewController: SettingViewModelDelegate {
    func requireUpdateSections() {
        self.reloadData()
    }
}

extension LanguageSettingViewController: SettingRowUpdatable {
    func reloadRow(for item: SettingDisplayItem, shouldReloadSection: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let indexPath = self.sections.findIndexPath(for: item) else { return }
            if shouldReloadSection {
                self.tableView.reloadSections([indexPath.section], with: .automatic)
            } else {
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }

    func reloadSection(_ section: Int) {
        Util.runInMainThread { [weak self] in
            guard let self = self, section < self.sections.count else { return }
            self.tableView.reloadSections([section], with: .automatic)
        }
    }

    func scrollToRow(for item: SettingDisplayItem, at position: UITableView.ScrollPosition, animated: Bool) {
        Util.runInMainThread { [weak self] in
            guard let self = self, let indexPath = self.sections.findIndexPath(for: item) else { return }
            self.tableView.scrollToRow(at: indexPath, at: position, animated: animated)
        }
    }
}
