//
//  BTSortControllerV2.swift
//  SKBitable
//
//  Created by X-MAN on 2023/8/28.
//

import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignTabs
import UniverseDesignLoading
import UniverseDesignToast

protocol BTSortPanelControllerDelegateV2: AnyObject {
    func sortPanelControllerDidTapAddNewCondition(_ controller: BTSortControllerV2)
    func sortPanelControllerDidTapDone(_ controller: BTSortControllerV2)
    func sortPanelControllerDidTapClose(_ controller: BTSortControllerV2)
    func sortPanelController(_ controller: BTSortControllerV2, didChange autoSort: Bool)
    func sortPanelController(_ controller: BTSortControllerV2,
                             didTapDeleteAt index: Int,
                             conditionModel: BTConditionSelectCellModel)
    func sortPanelController(_ controller: BTSortControllerV2,
                             didTapItemAt index: Int,
                             conditionCell: UITableViewCell,
                             conditionSubCell: UICollectionViewCell?,
                             subCellIndex: Int)
    func sortControllerWillShow(_ controller: BTSortControllerV2)
}


final class BTSortControllerV2: UIViewController {
    
    enum SectionType: Int, CaseIterable {
        case autoSort
        case condition
    }
    
    struct Const {
        static let bottomInset: CGFloat = 16.0
        static let bottomSpacing: CGFloat = 8.0
    }
    
    weak var delegate: BTSortPanelControllerDelegateV2?
    
    private(set) var model: BTSortPanelModel = BTSortPanelModel()
    
    private(set) var cellHeightCache: [String: CGFloat] = [:]
    
    private let addNewConditionView = BTBottomAddConditionView()
    private let applyConditionView = SortApplyView()
    
    private lazy var noticeView = BTFieldUnreadableNitceView()
    
    private lazy var loadingView = UDLoading.loadingImageView()
    
    // 告知父容器需要变高
    var changeContainerHeightBlock: ((BTDraggableViewController.ViewHeightMode, Bool) -> Void)?
    
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
    init(model: BTSortPanelModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
//        self.doneButtonTitle = BundleI18n.SKResource.Bitable_Common_Apply_Button
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
    
    func updateModel(_ model: BTSortPanelModel, scrollToConditionAt index: Int? = nil) {
        self.model = model
//        setDoneButtonHide(model.autoSort)
        updateAutoSort(autoSort: model.autoSort)
        addNewConditionView.setAddable(model.isAddable)
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
    
    private func updateAutoSort(autoSort: Bool) {
        guard applyConditionView.isHidden != autoSort else {
            return
        }
        guard applyConditionView.superview != nil else {
            return
        }
        applyConditionView.isHidden = autoSort
        if autoSort {
            addNewConditionView.updateButtonConstraints(letfMargin: Const.bottomInset,
                                                        rightMargin: Const.bottomInset)
            addNewConditionView.snp.remakeConstraints {
                $0.left.right.bottom.equalToSuperview()
            }
        } else {
            let addWidth = addNewConditionView.minWidth()
            let applyWidth = applyConditionView.minWidth()
            let itemWidth = max(addWidth, applyWidth)
            let contentMaxWidth = (view.bounds.width - Const.bottomInset * 2 - Const.bottomSpacing) / 2.0
            // |16-16||16-16| -> |16-4||4-16|
            if itemWidth < contentMaxWidth {
                applyConditionView.updateTopLine(hidden: false)
                addNewConditionView.updateButtonConstraints(letfMargin: Const.bottomInset,
                                                            rightMargin: Const.bottomSpacing / 2.0)
                applyConditionView.updateButtonConstraints(letfMargin: Const.bottomSpacing / 2.0,
                                                           rightMargin: Const.bottomInset)
                addNewConditionView.snp.remakeConstraints {
                    $0.left.bottom.equalToSuperview()
                    $0.width.equalToSuperview().multipliedBy(0.5)
                }
                applyConditionView.snp.remakeConstraints {
                    $0.right.bottom.equalToSuperview()
                    $0.left.equalTo(addNewConditionView.snp.right)
                }
            } else {
                applyConditionView.updateTopLine(hidden: true)
                addNewConditionView.updateButtonConstraints(letfMargin: Const.bottomInset,
                                                            rightMargin: Const.bottomInset)
                applyConditionView.updateButtonConstraints(letfMargin: Const.bottomInset,
                                                           rightMargin: Const.bottomInset)
                applyConditionView.snp.remakeConstraints {
                    $0.right.bottom.equalToSuperview()
                    $0.left.equalToSuperview()
                }
                addNewConditionView.snp.remakeConstraints {
                    $0.left.right.equalToSuperview()
                    $0.bottom.equalTo(applyConditionView.snp.top)
                }
            }
        }
        
    }
    
    private func updateEmptyView(isInitial: Bool) {
        guard !isInitial else {
            loadingView.isHidden = false
            emptyView.updateShowType(.hide)
            return
        }
        let desc = BundleI18n.SKResource.Bitable_Record_NoSortCondition
        if model.conditions.isEmpty {
            emptyView.updateShowType(.showNoData(desc: desc))
        } else {
            emptyView.updateShowType(.hide)
        }
        loadingView.isHidden = true
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
                let inset: CGFloat = showNotice ? 16 : 0
                make.top.left.right.equalToSuperview().inset(inset)
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
    
    private func setupContentView() {
        noticeView.isHidden = true
        view.addSubview(conditionListView)
        view.addSubview(emptyView)
        view.addSubview(addNewConditionView)
        view.addSubview(applyConditionView)
        view.addSubview(noticeView)
        view.addSubview(loadingView)
        applyConditionView.isHidden = true
        addNewConditionView.setAddable(model.isAddable)
        addNewConditionView.didTapAddButton = { [weak self] in
            guard let self = self else { return }
            if self.model.isAddable {
                self.changeContainerHeightBlock?(.maxHeight, true)
            }
            self.delegate?.sortPanelControllerDidTapAddNewCondition(self)
        }
        
        applyConditionView.didTapApplyButton = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.sortPanelControllerDidTapDone(self)
        }
        
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

extension BTSortControllerV2: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionType.allCases.count
    }
    
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SectionType(rawValue: section) {
        case .autoSort?:
            return !model.conditions.isEmpty ? 1 : 0
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
                    self.updateAutoSort(autoSort: isAutoSort)
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

extension BTSortControllerV2: BTConditionSelectCellDelegate {
    
    func didClickDelete(cell: UITableViewCell) {
        guard let index = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        delegate?.sortPanelController(self,
                                      didTapDeleteAt: index,
                                      conditionModel: self.model.conditions[index])
    }
    
    func didClickContainerButton(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        guard let cellIndex = conditionListView.indexPath(for: cell)?.item else {
            return
        }
        delegate?.sortPanelController(self,
                                      didTapItemAt:
                                        cellIndex,
                                      conditionCell: cell,
                                      conditionSubCell: subCell,
                                      subCellIndex: index)
    }
    
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {}
}

extension BTSortControllerV2: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        self.view
    }
    /// 可选实现，列表将要显示的时候调用
    func listWillAppear() {
        if model.conditions.isEmpty {
            emptyView.updateShowType(.hide)
            loadingView.isHidden = false
        }
        delegate?.sortControllerWillShow(self)
    }
}
