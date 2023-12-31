//
//  MomentsNickNameViewPersonInfoCell.swift
//  Moment
//
//  Created by ByteDance on 2022/8/2.
//

import Foundation
import LarkUIKit
import UIKit
import SnapKit
import SwiftUI

final class MomentsNickNameViewPersonInfoCell: UITableViewCell {

    enum Cons {
        static var leftContentPercentage: CGFloat { 194 / 343 }
        static var rightContentPercentage: CGFloat { 97 / 343 }
    }

    lazy var title: UILabel = {
        let title = UILabel()
        title.textColor = UIColor.ud.textTitle
        title.font = .systemFont(ofSize: 16)
        title.textAlignment = .justified
        title.numberOfLines = 0
        return title
    }()

    lazy var subTitle: UILabel = {
        let subTitle = UILabel()
        subTitle.textColor = UIColor.ud.textPlaceholder
        subTitle.font = .systemFont(ofSize: 14)
        subTitle.textAlignment = .right
        subTitle.numberOfLines = 0
        return subTitle
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }

    private func setUpUI() {
        /// 设置背景颜色
        self.backgroundColor = UIColor.ud.bgBody
        /// 设置cell不可点击
        self.selectionStyle = .none
        /// 添加title
        self.contentView.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.left.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.width.lessThanOrEqualToSuperview().multipliedBy(Cons.leftContentPercentage)
        }
        /// 添加subTitle
        self.contentView.addSubview(subTitle)
        subTitle.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.right.bottom.equalToSuperview().offset(-16)
            make.width.lessThanOrEqualToSuperview().multipliedBy(Cons.rightContentPercentage)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
