//
//  BanningSettingEditCellItem.swift
//  LarkChat
//
//  Created by kkk on 2019/3/12.
//

import UIKit
import Foundation

struct BanningSettingEditItem: BanningSettingItem {
    var icon: UIImage?
    var identifier: String
}

final class BanningSettingEditCell: UIControl, BanningSettingCell {
    private(set) var item: BanningSettingItem?
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        iconView.layer.cornerRadius = 16
        iconView.layer.masksToBounds = true
        self.addSubview(iconView)
        iconView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.width.height.equalTo(32).priority(.required)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(item: BanningSettingItem) {
        guard let item = item as? BanningSettingEditItem else {
            assert(false, "item type error")
            return
        }
        self.item = item
        iconView.image = item.icon
    }
}
