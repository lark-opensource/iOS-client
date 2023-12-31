//
//  SpaceFilterSortPanelController.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/8/26.
//
// disable-lint: magic number

import Foundation
import SKUIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignButton
import SKCommon
import SKResource
import SKFoundation

protocol SpaceFilterSortPanelDelegate: AnyObject {
    // 选中 filter 或 sortRule 时，遍历所有可能的组合判断是否需要置灰、弹 toast
    func invalidReasonForCombination(filterOption: SpaceFilterHelper.FilterOption, sortOption: SpaceSortHelper.SortOption, panel: SpaceFilterSortPanelController) -> String?
    func filterSortPanel(_ panel: SpaceFilterSortPanelController, didConfirmWith filterIndex: Int, sortIndex: Int)
    func didClickResetFor(filterSortPanel: SpaceFilterSortPanelController)
}

extension SpaceFilterSortPanelController {

    typealias FilterOption = SpaceFilterHelper.FilterOption
    typealias SortOption = SpaceSortHelper.SortOption

    private enum Layout {
        static var headerSectionHeight = 48
        static var buttonHeight = 40

        static var itemHeight: CGFloat { 32 }
        static var itemHorizontalSpacing: CGFloat { 13 }
        static var itemVerticalSpacing: CGFloat { 12 }
        static var collectionViewContentInsets: UIEdgeInsets {
            UIEdgeInsets(top: 12, left: 16, bottom: 0, right: 16)
        }
        static var collectionViewSectionInsets: UIEdgeInsets {
            UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        }
        static var collectionViewSectionHeaderHeight: CGFloat { 40 }

        static func collectionViewHeight(filterItemCount: Int, sortItemCount: Int) -> CGFloat {
            let filterSectionHeight = sectionHeight(itemCount: filterItemCount)
            let sortSectionHeight = sectionHeight(itemCount: sortItemCount)

            return Self.collectionViewContentInsets.top
                + filterSectionHeight
                + sortSectionHeight
                + Self.collectionViewContentInsets.bottom
        }

        private static func sectionHeight(itemCount: Int) -> CGFloat {
            let lineCount = (itemCount + 1) / 2
            return CGFloat(lineCount) * (Self.itemHeight + itemVerticalSpacing)
                - itemVerticalSpacing
                + collectionViewSectionHeaderHeight
                + collectionViewSectionInsets.top
                + collectionViewSectionInsets.bottom
        }
    }
}

