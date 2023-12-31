//
//  ItemDivideView.swift
//  LarkListItem
//
//  Created by Yuri on 2023/10/24.
//

import UIKit
import UniverseDesignColor

class ItemDivideView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.commonTableSeparatorColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
