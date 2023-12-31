//
//  MinutesHomeFilterViewController.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/13.
//

import Foundation
import LarkUIKit
import EENavigator
import MinutesFoundation
import MinutesNetwork

struct FilterCondition {
    var ownerType: MinutesOwnerType
    var rankType: MinutesRankType
    var schedulerType: MinutesSchedulerType
    var isConditionSelected: Bool
    var isArrowUp: Bool
    var hasArrow: Bool
    var isEnabled: Bool = true
    var isBelongTo: Bool = false
}

protocol FilterInfoDelegate: AnyObject {
    func confirmInfo(filterInfo: FilterInfo)
}

class MinutesHomeFilterViewController: UIViewController {

    private var filterInfo: FilterInfo

    var isRegular: Bool = false

    weak var delegate: FilterInfoDelegate?

    private var minutesSpaceType: MinutesSpaceType

    private var viewModel: MinutesHomeFilterViewModel

    private let tracker = BusinessTracker()

    var viewHeight: Int {
        viewModel.viewHeight
    }
    
    private lazy var minutesHomeFiletrPanel: MinutesHomeFiletrPanel = {
        var minutesHomeFiletrPanel = MinutesHomeFiletrPanel(isRegular: self.isRegular)
        minutesHomeFiletrPanel.delegate = self
        return minutesHomeFiletrPanel
    }()

    private var collectionLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        if isRegular {
            layout.itemSize = CGSize(width: 164, height: 40)
            layout.minimumLineSpacing = 16
            layout.minimumInteritemSpacing = 14
        } else {
            layout.itemSize = CGSize(width: (view.bounds.width - 48) / 2, height: 36)
            layout.minimumLineSpacing = 12
            layout.minimumInteritemSpacing = 14
        }
        layout.scrollDirection = .vertical
        return layout
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.register(MinutesHomeFilterConditionCell.self, forCellWithReuseIdentifier: MinutesHomeFilterConditionCell.description())
        collectionView.register(MinutesHomeFilterCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: MinutesHomeFilterCollectionHeader.description())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        return collectionView
    }()

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    init(filterInfo: FilterInfo) {
        self.minutesSpaceType = filterInfo.spaceType
        self.filterInfo = filterInfo
        self.viewModel = MinutesHomeFilterViewModel(filterInfo: filterInfo)
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        MinutesLogger.detail.info("no leak")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(tapGestureRecognizer)
        view.addSubview(minutesHomeFiletrPanel)
        view.addSubview(collectionView)

        tapGestureRecognizer.cancelsTouchesInView = false
        if isRegular {
            minutesHomeFiletrPanel.layer.cornerRadius = 12
            minutesHomeFiletrPanel.snp.makeConstraints { maker in
                maker.bottom.equalToSuperview()
                maker.left.right.equalToSuperview()
                maker.height.equalTo(viewModel.viewHeight)
            }

            collectionView.snp.makeConstraints { maker in
                maker.top.equalTo(minutesHomeFiletrPanel.snp.top).offset(48)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(viewModel.viewHeight - 144)
            }
        } else {
            minutesHomeFiletrPanel.layer.cornerRadius = 6
            minutesHomeFiletrPanel.snp.makeConstraints { maker in
                maker.bottom.equalToSuperview()
                maker.left.right.equalToSuperview()
                maker.height.equalTo(viewModel.viewHeight)
            }

            collectionView.snp.makeConstraints { maker in
                maker.top.equalTo(minutesHomeFiletrPanel.snp.top).offset(48)
                maker.left.right.equalToSuperview()
                maker.height.equalTo(viewModel.viewHeight - 144)
            }
        }
        viewModel.configCellInfo()
        updateResetStyle()
        trackerFilterIconClick()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func isDefaultStatus() -> Bool {
        if minutesSpaceType == .home {
            var belongToIsInitial = false
            var sortIsInitial = false
            for item in viewModel.homeCellsInfo {
                for subItem in item {
                    if subItem.isConditionSelected {
                        if subItem.isBelongTo {
                            belongToIsInitial = subItem.ownerType == MinutesOwnerType.byAnyone
                        } else {
                            sortIsInitial = subItem.rankType == .createTime
                        }
                    }
                }
            }
            return belongToIsInitial && sortIsInitial
        } else {
            for item in viewModel.cellsInfo where item.isConditionSelected {
                switch minutesSpaceType {
                case .my:
                    return item.rankType == MinutesRankType.createTime && !item.isArrowUp
                case .share:
                    return item.rankType == MinutesRankType.shareTime && !item.isArrowUp
                case .trash:
                    return true
                default:
                    return true
                }
            }
        }
        return true
    }

    func isInArrowType() -> Bool {
        if minutesSpaceType == .share || minutesSpaceType == .my {
            return true
        }
        return false
    }

    func updateResetStyle() {
        let resetStatus = isDefaultStatus()
        minutesHomeFiletrPanel.setResetBtnStyle(resetStatus: resetStatus)
    }
}

extension MinutesHomeFilterViewController: FilterPanelDelegate {
    func dismissSelector() {
        self.dismiss(animated: true, completion: nil)
    }

