//
//  FeedFilterSortViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/20.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignToast
import UniverseDesignActionPanel
import FigmaKit
import EENavigator
import LarkMessengerInterface
import UIKit
import LarkContainer

typealias Position = (section: Int, row: Int)

final class FeedFilterSortViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.userResolver }

    let viewModel: FilterSortViewModel
    let disposeBag = DisposeBag()

    // 右上保存按钮
    lazy var saveButtonItem: LKBarButtonItem = {
        let item = LKBarButtonItem(image: nil, title: BundleI18n.LarkFeed.Lark_Feed_Save, fontStyle: .medium)
        item.addTarget(self, action: #selector(saveFilterEditor), for: .touchUpInside)
        item.setBtnColor(color: UIColor.ud.primaryContentDefault)
        return item
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    let tableView: FeedFilterSortTableView = {
        let tableView = FeedFilterSortTableView(frame: .zero)
        tableView.lu.register(cellSelf: FilterCell.self)
        tableView.lu.register(cellSelf: FilterEditCell.self)
        tableView.lu.register(cellSelf: FilterCommonlyCell.self)
        tableView.lu.register(cellSelf: FilterRemoveDisableCell.self)
        tableView.lu.register(cellSelf: FeedFilterMoreSetsCell.self)
        tableView.register(HeaderViewWithTitle.self, forHeaderFooterViewReuseIdentifier: HeaderViewWithTitle.identifier)
        tableView.register(MultiTitleHeaderView.self, forHeaderFooterViewReuseIdentifier: MultiTitleHeaderView.identifier)
        tableView.register(FooterViewWithTitle.self, forHeaderFooterViewReuseIdentifier: FooterViewWithTitle.identifier)
        tableView.isEditing = true
        tableView.showsVerticalScrollIndicator = false
        tableView.estimatedSectionHeaderHeight = 40
        tableView.estimatedSectionFooterHeight = 20
        tableView.estimatedRowHeight = 58
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        tableView.separatorStyle = .none
        return tableView
    }()

    init(viewModel: FilterSortViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    override func loadView() {
        let view = FilterSortView()
        view.delegate = self
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind()
        viewModel.getFilters(on: self.view.window)
        FeedTracker.GroupEdit.View()
        addCancelItem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.maxLimitWidth = getTableViewCellWidth()
    }

    override func closeBtnTapped() {
        FeedTeaTrack.trackFilterEditClose()
        FeedTracker.GroupEdit.Click.Close()
        super.closeBtnTapped()
    }

    private func setupViews() {
        self.title = viewModel.getNavTitle()
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
    }

    private func getTableViewCellWidth() -> CGFloat {
        var maxLimitWidth: CGFloat
        if #available(iOS 13, *) {
            if let wrapperView = self.tableView.tableContentWrapper {
                // 由于tableview在iOS13+上用的.insetGrouped类型会拿不到边距值，所以取tableContentWrapper宽度
                maxLimitWidth = wrapperView.frame.size.width
            } else {
                // 如果tableContentWrapper=nil，则默认按边距20来做取值计算
                maxLimitWidth = self.view.frame.size.width - 40
            }
        } else {
            // iOS以下设置了inset值，以此计算获得tableviewcell宽度
            maxLimitWidth = self.view.frame.size.width - self.tableView.alignmentRectInsets.left * 2
        }
        return maxLimitWidth
    }

    private func getItemByIndexPath(_ indexPath: IndexPath) -> FeedFilterModel? {
        guard indexPath.section < viewModel.items.count else { return nil }
        let sectionVM = viewModel.items[indexPath.section]
        guard indexPath.row < sectionVM.rows.count else { return nil }
        return sectionVM.rows[indexPath.row] as? FeedFilterModel
    }

    // 更新用户分组
    @objc
    func saveFilterEditor() {
        guard let filtersModel = viewModel.filtersModel else {
            let info = FeedBaseErrorInfo(type: .error(), errorMsg: "no raw data")
            FeedExceptionTracker.Filter.setting(node: .saveFilterEditor, info: info)
            return
        }
        viewModel.saveFilterEditor(filtersModel)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.closeBtnTapped()
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Legacy_FailedtoLoadTryLater, on: self.view)
            }).disposed(by: disposeBag)
    }

    func showHUD(switchIsOn: Bool) {
        guard let window = self.view.window else {
            assertionFailure("缺少 window")
            return
        }
        if switchIsOn {
            UDToast.showTips(with: BundleI18n.LarkFeed.Lark_Feed_MessageFilterOnToast, on: window)
        } else {
            UDToast.showTips(with: BundleI18n.LarkFeed.Lark_Feed_MessageFilterOffToast, on: window)
        }
    }

    // MARK: 标记的跳转/高亮
    func jumpToTargetIndexIfNeed() {
        guard let targetIndex = self.viewModel.targetIndex else { return }
        DispatchQueue.main.async {
            self.tableView.scrollToRow(at: targetIndex, at: .middle, animated: false)
        }
    }

    func removeHighlight() {
        guard nil != self.viewModel.targetIndex else { return }
        self.viewModel.targetIndex = nil
        self.tableView.reloadData()
    }

    // MARK: - UDActionSheet
    func showActionSheet(sender: UIView, task: @escaping () -> Void, cancel: @escaping () -> Void) {
        let source = UDActionSheetSource(sourceView: sender,
                                         sourceRect: sender.bounds,
                                         arrowDirection: .up)
        let config = UDActionSheetUIConfig(titleColor: UIColor.ud.textPlaceholder, isShowTitle: true, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(BundleI18n.LarkFeed.Lark_FeedFilter_HideFilter_PopUpDesc,
                             font: UIFont.systemFont(ofSize: 14))
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_FeedFilter_HideFilter_Cancel_Button) { cancel() }
        let customItem = UDActionSheetItem(
            title: BundleI18n.LarkFeed.Lark_FeedFilter_HideFilter_Hide_Button,
            titleColor: UIColor.ud.functionDangerContentDefault,
            style: .default,
            isEnable: true,
            action: { task() }
        )
        actionSheet.addItem(customItem)
        userResolver.navigator.present(actionSheet, from: self)
    }

    func moveFilterOption(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let deleteSectionVM = self.viewModel.itemsMap[.delete], deleteSectionVM.section < self.viewModel.items.count else { return }
        let previousUserCount = deleteSectionVM.rows.count
        let newArray = self.viewModel.exchange(from: (sourceIndexPath.section, sourceIndexPath.row),
                                               to: (destinationIndexPath.section, destinationIndexPath.row))
        self.viewModel.update(newArray)
        guard let deleteVM = self.viewModel.itemsMap[.delete], deleteVM.section < self.viewModel.items.count else { return }
        let nowUserCount = deleteVM.rows.count
        self.viewModel.autoCheckSwitchState(previousUserCount: previousUserCount, nowUserCount: nowUserCount)
        self.tableView.reloadData()
    }

    // MARK: - UITableViewDelegate
    // 是否可以编辑
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section < viewModel.items.count else { return false }
        let sectionVM = viewModel.items[indexPath.section]
        return sectionVM.editEnable
    }

    // 编辑模式下row的样式
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard indexPath.section < viewModel.items.count else { return .none }
        let sectionVM = viewModel.items[indexPath.section]
        guard indexPath.row < sectionVM.rows.count,
              let item = sectionVM.rows[indexPath.row] as? FeedFilterModel else {
            return .none
        }
        return item.style
    }

    // 编辑模式出现的字符串，会根据字符串自适应宽度
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return BundleI18n.LarkFeed.Lark_Feed_Remove
    }

    // 编辑模式下触发的方法
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let item = getItemByIndexPath(indexPath) else { return }
        guard let deleteSectionVM = viewModel.itemsMap[.delete], deleteSectionVM.section < viewModel.items.count else { return }
        let newIndexPath: IndexPath
        switch editingStyle {
        case .delete:
            FeedTracker.GroupEdit.Click.Minus()
            guard let insertSectionVM = viewModel.itemsMap[.insert], insertSectionVM.section < viewModel.items.count else { return }
            newIndexPath = IndexPath(row: 0, section: insertSectionVM.section)
        case .insert:
            FeedTracker.GroupEdit.Click.Plus()
            newIndexPath = IndexPath(row: deleteSectionVM.rows.count, section: deleteSectionVM.section)
        default:
            return
        }

        if viewModel.needShowTips(item.filterItem.type),
           let insertSectionVM = viewModel.itemsMap[.insert],
           newIndexPath.section == insertSectionVM.section {
            // 移除选项
            showActionSheet(
                sender: self.view,
                task: { [weak self] in
                    self?.moveFilterOption(from: indexPath, to: newIndexPath)
                }, cancel: {})
        } else {
            // 增加选项
            moveFilterOption(from: indexPath, to: newIndexPath)
        }
    }

    // MARK: 移动模式
    // 是否可以移动row
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        guard let item = getItemByIndexPath(indexPath) else { return false }
        return item.moveEnable
    }

    // 预判断move的cell将要停留的位置，如果是在section1或者section0的row0，那么就返回原位置。反之，则返回目标位置
    func tableView(_ tableView: UITableView,
                   targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard let item = getItemByIndexPath(sourceIndexPath),
              let deleteSectionVM = viewModel.itemsMap[.delete], deleteSectionVM.section < viewModel.items.count,
              let insertSectionVM = viewModel.itemsMap[.insert], insertSectionVM.section < viewModel.items.count,
              (proposedDestinationIndexPath.section == deleteSectionVM.section ||
               proposedDestinationIndexPath.section == insertSectionVM.section) else {
            return sourceIndexPath
        }

        if proposedDestinationIndexPath.section == deleteSectionVM.section,
           proposedDestinationIndexPath.row == 0 {
            return sourceIndexPath
        }

        // 判断免打扰分组不允许隐藏
        if !Feed.Feature(userResolver).groupSettingEnable, item.filterItem.type == .mute, proposedDestinationIndexPath.section == insertSectionVM.section {
            return sourceIndexPath
        }

        return proposedDestinationIndexPath
    }

    // 移动row触发的方法
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // 先移动选项
        moveFilterOption(from: sourceIndexPath, to: destinationIndexPath)
        guard let item = getItemByIndexPath(destinationIndexPath),
              viewModel.needShowTips(item.filterItem.type),
              let insertSectionVM = viewModel.itemsMap[.insert], destinationIndexPath.section == insertSectionVM.section,
              let deleteSectionVM = viewModel.itemsMap[.delete], sourceIndexPath.section == deleteSectionVM.section else { return }
        // 需要撤销时才会移动选项
        showActionSheet(
            sender: self.view,
            task: { [weak self] in
                guard let self = self else { return }
                let newArray = self.viewModel.updateItem(from: (destinationIndexPath.section, destinationIndexPath.row))
                self.viewModel.update(newArray)
                self.tableView.reloadData()
            }, cancel: { [weak self] in
                self?.moveFilterOption(from: destinationIndexPath, to: sourceIndexPath)
            })
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < viewModel.items.count else {
            return 0
        }
        let sectionVM = viewModel.items[section]
        return sectionVM.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < viewModel.items.count else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        let sectionVM = viewModel.items[indexPath.section]

        guard indexPath.row < sectionVM.rows.count else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        var item = sectionVM.rows[indexPath.row]

        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? FeedFilterSortBaseCell {
            item.isLastRow = indexPath.row == sectionVM.rows.count
            cell.item = item
            if let filterCell = cell as? FilterCell {
                var color = UIColor.ud.bgFloat
                if let targetIndex = viewModel.targetIndex, targetIndex == indexPath {
                    color = UIColor.ud.Y50
                }
                filterCell.updateBackgroundColor(color)
                return filterCell
            }
            return cell
        }

        return UITableViewCell(style: .default, reuseIdentifier: "cell")
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < viewModel.items.count else {
            return UIView()
        }
        let sectionVM = viewModel.items[section]

        guard !sectionVM.headerIdentifier.isEmpty,
           let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionVM.headerIdentifier) as? FeedFilterSectionHeaderProtocol else {
            return nil
        }
        sectionHeader.setText(sectionVM.headerTitle, sectionVM.headerSubTitle)
        return sectionHeader
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < viewModel.items.count else {
            return UIView()
        }
        let sectionVM = viewModel.items[section]
        guard !sectionVM.footerIdentifier.isEmpty,
           let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionVM.footerIdentifier) as? FooterViewWithTitle else {
            return UIView()
        }
        sectionHeader.titleLabel.text = sectionVM.footerTitle
        return sectionHeader
    }
}
