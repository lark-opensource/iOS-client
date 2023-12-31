//
//  DownloadFailedView.swift
//  LarkUIKit
//
//  Created by wangwanxin on 2023/3/20.
//

import Foundation
import SnapKit
import UniverseDesignIcon

final class DownloadFailedView: UIView {

    init(frame: CGRect, failureViewType: BaseImageViewWrapper.DownloadFailureViewType) {
        super.init(frame: frame)

        switch failureViewType {
        case .image:
            self.backgroundColor = UIColor.ud.bgBody
            let image = UDIcon.getIconByKey(.loadfailFilled, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN3)
            let imageView = UIImageView(image: image)
            self.addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        case .placeholderColor:
            self.backgroundColor = UIColor.ud.N200
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
