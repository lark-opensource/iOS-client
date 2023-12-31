//
//  BTFilterOptionsView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/6/30.
//  

import RxCocoa
import RxSwift
import SKCommon
import SKUIKit
import SKResource
import SKBrowser
import UniverseDesignColor
import UIKit
import SKFoundation

protocol BTFilterOptionsViewDelegate: AnyObject {
    func valueChanged(_ value: BTCapsuleModel, selected: Bool)
    func search(_ keywords: String)
}

public final class BTFilterOptionsView: UIView {

    var selecteds: [BTCapsuleModel] {
        return alls.filter { $0.isSelected }
    }
    
    private let disposeBag = DisposeBag()
    
    private(set) var alls: [BTCapsuleModel] = []
    
    private(set) var shows: [BTCapsuleModel] = []
    
    private var isAllowMultipleSelect: Bool
    
    private var isFromNewFilter: Bool = false // 是否从新筛选来的
    
    weak var delegate: BTFilterOptionsViewDelegate?
    
    private lazy var searchView: BTSearchView = {
        let view = BTSearchView(shouldShowRightBtn: false)
        view.backgroundColor = .clear
        view.searchTextField.backgroundColor = UDColor.bgFloat
        return view
    }()
    
    private lazy var optionsView = UITableView(frame: .zero, style: .plain).construct { it in
        it.register(BTOptionPanelTableViewCell.self, forCellReuseIdentifier: BTOptionPanelTableViewCell.reuseIdentifier)
        it.dataSource = self
        it.delegate = self
        it.layer.masksToBounds = true
        it.clipsToBounds = true
        it.backgroundColor = UDColor.bgFloatBase
        it.separatorStyle = .none
    }
    
    private lazy var emptyView = BTEmptyView()
    
    init(options: [BTCapsuleModel], isAllowMultipleSelect: Bool, isNewFilter: Bool = false) {
        self.isAllowMultipleSelect = isAllowMultipleSelect
        self.isFromNewFilter = isNewFilter
        super.init(frame: .zero)
        self.alls = options
        self.shows = options
        setupViews()
        reloadData()
        bindActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(options: [BTCapsuleModel]) {
        self.alls = options
        self.shows = options.filter({ $0.isShow ?? false })
        self.reloadData()
    }
    
    private func bindActions() {
        searchView.searchTextField.rx.text.orEmpty.changed
            .subscribe(onNext: { [weak self] content in
                guard let self = self else { return }
                if self.isFromNewFilter {
                    self.delegate?.search(content)
                } else {
                    if content.isEmpty {
                        self.shows = self.alls
                    } else {
                        self.shows = self.alls.filter { $0.text.contains(content) }
                    }
                    self.reloadData()
                }
            }).disposed(by: disposeBag)
    }
    
    private func reloadData() {
        self.optionsView.reloadData()
        updateEmptyView()
    }
    
    private func updateEmptyView() {
        let desc = BundleI18n.SKResource.Bitable_Option_NoOptionFound
        if alls.isEmpty {
            emptyView.updateShowType(.showNoData(desc: desc))
        } else if shows.isEmpty {
            emptyView.updateShowType(.showNoRearchResult(desc: desc))
        } else {
            emptyView.updateShowType(.hide)
        }
    }
    
    private func deselected(at index: Int) {
        let option = shows[index]
        if self.isFromNewFilter {
            self.delegate?.valueChanged(option, selected: false)
        } else {
            self.alls = updateOptions(alls, item: option, isSelected: false)
            self.shows = updateOptions(shows, item: option, isSelected: false)
            reloadData()
        }
    }
    
    private func selected(at index: Int) {
        let option = shows[index]
        if self.isFromNewFilter {
            self.delegate?.valueChanged(option, selected: true)
        } else {
            self.alls = updateOptions(alls, item: option, isSelected: true)
            self.shows = updateOptions(shows, item: option, isSelected: true)
            reloadData()
        }
    }
    
    private func updateOptions(_ options: [BTCapsuleModel], item: BTCapsuleModel, isSelected: Bool) -> [BTCapsuleModel] {
        var item = item
        var options = options
        // 如果是单选，要把其他的选项给移除掉
        if isSelected, !isAllowMultipleSelect {
            options = options.map {
                var _item = $0
                _item.isSelected = _item.id == item.id
                return _item
            }
        } else {
            if let index = options.firstIndex(where: { $0.id == item.id }) {
                item.isSelected = isSelected
                options[index] = item
            }
        }
        return options
    }

    private func setupViews() {
        addSubview(searchView)
        addSubview(optionsView)
        addSubview(emptyView)
        

        searchView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(40)
        }
    
        optionsView.snp.makeConstraints { (make) in
            make.top.equalTo(searchView.snp.bottom).offset(16)
            make.right.left.bottom.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(optionsView)
        }
    }
}


extension BTFilterOptionsView: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shows.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BTOptionPanelTableViewCell.reuseIdentifier, for: indexPath)
        cell.backgroundColor = UDColor.bgFloatBase
        guard indexPath.row < shows.count else { return cell }
        if let cell = cell as? BTOptionPanelTableViewCell {
            let info = shows[indexPath.row]
            cell.update(text: info.text,
                        colors: info.color,
                        isSingle: false,
                        isSelected: info.isSelected,
                        canEdit: false)
            cell.model = info
            //最后一个cell不需要显示下划线
            cell.updateSeparatorStatus(isLast: indexPath.row == shows.count - 1)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard shows.count > indexPath.row else {
            return
        }
        if shows[indexPath.row].isSelected {
            deselected(at: indexPath.row)
        } else {
            selected(at: indexPath.row)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchView.endEditing(true)
    }
}
