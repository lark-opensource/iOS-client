//
//  SegmentControl.swift
//  LarkSegmentController
//
//  Created by kongkaikai on 2018/12/10.
//  Copyright © 2018 kongkaikai. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable missing_docs
public typealias PageSegmentCell = UICollectionViewCell

public protocol PageSegmentControlProtocol {
    typealias SelectedItemHandler = (_ index: Int) -> Void

    var onSelected: SelectedItemHandler? { get set }
    func select(itemAt index: Int)
    func reload(with newIndex: Int?)
}
// swiftlint:enable missing_docs

public protocol SegmentControlDataSource: AnyObject {
    func numberOfPage(in control: PageSegmentControl) -> Int
    func segmentControl(_ control: PageSegmentControl, cellAt index: Int) -> PageSegmentCell
}

open class PageSegmentControl: UIView, PageSegmentControlProtocol {
    public override var frame: CGRect {
        didSet {
            collectionView.frame = bounds
        }
    }

    public var itemsView: UIView { return collectionView }
    private var collectionView: UICollectionView

    public var onSelected: SelectedItemHandler?
    public weak var dataSource: SegmentControlDataSource?

    var itemCounts: Int = 0

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)

        backgroundColor = UIColor.white
        addSubview(collectionView)

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(
            PageSegmentCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(PageSegmentCell.self))
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 注册一个 item 重用 cell
    public func register(_ cellClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    /// 取出一个可用 cell
    public func dequeueReusableCell(withReuseIdentifier identifier: String, for index: Int) -> PageSegmentCell {
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: identifier,
            for: IndexPath(item: index, section: 0))
    }

    public func select(itemAt index: Int) {
        guard index < collectionView.numberOfItems(inSection: 0) else { return }
        collectionView.selectItem(
            at: IndexPath(item: index, section: 0),
            animated: true,
            scrollPosition: .centeredHorizontally)
    }

    public func reload(with newIndex: Int?) {
        collectionView.reloadData()
        if let index = newIndex {
            self.select(itemAt: index)
        }
    }
}

extension PageSegmentControl: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelected?(indexPath.item)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

extension PageSegmentControl: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfPage(in: self) ?? 0
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        assert(dataSource != nil, "instance of SegmentControl, 'dataSouce' can't be nil.")

        if let cell = dataSource?.segmentControl(self, cellAt: indexPath.item) {
            return cell
        }
        return collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(PageSegmentCell.self),
            for: indexPath)
    }
}
