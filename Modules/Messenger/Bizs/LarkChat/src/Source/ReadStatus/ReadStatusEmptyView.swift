//
//  ReadStatusEmptyView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/4/19.
//

import Foundation
import UIKit

final class ReadStatusEmptyView: UIView {
    private(set) var imageView: UIImageView = .init(image: nil)
    private(set) var textLabel: UILabel = .init()

    private let topMargin = UIScreen.main.bounds.height * (154 / 667)

    var text: String = "" {
        didSet {
            guard text != oldValue else {
                return
            }
            self.textLabel.text = text
        }
    }

    init(message: String) {
        super.init(frame: .zero)

        let imageView = UIImageView()
        imageView.image = Resources.readStatusEmpty
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(108)
            make.height.equalTo(112)
            make.top.equalTo(self.topMargin)
        }
        self.imageView = imageView

        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textColor = UIColor.ud.N600
        textLabel.textAlignment = .center
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.text = message
        self.addSubview(textLabel)
        textLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(15)
            make.right.lessThanOrEqualTo(-15)
        }
        self.textLabel = textLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
