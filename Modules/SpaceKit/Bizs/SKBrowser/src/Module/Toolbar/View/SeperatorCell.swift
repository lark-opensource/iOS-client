//
//  SeperatorCell.swift
//  SKCommon
//
//  Created by LiXiaolin on 2020/6/18.
//  

import UIKit
import UniverseDesignColor

class SeperatorCell: UICollectionViewCell {
    var seperatorLine: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UDColor.N400
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalTo(1)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
