//
//  MinutesCommentsCardCell.swift
//  Minutes
//
//  Created by yangyao on 2021/2/3.
//

import UIKit

class MinutesCommentsCardCell: UICollectionViewCell {
    lazy var commentsCardView: MinutesCommentsCardView = {
        return MinutesCommentsCardView()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 10
        contentView.addSubview(commentsCardView)
        commentsCardView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(454)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