class SpaceFilterSortPanelController: SKBlurPanelController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.CreationMobile_Space_FilterNSort)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = .clear
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = Layout.collectionViewSectionInsets
        layout.minimumLineSpacing = Layout.itemVerticalSpacing
        layout.minimumInteritemSpacing = Layout.itemHorizontalSpacing
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.contentInset = Layout.collectionViewContentInsets
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SpacePanelCell.self, forCellWithReuseIdentifier: SpacePanelCell.reuseIdentifier)
        collectionView.register(PanelHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PanelHeaderView.reuseIdentifier)
        collectionView.allowsMultipleSelection = true
        return collectionView
    }()

    private lazy var resetButton: UIButton = {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderComponent,
                                                      backgroundColor: UDColor.bgFloat,
                                                      textColor: UDColor.textTitle)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UDColor.lineBorderComponent,
                                                      backgroundColor: UDColor.udtokenComponentOutlinedBg,
                                                       textColor: UDColor.textDisabled)
        let config = UDButtonUIConifg(normalColor: normalColor, disableColor: disableColor)
        let button = UDButton(config)
        button.docs.addStandardLift()
        button.setTitle(BundleI18n.SKResource.Doc_List_Filter_Reset, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: #selector(didClickReset), for: .touchUpInside)
        return button
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_List_Filter_Done, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UDColor.primaryContentDefault
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.docs.addStandardLift()
        button.addTarget(self, action: #selector(didClickConfirm), for: .touchUpInside)
        return button
    }()

    private var filterIndex: Int
    let filterOptions: [FilterOption]
    let defaultFilterOption: FilterOption
    private var sortIndex: Int
    let sortOptions: [SortOption]
    let defaultSortOption: SortOption

    weak var delegate: SpaceFilterSortPanelDelegate?

    convenience init(config: SpaceSortFilterConfigV2) {
        self.init(filterOptions: config.filterOptions,
                  filterSelectionIndex: config.filterIndex,
                  defaultFilterOption: config.defaultFilterOption,
                  sortOptions: config.sortOptions,
                  sortSelectionIndex: config.sortIndex,
                  defaultSortOption: config.defaultSortOption)
    }

    init(filterOptions: [FilterOption],
         filterSelectionIndex: Int,
         defaultFilterOption: FilterOption,
         sortOptions: [SortOption],
         sortSelectionIndex: Int,
         defaultSortOption: SortOption) {
        self.filterOptions = filterOptions
        if filterSelectionIndex >= filterOptions.count {
            assertionFailure()
            filterIndex = 0
        } else {
            filterIndex = filterSelectionIndex
        }
        self.defaultFilterOption = defaultFilterOption
        self.sortOptions = sortOptions
        if sortSelectionIndex >= sortOptions.count {
            assertionFailure()
            sortIndex = 0
        } else {
            sortIndex = sortSelectionIndex
        }
        self.defaultSortOption = defaultSortOption
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Override
    public override func setupUI() {
        super.setupUI()

        containerView.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }

        let collectionViewHeight = Layout.collectionViewHeight(filterItemCount: filterOptions.count, sortItemCount: sortOptions.count)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.height.equalTo(collectionViewHeight)
        }

        containerView.addSubview(resetButton)
        containerView.addSubview(confirmButton)
        resetButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalTo(collectionView.snp.bottom).offset(8)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(24)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.left.equalTo(resetButton.snp.right).offset(Layout.itemHorizontalSpacing)
            make.width.height.top.bottom.equalTo(resetButton)
        }
        updateResetButton()
        collectionView.selectItem(at: IndexPath(item: filterIndex, section: 0), animated: false, scrollPosition: [])
        collectionView.selectItem(at: IndexPath(item: sortIndex, section: 1), animated: false, scrollPosition: [])
    }

    public override func transitionToRegularSize() {
        super.transitionToRegularSize()
        headerView.toggleCloseButton(isHidden: true)
    }

    public override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        headerView.toggleCloseButton(isHidden: false)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else { return }
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return filterOptions.count
        } else if section == 1 {
            return sortOptions.count
        } else {
            assertionFailure()
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PanelHeaderView.reuseIdentifier, for: indexPath)
        guard let headerView = view as? PanelHeaderView else {
            assertionFailure()
            return view
        }
        if indexPath.section == 0 {
            headerView.titleLabel.text = BundleI18n.SKResource.Doc_List_Filter_By_Type
        } else {
            headerView.titleLabel.text = BundleI18n.SKResource.Doc_List_Filter_Recent_Activity
        }
        return headerView
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpacePanelCell.reuseIdentifier, for: indexPath)
        guard let panelCell = cell as? SpacePanelCell else {
            assertionFailure()
            return cell
        }
        if indexPath.section == 0 {
            guard indexPath.item < filterOptions.count else {
                assertionFailure()
                return panelCell
            }
            let option = filterOptions[indexPath.item]
            panelCell.titleLabel.text = option.displayName
            let selectedSortOption = sortOptions[sortIndex]
            if let invalidReason = delegate?.invalidReasonForCombination(filterOption: option, sortOption: selectedSortOption, panel: self) {
                panelCell.validState = .invalid(reason: invalidReason)
            }
        } else {
            guard indexPath.item < sortOptions.count else {
                assertionFailure()
                return panelCell
            }
            let option = sortOptions[indexPath.item]
            panelCell.titleLabel.text = option.type.displayName
            let selectedFilterOption = filterOptions[filterIndex]
            if let invalidReason = delegate?.invalidReasonForCombination(filterOption: selectedFilterOption, sortOption: option, panel: self) {
                panelCell.validState = .invalid(reason: invalidReason)
            }
        }
        return panelCell
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return false }
        guard let spaceCell = cell as? SpacePanelCell else { return false }
        if case let .invalid(reason) = spaceCell.validState {
            UDToast.showFailure(with: reason, on: view.window ?? view)
            return false
        }
        // 同 section 选项间互斥
        collectionView.indexPathsForSelectedItems?
            .filter { $0.section == indexPath.section }
            .forEach { collectionView.deselectItem(at: $0, animated: false) }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        false
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            filterIndex = indexPath.item
            UIView.performWithoutAnimation {
                collectionView.reloadSections([1])
                collectionView.selectItem(at: IndexPath(item: sortIndex, section: 1), animated: false, scrollPosition: [])
            }
        } else {
            sortIndex = indexPath.item
            UIView.performWithoutAnimation {
                collectionView.reloadSections([0])
                collectionView.selectItem(at: IndexPath(item: filterIndex, section: 0), animated: false, scrollPosition: [])
            }
        }
        updateResetButton()
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (collectionView.frame.width
                            - Layout.collectionViewContentInsets.left
                            - Layout.collectionViewContentInsets.right
                            - Layout.itemHorizontalSpacing)
            / 2
        return CGSize(width: itemWidth, height: Layout.itemHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: 0, height: Layout.collectionViewSectionHeaderHeight)
    }

    // MARK: - Filter Picker Logic

    private func updateResetButton() {
        let selectedFilterOption = filterOptions[filterIndex]
        let selectedSortOption = sortOptions[sortIndex]
        resetButton.isEnabled = selectedFilterOption != defaultFilterOption || selectedSortOption != defaultSortOption
    }

    @objc
    private func didClickConfirm() {
        delegate?.filterSortPanel(self, didConfirmWith: filterIndex, sortIndex: sortIndex)
        dismiss(animated: true)
    }

    @objc
    private func didClickReset() {
        collectionView.indexPathsForSelectedItems?.forEach { indexPath in
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        let filterIndex = filterOptions.firstIndex(of: defaultFilterOption) ?? 0
        let sortIndex = sortOptions.firstIndex(of: defaultSortOption) ?? 0
        collectionView.selectItem(at: IndexPath(item: filterIndex, section: 0), animated: false, scrollPosition: [])
        collectionView.selectItem(at: IndexPath(item: sortIndex, section: 1), animated: false, scrollPosition: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [self] in
            delegate?.didClickResetFor(filterSortPanel: self)
            dismiss(animated: true)
        }
    }
}

private class PanelHeaderView: UICollectionReusableView {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.left.right.equalToSuperview()
        }
    }
}
