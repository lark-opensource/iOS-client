//
//  EmptyFooterView.swift
//  LarkWorkplace
//
//  Created by lilun.ios on 2020/7/22.
//

import UIKit
/// 空白的footer view
final class EmptyFooterView: UICollectionReusableView {
    var hasMore: Bool = false {
        didSet {
            hasMoreView.isHidden = !hasMore
        }
    }
    private lazy var hasMoreView: WPCategoryPageViewFooter = {
        WPCategoryPageViewFooter(frame: self.bounds)
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    private func setupViews() {
        addSubview(hasMoreView)
        setConstraints()
        hasMore = false
    }
    private func setConstraints() {
        hasMoreView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(footerViewHeight)
        }
    }
}
