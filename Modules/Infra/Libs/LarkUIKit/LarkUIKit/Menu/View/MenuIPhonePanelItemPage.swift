//
//  MenuIPhonePanelItemPage.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/1/29.
//

import Foundation
import UIKit
import LarkBadge
import SnapKit

/// iPhone菜单选项的集合视图
final class MenuIPhonePanelItemPage: UIView {

    /// collectionView的最小行间距
    private let collectionLayoutMinmimumLineSpacing: CGFloat = 12
    /// collectionView的最小选项的间距
    private let collectionLayoutMinimumInteritemSpacing: CGFloat = 4
    /// collectionView的区域偏移量
    private let collectionLayoutSectionInset = UIEdgeInsets(top: 24, left: 16, bottom: 5, right: 16)
    /// 页面圆点底部间距
    private let pageControllerBottomSpacing: CGFloat = 16
    /// 页面圆点的高度
    private let pageControllerHeight: CGFloat = 5

    /// 选项的集合视图
    private var collectionView: UICollectionView?
    /// 集合视图的布局
    private var collectionViewLayout: MenuIPhonePanelItemPageLayout?

    /// 页面圆点
    private var pageIndictorView: UIPageControl?

    /// 父视图的badge路径
    private let parentPath: Path

    /// 当前的视图模型
    private var currentViewModels: [MenuIPhonePanelCellViewModelProtocol] = []

    /// 默认的字号
    private let defaultFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    /// 最小字号
    private let minFont = UIFont.systemFont(ofSize: 12, weight: .regular)

    /// 执行点击事件的代理方法
    weak var delegate: MenuActionDelegate?

