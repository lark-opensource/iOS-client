//
//  SearchChatPickerViewController.swift
//  LarkSearch
//
//  Created by SuPeng on 4/24/19.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import RxSwift
import LarkModel
import LarkMessengerInterface
import SnapKit
import LarkSearchFilter
import LarkAccountInterface
import LarkSDKInterface
import LarkSearchCore
import LarkTraitCollection
import LarkOpenFeed
import LarkStorage
import LarkContainer

final class SearchChatPickerViewController: BaseUIViewController, UICollectionViewDelegate,
    UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, SearchResultViewListBindDelegate {
    var didFinishChooseItem: ((SearchChatPickerViewController, [SearchChatPickerItem]) -> Void)?

    private let searchAPI: SearchAPI
    private var selectMode: SearchChatPickerSelectMode
    private var selectedItems: [SearchChatPickerItem] {
        didSet {
            updateSelectedItems(selectedItems, oldValue: oldValue)
        }
    }
    private var originResults: [SearchChatPickerItem] = []
    private var showData: [SearchChatPickerItem] { return listState == .empty ? originResults : results }
    private let currentAccount: User

    // Navibar
    private var closeOrBackItem: UIBarButtonItem?
    private let sureButton = UIButton()
    private var sureItem: UIBarButtonItem { return UIBarButtonItem(customView: sureButton) }
    private let cancelItem = LKBarButtonItem(title: BundleI18n.LarkSearch.Lark_Legacy_Cancel)
    private let multiSelectItem = LKBarButtonItem(title: BundleI18n.LarkSearch.Lark_Legacy_Select)

    private let searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField { return searchWrapper.searchUITextField }
    private var lastQuery: String?

    private let selectedCollectionLayout = UICollectionViewFlowLayout()
    private let selectedCollectionView: UICollectionView

    private var itemsTableTop: Constraint!
    private var itemsTableView: UITableView { return resultView.tableview }

    private let disposeBag = DisposeBag()
    #if DEBUG || INHOUSE || ALPHA
    // debug悬浮按钮
    private let debugButton: ASLFloatingDebugButton
    #endif

    private let pickType: ChatFilterMode
    let userResolver: LarkContainer.UserResolver

    init(resolver: LarkContainer.UserResolver,
         selectedItems: [SearchChatPickerItem],
         searchAPI: SearchAPI,
         feedService: FeedSyncDispatchService,
         currentAccount: User,
         pickType: ChatFilterMode = .unlimited) {
        self.userResolver = resolver
        self.selectedItems = selectedItems
        self.selectMode = selectedItems.isEmpty ? .single : .multi
        self.searchAPI = searchAPI
        self.currentAccount = currentAccount
        self.pickType = pickType
        // 话题与消息区分开后，选择所在会话时需要区分小组/普通会话
        var chatTypes: [Chat.ChatMode]?
        switch pickType {
        case .normal:
            chatTypes = [.default]
        case .thread:
            chatTypes = [.thread, .threadV2]
        @unknown default:
            break
        }
        self.selectedCollectionView = UICollectionView(frame: .zero,
                                                       collectionViewLayout: selectedCollectionLayout)
        #if DEBUG || INHOUSE || ALPHA
        self.debugButton = ASLFloatingDebugButton()
        #endif
        super.init(nibName: nil, bundle: nil)

        feedService.topInboxChats(by: 20, chatType: chatTypes, needChatBox: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chats in
                self?.originResults = chats.map { .init(chat: $0) }
                self?.itemsTableView.reloadData()
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: SearchResultViewListBindDelegate
    typealias Item = SearchChatPickerItem
    var listvm: ListVM { vm.result }
    var resultView = SearchResultView(tableStyle: .plain, noResultView: nil)

    var listState: SearchListStateCases?
    var results: [Item] = []

    var searchLocation: String { "choose_chat" } /// 这个字段没找到详细文档，可能只是用于区分页面的。暂时填choose_chat

    private lazy var vm: SearchSimpleVM<Item> = {
        func makeSource(searchAPI: SearchAPI) -> SearchSource {
            // 小组tab下的“所在小组过滤器”，只允许搜索出小组群；searchHadChatHistoryScene会搜索出群+人（因为人也可看做是p2p的会话）
            let scene: SearchSceneSection = pickType == .thread ? .searchThreadOnly : .rustScene(.searchHadChatHistoryScene)
            var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: scene)
            maker.needSearchOuterTenant = true
            maker.includeBot = true
            maker.excludeUntalkedChatterBot = true
            maker.doNotSearchResignedUser = true
            maker.chatFilterMode = [pickType]
            maker.includeCrypto = false
            return maker.makeAndReturnProtocol()
        }
        let source = makeSource(searchAPI: self.searchAPI)
        let listvm = SearchListVM(source: source, pageCount: 20, compactMap: { (result: Search.Result) -> SearchChatPickerViewController.Item? in
            #if DEBUG || INHOUSE || ALPHA
            if let aslContextID = result.contextID {
                DispatchQueue.main.async {
                    self.debugButton.updateTitle(ContextID: aslContextID)
                }
            }
            #endif
            return result.convertToChatPickerItem()
        })
        return SearchSimpleVM(result: listvm)
    }()

    public func showPlaceholder(state: ListVM.State) {
        assert(listState == .empty)
        resultView.status = .result
        itemsTableView.reloadData()
    }
    public func hidePlaceholder(state: ListVM.State) {
        assert(listState != .empty)
        itemsTableView.reloadData()
    }

    // MARK: UI
    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.LarkSearch.Lark_Legacy_SelectLark

        defer {
            updateSelectedItems(selectedItems)
        }
        sureButton.addTarget(self, action: #selector(didTapSure), for: .touchUpInside)
        sureButton.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .disabled)
        sureButton.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        sureButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        sureButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        sureButton.contentHorizontalAlignment = .right

        cancelItem.setProperty(font: UIFont.systemFont(ofSize: 16))
        cancelItem.setBtnColor(color: UIColor.ud.textTitle)
        cancelItem.button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)

        multiSelectItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .right)
        multiSelectItem.setBtnColor(color: UIColor.ud.textTitle)
        multiSelectItem.button.addTarget(self, action: #selector(didTapMultiSelect), for: .touchUpInside)

        configNaviBar(aniamte: false)

        searchWrapper.searchUITextField.autocorrectionType = .no
        view.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }

        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkSearch.Lark_Legacy_Search
        searchTextField.rx.text.asDriver()
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                guard let self = self else { return }
                self.search(text: text)
            })
            .disposed(by: self.disposeBag)

        selectedCollectionLayout.scrollDirection = .horizontal
        selectedCollectionLayout.itemSize = CGSize(width: 30, height: 30)
        selectedCollectionLayout.minimumInteritemSpacing = 10

        selectedCollectionView.backgroundColor = UIColor.ud.bgBody
        selectedCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        selectedCollectionView.delegate = self
        selectedCollectionView.dataSource = self
        let collectionCellID = String(describing: SearchChatPickerCollectionViewCell.self)
        selectedCollectionView.register(SearchChatPickerCollectionViewCell.self,
                                        forCellWithReuseIdentifier: collectionCellID)
        view.addSubview(selectedCollectionView)
        selectedCollectionView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchWrapper.snp.bottom)
            make.height.equalTo(44)
        }

        itemsTableView.rowHeight = 68
        itemsTableView.keyboardDismissMode = .onDrag
        itemsTableView.sectionIndexBackgroundColor = UIColor.clear
        itemsTableView.sectionIndexColor = UIColor.ud.textTitle
        itemsTableView.separatorStyle = .none
        itemsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        itemsTableView.showsVerticalScrollIndicator = false
        itemsTableView.tableFooterView = UIView()
        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        let tableviewCellID = String(describing: SearchChatPickerTableViewCell.self)
        itemsTableView.register(SearchChatPickerTableViewCell.self,
                                forCellReuseIdentifier: tableviewCellID)
        #if DEBUG || INHOUSE || ALPHA
        // 初始化时读取默认状态
        self.debugButton.isHidden = !KVStores.SearchDebug.globalStore[KVKeys.SearchDebug.contextIdShow]
        // 之后通过通知传值
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(swittchDebugButton(_:)),
                         name: NSNotification.Name(KVKeys.SearchDebug.contextIdShow.raw),
                         object: nil)
        resultView.addSubview(debugButton)
        #endif
        view.insertSubview(resultView, aboveSubview: selectedCollectionView)
        resultView.backgroundColor = UIColor.ud.bgBody
        resultView.snp.makeConstraints { make in
            let top: CGFloat = selectedItems.isEmpty ? 0 : 44
            itemsTableTop = make.top.equalTo(searchWrapper.snp.bottom).offset(top).constraint
            make.left.right.bottom.equalToSuperview()
        }
        bindResultView().disposed(by: disposeBag)

        //处理分屏转换
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] _ in
                self.configNaviBar(aniamte: false)
            }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configNaviBar(aniamte: false)
    }

    #if DEBUG || INHOUSE || ALPHA
    @objc
    private func swittchDebugButton(_ notification: Notification) {
        if let isOn = notification.userInfo?["isOn"] as? Bool {
            self.debugButton.isHidden = !isOn
        }
    }
    #endif

    @objc
    private func didTapSure() {
        didFinishChooseItem?(self, selectedItems)
    }

    @objc
    private func didTapCancel() {
        closeBtnTapped()
    }

    @objc
    private func didTapMultiSelect() {
        selectMode = .multi
        configNaviBar(aniamte: true)
        itemsTableView.reloadData()
    }

    @objc
    private func search(text: String?) {
        guard searchTextField.markedTextRange == nil else { return }
        guard self.lastQuery != text else { return }
        vm.query.text.accept(text ?? "")
        self.lastQuery = text
    }

    private func configNaviBar(aniamte: Bool) {
        if hasBackPage, closeOrBackItem == nil {
            closeOrBackItem = addBackItem()
        } else if presentingViewController != nil {
            closeOrBackItem = addCloseItem()
        } else {
            closeOrBackItem = nil
        }
        navigationItem.leftBarButtonItem = cancelItem
        switch selectMode {
        case .single:
            navigationItem.rightBarButtonItem = multiSelectItem
        case .multi:
            navigationItem.rightBarButtonItem = sureItem
        }
    }

    private func updateSelectedItems(_ items: [SearchChatPickerItem], oldValue: [SearchChatPickerItem]? = nil) {
        let countString = items.isEmpty ? "" : "(\(items.count))"
        sureButton.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure + countString, for: .normal)
        sureButton.sizeToFit()

        self.itemsTableTop.update(offset: self.selectedItems.isEmpty ? 0 : 44)
        if let oldValue = oldValue, oldValue.isEmpty != items.isEmpty {
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    private func select(item: SearchChatPickerItem) {
        guard !isContainSelectedItem(item: item) else { return }
        selectedItems.append(item)
        selectedCollectionView.insertItems(at: [IndexPath(row: selectedItems.count - 1, section: 0)])
        itemsTableView.reloadData()
    }

    private func deselect(item: SearchChatPickerItem) {
        guard let index = firstIndexOfSelectedItem(item: item) else { return }
        selectedItems.remove(at: index)
        selectedCollectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        itemsTableView.reloadData()
    }
    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellID = String(describing: SearchChatPickerCollectionViewCell.self)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as? SearchChatPickerCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.set(item: selectedItems[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard indexPath.row < selectedItems.count else {
            return
        }
        deselect(item: selectedItems[indexPath.row])
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return showData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = String(describing: SearchChatPickerTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? SearchChatPickerTableViewCell else {
            return UITableViewCell()
        }
        let item = showData[indexPath.row]
        // FIXME: 人可能没有chatID, 相关依赖的地方需要调整
        cell.set(item: item,
                 isSelected: isContainSelectedItem(item: item),
                 selectModel: selectMode,
                 currentAccount: currentAccount)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: false)
        let item = showData[indexPath.row]
        switch selectMode {
        case .single:
            didFinishChooseItem?(self, [item])
        case .multi:
            if isContainSelectedItem(item: item) { deselect(item: item) } else { select(item: item) }
        }
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    // MARK: - Private
    private func isContainSelectedItem(item: SearchChatPickerItem) -> Bool {
        return selectedItems.contains { $0.chatID == item.chatID }
    }
    private func firstIndexOfSelectedItem(item: SearchChatPickerItem) -> Int? {
        return selectedItems.firstIndex { $0.chatID == item.chatID }
    }
}
