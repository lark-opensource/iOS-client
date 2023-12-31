//
//  NoDataSection.swift
//  Search
//
//  Created by weidong fu on 6/12/2017.
//

import Foundation
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignEmpty

class NoDataCell: UICollectionViewCell {

    private var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.Doc_Search_SearchNotFoundTip),
                                                  imageSize: 100,
                                                  type: .searchFailed,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        return emptyView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
