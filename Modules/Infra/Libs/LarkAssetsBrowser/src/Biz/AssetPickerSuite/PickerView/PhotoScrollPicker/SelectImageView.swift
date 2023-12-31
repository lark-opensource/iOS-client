//
//  SelectImageView.swift
//  LarkUIKit
//
//  Created by zc09v on 2017/6/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit

protocol SelectImageViewDelegate: AnyObject {
    func imageSelect(selected: Bool)
}

class SelectImageView: UIImageView {
    weak var delegate: SelectImageViewDelegate?

    var selectIndex: Int? {
        didSet {
            // 这里需要外界传入的index + 1表示选中的数量
            if let index = selectIndex {
                numberBox.number = index + 1
            } else {
                numberBox.number = nil
            }
        }
    }

    let numberBox = NumberBox(number: nil)
    
    static let checkBoxPadding: CGFloat = 5
    static let checkBoxSize = CGSize(width: 30, height: 30)

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = true

        numberBox.delegate = self
        numberBox.hitTestEdgeInsets = UIEdgeInsets(top: -9, left: -9, bottom: -9, right: -9)
        self.addSubview(numberBox)
        numberBox.frame = CGRect(x: Self.checkBoxPadding,
                                 y: Self.checkBoxPadding,
                                 width: Self.checkBoxSize.width,
                                 height: Self.checkBoxSize.width)
    }

    @objc
    func buttonClick() {
        var selected = self.selectIndex != nil
        selected = !selected
        // 这里需要传给外界 是选中还是取消
        self.delegate?.imageSelect(selected: selected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelectImageView: NumberBoxDelegate {
    // 数字的点击按钮
    func didTapNumberbox(_ numberBox: NumberBox) {
        buttonClick()
    }
}
