//
//  SearchTableController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/4.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift
import RxDataSources

let identiferSearchTableController = "SearchTableController"

/// Abstract class
class SearchTableController<Item>: UIViewController, UITableViewDelegate, UISearchControllerDelegate where Item: SearchTableItem {
    typealias Section = AnimatableSectionModel<String, Item>

    lazy var hintLabel = UILabel()
    lazy var tableView = UITableView()

    lazy var searchController = UISearchController()
    lazy var dataSource = configureDataSource()
    lazy var dataSubject = PublishSubject<[Section]>()
    // 首次加载到数据时需要通过此subject通知，以使搜索框尽快呈现
    lazy var hasDataSubject = PublishSubject<Bool>()

    let disposeBag = DisposeBag()
    // TODO: 不确定这个label会不会有问题
    let dispatchQueue = DispatchQueue(label: "SearchTableController", qos: .userInitiated)

    var hintText: String? {
        get { hintLabel.text }
        set { hintLabel.text = newValue }
    }
    var searchBar: UISearchBar { searchController.searchBar }
    var searchPlaceholder: String? {
        get { searchBar.placeholder }
        set { searchBar.placeholder = newValue }
    }
    open var shouldRegisterCell: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupRx()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    // MARK: - OVERRIDES

    func loadAllData() -> [Item] {
        fatalError("loadAllData() should be override")
    }

    func didSelected(item: Item, cell: UITableViewCell) {}
    func didRemoved(item: Item, cell: UITableViewCell) {}

    func accessorType(on item: Item) -> UITableViewCell.AccessoryType {
        .disclosureIndicator
    }

    func configureCell(
        dataSource: TableViewSectionedDataSource<Section>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: Section.Item
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: identiferSearchTableController, for: indexPath
        )

        if #available(iOS 14.0, *) {
            var configuration = cell.defaultContentConfiguration()
            configuration.text = item.title
            cell.contentConfiguration = configuration
        } else {
            cell.textLabel?.text = item.title
        }
        cell.accessoryType = accessorType(on: item)

        return cell
    }

    // MARK: - PRIVATES

    private func setupView() {
        hintLabel.text = "没有数据"
        hintLabel.textColor = .gray

        tableView.keyboardDismissMode = .onDrag
        if shouldRegisterCell {
            tableView.register(
                UITableViewCell.self, forCellReuseIdentifier: identiferSearchTableController
            )
        }

        searchController.hidesNavigationBarDuringPresentation = false
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = true
            searchController.searchBar.searchTextField.autocapitalizationType = .none
        }
        searchController.delegate = self

        view.backgroundColor = .white
        view.addSubview(hintLabel)
        view.addSubview(tableView)

        hintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    private func setupRx() {
        tableView.rx.itemSelected
            .bind { [weak self] indexPath in
                if let item = try? self?.dataSource.model(at: indexPath) as? Item,
                   let cell = self?.tableView.cellForRow(at: indexPath) {
                    // 用户选择item时再自动取消选择，即显示点击效果
//                    self?.tableView.deselectRow(at: indexPath, animated: true)
                    self?.didSelected(item: item, cell: cell)
                }
            }
            .disposed(by: disposeBag)

        // 创建数据流
        let dataStream = dataSubject
            .observeOn(MainScheduler.instance)
            .share(replay: 1)

        let isNotEmpty = hasDataSubject
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .share(replay: 1)

        // 有数据则隐藏hintLabel，添加搜索栏
        isNotEmpty.bind(to: hintLabel.rx.isHidden).disposed(by: disposeBag)
        isNotEmpty
            .bind { [weak self] in
                if $0 {
                    self?.addSearchController()
                } else {
                    self?.removeSearchController()
                }
            }
            .disposed(by: disposeBag)

        // 如果有数据，就用搜索栏的文本作为筛选，否则不筛选（用空字符串）
        let searchText = isNotEmpty
            .flatMap { [weak self] isNotEmpty in
                if let searchBar = self?.searchBar, isNotEmpty {
                    return searchBar.rx.text.orEmpty.asObservable()
                }
                return Observable.just("")
            }

        // 根据搜索框文本筛选数据
        Observable
            .combineLatest(searchText, dataStream) { keyword, sections in
                keyword.isEmpty ? sections : sections.compactMap { section in
                    let items = section.items.filter { item in
                        item.title.lowercased().contains(keyword.lowercased())
                    }
                    guard !items.isEmpty else { return nil }
                    return Section(original: section, items: items)
                }
            }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    func reloadData() {
        dispatchQueue.async { [weak self] in
            if let data = self?.loadAllData() {
                if data.isEmpty {
                    self?.hasDataSubject.onNext(false)
                }
                let section = Section(model: "", items: data)
                self?.dataSubject.onNext([section])
            }
        }
    }

    private func configureDataSource() -> RxTableViewSectionedReloadDataSource<Section> {
        RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] dataSource, tableView, indexPath, item in
                guard let self = self else { return UITableViewCell() }
                return self.configureCell(
                    dataSource: dataSource,
                    tableView: tableView,
                    indexPath: indexPath,
                    item: item
                )
            },
            canEditRowAtIndexPath: { (_, indexPath) in
                return true
            }
        )
    }

    private func addSearchController() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func removeSearchController() {
        navigationItem.searchController = nil
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] (_, _, completionHandler) in
            if let item = try? self?.dataSource.model(at: indexPath) as? Item,
               let cell = self?.tableView.cellForRow(at: indexPath) {
                self?.didRemoved(item: item, cell: cell)
            }
            self?.reloadData()
            completionHandler(true)
        }

        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    // MARK: - UISearchControllerDelegate

    func willPresentSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 13.0) {
            searchController.searchBar.setShowsCancelButton(true, animated: true)
        }
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        if #unavailable(iOS 13.0) {
            searchController.searchBar.setShowsCancelButton(false, animated: true)
        }
    }
}
#endif
