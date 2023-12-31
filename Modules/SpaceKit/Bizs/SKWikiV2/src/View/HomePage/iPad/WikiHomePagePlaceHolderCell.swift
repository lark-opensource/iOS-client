//
//  WikiHomePagePlaceHolderCell.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2023/9/25.
//

import Foundation
import UniverseDesignEmpty
import UniverseDesignColor
import SKResource

class WikiHomePagePlaceHolderCell: UICollectionViewCell {
    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: ""),
                                                  imageSize: 100,
                                                  type: .documentDefault))
        emptyView.useCenterConstraints = true
        return emptyView
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
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func update(message: String) {
        var config = emptyView.config
        config.description = .init(descriptionText: message)
        emptyView.update(config: config)
    }
}
