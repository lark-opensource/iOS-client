//
//  IMMentionViewController.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/20.
//
import Foundation
import UIKit
import SnapKit
import RxSwift

final class IMMentionViewController: UIViewController, IMMentionType {
    
    weak var delegate: IMMentionPanelDelegate?
    var contentView: IMMentionView
    weak var fromVc: UIViewController?
    var imMentionTarcker = IMMentionTraker()
    let disposeBag = DisposeBag()
    
    var stores: [MentionStore]
    let selectedStore = SelectedItemStore()
    var provider: MentionProviderType
    
    deinit {
        IMMentionLogger.shared.info(module: .vc, event: "\(Self.self) deinit")
    }
    
    private var context: IMMentionContext
    init(context: IMMentionContext, provider: MentionProviderType) {
        self.contentView = IMMentionView()
        self.provider = provider
        self.context = context
        self.stores = [AllStore(context: context),
                       ChatterStore(context: context),
                       DocumentStore(context: context)]
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 设置UI
        setupUI()
        // 绑定UI相关事件
        bindUIAction()
        bindSearch()
        bindStore()
        bindSelectedStore()
    }
    
    func show(from vc: UIViewController) {
        fromVc = vc
        imMentionTarcker.imMentionTrakerPost(action: .show)
    }
    