    func resetFilterPanel() {
        viewModel.setDefaultFilterInfo()
        viewModel.configCellInfo()
        collectionView.reloadData()
        viewModel.setConfirmInfo()
        viewModel.filterInfo.isFilterIconActived = !isDefaultStatus()
        self.delegate?.confirmInfo(filterInfo: viewModel.filterInfo)
        // 停留0.5s，让用户感受到重置了
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismissSelector()
        }
    }
    
    func getSelectedFilterCondition() -> (FilterCondition?, FilterCondition?) {
        var belongToFilter: FilterCondition?
        var sortFilter: FilterCondition?
        for item in viewModel.homeCellsInfo {
            for subItem in item {
                if subItem.isConditionSelected {
                    if subItem.isBelongTo {
                        belongToFilter = subItem
                    } else {
                        sortFilter = subItem
                    }
                }
            }
        }
        return (belongToFilter, sortFilter)
    }

    func confirmAction() {
        viewModel.setConfirmInfo()
        viewModel.filterInfo.isFilterIconActived = !isDefaultStatus()
        self.delegate?.confirmInfo(filterInfo: viewModel.filterInfo)
        switch minutesSpaceType {
        case .home:
            let filter = getSelectedFilterCondition()
            if let belongTo = filter.0 {
                trackerFilterHomeConfirmClick(ownerType: belongTo.ownerType)
            }
            if let filter = filter.1 {
                trackerFilterHomeConfirmClick(ownerType: filter.ownerType)
            }
        case .my, .share, .trash:
            trackerFilterRankConfirmClick()
        default:
            break
        }
        dismissSelector()
    }
}

extension MinutesHomeFilterViewController: UIGestureRecognizerDelegate {
    @objc
    private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        if !minutesHomeFiletrPanel.frame.contains(sender.location(in: self.view)) {
            self.dismiss(animated: true, completion: nil)
            MinutesLogger.detail.info(" Dismiss Area Tapped, dismissing")
        }
    }

}

extension MinutesHomeFilterViewController: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if minutesSpaceType == .home {
            return viewModel.homeCellsInfo.count
        }
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch minutesSpaceType {
        case .home:
            return viewModel.homeCellsInfo[section].count
        case .my, .share:
            if filterInfo.isEnabled {
                return 3
            } else {
                return 2
            }
        case .trash:
            return 2
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard (collectionView.cellForItem(at: indexPath) as? MinutesHomeFilterConditionCell) != nil else {
            return
        }
        
        var filterConditions = minutesSpaceType == .home ? viewModel.homeCellsInfo[indexPath.section] : viewModel.cellsInfo
        if filterConditions[indexPath.row].isConditionSelected {
            if filterConditions[indexPath.row].hasArrow {
                if minutesSpaceType != .home {
                    viewModel.cellsInfo[indexPath.row].isArrowUp = !filterConditions[indexPath.row].isArrowUp
                    collectionView.reloadData()
                }
            }
        } else {
            for i in 0..<filterConditions.count {
                if i == indexPath.row {
                    if minutesSpaceType == .home {
                        viewModel.homeCellsInfo[indexPath.section][i].isConditionSelected = true
                        if isInArrowType() {
                            viewModel.homeCellsInfo[indexPath.section][i].hasArrow = true
                        }
                    } else {
                        viewModel.cellsInfo[i].isConditionSelected = true
                        if isInArrowType() {
                            viewModel.cellsInfo[i].hasArrow = true
                        }
                    }
                } else {
                    if minutesSpaceType == .home {
                        viewModel.homeCellsInfo[indexPath.section][i].isConditionSelected = false
                        viewModel.homeCellsInfo[indexPath.section][i].hasArrow = false
                    } else {
                        viewModel.cellsInfo[i].isConditionSelected = false
                        viewModel.cellsInfo[i].hasArrow = false
                    }
                }
            }

            collectionView.reloadData()
        }

        updateResetStyle()
    }
}

extension MinutesHomeFilterViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: MinutesHomeFilterCollectionHeader.description(), for: indexPath) as? MinutesHomeFilterCollectionHeader {
            sectionHeader.label.text = indexPath.section == 0 ? BundleI18n.Minutes.MMWeb_G_Attribution : BundleI18n.Minutes.MMWeb_G_RecentActions
            sectionHeader.topY = indexPath.section == 0 ? 16 : 28
            return sectionHeader
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: section == 0 ? 48 : 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {     
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesHomeFilterConditionCell.description(), for: indexPath) as? MinutesHomeFilterConditionCell {
            if minutesSpaceType == .home {
                let item = viewModel.homeCellsInfo[indexPath.section][indexPath.row]
                cell.config(item: item, spaceType: minutesSpaceType)
            } else {
                let item = viewModel.cellsInfo[indexPath.row]
                cell.config(item: item, spaceType: minutesSpaceType)
            }
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
}

extension MinutesHomeFilterViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
}

// MARK: - Tracker

extension MinutesHomeFilterViewController {
    func trackerFilterIconClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "items_filter_button"
        trackParams["target"] = "vc_minutes_list_view"
        trackParams["page_name"] = minutesSpaceType.pageName
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerFilterHomeConfirmClick(ownerType: MinutesOwnerType) {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = viewModel.filterInfo.rankType == .schedulerExecuteTime ? "auto_delete_time_order" : "items_filter"
        trackParams["target"] = "vc_minutes_list_view"
        trackParams["page_name"] = minutesSpaceType.pageName
        trackParams["filter_type"] = ownerType.trackerKey
        trackParams["order_type"] = viewModel.filterInfo.asc ? "asc" : "desc"
        tracker.tracker(name: .listClick, params: trackParams)
    }

    func trackerFilterRankConfirmClick() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams["click"] = "items_filter"
        trackParams["target"] = "vc_minutes_list_view"
        trackParams["page_name"] = minutesSpaceType.pageName
        trackParams["show"] = viewModel.filterInfo.rankType.trackerKey
        trackParams["order"] = viewModel.filterInfo.asc ? "earliest_to_latest" : "latest_to_earliest"
        tracker.tracker(name: .listClick, params: trackParams)
    }
}
