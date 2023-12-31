//
//  BTRecordCollectionView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/3/24.
//

import Foundation

final class BTRecordCollectionView: UICollectionView {
    var context: BTContext?
    override func reloadData() {
        super.reloadData()
        // collectionView reload 的时候清理掉缓存，因为转屏开始时回调reload
        if let contextId = context?.id {
            BTFieldLayoutCacheManager.shared.cache(with: contextId).clear()
        }
    }
}
