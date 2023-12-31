//
//  SectionSearchTableController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/9.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift
import RxDataSources

protocol TitledItem: IdentifiableType, Equatable where Identity == String.Identity {
    var title: String { get }
    var identity: String { get }
}

extension TitledItem {
    var identity: String { title }
}

protocol TitledSectionType: AnimatableSectionModelType where Item: TitledItem, Identity == String.Identity {
    var title: String { get }
    var identity: String { get }
}

extension TitledSectionType {
    var identity: String { title }
}

class SectionSearchTableController<Section, Cell>: UIViewController,
    UITableViewDelegate,
    UISearchControllerDelegate
where Section: TitledSectionType, Cell: UITableViewCell {
    lazy var tableView = UITableView(frame: self.view.frame, style: .grouped)
    lazy var searchController = UISearchController()
    lazy var dataSource = self.configureDataSource()
    lazy var dataSubject = PublishSubject<[Section]>()

    let disposeBag = DisposeBag()
    // TODO: 不确定这个label会不会有问题
    let dispatchQueue = DispatchQueue(label: "MMKVEditorController", qos: .userInitiated)

    var searchBar: UISearchBar { searchController.searchBar }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraints()
        setupRx()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }

    // MARK: - ABOUT UI

    private func setupView() {
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag

        view.backgroundColor = .white
        view.addSubview(tableView)

        searchController.hidesNavigationBarDuringPresentation = false
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = true
            searchController.searchBar.searchTextField.autocapitalizationType = .none
        }
        searchController.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
    }

    // MARK: - ABOUT RX

    private func setupRx() {
        // 原始数据流，之后可以考虑监测文件改动
        let dataStream = dataSubject.share(replay: 1)
        let filteredStream = filterObservable(dataStream)

        filteredStream
            .observeOn(MainScheduler.instance)
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .observeOn(MainScheduler.instance)
            .bind { [weak self] indexPath in
                guard let self = self else {
                    return
                }

                self.tableView.deselectRow(at: indexPath, animated: true)

                let section = self.dataSource[indexPath.section]
                let item = section.items[indexPath.item]
                self.didSelected(item: item, section: section)
            }
            .disposed(by: disposeBag)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
    }

    func filterObservable(_ dataStream: Observable<[Section]>) -> Observable<[Section]> {
        let searchText = searchBar.rx.text.orEmpty
        return Observable.combineLatest(searchText, dataStream) { text, data in
            if text.isEmpty {
                return data
            }
            return data.compactMap { section in
                let items = section.items.filter { item in
                    item.title.lowercased().contains(text.lowercased())
                }
                guard !items.isEmpty else { return nil }
                return Section(original: section, items: items)
            }
        }
    }

    func reloadData() {
        dispatchQueue.async { [weak self] in
            if let data = self?.loadAllData() {
                self?.dataSubject.onNext(data)
            }
        }
    }

    private func configureDataSource() -> RxTableViewSectionedReloadDataSource<Section> {
        RxTableViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] dataSource, tableView, indexPath, item in
                guard let self = self else { return Cell() }
                return self.configureCell(
                    dataSource: dataSource, tableView: tableView, indexPath: indexPath, item: item
                )
            },
            titleForHeaderInSection: { dataSource, section in
                dataSource[section].title
            }
        )
    }

    // MARK: - TO OVERRIDE METHODS

    func loadAllData() -> [Section] {
        fatalError("loadlAllData() should be override")
    }

    func didSelected(item: Section.Item, section: Section) {}

    class func dequeueReusableCell(
        tableView: UITableView, withIdentifier identifier: String, for indexPath: IndexPath
    ) -> Cell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? Cell
        return cell ?? Cell()
    }

    func configureCell(
        dataSource: TableViewSectionedDataSource<Section>,
        tableView: UITableView,
        indexPath: IndexPath,
        item: Section.Item
    ) -> Cell {
        fatalError("this function should be override")
    }

    // MARK: - UITableViewDelegate

    // 空实现协议中的此方法，以便于子类继承
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    }

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
