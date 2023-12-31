//
//  CustomerVC.swift
//  LarkContact
//
//  Created by SolaWing on 2020/11/9.
//

import UIKit
import Foundation
import LarkUIKit
import LarkSearchCore
import RxSwift
import LarkModel
import LarkFeatureGating

final class CustomerVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // 别名 FG
    @FeatureGating("lark.chatter.name_with_another_name_p2") private var isSupportAnotherNameFG: Bool
    weak var selectionSource: SelectionDataSource?
    var viewModel: CustomerSelectViewModel
    struct Config {
        var openMyGroups: (CustomerVC) -> Void
    }
    let config: Config
    init(viewModel: CustomerSelectViewModel, config: Config, selectionSource: SelectionDataSource) {
        self.viewModel = viewModel
        self.config = config
        self.selectionSource = selectionSource
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let tableView: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        // 表格
        tableView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        tableView.separatorStyle = .none
        tableView.rowHeight = 68
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: "ContactTableViewCell")
        tableView.register(EmptyContactCell.self, forCellReuseIdentifier: "EmptyContactCell")
        tableView.register(DataItemViewCell.self, forCellReuseIdentifier: "DataItemViewCell")

        self.view.addSubview(tableView)

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.frame = view.bounds

        bindVM()
    }
    func bindVM() {
        viewModel.updateDriver
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)

        selectionSource?.isMultipleChangeObservable.distinctUntilChanged().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        selectionSource?.selectedChangeObservable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.viewModel.chatters.isEmpty {
            return 2
        } else {
            return self.viewModel.chatters.count + 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return self.viewModel.dataInFirstSection.count }
        if self.viewModel.chatters.isEmpty { return 1 }
        return self.viewModel.chatters[section - 1].elements.count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 { return nil }
        if self.viewModel.chatters.isEmpty { return UIView() }
        let view = UIView()
        let text = self.viewModel.chatters[section - 1].key
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N900

        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(70)
            make.centerY.equalToSuperview()
        }

        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 { return 0.01 }
        if self.viewModel.chatters.isEmpty { return 0.01 }
        return 24
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section != 0 && self.viewModel.chatters.isEmpty {
            return 220
        }
        if indexPath.section == 0 {
            return 51
        }
        return 68
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return self.tableView(tableView, rowInSectionZero: indexPath.row)
        } else if self.viewModel.chatters.isEmpty {
            return self.tableViewEmptyContact(tableView)
        } else {
            return self.tableView(tableView, contactInIndex: IndexPath(row: indexPath.row, section: indexPath.section - 1))
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            let data = self.viewModel.dataInFirstSection[indexPath.row]
            switch data.type {
            case .group: config.openMyGroups(self)
            default:
                break
            }
            return
        } else if self.viewModel.chatters.isEmpty { return }

        let chatter = self.viewModel.chatters[indexPath.section - 1].elements[indexPath.row]
        selectionSource?.toggle(option: chatter, from: self)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.viewModel.chatters.isEmpty { return nil }
        return self.viewModel.chatters.map { $0.key }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index + 1
    }

    private func tableView(_ tableView: UITableView, rowInSectionZero row: Int) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DataItemViewCell") as? DataItemViewCell {
            let data = self.viewModel.dataInFirstSection[row]
            cell.dataItem = data
            return cell
        }
        assertionFailure()
        return UITableViewCell(frame: .zero)
    }

    private func tableViewEmptyContact(_ tableView: UITableView) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyContactCell") as? EmptyContactCell {
            return cell
        }
        assertionFailure()
        return UITableViewCell(frame: .zero)
    }

    private func tableView(_ tableView: UITableView, contactInIndex index: IndexPath) -> UITableViewCell {
        let multiStatusBlock: (Chatter) -> ContactCheckBoxStaus = { [weak self] chatter in
            guard let self = self, let selectionSource = self.selectionSource, selectionSource.isMultiple else { return .invalid }
            return selectionSource.state(for: chatter, from: self).asContactCheckBoxStaus
        }

        if let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell") as? ContactTableViewCell {
            let chatter = self.viewModel.chatters[index.section].elements[index.row]
            var item = ContactTableViewCellProps(user: chatter, isSupportAnotherName: isSupportAnotherNameFG)
            item.checkStatus = multiStatusBlock(chatter)
            item.description = self.viewModel.tenantMap[chatter.tenantId]
            cell.setProps(item)
            return cell
        }
        assertionFailure()
        return UITableViewCell(frame: .zero)
    }
}