    private func setupUI() {
        self.view.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.leading.trailing.top.bottom.equalToSuperview()
        }
    }
    
    // TODO 高级函数for改造
    // 所有UI相关的事件绑定
    private var searchDisposeBag = DisposeBag()
    private func bindSearch() {
        // 搜索数据变化
        contentView.searchTextField.rx.text.asDriver()
            .distinctUntilChanged()
            .debounce(.milliseconds(150))
            .drive { [weak self] in
                guard let text = $0,
                      let self = self else { return }
                self.stores.forEach { $0.dispatch(event: .startSearch(text)) }
                self.searchDisposeBag = DisposeBag()
                let events = self.provider.search(query: text)
                self.bindProviderSearchEvent(events: events)
            }.disposed(by: disposeBag)
    }
    
    private func bindProviderSearchEvent(events: [Observable<ProviderEvent>]) {
        assert(events.count == self.stores.count, "The number of Providers and Stores does not match")
        for (i, signal) in events.enumerated() {
            let store = self.stores[i]
            signal
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: {
                    store.dispatch(event: $0)
                }, onCompleted: {
                    store.dispatch(event: .complete)
                })
                .disposed(by: self.searchDisposeBag)
        }
    }
    
    private func bindUIAction() {
        // 多选/确认 按钮切换
        contentView.didSwitchMulitSelectHandler = {
            [weak self] isOn in
            IMMentionLogger.shared.info(module: .action, event: "switch multi select", parameters: "isOn=\(isOn)")
            guard let self = self else { return }
            if isOn {
                self.imMentionTarcker.imMentionTrakerPost(action: .multiSelect)
                self.stores.forEach { $0.switchMultiSelect(isOn: true) }
                self.selectedStore.toggleMultiSelected(isOn: true)
            } else {
                self.selectFinish()
            }
        }
        // 多选切回单选
        contentView.didSwitchSingleHandle = {
            [weak self] in
            IMMentionLogger.shared.info(module: .action, event: "turn off multi select")
            self?.stores.forEach { $0.switchMultiSelect(isOn: false) }
            self?.selectedStore.toggleMultiSelected(isOn: false)
        }
        // tableview点击选项
        contentView.tabsView.tabItems.forEach {
            $0.didSelectItemHandler = { [weak self] item in
                guard let self = self else { return }
                IMMentionLogger.shared.info(module: .action, event: "select item", parameters: "id=\(item.id ?? "")")
                self.selectedStore.toggleItemSelected(item: item)
                // 单选状态下直接完成选中
                guard self.selectedStore.isMultiSelected else {
                    self.selectFinish()
                    return
                }
                self.stores.forEach {
                    $0.toggleItemSelected(item: item)
                }
            }
        }
        // 已选列表点击删除
        contentView.selectedView.didDeleteItemHandler = {
            [weak self] (item) in
            guard let self = self else { return }
            IMMentionLogger.shared.info(module: .action, event: "delete multi selected item", parameters: "id=\(item.id ?? "")")
            self.selectedStore.toggleItemSelected(item: item)
            self.stores.forEach { $0.toggleItemSelected(item: item) }
        }
        // 点击已选按钮展开数据
        contentView.didUnfoldSelectedItems = { [weak self] in
            guard let self = self else { return }
            IMMentionLogger.shared.info(module: .action, event: "open multi select vc")
            let vc = IMMentionSelectedViewController(store: self.selectedStore, from: self)
            vc.didDeselectItemHandler = { [weak self] item in
                self?.stores.forEach { $0.toggleItemSelected(item: item) }
            }
            self.navigationController?.pushViewController(vc, animated: false)
        }
        // 点击关闭
        contentView.didDismiss = { [weak self] in
            guard let self = self else { return }
            IMMentionLogger.shared.info(module: .action, event: "close")
            self.close()
        }
        // 列表下拉
        for index in 0 ..< contentView.tabsView.tabItems.count {
            contentView.tabsView.tabItems[index].didChangeHeightHandler = {
                [weak self] (changeY,state) in
                guard let self = self else { return }
                self.changePanelHeight(changeY: changeY, state: state)
            }
        }
        // 标题栏下拉
        contentView.didChangeHeightHandler = {
            [weak self] (changeY,state) in
            guard let self = self else { return }
            self.changePanelHeight(changeY: changeY, state: state)
        }
    }
    
    private func addLoadMoreForTableView(at i: Int) {
        self.contentView.tabsView.tabItems[i].tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            IMMentionLogger.shared.info(module: .action, event: "load more", parameters: "index=\(i)")
            self.searchDisposeBag = DisposeBag()
            let events = self.provider.loadMore()
            self.bindProviderSearchEvent(events: events)
        }
    }
    
    private func bindStore() {
        for (i, store) in stores.enumerated() {
            store.didReloadDataHandler = { [weak self] (result, state) in
                guard let self = self else { return }
                self.contentView.reloadTable(result: result, isSkeleton: state.isShowSkeleton, index: i, nameIndex: state.nameIndex, nameIndexForm: state.nameIndexForm,nameDict: state.nameDict, isMultiSelect: state.isMultiSelected)
                self.contentView.tabsView.tabItems[i].tableView.endBottomLoadMore(hasMore: state.hasMore)
                guard state.isReloading else { return }
                self.contentView.updateTableScroll()
            }
            
            store.didRefreshDataHandler = { [weak self] (result, state) in
                guard let self = self else { return }
                self.contentView.reloadTable(result: result, isSkeleton: state.isShowSkeleton, index: i, nameIndex: state.nameIndex, nameIndexForm: state.nameIndexForm,nameDict: state.nameDict, isMultiSelect: state.isMultiSelected)
            }
            
            store.didReloadItemAtIndexHandler = { [weak self] in
                self?.contentView.reloadTableAtRows(result: $0, index: i, indexPath: $1)
            }
        }
 
        for (index, store) in stores.enumerated() {
            // 绑定错误状态
            store.state.map { $0.error?.errorString }
                .subscribe(onNext: { [weak self] in
                    self?.contentView.setError(error: $0, index: index)
                }).disposed(by: disposeBag)
            
            store.state.map { $0.isShowPrivacy }
                .distinctUntilChanged()
                .subscribe { [weak self] in
                    self?.contentView.tabsView.tabItems[index].isShowPrivacyFooter = $0
                }.disposed(by: disposeBag)
            
            store.state.map { $0.hasMore }
                .distinctUntilChanged()
                .subscribe { [weak self] hasMore in
                    if hasMore {
                        self?.addLoadMoreForTableView(at: index)
                    } else {
                        self?.contentView.tabsView.tabItems[index].tableView.enableBottomLoadMore(false)
                    }
                }.disposed(by: disposeBag)
        }
    }
    
    func bindSelectedStore() {
        selectedStore.didUpdateSelectedItems = { [weak self] (items, cache) in
            self?.stores.forEach {
                $0.selectedCache = cache
            }
            self?.contentView.reloadCollect(items: items)
            self?.contentView.updateSelectedCount(numbers: items.count)
        }
    }
    
    func selectFinish() {
        let items = selectedStore.selectedResult
        delegate?.panel(didFinishWith: items)
        imMentionTarcker.imMentionTrakerPost(action: .mentionConfirm, targer: "none", items: items)
        self.fromVc?.dismiss(animated: true)
    }
    
    func close() {
        delegate?.panelDidCancel()
        fromVc?.dismiss(animated: true)
    }
    
    func changePanelHeight(changeY: CGFloat,state: UIGestureRecognizer.State) {
        switch state {
        case .changed:
            self.fromVc?.view.transform = CGAffineTransform(translationX: 0, y: changeY)
        case .ended:
            if changeY / (self.view.bounds.height) > 0.3 {
                self.close()
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    self.fromVc?.view.transform = CGAffineTransform(translationX: 0, y: 0)
                }
            }
        default:
            break
        }
    }
}

