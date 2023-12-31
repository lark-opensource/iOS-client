//
//  FlagUnknownMessageView.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class FlagUnknownMessageView: UIView {

    enum Cons {
        static var iconSize: CGFloat { 48.auto() }
        static var hMargin: CGFloat { 16 }
        static var vMargin: CGFloat { 8 }
    }

    var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .center
        view.image = UDIcon.getIconByKey(.fileRoundUnknowColorful, size: CGSize(width: Cons.iconSize, height: Cons.iconSize))
        view.layer.cornerRadius = Cons.iconSize / 2
        return view
    }()

    var tipLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.ud.title4
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkFlag.Lark_IM_Marked_PleaseUpdateToLatestVersionToViewMarked_Text
        return label
    }()

    var flagIconImageView: UIImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(iconView)
        self.addSubview(tipLabel)
        self.addSubview(flagIconImageView)
        flagIconImageView.image = UDIcon.getIconByKey(.flagFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 12, height: 12))
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Cons.iconSize)
            make.left.equalTo(Cons.hMargin)
            make.top.equalTo(Cons.vMargin)
            make.bottom.equalTo(-Cons.vMargin)
        }
        flagIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
            make.top.equalTo(12)
            make.right.equalTo(-16)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.equalTo(flagIconImageView.snp.left).offset(-Cons.hMargin)
        }
        self.snp.makeConstraints { make in
            make.bottom.equalTo(iconView).offset(Cons.vMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
