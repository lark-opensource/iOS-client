//
//  CategoryEditViewController.swift
//  Moments
//
//  Created by liluobin on 2021/5/13.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LKCommonsLogging
import SnapKit
import UniverseDesignToast
import LarkInteraction

final class CategoryEditViewController: BaseUIViewController,
                                  UICollectionViewDelegate,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegateFlowLayout {
    static let logger = Logger.log(CategoryEditViewController.self, category: "Module.Moments.CategoryEditViewController")
    let viewModel: CategoryEditViewModel
    private let disposeBag = DisposeBag()
    var onUserEditing = false
    /// 是否在loadingTab
    var loadingTab = true
    var onUserDrag = false
    lazy var cancelBtn: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.Moment.Lark_Community_Cancel, for: .normal)
        button.setTitleColor(UIColor.ud.N900, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        button.addPointer(.highlight)
        return button
    }()
    var enlargeCell: CagegoryEditCell?
    lazy var defaultLayout: CagegoryFlowLayout = {
        let layout = CagegoryFlowLayout()
        layout.scrollDirection = .vertical
        return layout
    }()
    /// 自定义导航栏
    lazy var navBar: TitleNaviBar = {
        let nav = TitleNaviBar(titleString: BundleI18n.Moment.Lark_Community_Categories)
        if Display.pad {
            nav.addCloseButton { [weak self] in
                self?.cancelBtnClick()
            }
        } else {
            nav.leftViews = [cancelBtn]
        }
        return nav
    }()

    lazy var categoryCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: defaultLayout)
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        let long = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gesture:)))
        long.minimumPressDuration = 0.3
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.addGestureRecognizer(long)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.register(CagegoryEditCell.self, forCellWithReuseIdentifier: CagegoryEditCell.reuseId)
        collectionView.register(CagegoryReusableFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CagegoryReusableFooterView.reuseId)
        collectionView.register(CagegoryReusableHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CagegoryReusableHeaderView.reuseId)
        return collectionView
    }()

    init(viewModel: CategoryEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.viewModel.loadTabs { [weak self] (_) in
            self?.loadingTab = false
            self?.categoryCollectionView.reloadData()
        }
        let maxWidth = self.view.frame.width - 32
        viewModel.headerItems = [CategoryEditHeaderItem(title: BundleI18n.Moment.Lark_Community_Category,
                                                        des: BundleI18n.Moment.Lark_Community_ReorderCategoriesDesc,
                                                        showEditBtn: true,
                                                        maxWidth: maxWidth),
                                 CategoryEditHeaderItem(title: BundleI18n.Moment.Lark_Community_MoreCategories,
                                                        des: BundleI18n.Moment.Lark_Community_ClickToAddCategory,
                                                        showEditBtn: false,
                                                        maxWidth: maxWidth)]
        setupViews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.categoryCollectionView.reloadData()
        }
    }

    func setupViews() {
        view.addSubview(navBar)
        view.addSubview(categoryCollectionView)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(54)
        }
        categoryCollectionView.snp.makeConstraints { (make) in
            make.top.equalTo(navBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        categoryCollectionView.reloadData()
    }

    @objc
    func cancelBtnClick() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func longPress(gesture: UILongPressGestureRecognizer) {
        let state = gesture.state
        switch state {
        case .began:
            guard let selectedIndexPath = categoryCollectionView.indexPathForItem(at: gesture.location(in: categoryCollectionView)) else {
                enlargeCell = nil
                return
            }
            onUserDrag = true
            onUserEditing = true
            updateCellForEditStatusChange()
            let cell = categoryCollectionView.cellForItem(at: selectedIndexPath)
            if let editCell = cell as? CagegoryEditCell,
               editCell.viewModel?.canRemove ?? false,
               selectedIndexPath.section == CategoryEditViewModel.editSection,
               cell?.transform == CGAffineTransform.identity {
                cell?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                cell?.contentView.backgroundColor = UIColor.ud.N300
                enlargeCell = cell as? CagegoryEditCell
            } else {
                enlargeCell = nil
            }
            categoryCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
            enlargeCell?.zoomActionIcon(reduce: true)
        case .changed:
            categoryCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view ?? .init()))
        case .ended:
            categoryCollectionView.endInteractiveMovement()
            onStopCollectionViewDrag()
        default:
            categoryCollectionView.cancelInteractiveMovement()
            onStopCollectionViewDrag()
        }
    }

    private func onStopCollectionViewDrag() {
        onUserDrag = false
        enlargeCell?.transform = CGAffineTransform.identity
        enlargeCell?.zoomActionIcon(reduce: false)
        updateCellForEditStatusChange()
    }

    func updateCanntMoveSectionHeaderForItem(_ item: CategoryEditHeaderItem) {
        let headers = categoryCollectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
         for header in headers {
            if let header = header as? CagegoryReusableHeaderView,
               let headerItem = header.item,
               headerItem === item {
                header.item = item
                break
             }
         }
    }

    func updateCellForEditStatusChange() {
       let headers = categoryCollectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
        for header in headers {
            if let header = header as? CagegoryReusableHeaderView {
                header.isEditing = onUserEditing
            }
        }
        categoryCollectionView.visibleCells.forEach { (cell) in
            if let cell = cell as? CagegoryEditCell {
                cell.viewModel?.onEditing = self.onUserEditing
                cell.updateUI()
                if onUserEditing {
                    cell.startShakeAnimation()
                } else {
                    cell.stopShareAnimation()
                }
            }
        }
    }

    // MARK: - collectionView代理
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.datas.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.datas[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CagegoryEditCell.reuseId, for: indexPath)
        if let categoryCell = cell as? CagegoryEditCell {
            let cellViewModel = viewModel.datas[indexPath.section][indexPath.row]
            cellViewModel.onEditing = onUserEditing
            cellViewModel.section = indexPath.section
            categoryCell.viewModel = cellViewModel
            if onUserEditing {
                cell.removeExistedPointers()
                categoryCell.startShakeAnimation()
            } else {
                cell.addPointer(.lift)
                categoryCell.stopShareAnimation()
            }
            categoryCell.iconTap = { [weak self] (tapCell) in
                self?.moveTapCell(tapCell)
            }
        }
        return cell
    }
    /**
     不同section之间的移动
     */
    private func moveTapCell(_ cell: CagegoryEditCell) {
        guard let indexPath = categoryCollectionView.indexPath(for: cell), self.onUserEditing else {
            return
        }
        if indexPath.section == CategoryEditViewModel.cannotMoveSection {
            let vm = viewModel.datas[CategoryEditViewModel.cannotMoveSection].remove(at: indexPath.row)
            viewModel.datas[CategoryEditViewModel.editSection].append(vm)
            vm.section = CategoryEditViewModel.editSection
            cell.updateIconWithImage(vm.iconImage)
            cell.startShakeAnimation()
            let row = viewModel.datas[CategoryEditViewModel.editSection].count - 1
            categoryCollectionView.moveItem(at: indexPath, to: IndexPath(row: row, section: CategoryEditViewModel.editSection))
        } else {
            let vm = viewModel.datas[CategoryEditViewModel.editSection].remove(at: indexPath.row)
            viewModel.datas[CategoryEditViewModel.cannotMoveSection].insert(vm, at: 0)
            vm.section = CategoryEditViewModel.cannotMoveSection
            cell.updateIconWithImage(vm.iconImage)
            cell.stopShareAnimation()
            categoryCollectionView.moveItem(at: indexPath, to: IndexPath(row: 0, section: CategoryEditViewModel.cannotMoveSection))
        }
        let item = viewModel.headerItems[CategoryEditViewModel.cannotMoveSection]
        item.hadEditItems = !viewModel.datas[CategoryEditViewModel.cannotMoveSection].isEmpty
        updateCanntMoveSectionHeaderForItem(item)
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let idx = viewModel.datas[sourceIndexPath.section].remove(at: sourceIndexPath.row)
        viewModel.datas[destinationIndexPath.section].insert(idx, at: destinationIndexPath.row)
    }

    /// 按钮的点击事件
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.onUserEditing {
            return
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? CagegoryEditCell {
            cell.contentView.backgroundColor = UIColor.ud.N300
        }
        let cellVm = viewModel.datas[indexPath.section][indexPath.row]
        viewModel.selectBlock?(cellVm.tab)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        /// 用户拖拽编辑中
        if !onUserDrag {
            return true
        }
        if indexPath.section == CategoryEditViewModel.cannotMoveSection {
            return false
        }
        return viewModel.datas[indexPath.section][indexPath.row].canRemove
    }

    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        if !onUserDrag {
            return proposedIndexPath
        }
        if proposedIndexPath.section == CategoryEditViewModel.cannotMoveSection {
            return originalIndexPath
        }
        if !viewModel.datas[proposedIndexPath.section][proposedIndexPath.row].canRemove {
            return originalIndexPath
        }
        return proposedIndexPath
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CagegoryReusableHeaderView.reuseId, for: indexPath)
            updateHeaderUIForSection(indexPath.section, view: header)
            return header
        }
        return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: CagegoryReusableFooterView.reuseId, for: indexPath)
    }

    func updateHeaderUIForSection(_ section: Int, view: UICollectionReusableView) {
        guard let header = view as? CagegoryReusableHeaderView, section < viewModel.headerItems.count else {
            return
        }
        let item = viewModel.headerItems[section]
        if section == CategoryEditViewModel.cannotMoveSection {
            item.loadingTab = self.loadingTab
            item.hadEditItems = !viewModel.datas[CategoryEditViewModel.cannotMoveSection].isEmpty
        } else {
            item.loadingTab = false
            item.hadEditItems = true
        }
        header.item = item
        header.isEditing = onUserEditing
        /// 这里header 需要使用weak
        header.editCallBack = { [weak self, weak header] in
            guard let self = self else { return }
            if self.onUserEditing {
                self.viewModel.headerItems[CategoryEditViewModel.editSection].settingTab = true
                self.startConfigTabsWithHeader(header)
            } else {
                self.onUserEditing = true
                self.categoryCollectionView.reloadData()
            }
        }
    }

    func startConfigTabsWithHeader(_ header: CagegoryReusableHeaderView?) {
        header?.showloading()
        self.viewModel.configTabsComplete { [weak self, weak header] (success) in
            guard let self = self else { return }
            if success {
                self.onUserEditing = false
                self.categoryCollectionView.reloadData()
            } else {
                UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_UnableToMakeChangesToast, on: self.view)
            }
            self.viewModel.headerItems[CategoryEditViewModel.editSection].settingTab = false
            header?.hideLoading()
        }
    }

    // MARK: - collectionViewLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if view.bounds.width < 540 {
            return CGSize(width: (view.frame.size.width - 32 - 16) / 2.0, height: 36)
        } else {
            return CGSize(width: (view.frame.size.width - 32 - 32) / 3.0, height: 36)
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section < self.viewModel.headerItems.count else {
            return .zero
        }
        if !onUserEditing {
            return CGSize(width: view.frame.size.width - 32, height: 40)
        }
        return CGSize(width: view.frame.size.width - 32, height: viewModel.headerItems[section].suggestHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != -16 {
            scrollView.contentOffset = CGPoint(x: -16, y: scrollView.contentOffset.y)
        }
    }
}

extension CategoryEditViewController: SwipeContainerViewControllerDelegate {
    func startDrag() {}

    func dismissByDrag() {}

    func disablePanGestureViews() -> [UIView] {
        if self.onUserEditing {
            return self.view.subviews
        }
        return []
    }

    func configSubviewOn(containerView: UIView) {}
}
