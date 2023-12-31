//
//  MinutesLyricTimeView.swift
//  Minutes
//
//  Created by yangyao on 2021/4/3.
//

import UIKit

class MinutesLyricTimeView: UIView {
    let lyricEffectView = UIVisualEffectView()

    lazy var lyricTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        lyricEffectView.effect = UIBlurEffect(style: .light)

        addSubview(lyricEffectView)
        addSubview(lyricTimeLabel)

        lyricEffectView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        lyricTimeLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(3.5)
            maker.bottom.equalToSuperview().offset(-3.5)
//            maker.left.equalToSuperview().offset(7)
//            maker.right.equalToSuperview().offset(-8)
            maker.centerX.equalToSuperview().offset(1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height),
                                    byRoundingCorners: [UIRectCorner.topLeft, UIRectCorner.bottomLeft],
                                    cornerRadii: CGSize(width: bounds.height / 2.0, height: bounds.height / 2.0))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }
}