    init(parent: Path, itemModels: [MenuItemModelProtocol] = []) {

        self.parentPath = parent
        super.init(frame: .zero)

        self.setupSubViews()
        self.setupStaticConstrain()

        let initViewModels = self.convertItemModelsToViewModels(for: itemModels)
        self.updateViewModels(for: initViewModels)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 初始化子视图
    private func setupSubViews() {
        setupCollectionLayout()
        setupCollectionView()
        setupPageController()
    }

    /// 初始化子视图的约束
    private func setupStaticConstrain() {
        setupCollectionViewStaticConstrain()
        setupPageControllerStaticConstrain()
    }

    /// 初始化集合视图布局
    private func setupCollectionLayout() {
        let newLayout = MenuIPhonePanelItemPageLayout()
        newLayout.sectionInset = self.collectionLayoutSectionInset
        newLayout.minimumInteritemSpacing = self.collectionLayoutMinimumInteritemSpacing
        newLayout.minimumLineSpacing = self.collectionLayoutMinmimumLineSpacing
        newLayout.scrollDirection = .horizontal
        self.collectionViewLayout = newLayout

    }

    /// 初始化集合视图
    private func setupCollectionView() {
        guard let layout = self.collectionViewLayout else {
            return
        }

        if let collectionView = self.collectionView {
            collectionView.removeFromSuperview()
            self.collectionView = nil
        }

        let newCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        newCollectionView.dataSource = self
        newCollectionView.delegate = self
        newCollectionView.bounces = false
        newCollectionView.showsVerticalScrollIndicator = false
        newCollectionView.showsHorizontalScrollIndicator = false
        newCollectionView.isPagingEnabled = true
        newCollectionView.backgroundColor = UIColor.clear
        self.addSubview(newCollectionView)
        self.collectionView = newCollectionView
        newCollectionView.register(MenuIPhonePanelCell.self, forCellWithReuseIdentifier: String(describing: MenuIPhonePanelCell.self))
    }

    /// 初始化圆点
    private func setupPageController() {
        if let pageController = self.pageIndictorView {
            pageController.removeFromSuperview()
            self.pageIndictorView = nil
        }
        let newPageController = UIPageControl()
        newPageController.currentPageIndicatorTintColor = UIColor.ud.colorfulBlue
        newPageController.pageIndicatorTintColor = UIColor.ud.textDisabled
        newPageController.hidesForSinglePage = true
        self.pageIndictorView = newPageController
        self.addSubview(newPageController)
    }

    /// 初始化集合视图的约束
    private func setupCollectionViewStaticConstrain() {
        guard let collectionView = self.collectionView, let layout = self.collectionViewLayout else {
            return
        }
        collectionView.snp.makeConstraints {
            make in
            make.trailing.leading.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(layout.collectionHeight) // 根据layout获取高度
        }
    }

    /// 初始化页面圆点的约束
    private func setupPageControllerStaticConstrain() {
        guard let pageController = self.pageIndictorView else {
            return
        }
        pageController.snp.makeConstraints {
            make in
            make.bottom.equalToSuperview().offset(-self.pageControllerBottomSpacing)
            make.centerX.equalToSuperview()
            make.height.equalTo(self.pageControllerHeight)
        }
    }

    /// 更新集合视图的约束
    private func updateCollectionViewDynamicConstrain() {
        guard let collectionView = self.collectionView, let layout = self.collectionViewLayout else {
            return
        }
        let pageControllerShow = layout.pageNumber > 1
        let bottomHeight = pageControllerShow ? self.pageControllerHeight + self.pageControllerBottomSpacing : 9 // 根据是否有页面原点调整底部间距
        collectionView.snp.updateConstraints {
            make in
            make.height.equalTo(layout.collectionHeight)
            make.bottom.equalToSuperview().offset(-bottomHeight)
        }
    }

    /// 更新模型
    /// - Parameter models: 需要更新的模型
    func updateModels(for models: [MenuItemModelProtocol]) {
        let newViewModels = self.convertItemModelsToViewModels(for: models)
        let deletes = self.findDeleteViewModels(for: newViewModels)
        deletes.map {
            BadgeManager.clearBadge($0.path)
        }
        self.updateViewModels(for: newViewModels)
    }

    /// 将模型转换为视图模型
    /// - Parameter models: 需要转换的数据模型
    /// - Returns: 转换完成的视图模型
    private func convertItemModelsToViewModels(for models: [MenuItemModelProtocol]) -> [MenuIPhonePanelCellViewModelProtocol] {
        models.map {
            MenuIPhonePanelCellViewModel(model: $0, defaultFont: defaultFont, minFont: minFont, parentPath: parentPath, badgeStyle: .strong)
        }
    }

    /// 找到被删除的视图模型
    /// - Parameter news: 新的视图模型
    /// - Returns: 被删除的视图模型
    private func findDeleteViewModels(for news: [MenuIPhonePanelCellViewModelProtocol]) -> [MenuIPhonePanelCellViewModelProtocol] {
        let flapViewModels = self.currentViewModels
        let result = flapViewModels.filter {
            old in
            !news.contains(where: {
                $0.path == old.path // 通过Path比较
            })
        }
        return result
    }

    /// 更新视图
    /// - Parameter viewModels: 需要更新的视图模型
    private func updateViewModels(for viewModels: [MenuIPhonePanelCellViewModelProtocol]) {
        self.currentViewModels = viewModels
        self.updateSubViewContent()
        self.updateCollectionViewDynamicConstrain()
    }

    /// 更新子视图
    private func updateSubViewContent() {
        updateCollectionViewContent()
        updatePageControllerContent()
    }

    /// 更新页面圆点
    private func updatePageControllerContent() {
        guard let pageController = self.pageIndictorView, let layout = self.collectionViewLayout else {
            return
        }
        pageController.numberOfPages = layout.pageNumber
    }

    /// 重新加载collecitonView
    private func updateCollectionViewContent() {
        self.collectionView?.reloadData()
    }

}

extension MenuIPhonePanelItemPage: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.currentViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: MenuIPhonePanelCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        let location = indexPath.row
        guard let panelCell = cell as? MenuIPhonePanelCell else {
            return cell
        }
        panelCell.updateViewModel(viewModel: self.currentViewModels[location])
        panelCell.delegate = self.delegate
        return panelCell
    }
}

extension MenuIPhonePanelItemPage: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MenuIPhonePanelCell else {
            return
        }
        cell.executeAction() // 触发点击事件
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = self.collectionView else {
            return
        }
        /// 滚动完成后判断当前在第几页
        let currentPageNumber = Int(scrollView.contentOffset.x / collectionView.frame.width)
        self.pageIndictorView?.currentPage = currentPageNumber
    }

}
