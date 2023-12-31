//
//  SelectTranslateView.swift
//  LarkAI
//
//  Created by ByteDance on 2022/7/25.
//

import Foundation
import UIKit
import LarkUIKit

class BaseSelectTranslateCardCell: BaseTableViewCell {
    var item: SelectTranslateDictItemProtocol? {
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
