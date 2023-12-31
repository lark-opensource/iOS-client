//
//  BTPanelEmptyContentView.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/8/9.
//

import Foundation
import UniverseDesignEmpty
import UniverseDesignColor
import SKFoundation
import SKUIKit

final class BTPanelEmptyContentView: UIView, ContentCustomViewProtocol {
    private lazy var contentView = UIStackView().construct { it in
        it.backgroundColor = .clear
        it.axis = .vertical
        it.alignment = .center
        it.spacing = 12
    }

    private lazy var iconImageView = UIImageView().construct { it in
        it.contentMode = .scaleAspectFit
    }

    private lazy var descLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 14)
        it.textAlignment = .center
        it.numberOfLines = 0
        it.textColor = UDColor.textCaption
    }

    private let model: BTPanelEmptyContentModel

    init?(model: Any) {
        guard let model = model as? BTPanelEmptyContentModel else {
            DocsLogger.btError("[BTPanel] convert to BTPanelEmptyContentModel fail")
            return nil
        }
        self.model = model
        super.init(frame: .zero)
        setupSubview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubview() {
        addSubview(contentView)
        let topOffset = SKDisplay.pad ? 28 : 36
        let bottomOffset = SKDisplay.pad ? 28 : 22
        contentView.snp.makeConstraints { make in
            make.top.equalTo(topOffset)
            make.bottom.equalTo(-bottomOffset)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
        }
        if let icon = model.contentImage {
            iconImageView.image = icon.image()
            contentView.addArrangedSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.width.height.equalTo(100)
            }
        }
        if let desc = model.desc {
            descLabel.text = desc
            contentView.addArrangedSubview(descLabel)
            descLabel.snp.makeConstraints { make in
                make.leading.trailing.lessThanOrEqualToSuperview()
            }
        }
    }
}
