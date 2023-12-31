//
//  TodoShareConfirmFooter.swift
//  LarkForward
//
//  Created by 白言韬 on 2020/12/14.
//

import UIKit
import Foundation

final class TodoShareConfirmFooter: BaseForwardConfirmFooter {

    private lazy var imgView: UIImageView = {
        let imgView = UIImageView()
        return imgView
    }()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 3
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        return nameLabel
    }()

    init(message: String, image: UIImage) {
        super.init()
        nameLabel.text = message
        imgView.image = image
        self.addSubview(nameLabel)
        self.addSubview(imgView)
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout() {
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(imgView.snp.top).offset(4)
            $0.bottom.lessThanOrEqualTo(imgView.snp.bottom).offset(-4)
            $0.left.equalTo(imgView.snp.right).offset(10)
            $0.right.equalToSuperview().offset(-10)
        }
    }
}
