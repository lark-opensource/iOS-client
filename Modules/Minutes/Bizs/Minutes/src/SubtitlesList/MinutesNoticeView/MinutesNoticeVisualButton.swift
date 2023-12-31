//
//  MinutesNoticeVisualButton.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import YYText
import UniverseDesignColor

extension String {
    func ga_widthForComment(fontSize: CGFloat, height: CGFloat = 15) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let rect = NSString(string: self).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(rect.width)
    }

}

class MinutesNoticeVisualButton: UIButton {

    public static var viewWidth: CGFloat = {
        return BundleI18n.Minutes.MMWeb_G_ContentUpdated.ga_widthForComment(fontSize: 14) + 52
    }()

    static var shadowColor: UIColor = UIColor.ud.N900.withAlphaComponent(0.12) & .clear

    public static let viewHeight: CGFloat = 36

    private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.dynamicIcon(.iconRefresh, dimension: 14, color: UIColor.ud.functionInfoContentDefault)
        return imageView
    }()

    private(set) lazy var label: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.primaryContentDefault
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.text = BundleI18n.Minutes.MMWeb_G_ContentUpdated
        return titleLabel
    }()

    override init(frame: CGRect) {
        let fixedFrame = CGRect(x: 0, y: 0, width: MinutesNoticeVisualButton.viewWidth, height: MinutesNoticeVisualButton.viewHeight)
        super.init(frame: fixedFrame)

        self.clipsToBounds = false

        let shadowPath0 = UIBezierPath(roundedRect: self.bounds, cornerRadius: 18)
        self.layer.ud.setShadowColor(MinutesNoticeVisualButton.shadowColor)
        self.layer.shadowPath = shadowPath0.cgPath
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 4
        self.layer.shadowOffset = CGSize(width: 0, height: 2)

        var shapes = UIView()
        shapes.frame = fixedFrame
        shapes.clipsToBounds = true
        shapes.backgroundColor = UIColor.ud.bgFloat
        shapes.layer.cornerRadius = 18
        shapes.isUserInteractionEnabled = false
        self.addSubview(shapes)

        self.addSubview(iconView)
        iconView.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(12)
            maker.height.width.equalTo(14)
        }

        self.addSubview(label)
        label.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(iconView.snp.trailing).offset(6)
            maker.trailing.equalToSuperview().offset(-12)
            maker.height.equalTo(19)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
