//
//  UnknownCellView.swift
//  LarkFavorite
//
//  Created by liuwanlin on 2018/6/19.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

final class UnknownCellView: UIView {

    enum Cons {
        static var tipFont: UIFont { UIFont.ud.body2 }
        static var iconSize: CGFloat { 36.auto() }
        static var hMargin: CGFloat { 12 }
        static var vMargin: CGFloat { 16 }
    }

    var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.image = Resources.favoriteUnknown
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    var tipLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Cons.tipFont
        label.textColor = UIColor.ud.N600
        label.text = BundleI18n.LarkChat.Lark_Legacy_SaveBoxListUnknown
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = 4
        self.layer.borderWidth = 1 / UIScreen.main.scale
        self.layer.borderColor = UIColor.ud.N300.cgColor

        self.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Cons.iconSize)
            make.left.equalTo(Cons.hMargin)
            make.top.equalTo(Cons.vMargin)
            make.bottom.equalTo(-Cons.vMargin)
        }

        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(Cons.hMargin)
            make.right.equalTo(-Cons.hMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
