//
//  MenuIPadPanel.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/3.
//

import Foundation
import UIKit
import LarkBadge

/// iPad菜单面板
final class MenuIPadPanel: UIView {
    /// 集合视图布局的最小行间距
    private let collectionLayoutMinmimumLineSpacing: CGFloat = 0
    /// 集合视图布局的区域偏移量
    private let collectionLayoutSectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    /// 选项的字号
    private let itemFont = UIFont.systemFont(ofSize: 16, weight: .regular)

    /// 集合视图
    private var collectionView: UICollectionView?
    /// 集合视图布局
    private var collectionViewLayout: MenuIPadPanelLayout?
    /// 父视图的badge路径
    private var parentPath: Path

    /// 当前的选项视图模型
    private var currentItemViewModels: [MenuIPadPanelCellViewModelProtocol] = []

    /// 当前的附加视图
    private var currentFooterAdditionView: MenuAdditionView?

    /// 菜单操作事件的代理
    weak var actionMenuDelegate: MenuActionDelegate?

    init(parentPath: Path, itemModels: [MenuItemModelProtocol] = [], footerView: MenuAdditionView? = nil) {
        self.parentPath = parentPath
        self.currentFooterAdditionView = footerView
        super.init(frame: .zero)

        self.currentItemViewModels = self.convertItemModelsToViewModels(for: itemModels)
        self.adjustViewModelsWhenDataSourceChanged()

        setupSubviews()
        setupStaticConstrain()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化子视图
    private func setupSubviews() {
        setupCollectionLayout()
        setupCollectionView()
    }

    /// 初始化集合视图布局
    private func setupCollectionLayout() {
        let newLayout = MenuIPadPanelLayout()
        newLayout.sectionInset = self.collectionLayoutSectionInset
        newLayout.minimumLineSpacing = self.collectionLayoutMinmimumLineSpacing
        newLayout.scrollDirection = .vertical
        newLayout.updateLayout(for: self.currentItemViewModels, currentAdditionView: self.currentFooterAdditionView)
        self.collectionViewLayout = newLayout
    }

    /// 初始化集合视图
    private func setupCollectionView() {
        if let collectionView = self.collectionView {
            collectionView.removeFromSuperview()
            self.collectionView = nil
        }
        guard let layout = self.collectionViewLayout else {
            return
        }
        let newCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        newCollectionView.delegate = self
        newCollectionView.dataSource = self
        newCollectionView.backgroundColor = UIColor.menu.panelBackgroundColorForIPad
        newCollectionView.bounces = false
        newCollectionView.showsVerticalScrollIndicator = true
        newCollectionView.showsHorizontalScrollIndicator = false
        newCollectionView.register(MenuIPadPanelCell.self, forCellWithReuseIdentifier: String(describing: MenuIPadPanelCell.self))
        newCollectionView.register(MenuFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: MenuFooterView.self))
        self.addSubview(newCollectionView)
        self.collectionView = newCollectionView
    }

    /// 初始化约束
    private func setupStaticConstrain() {
        setupCollectionViewStaticConstrain()
    }

    /// 初始化集合视图的约束
    private func setupCollectionViewStaticConstrain() {
        guard let collectionView = self.collectionView, let layout = self.collectionViewLayout else {
            return
        }
        collectionView.snp.makeConstraints {
            make in
            make.bottom.top.trailing.leading.equalToSuperview()
            make.height.equalTo(layout.collectionViewHeight)
            make.width.equalTo(layout.collectionViewWidth)
        }
    }

    /// 将选项数据转换为视图模型
    /// - Parameter models: 需要转换的数据模型
    /// - Returns: 转换完成的视图模型
    private func convertItemModelsToViewModels(for models: [MenuItemModelProtocol]) -> [MenuIPadPanelCellViewModelProtocol] {
        models.map {
            MenuIPadPanelCellViewModel(model: $0, parentPath: self.parentPath, badgeStyle: .strong, font: self.itemFont)
        }
    }

