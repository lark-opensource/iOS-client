//
//  CommentCollectionViewFlowLayout.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/11/19.
//

import UIKit

class CommentCollectionViewFlowLayout: UICollectionViewFlowLayout {

    var contentOffset: CGPoint?

    override init() {
        super.init()

        self.scrollDirection = .horizontal
        self.minimumInteritemSpacing = 0
        self.minimumLineSpacing = 0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        if let contentOffset = contentOffset {
            self.collectionView?.contentOffset = contentOffset
            self.contentOffset = nil
        }
    }
}
