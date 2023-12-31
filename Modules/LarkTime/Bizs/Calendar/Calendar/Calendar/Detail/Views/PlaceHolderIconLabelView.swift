//
//  PlaceHolderIconLabelView.swift
//  Calendar
//
//  Created by Rico on 2021/8/20.
//

import Foundation
import UIKit
import UniverseDesignColor

/// 全屏 Icon + 文字 View
final class PlaceHolderIconLabelView: UIView {

    var image: UIImage? {
        get {
            return icon.image
        }
        set {
            icon.image = newValue
        }
    }

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    private let icon = UIImageView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(frame: .zero)

        backgroundColor = UDColor.bgBase

        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(120)
            make.center.equalToSuperview()
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(icon.snp.bottom).offset(12)
            make.height.equalTo(20)
            make.left.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
