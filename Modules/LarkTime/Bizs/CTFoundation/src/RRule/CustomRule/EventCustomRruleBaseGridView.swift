//
//  EventCustomRruleBaseGridView.swift
//  Calendar
//
//  Created by 张威 on 2020/4/16.
//

import UIKit

final class EventCustomRruleBaseGridView: UICollectionView,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource,
    UICollectionViewDelegate {
    var itemTitleLabelGetter: ((_ index: Int) -> UILabel?)?
    var itemSelectHandler: ((_ index: Int) -> Void)?

    let itemSpacing: CGFloat = 1.5

    private var numberOfRows: Int
    private var numberOfColomn: Int
    // cell 可能有两种：有内容（content），无内容（placeholder），使用 cellTags 进行区分
    private let cellTags: (content: Int, placeholder: Int) = (42, 1024)
    private let cellReuseId = "Cell"

    override var bounds: CGRect {
        didSet {
            guard window != nil, !oldValue.size.equalTo(bounds.size) else { return }
            guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
                return
            }
            layout.itemSize = calItemSize(withCollectionViewSize: bounds.size)
            layout.prepare()
            layout.invalidateLayout()
            reloadData()
        }
    }

    init(numberOfRows: Int, numberOfColomn: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfColomn = numberOfColomn

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 42, height: 42)
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        super.init(frame: CGRect.zero, collectionViewLayout: layout)

        backgroundColor = UIColor.ud.lineDividerDefault
        isScrollEnabled = false
        delegate = self
        dataSource = self

        register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellReuseId)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func calItemSize(withCollectionViewSize collectionViewSize: CGSize) -> CGSize {
        let height = (bounds.height - CGFloat(numberOfRows - 1) * itemSpacing) / CGFloat(numberOfRows)
        let width = (bounds.width - CGFloat(numberOfColomn - 1) * itemSpacing) / CGFloat(numberOfColomn)
        return CGSize(width: floor(width), height: floor(height))
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellReuseId,
            for: indexPath
        )
        cell.contentView.backgroundColor = UIColor.ud.bgBody
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        if let titleLabel = itemTitleLabelGetter?(indexPath.row) {
            titleLabel.removeFromSuperview()
            cell.contentView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            cell.tag = cellTags.content
        } else {
            cell.tag = cellTags.placeholder
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if let cell = collectionView.cellForItem(at: indexPath),
            cell.tag == cellTags.content {
            itemSelectHandler?(indexPath.row)
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfRows * numberOfColomn
    }

}
