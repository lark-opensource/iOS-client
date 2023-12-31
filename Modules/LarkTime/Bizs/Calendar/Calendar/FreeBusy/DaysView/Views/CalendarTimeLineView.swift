//
//  CalendarTodayIndicatorView.swift
//  Calendar
//
//  Created by ChalrieSu on 13/12/2017.
//  Copyright © 2017 linlin. All rights reserved.
//
//  用于在当天日程中，展示一个指示当前时刻的红线

import UIKit
import SnapKit
import CalendarFoundation
final class CalendarTimeLineView: UIView {
    let redDotView: UIView
    let redLineView: UIView

    override init(frame: CGRect) {
        redDotView = UIView()
        redLineView = UIView()
        super.init(frame: frame)

        redDotView.backgroundColor = UIColor.ud.functionDangerContentDefault
        redDotView.layer.masksToBounds = true
        redDotView.layer.cornerRadius = 3.5
        addSubview(redDotView)
        redDotView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.height.equalTo(7)
        }

        redLineView.backgroundColor = UIColor.ud.functionDangerContentDefault
        addSubview(redLineView)
        redLineView.snp.makeConstraints { (make) in
            make.centerY.equalTo(redDotView.snp.centerY)
            make.height.equalTo(1)
            make.left.equalTo(redDotView.snp.right).offset(1).priority(.high)
            make.right.equalToSuperview().priority(.high)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
}
