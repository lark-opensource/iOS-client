//
//  MinutesAddCommentsQuoteView.swift
//  Minutes
//
//  Created by yangyao on 2021/1/29.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon

class MinutesAddCommentsQuoteView: UIView {
    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgFloatOverlay
        layer.cornerRadius = 8

        let quoteImageView = UIImageView()
        quoteImageView.image = UIImage.dynamicIcon(.iconQuote, dimension: 14, color: UIColor.ud.textPlaceholder)
        addSubview(quoteImageView)
        addSubview(contentLabel)

        quoteImageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(14)
            maker.top.equalToSuperview().offset(13)
            maker.bottom.equalToSuperview().offset(-13)
            maker.left.equalToSuperview().offset(10)
        }

        contentLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(18)
            maker.left.equalTo(quoteImageView.snp.right).offset(8)
            maker.right.equalToSuperview().offset(-13)
            maker.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
