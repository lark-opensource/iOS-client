//
//  NavigationDebugViewController.swift
//  LarkNavigation
//
//  Created by KT on 2020/7/4.
//

import Foundation
import UIKit
import SnapKit
import Swinject
import AnimatedTabBar
import LarkFeatureGating
import BootManager
import LarkTab
import LarkStorage

final class NavigationDebugViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var navi: [[Tab]] = []
    private let initialNavi: [[Tab]]
    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
        let navi = resolver.resolve(NavigationService.self)!
        self.initialNavi = [navi.mainTabs, navi.quickTabs]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.loadData()
    }

    private lazy var table: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 45
        tableView.sectionHeaderHeight = 25
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(Header.self, forHeaderFooterViewReuseIdentifier: "header")
        tableView.tableFooterView = Footer(onConfirm: { [weak self] in
            self?.store()
        }, onClear: { [weak self] in
            self?.loadData()
        })
        return tableView
    }()

    private func setupViews() {
        self.view.addSubview(self.table)
        self.table.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.table.setEditing(true, animated: true)
    }

    private func loadData() {
        self.navi = self.initialNavi
        self.table.reloadData()
    }

    private func store() {
        let (key, store) = (KVKeys.Navigation.debugLocalTabs, KVStores.Navigation.buildGlobal())
        if self.navi == self.initialNavi {
            store.removeValue(forKey: key)
        } else {
            store[key] = self.navi.map { $0.map(\.key) }
        }
        store.synchronize()
        exit(0)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.navi.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.navi[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else {
            return UITableViewCell()
        }
        cell.textLabel?.text = self.navi[indexPath.section][indexPath.row].tabName
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? Header else {
            return nil
        }
        header.label.text = section == 0 ? "主导航(3-5个，必须包含Feed)" : "快捷导航"
        return header
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        let last = self.navi[sourceIndexPath.section][sourceIndexPath.row]
        self.navi[sourceIndexPath.section].lf_remove(object: last)
        self.navi[destinationIndexPath.section].insert(last, at: destinationIndexPath.row)
        self.table.reloadData()
    }

    func tableView(_ tableView: UITableView,
                   targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section == 0,
            sourceIndexPath.section != 0,
            tableView.numberOfRows(inSection: 0) >= 5 {
            return sourceIndexPath
        }
        // MainTab不能少于3个
        if sourceIndexPath.section == 0, tableView.numberOfRows(inSection: 0) <= 3 {
            return sourceIndexPath
        }
        // Feed只能在MainTab
        if self.navi[sourceIndexPath.section][sourceIndexPath.row] == Tab.feed,
            proposedDestinationIndexPath.section != 0 {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }
}

final class Header: UITableViewHeaderFooterView {
    let label = UILabel()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.bottom.right.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class Footer: UIView {
    typealias Action = () -> Void
    private let onConfirm: Action
    private let onClear: Action

    init(onConfirm: @escaping Action, onClear: @escaping Action) {
        self.onConfirm = onConfirm
        self.onClear = onClear
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 200))

        self.clearBtn.setTitle("重置", for: .normal)
        self.clearBtn.setTitleColor(.black, for: .normal)
        self.confirmBtn.setTitle("确认(重启生效)", for: .normal)
        self.confirmBtn.setTitleColor(.systemRed, for: .normal)
        self.addSubview(self.clearBtn)
        self.addSubview(self.confirmBtn)
        self.clearBtn.backgroundColor = .groupTableViewBackground
        self.confirmBtn.backgroundColor = .groupTableViewBackground

        self.clearBtn.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(45)
            make.top.equalToSuperview().offset(20)
        }
        self.confirmBtn.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(45)
            make.top.equalTo(self.clearBtn.snp.bottom).offset(20)
        }

        self.clearBtn.addTarget(self, action: #selector(clear), for: .touchUpInside)
        self.confirmBtn.addTarget(self, action: #selector(confirm), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clear() { self.onClear() }

    @objc
    private func confirm() { self.onConfirm() }

    private let clearBtn = UIButton(type: .custom)
    private let confirmBtn = UIButton(type: .custom)
}
