//
//  BTFilterControllerV2.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/28.
//

import Foundation
import SKResource
import UniverseDesignTabs
import UniverseDesignLoading

protocol BTFilterControllerDelegateV2: AnyObject {
    func filterPanelControllerDidTapAddNewCondition(_ controller: BTFilterControllerV2)
    func filterPanelController(_ controller: BTFilterControllerV2,
                               didTapConjuction button: BTConditionSelectButton)
    func filterPanelController(_ controller: BTFilterControllerV2,
                               didTapDeleteAt index: Int,
                               conditionModel: BTConditionSelectCellModel)
    func filterPanelController(_ controller: BTFilterControllerV2,
                               didTapItemAt index: Int,
                               conditionCell: UITableViewCell,
                               conditionSubCell: UICollectionViewCell?,
                               subCellIndex: Int)
    func filterPanelController(_ controller: BTFilterControllerV2,
                               conditionModel: BTConditionSelectCellModel)
    func filterPanelControllerWillShow(_ controller: BTFilterControllerV2)
}

final class BTFilterControllerV2: UIViewController {
    enum SectionType: Int, CaseIterable {
        case conjuction
        case condition
    }
    
    weak var delegate: BTFilterControllerDelegateV2?
    
    private(set) var model: BTFilterPanelModel = BTFilterPanelModel()
    
    private(set) var cellHeightCache: [String: CGFloat] = [:]
    
    private let addNewConditionView = BTBottomAddConditionView()
    
    private lazy var conditionListView: UITableView = {
        let tableV = UITableView()
        tableV.backgroundColor = .clear
        tableV.delegate = self
        tableV.dataSource = self
        tableV.separatorStyle = .none
        tableV.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableV.register(BTConditionSelectCell.self, forCellReuseIdentifier: BTConditionSelectCell.reuseIdentifier)
        tableV.register(BTConditionConjunctionCell.self, forCellReuseIdentifier: BTConditionConjunctionCell.reuseIdentifier)
        return tableV
    }()
    
    private lazy var emptyView = BTEmptyView()
    
    private lazy var noticeView = BTFieldUnreadableNitceView()
    
    private lazy var loadingView = UDLoading.loadingImageView()
    
    // 告知父容器需要变高
    var changeContainerHeightBlock: ((BTDraggableViewController.ViewHeightMode, Bool) -> Void)?
        
    init(model: BTFilterPanelModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentView()
        updateEmptyView(isInitial: true)
        updateNitce()
        conditionListView.reloadData()
    }
    
    func superControllerDidAppear(safeInset: UIEdgeInsets) {
        // safe area 刷新
        addNewConditionView.updateWillAppear(safeInset: safeInset)
    }
    
    /// 更新数据源，并滚动到响应的位置。
    /// - Parameters:
    ///   - model: 数据模型
    ///   - index: 只有当有传入时才进行滚动
    func updateModel(_ model: BTFilterPanelModel, scrollToConditionAt index: Int? = nil) {
        self.model = model
        updateEmptyView(isInitial: false)
        updateNitce()
        conditionListView.reloadData()
        if let scrollIndex = index,
            scrollIndex < model.conditions.count,
            scrollIndex >= 0 {
            conditionListView.scrollToRow(at: IndexPath(row: scrollIndex, section: SectionType.condition.rawValue),
                                          at: .bottom,
                                          animated: false)
        }
    }
    
    // nolint: duplicated_code
    private func updateNitce() {
        let showNotice = !model.displayNoticeText.isEmpty
        noticeView.isHidden = !showNotice
        noticeView.updateNoticeContent(model.displayNoticeText)
        if showNotice {
            conditionListView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        } else {
            conditionListView.tableHeaderView = nil
            conditionListView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        }
        if noticeView.superview != nil {
            noticeView.snp.updateConstraints { make in
                let inset = showNotice ? 16 : 0
                make.left.top.right.equalToSuperview().inset(inset)
            }
        }
        if conditionListView.superview != nil {
            conditionListView.snp.remakeConstraints {
                if showNotice {
                    $0.top.equalTo(noticeView.snp.bottom).offset(10)
                } else {
                    $0.top.equalToSuperview()
                }
                $0.left.right.equalToSuperview()
                $0.bottom.equalTo(addNewConditionView.snp.top)
            }
        }
    }
    
