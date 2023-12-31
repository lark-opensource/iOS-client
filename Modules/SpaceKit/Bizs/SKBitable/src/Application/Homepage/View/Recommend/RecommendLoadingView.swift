//
//  BitableRecommendCell.swift
//  SKBitable
//
//  Created by qianhongqiang on 2023/9/4.
//

import Foundation
import UIKit
import SnapKit
import SkeletonView
import UniverseDesignColor

struct RecommendLoadingViewLayoutConfig {
    static let colloctionViewminimumSpacing: CGFloat = 14.0
    static let colloctionViewInsetLength: CGFloat = 16.0
    static let innnerMarigin12: CGFloat = 12.0
    static let innerHeight16: CGFloat = 16.0
    static let nameImageWidth: CGFloat = 56.0
}

class RecommendLoadingView: UIView, SkeletonCollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private lazy var loadingView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = RecommendLoadingViewLayoutConfig.colloctionViewminimumSpacing
        layout.minimumInteritemSpacing = RecommendLoadingViewLayoutConfig.colloctionViewminimumSpacing
        layout.sectionInset = UIEdgeInsets(top: RecommendLoadingViewLayoutConfig.colloctionViewInsetLength,
                                           left: RecommendLoadingViewLayoutConfig.colloctionViewInsetLength,
                                           bottom: RecommendLoadingViewLayoutConfig.colloctionViewInsetLength,
                                           right: RecommendLoadingViewLayoutConfig.colloctionViewInsetLength)
        let loading = UICollectionView(frame: .zero, collectionViewLayout: layout)
        loading.dataSource = self
        loading.delegate = self
        loading.register(RecommendLoadingCell.self, forCellWithReuseIdentifier: RecommendLoadingCell.cellWithReuseIdentifier())
        loading.isSkeletonable = true
        loading.backgroundColor = UDColor.bgBody
        return loading
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func showSkeleton() {
        loadingView.udPrepareSkeleton {[weak loadingView] _ in
            loadingView?.showUDSkeleton()
        }
    }
    
    func stopSkeleton() {
        loadingView.hideUDSkeleton()
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> SkeletonView.ReusableCellIdentifier {
        return RecommendLoadingCell.cellWithReuseIdentifier()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // cell宽度为自身宽度 - 2 * collectionView的内边距 - 中间(2列)间隙
        let itemWidth = max(0,(self.bounds.width - RecommendLoadingViewLayoutConfig.colloctionViewInsetLength * 2 - RecommendLoadingViewLayoutConfig.colloctionViewminimumSpacing)/2.0)
        // cell高度为 图片骨架 + 图片与标题间距(12) + 标题与作者间距(12) +标题高度(16) + 作者高度(16) + 作者到底部的边距(14)
        let itemHeight = itemWidth * RecommendLoadingCellLayoutConfig.topImageHWRate + RecommendLoadingCellLayoutConfig.innnerMarigin12 * 3 + RecommendLoadingCellLayoutConfig.innerHeight16 * 3 + RecommendLoadingCellLayoutConfig.iconMarginBottom
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: RecommendLoadingCell.cellWithReuseIdentifier(), for: indexPath)
    }
}
