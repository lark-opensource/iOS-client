//
//  LarkGuideDebugController.swift
//  LarkGuide
//
//  Created by zhenning on 2020/12/10.
//

import UIKit
import Foundation
import LarkUIKit
import LarkActionSheet
import LarkContainer

final class LarkGuideDebugController: BaseUIViewController,
UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    @InjectedLazy private var newGuideManager: NewGuideService
    // 数据源
    private var guideDebugDataSouce: [String: GuideDebugInfo] = [:]
    private var guideDebugDataKeys: [String] {
        return guideDebugDataSouce.map { $0.key }.sorted(by: <)
    }
    // 本都缓存
    private var guideCacheData: [String: GuideDebugInfo] = [:]
    private var guideCacheDataKeys: [String] {
        return guideCacheData.map { $0.key }.sorted(by: <)
    }

    // 过滤字段
    private var filter: String = ""

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView = nil
        tableView.tableFooterView = nil
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GuideDebugCell.self, forCellReuseIdentifier: "GuideDebugCell")
        return tableView
    }()

    private lazy var searchTextField: UISearchBar = {
        let searchTextField = UISearchBar()
        searchTextField.placeholder = "过滤内容..."
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        return searchTextField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        reloadPageByLocalData()
    }

    private func setupUI() {
        self.setupNaviBar()
        self.view.addSubview(self.searchTextField)
        self.searchTextField.snp.makeConstraints { (make) in
            make.top.equalTo(self.viewTopConstraint)
            make.right.left.equalToSuperview()
            make.height.equalTo(44)
        }
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchTextField.snp.bottom)
            make.right.left.equalToSuperview()
            make.bottom.equalTo(self.viewBottomConstraint)
        }
    }

    private func setupNaviBar() {
        self.title = "LarkGuide Data"
        self.addCloseItem()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(fetchGuideDataFromServer))
    }

    // 获取原本地的缓存配置
    private func reloadPageByLocalData() {
        refreshDebugInfoByLocalData()
        reloadDebugTable(filter: self.filter)
    }

    // 使用本地缓存
    private func refreshDebugInfoByLocalData() {
        self.guideCacheData = newGuideManager.getLocalUserGuideInfoCache()
            .reduce(into: [String: GuideDebugInfo]()) { (dict, guideDebugInfo) in
                dict[guideDebugInfo.key] = guideDebugInfo
            }
        self.guideDebugDataSouce = self.guideCacheData
    }

    @objc
    private func fetchGuideDataFromServer() {
        // fetch guide
        newGuideManager.fetchUserGuideInfos(finish: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.reloadPageByLocalData()
        }
    }

    private func filterDataSource(filter: String) {
        if filter.isEmpty {
            refreshDebugInfoByLocalData()
        } else {
            var tempCache: [String: GuideDebugInfo] = [:]
            self.guideCacheDataKeys.forEach { (guideKey) in
                let guideInfo = self.guideCacheData[guideKey]
                if guideKey.lowercased().contains(filter.lowercased()) {
                    tempCache[guideKey] = guideInfo
                }
            }
            self.guideDebugDataSouce = tempCache
        }
    }

    private func reloadDebugTable(filter: String) {
        filterDataSource(filter: filter)
        self.tableView.reloadData()
    }

// MARK: - UITableViewDataSource, UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.guideDebugDataKeys.count
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let guideDebugCell = tableView
                .dequeueReusableCell(withIdentifier: "GuideDebugCell", for: indexPath) as? GuideDebugCell else {
                return UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let currKey = self.guideDebugDataKeys[indexPath.row]
        guideDebugCell.titleLabel.text = currKey
        guideDebugCell.valueLabel.text = "\(self.guideDebugDataSouce[currKey]?.canShow ?? false)"
        return guideDebugCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        let currKey = self.guideDebugDataKeys[indexPath.row]
        let actionSheet = ActionSheet()
        // can show
        actionSheet.addItem(title: "true", textColor: UIColor.ud.textTitle) { [weak self] in
            guard let self = self else { return }
            // update guide
            self.newGuideManager.setGuideInfoOfLocalCache(guideKey: currKey, canShow: true)
            self.reloadDebugTable(filter: self.filter)
        }
        // hide
        actionSheet.addItem(title: "false", textColor: UIColor.ud.textTitle) { [weak self] in
            guard let self = self else { return }
            // update guide
            self.newGuideManager.setGuideInfoOfLocalCache(guideKey: currKey, canShow: false)
            self.reloadDebugTable(filter: self.filter)
        }
        actionSheet.addCancelItem(title: "取消", textColor: UIColor.ud.textTitle)
        self.present(actionSheet, animated: true, completion: nil)
    }

// MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.filter = searchText
        reloadDebugTable(filter: self.filter)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        self.filter = searchBar.text ?? ""
        reloadDebugTable(filter: self.filter)
    }
}
