//
//  MineTranslateLanguageListController.swift
//  LarkMine
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import EENavigator
import FigmaKit

private enum TableViewType: Int {
    case list = 1
    case searchResult
}

/// 翻译语言列表
final class MineTranslateLanguageListController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let viewModel: MineTranslateLanguageListViewModel
    private let disposeBag = DisposeBag()
    private var searchTextField = SearchUITextField()
    private lazy var tableView = self.createTableView(.list)
    private lazy var resultTable = self.createTableView(.searchResult)

    init(viewModel: MineTranslateLanguageListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.viewModel.detailModelType == .translateStyleEffect
            ? BundleI18n.LarkMine.Lark_NewSettings_SetByLanguageTranslationDisplay
            : BundleI18n.LarkMine.Lark_NewSettings_AutoTranslation

        // 初始化searchBar
        searchTextField.backgroundColor = .ud.bgFloat
        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkMine.Lark_NewSettings_SetByLanguageSearchLanguage
        searchTextField.addTarget(self, action: #selector(inputViewTextFieldDidChange), for: .editingChanged)
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(18)
            make.height.equalTo(36)
        })
        searchTextField.layer.cornerRadius = 10

        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(searchTextField.snp.bottom).offset(8)
        }
        self.tableView.contentInsetAdjustmentBehavior = .never

        self.resultTable.isHidden = true
        self.view.addSubview(self.resultTable)
        self.resultTable.snp.makeConstraints { (make) in
            make.edges.equalTo(self.tableView.snp.edges)
        }
        self.resultTable.contentInsetAdjustmentBehavior = .never

        /// 每次到列表页时，拉取下最新的翻译设置
        self.viewModel.fetchTranslateServerLanguageSetting()

        self.viewModel.refreshDriver.drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.tableView.reloadData()
            self.search(query: self.searchTextField.text)
        }).disposed(by: self.disposeBag)
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewWillDisappear(_ animated: Bool) {
        searchTextField.resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    private func createTableView(_ type: TableViewType) -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 74
        tableView.estimatedSectionHeaderHeight = (type == .list) ? 42 : 0
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.tag = type.rawValue
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: MineTranslateLanguageCell.self)
        return tableView
    }

    @objc
    private func inputViewTextFieldDidChange() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(searchTextChangedHandler), object: nil)
        self.perform(#selector(searchTextChangedHandler), with: nil, afterDelay: 0.3)
    }

    @objc
    private func searchTextChangedHandler() {
        guard searchTextField.markedTextRange == nil else { return }
        let query = searchTextField.text ?? ""
        self.resultTable.isHidden = query.isEmpty
        search(query: query)
    }

    func search(query: String?) {
        guard let query = query, !query.isEmpty else { return }
        self.viewModel.updateSearchResult(filterKey: query)
        self.resultTable.reloadData()
    }

    func getTableDataSource(tableView: UITableView) -> [MineTranslateLanguageModel] {
        guard let type = TableViewType(rawValue: tableView.tag) else { return [] }
        switch type {
        case .list:
            return self.viewModel.items
        case .searchResult:
            return self.viewModel.searchResultItems
        }
    }

// MARK: - TableViewDataSource

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let type = TableViewType(rawValue: tableView.tag) else { return nil }
        switch type {
        case .list:
            return self.viewModel.headerViews[section]()
        case .searchResult:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getTableDataSource(tableView: tableView).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let items = getTableDataSource(tableView: tableView)
        let item: MineTranslateLanguageModel = items[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? MineTranslateBaseCell {
            cell.item = item
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let items = getTableDataSource(tableView: tableView)
        let selectedItem = items[indexPath.row]
        let viewModel = MineTranslateLanguageDetailViewModel(
            userResolver: self.viewModel.userResolver,
            userGeneralSettings: self.viewModel.userGeneralSettings,
            srcLanguageModel: selectedItem,
            currGloabalScopes: self.viewModel.currGloabalScopes,
            detailModelType: self.viewModel.detailModelType)
        let vc = MineTranslateLanguageDetailController(viewModel: viewModel)
        self.viewModel.userNavigator.push(vc, from: self)
    }
}
