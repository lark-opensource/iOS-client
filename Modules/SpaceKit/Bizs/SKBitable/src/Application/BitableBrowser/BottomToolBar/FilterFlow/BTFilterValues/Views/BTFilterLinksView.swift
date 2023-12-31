//
//  BTFilterLinksView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/1.
//  


import RxCocoa
import SKUIKit
import SKCommon
import SKResource
import SKFoundation
import SKBrowser
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignLoading
import UIKit

protocol BTFilterLinksViewDelegate: AnyObject {
    func valueChanged(_ value: BTLinkRecordModel, selected: Bool)
}

final class BTFilterLinksView: UIView {

    var selecteds: [BTLinkRecordModel] {
        if !isAllowMultipleSelect {
            if let firstSelected = alls.first(where: { $0.isSelected }) {
                return [firstSelected]
            }
            return []
        }
        return alls.filter { $0.isSelected }
    }
    
    var searchText: String? {
        return searchView.searchTextField.text
    }
    
    private(set) var alls: [BTLinkRecordModel] = []
    
    private(set) var shows: [BTLinkRecordModel] = []
    
    private lazy var emptyView = BTEmptyView()
    
    private var isAllowMultipleSelect: Bool
    
    private var selectedRecordModels: [BTLinkRecordModel] = [] //选中的记录
    
    private var keyboard: Keyboard?
    
    private let loadingViewManager = BTLaodingViewManager()

    private var isFromNewFilter = false
    
    weak var delegate: BTFilterLinksViewDelegate?
    
