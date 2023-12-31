//
//  SkeletonCollectionViewController.swift
//  UniverseDesignLoadingDev
//
//  Created by Miaoqi Wang on 2020/11/9.
//

import Foundation
import UIKit
import UniverseDesignLoading

private let reusableIdentifier: String = "SkeletonCollectionViewController.cell"

class SkeletonCollectionViewController: UICollectionViewController {

    var dataSource: [UIColor] = [.alizarin, .amethyst, .asbestos, .belizeHole, .black, .blue]

    init() {
        let flow = UICollectionViewFlowLayout()
        flow.itemSize = CGSize(width: 100, height: 50)
        super.init(collectionViewLayout: flow)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isSkeletonable = true
        dataSource += dataSource
        dataSource += dataSource
        collectionView.backgroundColor = UIColor.ud.neutralColor1
        collectionView.isSkeletonable = true
        collectionView.register(SkeletonCollectionCel.self, forCellWithReuseIdentifier: reusableIdentifier)

        collectionView.udPrepareSkeleton { [weak self](_) in
            self?.collectionView.showUDSkeleton()
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self?.collectionView.hideUDSkeleton()
            }
        }
    }
}

extension SkeletonCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: reusableIdentifier,
                for: indexPath) as? SkeletonCollectionCel else {
            return UICollectionViewCell()
        }
        cell.backgroundColor = dataSource[indexPath.row]
        return cell
    }
}
