//
//  WPTemplateFallbackCell.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/3/28.
//

import Foundation
import SnapKit

final class WPTemplateFallbackCell: UICollectionViewCell {
    private let fallbackView = ComponentFallbackView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(fallbackView)
        fallbackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
