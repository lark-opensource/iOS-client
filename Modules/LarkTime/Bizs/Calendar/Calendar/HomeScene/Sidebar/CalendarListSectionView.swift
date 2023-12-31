//
//  CalendarListSectionView.swift
//  Calendar
//
//  Created by linlin on 2018/1/15.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import UniverseDesignIcon
import Foundation
import CalendarFoundation
import SnapKit

final class CalendarSection: UIView {
    private var image: UIImage?
    let imageBgColor: UIColor
    init(text: String, type: SideBarCellType) {
        switch type {
        case .larkMine:
            imageBgColor = UIColor.ud.primaryContentDefault.withAlphaComponent(0.08)
        case .larkSubscribe:
            imageBgColor = UIColor.ud.primaryContentDefault.withAlphaComponent(0.08)
        case .local:
            image = UDIcon.getIconByKeyNoLimitSize(.phoneColorful)
            imageBgColor = UIColor.ud.primaryContentDefault.withAlphaComponent(0.08)
        case .google:
            image = UDIcon.getIconByKeyNoLimitSize(.googleColorful)
            imageBgColor = UIColor.ud.N200
        case .exchange:
            image = UDIcon.getIconByKeyNoLimitSize(.exchangeColorful)
            imageBgColor = UIColor.ud.N200
        }

        super.init(frame: .zero)
        let imageView = setupImageView()
        setupLabel(text: text, leftView: imageView)
        backgroundColor = UIColor.ud.bgBody
    }

    private func setupImageView() -> UIView {
        let imageBg = UIView()
        imageBg.layer.cornerRadius = 20
        imageBg.backgroundColor = imageBgColor
        self.addSubview(imageBg)
        imageBg.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        if let image = image {
            let imageView = UIImageView(image: image)
            imageBg.addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.height.equalTo(20)
            }
        }

        return imageBg
    }

    private func setupLabel(text: String, leftView: UIView) {
        let label = UILabel.cd.titleLabel(fontSize: 17)
        label.text = text
        label.textColor = UIColor.ud.N800
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalTo(leftView)
            make.left.equalTo(leftView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
