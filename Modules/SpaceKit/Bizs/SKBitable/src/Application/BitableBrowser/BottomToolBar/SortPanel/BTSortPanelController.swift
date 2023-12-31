//
//  BTSortPanelController.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/12.
//  

import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignToast

protocol BTSortPanelControllerDelegate: AnyObject {
    func sortPanelControllerDidTapAddNewCondition(_ controller: BTSortPanelController)
    func sortPanelControllerDidTapDone(_ controller: BTSortPanelController)
    func sortPanelControllerDidTapClose(_ controller: BTSortPanelController)
    func sortPanelController(_ controller: BTSortPanelController, didChange autoSort: Bool)
    func sortPanelController(_ controller: BTSortPanelController,
                             didTapDeleteAt index: Int,
                             conditionModel: BTConditionSelectCellModel)
    func sortPanelController(_ controller: BTSortPanelController,
                             didTapItemAt index: Int,
                             conditionCell: UITableViewCell,
                             conditionSubCell: UICollectionViewCell?,
                             subCellIndex: Int)
}

struct BTSortPanelModel {
    var isAddable: Bool = true
    var autoSort: Bool = false
    var conditions: [BTConditionSelectCellModel] = []
    
    var isPartial: Bool = false
    
    var notice: String? = nil
    
    var hasInvalideCondition: Bool {
        return conditions.contains { model in
            return model.invalidType == .fieldUnreadable
        }
    }
}

extension BTSortPanelModel {
    var displayNoticeText: String {
        if hasInvalideCondition {
            return BundleI18n.SKResource.Bitable_AdvancedPermission_FailedToUseSort_NoPermToViewField_Tooltip
        }
        if let notice, !notice.isEmpty {
            return notice
        }
        return ""
    }
}

final class BTSortPanelController: BTDraggableViewController {
    
    enum SectionType: Int, CaseIterable {
        case autoSort
        case condition
    }
    
    weak var delegate: BTSortPanelControllerDelegate?
    
    private(set) var model: BTSortPanelModel = BTSortPanelModel()
    
    private(set) var cellHeightCache: [String: CGFloat] = [:]
    
    private let addNewConditionView = BTBottomAddConditionView()
    
    private lazy var noticeView = BTFieldUnreadableNitceView()
    
    private lazy var conditionListView: UITableView = {
        let tableV = UITableView()
        tableV.backgroundColor = .clear
        tableV.delegate = self
        tableV.dataSource = self
        tableV.separatorStyle = .none
        tableV.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableV.register(BTAutoSortCell.self, forCellReuseIdentifier: BTAutoSortCell.reuseIdentifier)
        tableV.register(BTConditionSelectCell.self, forCellReuseIdentifier: BTConditionSelectCell.reuseIdentifier)
        return tableV
    }()
    
    private lazy var emptyView = BTEmptyView()
    init(model: BTSortPanelModel, shouldShowDragBar: Bool) {
        self.model = model
        super.init(title: BundleI18n.SKResource.Bitable_Record_SetSortCondition, shouldShowDragBar: shouldShowDragBar, shouldShowDoneButton: !model.autoSort)
        self.doneButtonTitle = BundleI18n.SKResource.Bitable_Common_Apply_Button
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
    
    func updateModel(_ model: BTSortPanelModel, scrollToConditionAt index: Int? = nil) {
        self.model = model
        setDoneButtonHide(model.autoSort)
        addNewConditionView.setAddable(model.isAddable)
        updateEmptyView()
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
    
    private func updateEmptyView() {
        let desc = BundleI18n.SKResource.Bitable_Record_NoSortCondition
        if model.conditions.isEmpty {
            emptyView.updateShowType(.showNoData(desc: desc))
        } else {
            emptyView.updateShowType(.hide)
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
    
    private func setupContentView() {
        noticeView.isHidden = true
        contentView.addSubview(conditionListView)
        contentView.addSubview(emptyView)
        contentView.addSubview(addNewConditionView)
        contentView.addSubview(noticeView)
        
        addNewConditionView.setAddable(model.isAddable)
        addNewConditionView.didTapAddButton = { [weak self] in
            guard let self = self else { return }
            if self.model.isAddable {
                self.changeViewHeightMode(.maxHeight)
            }
            self.delegate?.sortPanelControllerDidTapAddNewCondition(self)
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
    
    override func didClickDoneButton() {
        self.delegate?.sortPanelControllerDidTapDone(self)
    }
    
    override func didClickMask() {
        self.delegate?.sortPanelControllerDidTapClose(self)
    }
}

extension BTSortPanelController: UITableViewDelegate, UITableViewDataSource {
    
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
        case .autoSort?:
            return model.conditions.count > 0 ? 1 : 0
        case .condition?:
            return model.conditions.count
        default:
            return 0
        }
    }
    
    // nolint: duplicated_code
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SectionType(rawValue: indexPath.section) {
        case .autoSort?:
            let cell = tableView.dequeueReusableCell(withIdentifier: BTAutoSortCell.reuseIdentifier, for: indexPath)
            if let autoSortCell = cell as? BTAutoSortCell {
                autoSortCell.config(autoSort: model.autoSort, enable: !model.isPartial)
                autoSortCell.didChangeAutoSortTo = {[weak self] isAutoSort in
                    guard let self = self else { return }
                    self.delegate?.sortPanelController(self, didChange: isAutoSort)
                }
                autoSortCell.didTapSwitch = { [weak self] in
                    guard let self = self, self.model.isPartial else {
                        return
                    }
                    UDToast.showTips(with: BundleI18n.SKResource.Bitable_Mobile_DataOverLimitNotSupport_Desc, on: self.view)
                }
            }
            return cell
        case .condition?:
            let cell = tableView.dequeueReusableCell(withIdentifier: BTConditionSelectCell.reuseIdentifier, for: indexPath)
            if let conditonCell = cell as? BTConditionSelectCell {
                let cellModel = model.conditions[indexPath.row]
                conditonCell.configModel(cellModel)
                conditonCell.delegate = self
                conditonCell.isFirstCell = false
                conditonCell.relayout()
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionType(rawValue: indexPath.section) {
        case .autoSort?:
            return 52
        case .condition?:
            let cellModel = model.conditions[indexPath.row]
            if let height = cellHeightCache[cellModel.conditionId] {
                return height
            } else {
                let height = BTConditionSelectCell.calculateCellHeight(with: cellModel,
                                                                       cellWith: tableView.frame.width,
                                                                       hasTopSpacing: true)
                cellHeightCache[cellModel.conditionId] = height
                return height
            }
        default:
            return 0
        }
    }
}

extension BTSortPanelController: BTConditionSelectCellDelegate {
    
    func didClickDelete(cell: UITableViewCell) {
        guard let index = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        delegate?.sortPanelController(self, didTapDeleteAt: index, conditionModel: self.model.conditions[index])
    }
    
    func didClickContainerButton(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        guard let cellIndex = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        delegate?.sortPanelController(self, didTapItemAt: cellIndex, conditionCell: cell, conditionSubCell: subCell, subCellIndex: index)
    }
    
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {}
}