    //用来放emptyView和loading
    private lazy var placeholderViewContainer: UIView = UIView().construct { it in
        it.backgroundColor = .clear
        it.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.centerY.greaterThanOrEqualToSuperview()
        }
    }
    
    lazy var searchView: BTSearchView = {
        let view = BTSearchView(shouldShowRightBtn: false)
        view.backgroundColor = .clear
        view.searchTextField.backgroundColor = UDColor.bgFloat
        view.isHidden = true
        return view
    }()
    
    private lazy var recordsView = UITableView(frame: .zero, style: .plain).construct { it in
        it.register(BTLinkRecordCell.self, forCellReuseIdentifier: BTLinkRecordCell.reuseIdentifier)
        it.backgroundColor = UDColor.bgFloatBase
        it.dataSource = self
        it.delegate = self
        it.keyboardDismissMode = .onDrag
        it.separatorStyle = .none
    }

    init(isAllowMultipleSelect: Bool) {
        self.isAllowMultipleSelect = isAllowMultipleSelect
        super.init(frame: .zero)
        setupViews()
    }
    
    init(datas: [BTLinkRecordModel], isAllowMultipleSelect: Bool) {
        self.isAllowMultipleSelect = isAllowMultipleSelect
        self.isFromNewFilter = true
        self.alls = datas
        self.shows = self.alls.filter({ $0.isShow ?? false})
        super.init(frame: .zero)
        setupViews()
        updateEmptyView()
        self.searchView.isHidden = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        keyboard?.stop()
    }
    
    private func reloadData() {
        self.recordsView.reloadData()
        updateEmptyView()
    }
    
    private func updateEmptyView() {
        let desc = BundleI18n.SKResource.Bitable_Relation_NoResultFound
        if alls.isEmpty {
            placeholderViewContainer.isHidden = false
            emptyView.updateShowType(.showNoData(desc: desc))
        } else if shows.isEmpty {
            placeholderViewContainer.isHidden = false
            emptyView.updateShowType(.showNoRearchResult(desc: desc))
        } else {
            placeholderViewContainer.isHidden = true
            emptyView.updateShowType(.hide)
        }
    }
    
    private func deselected(at index: Int) {
        let option = shows[index]
        if self.isFromNewFilter {
            self.delegate?.valueChanged(option, selected: false)
        } else {
            self.alls = updateRecords(alls, item: option, isSelected: false)
            self.shows = updateRecords(shows, item: option, isSelected: false)
            self.delegate?.valueChanged(option, selected: false)
            reloadData()
        }
    }
    
    private func selected(at index: Int) {
        let option = shows[index]
        if self.isFromNewFilter {
            self.delegate?.valueChanged(option, selected: false)
        } else {
            self.alls = updateRecords(alls, item: option, isSelected: true)
            self.shows = updateRecords(shows, item: option, isSelected: true)
            reloadData()
        }
    }
    
    private func updateRecords(_ records: [BTLinkRecordModel], item: BTLinkRecordModel, isSelected: Bool) -> [BTLinkRecordModel] {
        var item = item
        var options = records
        
        if !isAllowMultipleSelect {
            return options.compactMap {
                var _item = $0
                _item.isSelected = _item.id == item.id
                return _item
            }
        }
        
        if let index = options.firstIndex(where: { $0.id == item.id }) {
            item.isSelected = isSelected
            options[index] = item
        }
        return options
    }

    private func setupViews() {
        addSubview(searchView)
        addSubview(recordsView)
        addSubview(placeholderViewContainer)

        searchView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
    
        recordsView.snp.makeConstraints { (make) in
            make.top.equalTo(searchView.snp.bottom).offset(16)
            make.right.left.bottom.equalToSuperview()
        }
        
        placeholderViewContainer.snp.makeConstraints { (make) in
            make.top.equalTo(searchView.snp.bottom).offset(16)
            make.right.left.bottom.equalToSuperview()
        }
        
        startKeyBoardObserver()
    }
    
    private func startKeyBoardObserver() {
        keyboard = Keyboard(listenTo: [searchView.searchTextField], trigger: "bitableFilterLink")
        keyboard?.on(events: [.willShow, .didShow]) { [weak self] option in
            guard let self = self else { return }

            let realKeyboardHeight = option.endFrame.height
            let remainHeightExceptKeyboard = self.bounds.height - self.placeholderViewContainer.frame.minY - 48
            var remainHeight = remainHeightExceptKeyboard - realKeyboardHeight

            remainHeight = max(133, remainHeight)

            let bottomOffset = remainHeightExceptKeyboard - remainHeight

            UIView.performWithoutAnimation {

                self.placeholderViewContainer.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-bottomOffset)
                }

                self.layoutIfNeeded()
            }
        }

        keyboard?.on(events: [.willHide, .didHide]) { [weak self] _ in
            guard let self = self else { return }
            
            UIView.performWithoutAnimation {
                self.placeholderViewContainer.snp.updateConstraints { make in
                    make.bottom.equalToSuperview()
                }
                
                self.layoutIfNeeded()
            }
        }
        keyboard?.start()
    }
    
    func handleData(data: [BTLinkRecordModel]) {
        self.searchView.isHidden = false
        if UserScopeNoChangeFG.ZJ.btFilterLinkViewSearchFixDisable {
            self.alls = data
        } else {
            self.alls = handleDataSelected(data)
        }
        let content = searchView.searchTextField.text ?? ""
        if content.isEmpty {
            self.shows = self.alls
        } else {
            self.shows = self.alls.filter { $0.text.contains(content) }
        }
        reloadData()
    }
    
    func setData(data: [BTLinkRecordModel]) {
        self.searchView.isHidden = false
        self.alls = data
        self.shows = data.filter({ $0.isShow ?? false })
        self.reloadData()
    }
    
    func handleDataSelected(_ data: [BTLinkRecordModel]) -> [BTLinkRecordModel] {
        return data.compactMap { model in
            var newModel = model
            newModel.isSelected = self.alls.first(where: { $0.id == model.id })?.isSelected ?? newModel.isSelected
            return newModel
        }
    }
    
    ///开启loading计时器，超过200ms无数据，显示loading
    func startLoadingTimer() {
        self.perform(#selector(type(of: self).showLoading), with: nil, afterDelay: 0.2)
    }
    
    ///显示加载中的loading
    @objc
    func showLoading() {
        emptyView.updateShowType(.hide)
        recordsView.isHidden = true
        placeholderViewContainer.isHidden = false
        
        loadingViewManager.showLoading(superView: placeholderViewContainer)
        bringSubviewToFront(placeholderViewContainer)
    }
    
    ///隐藏loading
    func hideLoading() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showLoading), object: nil)
        recordsView.isHidden = false
        placeholderViewContainer.isHidden = true
        loadingViewManager.hideLoading()
    }
    
    ///显示超时重试页面
    func showTryAgainEmptyView(text: String, type: UDEmptyType, tryAgainBlock: (() -> Void)? = nil) {
        hideLoading()
        emptyView.isHidden = false
        placeholderViewContainer.isHidden = false
        let listEmptyConfig = loadingViewManager.getTryAgainEmptyConfig(description: text, type: type, tryAgainBlock: { [weak self] in
            tryAgainBlock?()
            self?.emptyView.updateShowType(.hide)
            self?.showLoading()
        })
        emptyView.updateConfig(listEmptyConfig)
    }
}


extension BTFilterLinksView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BTLinkRecordCell.reuseIdentifier, for: indexPath)
        guard indexPath.row < shows.count else { return cell }
        if let cell = cell as? BTLinkRecordCell {
            cell.configModel(shows[indexPath.row],
                             uiConfig: BTLinkRecordCell.UIConfig(recordViewBackgroundColor: UDColor.bgFloat,
                                                                 contentViewBackgroundColor: UDColor.bgFloatBase))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard shows.count > indexPath.row else {
            return
        }
        if shows[indexPath.row].isSelected, isAllowMultipleSelect {
            deselected(at: indexPath.row)
        } else {
            selected(at: indexPath.row)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchView.endEditing(true)
    }
}
