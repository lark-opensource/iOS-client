//
//  CountDownBoardDotView.swift
//  ByteView
//
//  Created by wulv on 2022/5/1.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

extension CountDown.Stage {

    var suspendDotColor: UIColor {
        switch self {
        case .normal:
            return UIColor.ud.functionInfo300
        case .closeTo:
            return UIColor.ud.functionWarning300
        case .warn:
            return UIColor.ud.functionDanger300
        case .end:
            return UIColor.ud.N500
        }
    }
}

class CountDownBoardDotView: UIView {

    var color: UIColor? {
        didSet {
            one.backgroundColor = color
            two.backgroundColor = color
        }
    }

    let one: UIView = {
        let one = UIView()
        one.layer.cornerRadius = 2
        one.layer.masksToBounds = true
        return one
    }()

    let two: UIView = {
        let two = UIView()
        two.layer.cornerRadius = 2
        two.layer.masksToBounds = true
        return two
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setContentHuggingPriority(.required, for: .horizontal)
        backgroundColor = .clear
        addSubview(one)
        addSubview(two)
        one.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.size.equalTo(CGSize(width: 4, height: 4))
        }
        two.snp.makeConstraints {
            $0.bottom.left.right.equalToSuperview()
            $0.size.equalTo(one)
            $0.top.equalTo(one.snp.bottom).offset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
