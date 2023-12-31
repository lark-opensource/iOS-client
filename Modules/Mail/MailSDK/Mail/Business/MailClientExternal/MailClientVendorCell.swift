//
//  MailClientVendorCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/11/24.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import Lottie

//enum MailVendorType: String {
//    case exchange
//    case tencent
//    case netease
//    case ali
//    case other
//}

protocol MailClientVendorDelegate: AnyObject {
    func vendorBtnClick(type: MailTripartiteProvider)
}

class MailClientVendorCell: UITableViewCell {
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        return label
    }

    private func makeArrowIcon() -> UIImageView {
        let imageview = UIImageView()
        imageview.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        imageview.tintColor = UIColor.ud.iconN3
        return imageview
    }

    private func makeBgButton() -> UIButton {
        let bgButton = TouchFeedbackButton(normalBackgroundColor: .clear, highlightedBackgroundColor: .ud.fillPressed)
        bgButton.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        bgButton.layer.cornerRadius = 10
        bgButton.layer.masksToBounds = true
        bgButton.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        bgButton.layer.borderWidth = 1
        return bgButton
    }

    weak var delegate: MailClientVendorDelegate?
    private lazy var titleLabel = self.makeTitleLabel()
    private lazy var iconView = UIImageView()
    private lazy var arrowIcon = self.makeArrowIcon()
    private lazy var bgButton = self.makeBgButton()
    private var type: MailTripartiteProvider = .other

    func configVendor(_ type: MailTripartiteProvider) {
        self.type = type
        let configInfo = type.config()
        titleLabel.text = configInfo.0
        iconView.image = configInfo.1
        if type.needRenderIcon() {
            iconView.tintColor = UIColor.ud.N400
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(bgButton)
        [titleLabel, iconView, arrowIcon].forEach {
            bgButton.addSubview($0)
        }

        self.backgroundColor = UIColor.clear
        bgButton.snp.makeConstraints { (make) in
            make.left.equalTo(24)
            make.right.equalTo(-24)
            make.top.equalTo(6)
            make.bottom.equalTo(-6)
        }
        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        arrowIcon.snp.makeConstraints { (make) in
            make.right.equalTo(bgButton.snp.right).offset(-20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(10)
            make.right.equalTo(arrowIcon.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    func clickButton() {
        delegate?.vendorBtnClick(type: type)
    }
}
