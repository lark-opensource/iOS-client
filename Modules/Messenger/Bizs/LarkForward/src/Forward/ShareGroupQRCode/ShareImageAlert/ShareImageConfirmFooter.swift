//
//  ShareImageConfirmFooter.swift
//  LarkForward
//
//  Created by 李勇 on 2020/3/29.
//

import UIKit
import Foundation

// nolint: duplicated_code -- 代码可读性治理无QA，不做复杂修改
// TODO: 转发内容预览能力组件内置时优化该逻辑
final class ShareImageConfirmFooter: BaseForwardConfirmFooter {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(image: UIImage) {
        super.init()

        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.image = image
        self.addSubview(imgView)
        imgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(64)
            make.left.top.equalTo(10)
            make.bottom.equalToSuperview().offset(-10)
        }
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        label.text = BundleI18n.LarkForward.Lark_Legacy_ImageMessageHolder
        label.textColor = UIColor.ud.iconN1
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imgView.snp.top).offset(4)
            make.left.equalTo(imgView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.lessThanOrEqualToSuperview().offset(-10)
        }
    }
}

final class ShareNewImageConfirmFooter: BaseForwardConfirmFooter {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let imageViewSize: CGSize = CGSize(width: 80, height: 80)

    private lazy var imgView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = ImageCons.cornerRadius
        imgView.layer.masksToBounds = true
        return imgView
    }()

    init(image: UIImage) {
        super.init()

        self.backgroundColor = .clear
        self.layer.cornerRadius = 0
        self.addSubview(imgView)
        imgView.image = image
        updateImageConstraints(size: imageViewSize)
    }

    func updateImageConstraints(size: CGSize) {
        if size.width < (ImageCons.cornerRadius * 2) || size.height < (ImageCons.cornerRadius * 2) {
            imgView.layer.cornerRadius = 0
        }
        imgView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-2)
        }
    }
}
