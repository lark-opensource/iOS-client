//
//  MinutesSubtitleSkeletonCell.swift
//  Minutes
//
//  Created by yangyao on 2022/9/19.
//

import UIKit
import SnapKit
import UniverseDesignColor

class MinutesSubtitleSkeletonCell: UITableViewCell {
    static let height = 100.0
    
    let skeletonView = MinutesSubtitleSkeletonView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(skeletonView)
        skeletonView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
