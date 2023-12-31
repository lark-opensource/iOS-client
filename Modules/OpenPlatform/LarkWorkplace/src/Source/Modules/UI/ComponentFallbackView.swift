//
//  ComponentFallbackView.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/3/9.
//

import UIKit
import SnapKit
import UniverseDesignFont
import UniverseDesignColor

final class ComponentFallbackView: UIView {
    private let label = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.edges.equalToSuperview().inset(16.0)
        }

        label.text = BundleI18n.LarkWorkplace.OpenPlatform_FeedList_FeatureUnavailableErr
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UDFont.body2
        label.textColor = UDColor.textDisabled
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
