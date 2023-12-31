//
//  SCDebugViewController.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/16.
//

import UIKit
import EENavigator
import LarkContainer
import LarkSecurityComplianceInfra

public class SCDebugViewController: UIViewController {
    static let historyKey = "sc_debug_vc_history_search"
    let sectionList = SCDebugSectionType.casesForDebugEntrance
    let resolver: UserResolver
    let debugEntrance: SCDebugEntrance
    let userStorage: SCKeyValueStorage

    private var searchHistory: String? {
        didSet {
            searchController.searchBar.placeholder = searchHistory ?? "请输入"
        }
    }

    private lazy var filtedSectionList = sectionList {
        didSet {
            tableView.reloadData()
        }
    }

    private let tableView = SCDebugTableView(frame: .zero)

    private let searchController: UISearchController

    public init(resolver: UserResolver) throws {
        self.resolver = resolver
        self.debugEntrance = try resolver.resolve(assert: SCDebugEntrance.self)
        debugEntrance.config()
        self.userStorage = SCKeyValue.userDefault(userId: resolver.userID)
        self.searchController = UISearchController(searchResultsController: nil)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "安全 & 合规"

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tableView.dataSource = self
        tableView.delegate = self
        searchHistory = userStorage.string(forKey: Self.historyKey)
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        tableView.setContentOffset(.init(x: 0, y: 200), animated: true)
    }
}

extension SCDebugViewController: UITableViewDataSource, UITableViewDelegate {
    // 返回单元格行数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtedSectionList.count
    }

    // 配置并返回单元格
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let model = filtedSectionList[indexPath.row]
        cell.textLabel?.text = model.name
        return cell
    }

    // MARK: UITableViewDelegate Method
    // 选中单元格时触发对应的调试页面跳转事件
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = filtedSectionList[indexPath.row]
        let sectionViewModels = debugEntrance.generateSectionViewModels(section: section)
        let redirector = debugEntrance.generateRedirectorForSection(section: section)
        if searchController.isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                redirector(sectionViewModels, section.name)
            }
        }
        else {
            redirector(sectionViewModels, section.name)
        }
        searchController.isActive = false
    }
}

extension SCDebugViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchHistory = searchText
        userStorage.set(searchHistory, forKey: Self.historyKey)
        filtedSectionList = sectionList.filter { searchInSectionModel(sectionType: $0, searchKey: searchText) }
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let searchHistory else { return }
        searchBar.text = searchHistory
        filtedSectionList = sectionList.filter { searchInSectionModel(sectionType: $0, searchKey: searchHistory) }
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchHistory = nil
        userStorage.removeObject(forKey: Self.historyKey)
        searchBar.text = nil
        filtedSectionList = sectionList
    }

    private func searchInSectionModel(sectionType: SCDebugSectionType, searchKey: String) -> Bool {
        if sectionType.name.fuzzyMatch(searchKey) { return true }
        let debugModelList = debugEntrance.generateSectionViewModels(section: sectionType)
        return debugModelList.contains(where: { $0.cellTitle.fuzzyMatch(searchKey)})
    }
}
