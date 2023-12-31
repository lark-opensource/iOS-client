//
//  TranslationView.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/7/10.
//  

import UIKit
import LarkUIKit

class TranslationViewV2: UIView {

    private(set) lazy var bgView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.N400
        return bgView
    }()

    private(set) lazy var content: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TranslationViewV2 {
    private func setupUI() {

//        addSubview(bgView)
        addSubview(content)

//        bgView.layer.cornerRadius = 4
//        bgView.layer.masksToBounds = true
//
//        bgView.snp.makeConstraints { (make) in
//            make.left.equalTo(content.snp.left).offset(-4)
//            make.right.equalTo(content.snp.right).offset(4)
//            make.top.equalTo(content.snp.top).offset(-2)
//            make.bottom.equalTo(content.snp.bottom).offset(2)
//        }

        content.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
            //make.right.lessThanOrEqualToSuperview()
        }

    }
}
