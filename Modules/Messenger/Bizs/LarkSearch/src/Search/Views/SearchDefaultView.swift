//
//  SearchDefaultView.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/25.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

final class SearchDefaultView: UIView {
    init(hasSearchItems: Bool = true,
         text: String = BundleI18n.LarkSearch.Lark_Legacy_SearchDefaultYouCanSearch) {
        super.init(frame: CGRect.zero)
        // title容器
        let titleWrapper = UIView()
        self.addSubview(titleWrapper)
        titleWrapper.snp.makeConstraints({ make in
            make.top.equalTo(44)
            make.left.right.equalToSuperview()
        })

        // 你可以搜索
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        titleWrapper.addSubview(label)
        label.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        })

        // 左边的线
        let leftLine = UIView()
        leftLine.backgroundColor = UIColor.ud.N300
        titleWrapper.addSubview(leftLine)
        leftLine.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: 76, height: 0.5))
            make.centerY.equalToSuperview()
            make.right.equalTo(label.snp.left).offset(-10)
        })

        // 右边的线
        let rightLine = UIView()
        rightLine.backgroundColor = UIColor.ud.N300
        titleWrapper.addSubview(rightLine)
        rightLine.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: 76, height: 0.5))
            make.centerY.equalToSuperview()
            make.left.equalTo(label.snp.right).offset(10)
        })

        if hasSearchItems {
            // 群组搜索项
            let centerSearchItem = self.buildSearchItem(image: Resources.group_search, title: BundleI18n.LarkSearch.Lark_Legacy_Group)
            self.addSubview(centerSearchItem)
            centerSearchItem.snp.makeConstraints({ make in
                make.centerX.equalToSuperview()
                make.top.equalTo(titleWrapper.snp.bottom).offset(20)
            })

            // 联系人搜索项
            let leftSearchItem = self.buildSearchItem(image: Resources.contacts_search, title: BundleI18n.LarkSearch.Lark_Legacy_Contact)
            self.addSubview(leftSearchItem)
            leftSearchItem.snp.makeConstraints({ make in
                make.centerY.equalTo(centerSearchItem)
                make.right.equalTo(centerSearchItem.snp.left).offset(-43)
            })

            // 聊天记录搜索项
            let rightSearchItem = self.buildSearchItem(image: Resources.message_search, title: BundleI18n.LarkSearch.Lark_Legacy_TitleChatRecord)
            self.addSubview(rightSearchItem)
            rightSearchItem.snp.makeConstraints({ make in
                make.centerY.equalTo(centerSearchItem)
                make.left.equalTo(centerSearchItem.snp.right).offset(43)
            })
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func buildSearchItem(image: UIImage, title: String) -> UIView {
        let item = UIView()

        // 为了设置圆角和背景加的wrapper
        let iconWrapper = UIView()
        let size: CGFloat = 46
        item.addSubview(iconWrapper)
        iconWrapper.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: size, height: size))
            make.left.right.top.equalToSuperview()
        })

        // 图标
        let icon = UIImageView()
        icon.image = image
        iconWrapper.addSubview(icon)
        icon.snp.makeConstraints({ make in
            make.center.equalToSuperview()
        })

        // 标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = UIColor.ud.functionInfoContentDefault
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        item.addSubview(titleLabel)
        titleLabel.snp.makeConstraints({ make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconWrapper.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        })

        return item
    }

}
