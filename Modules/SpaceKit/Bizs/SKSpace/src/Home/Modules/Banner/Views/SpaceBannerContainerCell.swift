//
//  SpaceBannerContainerCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import SnapKit

class SpaceBannerContainerCell: UICollectionViewCell {

    private var bannerContentView: SpaceBannerContentView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bannerContentView?.removeFromSuperview()
        bannerContentView = nil
    }

    func update(bannerContentView: SpaceBannerContentView) {
        self.bannerContentView = bannerContentView
        contentView.addSubview(bannerContentView)
        contentView.clipsToBounds = true
        bannerContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
