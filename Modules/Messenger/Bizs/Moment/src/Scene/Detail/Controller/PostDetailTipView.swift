//
//  PostDetailNoPermissionView.swift
//  Moment
//
//  Created by zc09v on 2021/1/28.
//

import Foundation
import UIKit

final class PostDetailTipView: UIView {
     init(topOffset: CGFloat, tip: String, image: UIImage) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.N00
        let container = UIView(frame: .zero)
        self.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topOffset)
            make.centerX.width.equalToSuperview()
        }

        let imageTip = UIImageView(image: image)
        container.addSubview(imageTip)
        imageTip.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        let label = UILabel(frame: .zero)
        label.text = tip
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N600
        label.numberOfLines = 0
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imageTip.snp.bottom)
            make.width.lessThanOrEqualToSuperview().inset(16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
