//
//  MineTranslateBaseCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/6/14.
//

import UIKit
import Foundation
import LarkUIKit

/// cell点击事件
typealias MineTranslateTapHandler = () -> Void
typealias MineTranslateSwitchHandler = (Bool) -> Void

protocol MineTranslateItemProtocol {
    var cellIdentifier: String { get }
}

/// 翻译设置
class MineTranslateBaseCell: BaseTableViewCell {
    var item: MineTranslateItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
