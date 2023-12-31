//
//  PickerRecommendListView.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/5/17.
//

import Foundation
import RxSwift
import LarkListItem
import LarkModel
import LarkCore
import LarkUIKit
import LarkContainer
import LarkFocusInterface

final public class PickerRecommendListView: UIView, PickerDefaultViewType, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    var featureConfig = PickerFeatureConfig() {
        didSet {
            self.transformer.accessoryTransformer = PickerItemAccessoryTransformer(isOpen: featureConfig.targetPreview.isOpen)
        }
    }

    var searchConfig = PickerSearchConfig() {
        didSet {
            PickerLogger.shared.info(module: PickerLogger.Module.recommend, event: "recommend search config") {
                do {
                    let searchData = try JSONEncoder().encode(self.searchConfig)
                    let searchString = String(data: searchData, encoding: .utf8) ?? ""
                    return searchString
                } catch {
                    return "error: \(error.localizedDescription)"
                }
            }
            self.searchProvider.searchConfig = searchConfig
        }
    }

    var didPresentTargetPreviewHandler: ((PickerItem) -> Void)?

    private let identifier = "ItemTableViewCell"

    var listView: SearchResultView = SearchResultView(tableStyle: .plain)
    private weak var picker: SearchPickerView?

    private var context = PickerContext()
    private var isOpenMulti = false
    private var tenantId = ""

    private var searchProvider: PickerSearchProvider
    private var statusService: PickerFocusStatusService?
    private var usingProvider: PickerRecommendLoadable
    private var providerMap = [String: PickerRecommendLoadable]()
    private let disposeBag = DisposeBag()
    private var loadDisposeBag = DisposeBag()
    private var items = [PickerItem]()
    private lazy var transformer = PickerItemTransformer(accessoryTransformer: PickerItemAccessoryTransformer(isOpen: self.featureConfig.targetPreview.isOpen))

    // MARK: - Public
    public init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
        self.searchProvider = PickerSearchProvider(resolver: resolver)
        self.usingProvider = self.searchProvider
        super.init(frame: .zero)
    }

    /// 添加自定义加载器, 并切换至该加载器
    /// - Parameters:
    ///   - provider: 加载器
    ///   - key: 加载器绑定的key, 用于切换
    public func add(provider: PickerRecommendLoadable, for key: String) {
        providerMap[key] = provider
        self.usingProvider = provider
    }

    /// 切换至指定的加载器
    /// - Parameter key: 加载器绑定的key, 不传时切换到默认的空搜加载器
    public func switchProvider(by key: String? = nil) {
        guard let key = key else {
            self.usingProvider = searchProvider
            return
        }
        guard let provider = providerMap[key] else { return }
        self.usingProvider = provider
    }

    public func reload() {
        self.loadDisposeBag = DisposeBag() // 清除之前的订阅
        load()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        listView.tableview.dataSource = self
        listView.tableview.delegate = self
        addSubview(listView)
        listView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        listView.tableview.register(ItemTableViewCell.self, forCellReuseIdentifier: identifier)
        listView.tableview.rowHeight = UITableView.automaticDimension
        listView.tableview.estimatedRowHeight = 68
    }
    // MARK: - Bind Picker
    public func bind(picker: SearchPickerView) {
        render()
        self.picker = picker
        self.context = picker.context
        self.isOpenMulti = picker.isMultiple
        self.tenantId = context.tenantId
        picker.isMultipleChangeObservable.observeOn(MainScheduler.instance)
            .subscribe { [weak self] in
                self?.isOpenMulti = $0
                self?.listView.tableview.reloadData()
            }.disposed(by: disposeBag)
        picker.selectedChangeObservable.observeOn(MainScheduler.instance)
            .subscribe { [weak self] _ in
                self?.listView.tableview.reloadData()
            }.disposed(by: disposeBag)
        load()
    }

    private func load() {
        self.listView.status = .loading
        self.endLoadMore(hasMore: false)
        usingProvider.load().observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self = self else { return }
                self.items = result.items
                self.listView.status = self.items.isEmpty ? .noResult("") : .result
                self.listView.tableview.reloadData()
                if !self.items.isEmpty {
                    self.listView.tableview.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
                }
                if result.hasMore { self.addLoadMore() } // 添加loadMore
            } onError: { error in
                PickerLogger.shared.info(module: PickerLogger.Module.recommend, event: "recommend load failed: \(error.localizedDescription)")
                self.listView.status = .failed("")
            }.disposed(by: self.loadDisposeBag)
    }

    private func loadMore() {
        usingProvider.loadMore().observeOn(MainScheduler.instance)
            .subscribe { [weak self] result in
                guard let self = self else { return }
                if result.isPage {
                    self.items.append(contentsOf: result.items)
                } else {
                    self.items = result.items
                }
                self.listView.status = .result
                self.listView.tableview.reloadData()
                self.endLoadMore(hasMore: result.hasMore)
            } onError: { error in
                PickerLogger.shared.info(module: PickerLogger.Module.recommend, event: "recommend load more failed: \(error.localizedDescription)")
                // load more 报错目前不处理, 保留已加载的内容
            }.disposed(by: self.loadDisposeBag)
    }

    private func addLoadMore() {
        listView.tableview.addBottomLoadMoreView { [weak self] in
            self?.loadMore()
        }
    }

    private func endLoadMore(hasMore: Bool) {
        listView.tableview.endBottomLoadMore(hasMore: hasMore)
    }

    private func getCurrentStatusService(userId: String?) -> PickerFocusStatusService? {
        if userId == self.statusService?.userId {
            return self.statusService
        }
        self.statusService = PickerFocusStatusService(userId: userId)
        return self.statusService
    }
}

extension PickerRecommendListView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = items[indexPath.row]
        let state = picker?.state(for: result, from: self, category: .emptySearch) ?? .normal
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        if let pickerCell = cell as? ItemTableViewCell {
            pickerCell.delegate = self
            let item = result
            let checkBox = ListItemNode.CheckBoxState(isShow: isOpenMulti, isSelected: state.selected, isEnable: !state.disabled)
            pickerCell.context.userId = context.userId
            pickerCell.context.statusService = getCurrentStatusService(userId: context.userId)
            let node = transformer.transform(indexPath: indexPath, item: item, checkBox: checkBox)
            pickerCell.node = node
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        _ = picker?.toggle(option: item, from: self)
    }
}

extension PickerRecommendListView: ItemTableViewCellDelegate {
    public func listItemDidClickAccessory(type: ListItemNode.AccessoryType, at indexPath: IndexPath) {
        guard type == .targetPreview else { return }
        let item = items[indexPath.row]
        self.didPresentTargetPreviewHandler?(item)
    }
}
