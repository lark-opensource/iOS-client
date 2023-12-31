//
//  SingleLineShareOptionArea.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/22.
//

import Foundation
import UIKit
import SnapKit

final class ShareOptionSingleLineView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    var onShareItemViewClicked: ((LarkShareItemType) -> Void)?
    private var shareTypes: [LarkShareItemType]

    private lazy var shareOptionArea: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = ShareCons.shareCellItemSize
        layout.sectionInset = UIEdgeInsets(top: 0,
                                           left: ShareCons.defaultSpacing,
                                           bottom: 0,
                                           right: ShareCons.defaultSpacing)
        layout.minimumLineSpacing = ShareCons.shareIconDefaultSpacing
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.insetsLayoutMarginsFromSafeArea = true
        collectionView.register(ShareOptionCell.self,
                                forCellWithReuseIdentifier: ShareOptionCell.idenContentString)
        return collectionView
    }()

    init(shareTypes: [LarkShareItemType]) {
        self.shareTypes = shareTypes
        super.init(frame: .zero)
        self.addSubview(shareOptionArea)

        shareOptionArea.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return shareTypes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ShareOptionCell.idenContentString,
                                                         for: indexPath) as? ShareOptionCell {
            let type = shareTypes[indexPath.row]
            cell.configure(type: type)
            return cell
        } else {
            return UICollectionViewCell()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = shareTypes[indexPath.item]
        self.onShareItemViewClicked?(type)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
