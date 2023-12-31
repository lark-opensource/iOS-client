//
//  DKCardModeNaviBar.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/11/18.
//

import UIKit
import UniverseDesignColor
import SKCommon
import LarkDocsIcon

class DKCardModeNaviBar: UIView {
    let bgImageView = UIImageView()
    let imageIcon: UIImageView = UIImageView()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.staticBlack90
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    override class var layerClass: AnyClass { CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer } // swiftlint:disable:this all
    init(type: DriveFileType?, title: String) {
        super.init(frame: .zero)
        gradientLayer.colors = [UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.95).cgColor,
                                UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.95).cgColor,
                                UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0).cgColor]
        gradientLayer.locations = [0, 0.4, 1]
        addSubview(imageIcon)
        addSubview(titleLabel)
        imageIcon.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.width.equalTo(18)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(imageIcon.snp.right).offset(4)
            make.right.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(8)
        }
        imageIcon.image = type?.squareImage
        titleLabel.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ type: DriveFileType, title: String) {
        imageIcon.image = type.squareImage
        titleLabel.text = title
    }
}
