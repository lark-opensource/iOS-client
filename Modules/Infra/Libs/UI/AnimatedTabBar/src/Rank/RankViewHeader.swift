//
//  RankViewHeader.swift
//  RankDemo2
//
//  Created by bytedance on 2020/11/26.
//

import Foundation
import UIKit
import SnapKit

final class RankViewHeader: UITableViewHeaderFooterView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-4)
            make.height.equalTo(20)
            make.left.equalToSuperview().offset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RankViewHeader {
    /// cell 配置
    struct Config {
        static let headerHeight: CGFloat = 40
        static let identifier: String = "RankViewHeader"
    }
}
