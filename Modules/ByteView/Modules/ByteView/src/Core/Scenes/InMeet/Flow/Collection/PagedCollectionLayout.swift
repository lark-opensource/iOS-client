//
//  PagedCollectionLayout.swift
//  ByteView
//
//  Created by liujianlong on 2022/7/28.
//

import Foundation
import RxSwift

protocol PagedCollectionLayout {
    var pageObservable: Observable<Int> { get }
    var pageCount: Int { get }
    var visibleRange: GridVisibleRange { get }
}

extension PagedCollectionLayout where Self: UICollectionViewLayout {
    var collectionVisibleRange: (startIndex: Int, endIndex: Int) {
        let visibleIndexes = collectionView?.indexPathsForVisibleItems.map { $0.row }.sorted(by: <) ?? []
        guard let start = visibleIndexes.first, let end = visibleIndexes.last else { return (0, 0) }
        return (start, end + 1)
    }
}
