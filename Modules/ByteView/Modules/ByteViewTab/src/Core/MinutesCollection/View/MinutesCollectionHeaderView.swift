//
//  MinutesCollectionHeaderView.swift
//  ByteViewTab
//
//  Created by 陈乐辉 on 2023/5/8.
//

import Foundation
import UniverseDesignColor
import ByteViewCommon
import UIKit
import SnapKit

final class MinutesCollectionHeaderView: UIView {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalTo(-19)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.right.equalTo(subtitleLabel)
            make.bottom.equalTo(-48)
            make.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    func calculateHeight() -> CGFloat {
        var height: CGFloat
        if traitCollection.isRegular {
            height = 108.0
        } else {
            height = 180.0
        }
        let newSize = titleLabel.sizeThatFits(CGSize(width: bounds.width - 32, height: .greatestFiniteMagnitude))
        if newSize.height > titleLabel.font.lineHeight * 1.5 {
            height += 28.0
        }
        return height
    }
}
