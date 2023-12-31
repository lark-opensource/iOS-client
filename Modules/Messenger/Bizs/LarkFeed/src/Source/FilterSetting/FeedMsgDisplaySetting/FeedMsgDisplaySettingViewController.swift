//
//  FeedMsgDisplaySettingViewController.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/20.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import FigmaKit
import UniverseDesignToast

final class FeedMsgDisplaySettingViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    let viewModel: FeedMsgDisplaySettingViewModel
    let defaultCellIdentifier = "FeedMsgDisplayDefaultCellIdentifier"
    let disposeBag = DisposeBag()

    let tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.lu.register(cellSelf: FeedMsgDisplayCell.self)
        tableView.lu.register(cellSelf: FeedMsgDisplayCheckBoxCell.self)
        tableView.register(HeaderViewWithTitle.self, forHeaderFooterViewReuseIdentifier: HeaderViewWithTitle.identifier)
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.separatorStyle = .none
        return tableView
    }()

    // 右上保存按钮
    lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkFeed.Lark_FeedFilter_Done_Button, fontStyle: .medium)
        item.addTarget(self, action: #selector(saveFilterEditor), for: .touchUpInside)
        item.setBtnColor(color: UIColor.ud.primaryContentDefault)
        return item
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(viewModel: FeedMsgDisplaySettingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
    }

    private func setupViews() {
        self.title = viewModel.getNavTitle()
        self.navigationItem.rightBarButtonItem = self.saveButtonItem
        addCancelItem()

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override func closeBtnTapped() {
        super.closeBtnTapped()
    }

    @objc
    func saveFilterEditor() {
        viewModel.saveOptions()
        closeBtnTapped()
    }

    private func bind() {
        viewModel.reloadDataDriver.drive(onNext: { [weak self] in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        viewModel.hudShowDriver.drive(onNext: { [weak self] text in
            guard !text.isEmpty else { return }
            guard let window = self?.view.window else {
                assertionFailure("cannot find window")
                return
            }
            UDToast.showTips(with: text, on: window)
        }).disposed(by: disposeBag)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < viewModel.sections.count else { return 0 }
        let sectionVM = viewModel.sections[section]
        return sectionVM.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < viewModel.sections.count else {
            return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
        }
        let sectionVM = viewModel.sections[indexPath.section]

        guard indexPath.row < sectionVM.rows.count else {
            return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
        }
        var item = sectionVM.rows[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? FeedMsgDisplayCell {
            item.isLastRow = indexPath.row == sectionVM.rows.count
            cell.item = item
            return cell
        }

        return UITableViewCell(style: .default, reuseIdentifier: defaultCellIdentifier)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < viewModel.sections.count else { return UIView() }
        let sectionVM = viewModel.sections[section]

        guard !sectionVM.headerIdentifier.isEmpty,
           let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionVM.headerIdentifier) as? FeedFilterSectionHeaderProtocol else {
            return UIView()
        }
        sectionHeader.setText(sectionVM.headerTitle, sectionVM.headerSubTitle)
        sectionHeader.setTitleLabelLeadingOffset(0.0)
        return sectionHeader
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.section < viewModel.sections.count else { return }
        let sectionVM = viewModel.sections[indexPath.section]
        guard indexPath.row < sectionVM.rows.count else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        var selectRow = sectionVM.rows[indexPath.row]
        viewModel.updateOptions(selectRow.type)
    }
}
