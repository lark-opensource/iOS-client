//
//  BTFilterPanel.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/12.
//  


import SKFoundation
import SKUIKit
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignIcon
import SKResource
import Foundation
import HandyJSON

protocol BTFilterPanelControllerDelegate: AnyObject {
    func filterPanelControllerDidTapAddNewCondition(_ controller: BTFilterPanelController)
    func filterPanelController(_ controller: BTFilterPanelController,
                               didTapConjuction button: BTConditionSelectButton)
    func filterPanelController(_ controller: BTFilterPanelController,
                               didTapDeleteAt index: Int,
                               conditionModel: BTConditionSelectCellModel)
    func filterPanelController(_ controller: BTFilterPanelController,
                               didTapItemAt index: Int,
                               conditionCell: UITableViewCell,
                               conditionSubCell: UICollectionViewCell?,
                               subCellIndex: Int)
    func filterPanelController(_ controller: BTFilterPanelController,
                               conditionModel: BTConditionSelectCellModel)
}

struct BTFilterPanelModel {
    var conjuction: BTConditionConjuctionModel = BTConditionConjuctionModel(id: "", text: "")
    var conditions: [BTConditionSelectCellModel] = []

    var notice: String?
    
    var hasInvalideCondition: Bool {
        return conditions.contains { model in
            return model.invalidType == .fieldUnreadable
        }
    }
}

extension BTFilterPanelModel {
    var displayNoticeText: String {
        if hasInvalideCondition {
            return BundleI18n.SKResource.Bitable_AdvancedPermission_FailedToUseFilter_NoPermToViewField_Tooltip
        } else if let notice, !notice.isEmpty, !conditions.isEmpty {
            return notice
        }
        return ""
    }
}


final class BTFilterPanelController: BTDraggableViewController {
    
    enum SectionType: Int, CaseIterable {
        case conjuction
        case condition
    }
    
    weak var delegate: BTFilterPanelControllerDelegate?
    
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
        
    init(model: BTFilterPanelModel, shouldShowDragBar: Bool) {
        self.model = model
        super.init(title: BundleI18n.SKResource.Bitable_Record_SetFilterCondition,
                   shouldShowDragBar: shouldShowDragBar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }

    override func setupUI() {
        super.setupUI()
        setupContentView()
        updateEmptyView()
        updateNitce()
        conditionListView.reloadData()
    }
    
    override func containerViewHeightUpdate(byDrag state: UIGestureRecognizer.State, height: CGFloat) {
        let isDragging: Bool
        switch state {
        case .began, .changed: isDragging = true
        default: isDragging = false
        }
        let offset = max(draggableMinViewHeight - height, 0)
        let isNeedUpdate = (isDragging && offset > 0) || !isDragging
        if isNeedUpdate {
            addNewConditionView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(offset)
            }
        }
    }
    
    /// 更新数据源，并滚动到响应的位置。
    /// - Parameters:
    ///   - model: 数据模型
    ///   - index: 只有当有传入时才进行滚动
    func updateModel(_ model: BTFilterPanelModel, scrollToConditionAt index: Int? = nil) {
        self.model = model
        updateEmptyView()
        updateNitce()
        conditionListView.reloadData()
        if let scrollIndex = index,
           scrollIndex < model.conditions.count,
           scrollIndex >= 0 {
            conditionListView.scrollToRow(at: IndexPath(row: scrollIndex, section: SectionType.condition.rawValue),
                                          at: .bottom,
                                          animated: false)
        } else {
            DocsLogger.btError("[BTFilterPanelController] index out of bounds \(String(describing: index)) \(model.conditions.count)")
        }
    }
    
    // nolint: duplicated_code
    private func updateNitce() {
        let hasInvalideCondition = model.hasInvalideCondition
        noticeView.isHidden = !hasInvalideCondition
        noticeView.updateNoticeContent(model.displayNoticeText)
        if hasInvalideCondition {
            conditionListView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        } else {
            conditionListView.tableHeaderView = nil
            conditionListView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        }
        if conditionListView.superview != nil {
            conditionListView.snp.remakeConstraints {
                if hasInvalideCondition{
                    $0.top.equalTo(noticeView.snp.bottom)
                } else {
                    $0.top.equalToSuperview()
                }
                $0.left.right.equalToSuperview()
                $0.bottom.equalTo(addNewConditionView.snp.top)
            }
        }
    }
    
    private func updateEmptyView() {
        let desc = BundleI18n.SKResource.Bitable_Record_NoFilterCondition
        let isEmpty = model.conditions.isEmpty
        if isEmpty {
            emptyView.updateShowType(.showNoData(desc: desc))
        } else {
            emptyView.updateShowType(.hide)
        }
    }
    
    private func setupContentView() {
        noticeView.isHidden = true
        contentView.addSubview(addNewConditionView)
        contentView.addSubview(conditionListView)
        contentView.addSubview(emptyView)
        contentView.addSubview(noticeView)

        addNewConditionView.didTapAddButton = { [weak self] in
            guard let self = self else { return }
            self.changeViewHeightMode(.maxHeight)
            self.delegate?.filterPanelControllerDidTapAddNewCondition(self)
        }
        
        remakeContentViewConstraints(isContainBottomSafeArea: true)
        
        noticeView.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview()
        }
        
        conditionListView.snp.makeConstraints {
            $0.top.equalTo(noticeView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(addNewConditionView.snp.top)
        }
        
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(conditionListView)
        }
        
        addNewConditionView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
        }
    }
}

extension BTFilterPanelController: UITableViewDelegate, UITableViewDataSource {
    
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
            if let cellModel = self.model.conditions.safe(index: indexPath.row) {
                if let height = cellHeightCache[cellModel.conditionId] {
                    return height
                } else {
                    let height = BTConditionSelectCell.calculateCellHeight(with: cellModel,
                                                                           cellWith: tableView.frame.width,
                                                                           hasTopSpacing: isCellNeedTopSpacing(at: indexPath.row))
                    cellHeightCache[cellModel.conditionId] = height
                    return height
                }
            } else {
                DocsLogger.error("[BTFilterPanelController] heightForRowAt can not find model")
                return 0
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

extension BTFilterPanelController: BTConditionSelectCellDelegate {
    
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
        delegate?.filterPanelController(self, didTapItemAt: cellIndex, conditionCell: cell, conditionSubCell: subCell, subCellIndex: index)
    }
    
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        guard let cellIndex = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        //点击重试后更新成loading态
        delegate?.filterPanelController(self, conditionModel: self.model.conditions[cellIndex])
    }
}
