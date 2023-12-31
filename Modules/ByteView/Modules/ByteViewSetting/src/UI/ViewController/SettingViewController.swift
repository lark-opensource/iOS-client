//
//  SettingViewController.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import SnapKit
import UniverseDesignColor
import ByteViewCommon
import ByteViewUI

class SettingViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    override var logger: Logger { viewModel.logger }
    lazy var tableView: UITableView = createTableView()
    let viewModel: BaseSettingViewModel
    /// tableView的数据源，只能主线程使用
    private(set) var sections: [SettingDisplaySection] = []

    var emptyHeaderHeight: CGFloat { 4.0 }
    var emptyFooterHeight: CGFloat { 12.0 }

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

        self.title = self.viewModel.title
        self.view.backgroundColor = .ud.bgFloatBase
        setNavigationBarBgColor(.ud.bgFloatBase)

        tableView.estimatedRowHeight = 52
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
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
        self.scrollToCellIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.trackPageAppear()
    }

    func createTableView() -> UITableView {
        return BaseGroupedTableView()
    }

    private func scrollToCellIfNeeded() {
        for (sectionIdx, section) in sections.enumerated() {
            for (rowIdx, row) in section.rows.enumerated() {
                if row.autoJump {
                    DispatchQueue.main.async {
                        self.tableView.scrollToRow(at: IndexPath(row: rowIdx, section: sectionIdx), at: .none, animated: false)
                    }
                    return
                }
            }
        }
    }

    func registerTableViewCells() {
        self.viewModel.supportedCellTypes.forEach {
            tableView.registerSettingCell($0)
        }
        self.viewModel.supportedHeaderTypes.forEach {
            tableView.registerSettingHeaderView($0)
        }
        self.viewModel.supportedFooterTypes.forEach {
            tableView.registerSettingFooterView($0)
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
        if let switchCell = cell as? SettingSwitchCell {
            switchCell.delegate = self
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let model = self.sections[section].header,
            !model.title.isEmpty,
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: model.type.reuseIdentifier) as? SettingBaseHeaderView {
            headerView.config(for: model,
                              maxLayoutWidth: tableView.bounds.width,
                              contentInsets: headerContentInsets(isFirst: section == 0),
                              showSaperator: shouldShowSeparator(isHeader: true, isFirst: section == 0))
            return headerView
        } else {
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingDisplayHeaderType.emptyHeader.reuseIdentifier) as? SettingEmptyHeaderView
            view?.isShowSeparator = shouldShowSeparator(isHeader: true, isFirst: section == 0)
            return view
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let model = self.sections[section].footer,
            !model.description.isEmpty,
           let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: model.type.reuseIdentifier) as? SettingBaseFooterView {
            footerView.config(for: model,
                              maxLayoutWidth: tableView.bounds.width,
                              showSaperator: shouldShowSeparator(isHeader: false, isFirst: section == 0))
            return footerView
        } else {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: SettingDisplayFooterType.emptyFooter.reuseIdentifier)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let model = self.sections[section].header {
            switch model.type {
            case .emptyHeader:
                return emptyHeaderHeight
            case .titleHeader:
                return UITableView.automaticDimension
            case .titleAndRedirectDescriptionHeader:
                guard let desc = model.description, !desc.isEmpty else { return emptyFooterHeight }
                return calcCeiledHeaderFooterHeight(with: desc,
                                                    font: VCFontConfig.r_14_22.font,
                                                    layoutWidth: tableView.bounds.width - 32) + 61 // 26 + 24 + 2 + 4 + 5
            default:
                return emptyHeaderHeight
            }
        } else {
            return emptyHeaderHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let model = self.sections[section].footer {
            switch model.type {
            case .emptyFooter:
                return emptyFooterHeight
            case .descriptionFooter, .redirectDescriptionFooter:
                guard !model.description.isEmpty else { return emptyFooterHeight }
                return calcCeiledHeaderFooterHeight(with: model.description,
                                                    font: VCFontConfig.bodyAssist.font,
                                                    layoutWidth: tableView.bounds.width - 64) + 20
            default:
                return emptyFooterHeight
            }
        } else {
            return emptyFooterHeight
        }
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

    @RwAtomic private var shouldReloadData: Bool = true
    /// 当前是主线程时，实时刷新。当前是非主线程时，会在进入主线程时合并刷新（可合并一些同一个push message被分成多个callback处理的case）。
    /// - note: 不可延迟，后面可能会紧跟tableView的其他操作。
    func reloadData() {
        self.shouldReloadData = true
        Util.runInMainThread { [weak self] in
            self?.reloadDataIfNeeded()
        }
    }

    func headerContentInsets(isFirst: Bool) -> UIEdgeInsets {
        let top: CGFloat = isFirst ? 0 : 4
        let contentInsets = UIEdgeInsets(top: top, left: 0, bottom: 4, right: 0)
        return contentInsets
    }

    func shouldShowSeparator(isHeader: Bool, isFirst: Bool) -> Bool {
        return false
    }

    private func reloadDataIfNeeded() {
        guard self.shouldReloadData else { return }
        self.shouldReloadData = false
        if #available(iOS 15.0.1, *) {
            self.sections = self.viewModel.sections
            self.tableView.reloadData()
        } else {
            // iOS 14, reloadData 会导致 tableView 跳动，推测和估算 self sizing cell/section 高度有关
            // https://meego.feishu.cn/larksuite/issue/detail/15265508
            UIView.performWithoutAnimation {
                self.sections = self.viewModel.sections
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
            }
        }
    }

    private func buildRowActionContext(row: SettingDisplayRow, indexPath: IndexPath, isOn: Bool, anchorView: UIView? = nil) -> SettingRowActionContext {
        SettingRowActionContext(source: self.viewModel.pageId, service: self.viewModel.service,
                                row: row, indexPath: indexPath, from: self, updator: self, isOn: isOn, anchorView: anchorView)
    }

    private func calcCeiledHeaderFooterHeight(with text: String, font: UIFont, layoutWidth: CGFloat) -> CGFloat {
        let attributedString = NSAttributedString(string: text,
                                                  attributes: [.font: font,
                                                               .foregroundColor: UIColor.ud.textPlaceholder])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        let height = attributedString.string.boundingRect(with: CGSize(width: CGFloat(layoutWidth),
                                                                       height: CGFloat(MAXFLOAT)),
                                                          options: .usesLineFragmentOrigin,
                                                          attributes: [.font: font,
                                                                       .paragraphStyle: paragraphStyle],
                                                          context: nil).height
        return ceil(height)
    }

    override var description: String {
        "\(super.description) \(viewModel.pageId)"
    }
}

extension SettingViewController: SettingViewModelDelegate {
    func requireUpdateSections() {
        self.reloadData()
    }
}

extension SettingViewController: SettingRowUpdatable {
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

extension SettingViewController: SettingSwitchCellDelegate {
    func didClickSwitchCell(_ cell: SettingSwitchCell, isOn: Bool) {
        guard let row = cell.row else { return }
        logger.info("[\(self.viewModel.pageId)] click switchCell \(row.item)")
        row.action?(buildRowActionContext(row: row, indexPath: cell.indexPath, isOn: isOn, anchorView: cell))
    }

    func didClickDisabledSwitchCell(_ cell: SettingSwitchCell, sender: UIView) {
        guard let row = cell.row else { return }
        logger.info("[\(self.viewModel.pageId)] click disabled switchCell \(row.item)")
        row.action?(buildRowActionContext(row: row, indexPath: cell.indexPath, isOn: row.isOn, anchorView: sender))
    }
}
