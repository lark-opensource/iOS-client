//
//  BigAddButton.swift
//  Todo
//
//  Created by wangwanxin on 2021/11/4.
//

import UniverseDesignShadow
import UniverseDesignIcon

/// + 号大按钮
final class BigAddButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.primaryFillDefault
        let icon = UDIcon.getIconByKey(
            .addOutlined,
            iconColor: UIColor.ud.primaryOnPrimaryFill,
            size: CGSize(width: 24, height: 24)
        )
        let imageView = UIImageView(image: icon)
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        layer.ud.setShadow(type: .s4DownPri)
        layer.cornerRadius = 24
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
