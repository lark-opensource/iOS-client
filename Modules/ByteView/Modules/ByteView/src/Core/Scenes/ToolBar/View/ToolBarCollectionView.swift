//
//  ToolBarCollectionView.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit
import ByteViewUI

protocol ToolBarCollectionViewDelegate: AnyObject {
    func toolbarCollectionViewDidScroll(_ collectionView: UICollectionView)
}

struct ToolBarCollectionViewConfigurator: Equatable {
    var itemHeight: CGFloat
    var rowInset: CGFloat
    var topPadding: CGFloat
    var bottomPadding: CGFloat
    var horizontalPadding: CGFloat
    let numberOfRows: Int

    static let portrait = ToolBarCollectionViewConfigurator(itemHeight: 90, rowInset: 8,
                                                            topPadding: 30, bottomPadding: 8,
                                                            horizontalPadding: 12, numberOfRows: 10)
    static let landscape = ToolBarCollectionViewConfigurator(itemHeight: 82, rowInset: 4,
                                                             topPadding: 24, bottomPadding: 0,
                                                             horizontalPadding: 8, numberOfRows: 2)
}

class ToolBarCollectionView: UIView {
    weak var delegate: ToolBarCollectionViewDelegate?

    private var items: [ToolBarItem] = []
    private static let portraitCellID = "ToolBarPortraitCell"
    private static let landscapeCellID = "ToolBarLandscapeCellID"
    private static let portraiMyAiCellID = "portraiMyAiCellID"
    private static let landscapeMyAiCellID = "landscapeMyAiCellID"
    private let fullWidth: CGFloat
    private let configurator: ToolBarCollectionViewConfigurator
    lazy var layout: ToolBarPagableCollectionViewFlowLayout = {
        let layout = ToolBarPagableCollectionViewFlowLayout(numberOfRows: configurator.numberOfRows, fullWidth: fullWidth)
        layout.itemHeight = configurator.itemHeight
        layout.rowInset = configurator.rowInset
        layout.topPadding = configurator.topPadding
        layout.bottomPadding = configurator.bottomPadding
        layout.horizontalPadding = configurator.horizontalPadding
        return layout
    }()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .never
        if isLandscapeMode {
            collectionView.register(ToolBarLandscapeCollectionCell.self, forCellWithReuseIdentifier: Self.landscapeCellID)
            collectionView.register(ToolBarMyAILandscapeCollectionCell.self, forCellWithReuseIdentifier: Self.landscapeMyAiCellID)
        } else {
            collectionView.register(ToolBarCollectionCell.self, forCellWithReuseIdentifier: Self.portraitCellID)
            collectionView.register(ToolBarMyAICollectionCell.self, forCellWithReuseIdentifier: Self.portraiMyAiCellID)
        }
        return collectionView
    }()

    var numberOfPages = 0
    var countOfItems: Int {
        items.count
    }
    var isLandscapeMode: Bool

    init(frame: CGRect, isLandscape: Bool) {
        self.isLandscapeMode = isLandscape
        if isLandscape {
            self.configurator = .landscape
            self.fullWidth = LandscapeMoreViewController.Layout.containerWidth
        } else {
            self.configurator = .portrait
            self.fullWidth = VCScene.isPhoneLandscape ? VCScene.bounds.height : VCScene.bounds.width
        }
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func initCollectionItems(_ items: [ToolBarItem]) {
        self.items = items
        updatePageControl()
        collectionView.reloadData()
    }

    func update(item: ToolBarItem, collectionItems: [ToolBarItemType]) -> [ToolBarItem] {
        UIView.performWithoutAnimation {
            let newIsShowing = item.phoneLocation == .more
            if let position = items.firstIndex(where: { $0.itemType == item.itemType }) {
                if newIsShowing {
                    // 原来就存在，更新显示
                    collectionView.reloadItems(at: [IndexPath(item: position, section: 0)])
                } else {
                    // 从有到无
                    items.remove(at: position)
                    collectionView.deleteItemsAtIndexPaths([IndexPath(item: position, section: 0)], animationStyle: .none)
                    updatePageControl()
                }
            } else if newIsShowing {
                // 从无到有
                let position = ToolBarFactory.insertPosition(of: item.itemType,
                                                             target: items.map { $0.itemType },
                                                             order: collectionItems)
                items.insert(item, at: position)
                collectionView.insertItemsAtIndexPaths([IndexPath(item: position, section: 0)], animationStyle: .none)
                updatePageControl()
            }
        }
        return items
    }

    var itemsHeight: CGFloat {
        let numberOfRows = max(items.count - 1, 0) / 4 + 1
        let result = CGFloat(numberOfRows) * (configurator.itemHeight + configurator.rowInset) + 30
        return result
    }

    var pageNumber: Int {
        Int(ceil(Double(items.count) / Double(layout.numberPerPage)))
    }

    var currentPage: Int {
        let pageWidth = collectionView.bounds.width
        let offsetX = collectionView.contentOffset.x
        guard pageWidth != 0 else { return 0 }
        return Int(offsetX / pageWidth)
    }

    func setContentOffset(_ offset: CGPoint, animated: Bool) {
        collectionView.setContentOffset(offset, animated: animated)
    }

    private func updatePageControl() {
        numberOfPages = pageNumber
        collectionView.isScrollEnabled = pageNumber > 1
    }
}

extension ToolBarCollectionView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        if isLandscapeMode {
            if item.itemType == .myai {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.landscapeMyAiCellID,
                                                                    for: indexPath) as? ToolBarMyAILandscapeCollectionCell else {
                    return UICollectionViewCell()
                }
                cell.update(with: item)
                return cell
            }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.landscapeCellID,
                                                                for: indexPath) as? ToolBarLandscapeCollectionCell else { return UICollectionViewCell() }
            cell.update(with: item)
            return cell
        } else {
            if item.itemType == .myai {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.portraiMyAiCellID,
                                                                    for: indexPath) as? ToolBarMyAICollectionCell else {
                    return UICollectionViewCell()
                }
                cell.update(with: item)
                return cell
            }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.portraitCellID,
                                                                for: indexPath) as? ToolBarCollectionCell else {
                return UICollectionViewCell()
            }
            cell.update(with: item)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        items[indexPath.row].clickAction()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.toolbarCollectionViewDidScroll(collectionView)
    }
}