    /// 找到被删除的选项视图模型
    /// - Parameter news: 新的视图模型
    /// - Returns: 已经被删除的视图模型
    private func findDeleteViewModels(for news: [MenuIPadPanelCellViewModelProtocol]) -> [MenuIPadPanelCellViewModelProtocol] {
        let flapViewModels = self.currentItemViewModels
        let result = flapViewModels.filter {
            old in
            !news.contains(where: {
                $0.path == old.path
            })
        }
        return result
    }

    /// 更新选项视图
    /// - Parameter viewModels: 需要更新的视图模型
    private func updateItemViewModels(for viewModels: [MenuIPadPanelCellViewModelProtocol]) {
        self.currentItemViewModels = viewModels
        self.adjustViewModelsWhenDataSourceChanged()
        self.updateCollectionView()
    }

    /// 当选项视图模型更新后，需要更新视图模型是否显示分割线的标识位
    /// - Parameter viewModels: 新的选项视图模型
    private func adjustViewModelsWhenDataSourceChanged() {
        var newViewModels = self.currentItemViewModels
        for var model in newViewModels {
            model.isShowBorderLine = true
        }
        if self.currentFooterAdditionView == nil {
            var last = newViewModels.last
            last?.isShowBorderLine = false
        }
        self.currentItemViewModels = newViewModels
    }

    /// 更新集合视图
    private func updateCollectionView() {
        self.updateCollectionData()
        self.updateCollectionViewDynamicConstrain()
    }

    /// 更新集合视图的约束
    private func updateCollectionViewDynamicConstrain() {
        guard let collectionView =  self.collectionView, let layout = self.collectionViewLayout else {
            return
        }

        collectionView.snp.updateConstraints {
            make in
            make.height.equalTo(layout.collectionViewHeight)
            make.width.equalTo(layout.collectionViewWidth)
        }

        // 强制刷新布局，否则iPad菜单将显示有问题
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
    }

    /// 更新集合视图数据
    private func updateCollectionData() {
        /// 先要更新layout数据模型
        self.collectionViewLayout?.updateLayout(for: self.currentItemViewModels, currentAdditionView: self.currentFooterAdditionView)
        self.collectionView?.reloadData()
    }

}

extension MenuIPadPanel: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MenuIPadPanelCell else {
            return
        }
        cell.executeAction()
    }
}

extension MenuIPadPanel: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.currentItemViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: MenuIPadPanelCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        let location = indexPath.row
        guard let itemCell = cell as? MenuIPadPanelCell else {
            return cell
        }
        itemCell.updateViewModel(for: self.currentItemViewModels[location])
        itemCell.delegate = self
        return itemCell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let name = String(describing: MenuFooterView.self)
        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: name, for: indexPath)
        guard let footerView = footer as? MenuFooterView else {
            return footer
        }
        footerView.updateFooterView(for: self.currentFooterAdditionView)
        return footerView
    }
}

extension MenuIPadPanel: MenuPanelVisibleProtocol {
    func hide(animation: Bool, duration: Double, complete: ((Bool) -> Void)?) {
        complete?(true)
    }

    func show(animation: Bool, duration: Double, complete: ((Bool) -> Void)?) {
        complete?(true)
    }
}

extension MenuIPadPanel: MenuPanelDataUpdaterProtocol {
    func updatePanelHeader(for view: MenuAdditionView?) {
        assertionFailure("CompactMenu isn't implement this method")
    }

    /// 更新底部视图
    /// - Parameter view: 新的附加视图
    func updatePanelFooter(for view: MenuAdditionView?) {
        self.currentFooterAdditionView = view
        self.adjustViewModelsWhenDataSourceChanged()
        self.updateCollectionView()
    }

    /// 更新选项视图
    /// - Parameter models: 需要更新的数据模型
    func updateItemModels(for models: [MenuItemModelProtocol]) {
        let newViewModels = self.convertItemModelsToViewModels(for: models)
        let deletes = self.findDeleteViewModels(for: newViewModels)
        deletes.map {
            BadgeManager.clearBadge($0.path)
        }
        self.updateItemViewModels(for: newViewModels)
    }
}

extension MenuIPadPanel: MenuActionDelegate {
    func actionMenu(for identifier: String?, autoClose: Bool, animation: Bool, action: (() -> Void)?) {
        self.actionMenuDelegate?.actionMenu(for: identifier, autoClose: autoClose, animation: animation, action: action)
    }
}
