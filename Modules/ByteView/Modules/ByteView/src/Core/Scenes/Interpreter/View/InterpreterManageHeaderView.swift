//
//  InterpreterManageHeaderView.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import UIKit

class InterpreterManageHeaderView: UIView {

    enum Layout {
        static var topGap: CGFloat = 0
        static var buttonHeight: CGFloat = 48
        static var bottomGap: CGFloat = 0
    }

    lazy var addButton: UIButton = {
        return AddInterpreterButton()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBase
        addSubview(addButton)
        addButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(Layout.topGap)
            maker.height.equalTo(Layout.buttonHeight)
            maker.bottom.equalTo(-Layout.bottomGap)
            maker.left.equalToSuperview().offset(16)
            maker.right.equalTo(safeAreaLayoutGuide).offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AddInterpreterButton: UIButton {
    lazy var normalIcon: UIImage? = {
        UDIcon.getIconByKey(.addOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
    }()

    lazy var icon: UIImageView = {
        let imageView = UIImageView(image: normalIcon)
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_AddInterpreter
        label.textColor = UIColor.ud.primaryContentDefault
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    lazy var infoLabel: PaddingLabel = {
       let label = PaddingLabel()
        label.textAlignment = .center
        label.textColor = UIColor.ud.udtokenTagTextSYellow
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = UIColor.ud.udtokenTagBgYellow
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.isHidden = true
        label.textInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 10
        layer.masksToBounds = true
        vc.setBackgroundColor(UIColor.ud.bgFloat, for: .normal)
        vc.setBackgroundColor(UIColor.ud.fillPressed, for: .highlighted)

        addSubview(icon)
        addSubview(label)
        addSubview(infoLabel)

        icon.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalToSuperview().offset(16)
        }

        label.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(icon.snp.right).offset(4)
        }

        infoLabel.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right).offset(8)
            make.height.equalTo(18)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
