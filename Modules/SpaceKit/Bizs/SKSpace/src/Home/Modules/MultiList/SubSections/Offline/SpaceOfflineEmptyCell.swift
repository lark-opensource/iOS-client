//
//  SpaceOfflineEmptyCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/20.
//

import UIKit
import SnapKit
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty

class SpaceOfflineEmptyCell: UICollectionViewCell {

    private lazy var emptyView: UDEmpty = {
        let empty = UDEmpty(config: .init(title: .init(titleText: BundleI18n.SKResource.Doc_Facade_OfflineEmptyAvailableFile),
                                          description: .init(descriptionText: BundleI18n.SKResource.Doc_Facade_OfflineBannerTitle),
                                          imageSize: 100,
                                          type: .noContent,
                                          labelHandler: nil,
                                          primaryButtonConfig: nil,
                                          secondaryButtonConfig: nil))
        return empty
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.center.left.right.equalToSuperview()
        }
    }
}