    private func updateEmptyView(isInitial: Bool) {
        guard !isInitial else {
            loadingView.isHidden = false
            emptyView.updateShowType(.hide)
            return
        }
        let desc = BundleI18n.SKResource.Bitable_Record_NoFilterCondition
        let isEmpty = model.conditions.isEmpty
        if isEmpty {
            emptyView.updateShowType(.showNoData(desc: desc))
        } else {
            emptyView.updateShowType(.hide)
        }
        loadingView.isHidden = true
    }
    
    private func setupContentView() {
        noticeView.isHidden = true
        view.addSubview(addNewConditionView)
        view.addSubview(conditionListView)
        view.addSubview(emptyView)
        view.addSubview(noticeView)
        view.addSubview(loadingView)
        
        addNewConditionView.didTapAddButton = { [weak self] in
            guard let self = self else { return }
            // 通知容器变高
            self.delegate?.filterPanelControllerDidTapAddNewCondition(self)
            self.changeContainerHeightBlock?(.maxHeight, true)
        }
        
//        remakeContentViewConstraints(isContainBottomSafeArea: true)
        noticeView.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview().inset(0)
        }
        
        conditionListView.snp.makeConstraints {
            $0.top.equalTo(noticeView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(addNewConditionView.snp.top)
        }
        
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(conditionListView)
        }
        
        loadingView.snp.makeConstraints { make in
            make.center.equalTo(conditionListView)
        }
        
        addNewConditionView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }
    }
}

extension BTFilterControllerV2: BTConditionSelectCellDelegate {
    
    func didClickDelete(cell: UITableViewCell) {
        guard let index = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        delegate?.filterPanelController(self, didTapDeleteAt: index, conditionModel: self.model.conditions[index])
    }
    
    func didClickContainerButton(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        guard let cellIndex = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        delegate?.filterPanelController(self,
                                        didTapItemAt: cellIndex,
                                        conditionCell: cell,
                                        conditionSubCell: subCell,
                                        subCellIndex: index)
    }
    
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        guard let cellIndex = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        //点击重试后更新成loading态
        delegate?.filterPanelController(self, conditionModel: self.model.conditions[cellIndex])
    }
}

extension BTFilterControllerV2: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 && model.hasInvalideCondition {
            return UIView()
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && model.hasInvalideCondition {
            return 8
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionType(rawValue: section) {
        case .conjuction?:
            return model.conditions.count > 1 ? 1 : 0
        case .condition?:
            return model.conditions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionType(rawValue: indexPath.section) {
        case .conjuction?:
            let cell = tableView.dequeueReusableCell(withIdentifier: BTConditionConjunctionCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? BTConditionConjunctionCell {
                cell.didTapConjuctionButton = { [weak self] btn in
                    guard let self = self else { return }
                    self.delegate?.filterPanelController(self, didTapConjuction: btn)
                }
                cell.configModel(self.model.conjuction)
            }
            return cell
        case .condition?:
            let cell = tableView.dequeueReusableCell(withIdentifier: BTConditionSelectCell.reuseIdentifier, for: indexPath)
            if let conditonCell = cell as? BTConditionSelectCell {
                let cellModel = model.conditions[indexPath.row]
                conditonCell.configModel(cellModel)
                conditonCell.delegate = self
                conditonCell.isFirstCell = !isCellNeedTopSpacing(at: indexPath.row)
                let height = conditonCell.relayout()
                cellHeightCache[cellModel.conditionId] = height
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionType(rawValue: indexPath.section) {
        case .conjuction?:
            return 52
        case .condition?:
            let cellModel = self.model.conditions[indexPath.row]
            if let height = cellHeightCache[cellModel.conditionId] {
                return height
            } else {
                let height = BTConditionSelectCell.calculateCellHeight(with: cellModel,
                                                                       cellWith: tableView.frame.width,
                                                                       hasTopSpacing: isCellNeedTopSpacing(at: indexPath.row))
                cellHeightCache[cellModel.conditionId] = height
                return height
            }
           
        default:
            return 0
        }
    }
    
    private func isCellNeedTopSpacing(at index: Int) -> Bool {
        let conditionsConunt = model.conditions.count
        return !(conditionsConunt == 1 && index == 0)
    }
}


extension BTFilterControllerV2: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        self.view
    }
    /// 可选实现，列表将要显示的时候调用
    func listWillAppear() {
        if model.conditions.isEmpty {
            emptyView.updateShowType(.hide)
            loadingView.isHidden = false
        }
        delegate?.filterPanelControllerWillShow(self)
    }
}
