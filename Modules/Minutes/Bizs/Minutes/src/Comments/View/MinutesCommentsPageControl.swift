//
//  MinutesCommentsPageControl.swift
//  Minutes
//
//  Created by yangyao on 2021/1/31.
//

import UIKit

class MinutesCommentsPageControlCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = MinutesCommentsPageControl.height / 2.0
        contentView.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(_ color: UIColor) {
        contentView.backgroundColor = color
    }
}

extension MinutesCommentsPageControl: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
}

extension MinutesCommentsPageControl: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesCommentsPageControlCell.description(), for: indexPath) as? MinutesCommentsPageControlCell else {
            return UICollectionViewCell()
        }
        cell.configure(dataSource[indexPath.item])
        return cell
    }
}

class MinutesCommentsPageControl: UIView {
    static let height: CGFloat = 4
    static let maxWidth: CGFloat = 120

    private var collectionLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 16, height: MinutesCommentsPageControl.height)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        return layout
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.backgroundColor = .clear
        collectionView.register(MinutesCommentsPageControlCell.self, forCellWithReuseIdentifier: MinutesCommentsPageControlCell.description())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        collectionView.isScrollEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    var dataSource: [UIColor] = []
    var totalCount: Int = 0 {
        didSet {
            dataSource.removeAll()
            for _ in 0..<totalCount {
                dataSource.append(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.3))
            }
            collectionView.reloadData()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        addSubview(collectionView)
        collectionView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(MinutesCommentsPageControl.height)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var currentCount: Int = 0 {
        didSet {
            guard currentCount >= 0 && currentCount < dataSource.count else {
                return
            }
            for index in 0..<dataSource.count {
                dataSource[index] = index == currentCount ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.N00.withAlphaComponent(0.3)
            }
            collectionView.reloadData()
            collectionView.scrollToItem(at: IndexPath(item: currentCount, section: 0), at: .centeredHorizontally, animated: true)
        }
    }
}
