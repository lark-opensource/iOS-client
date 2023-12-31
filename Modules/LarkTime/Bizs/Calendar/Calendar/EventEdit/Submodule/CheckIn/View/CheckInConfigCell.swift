//
//  CheckInConfigView.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxCocoa

class CheckInConfigCell: UIView {

    enum Layout {
        static var topPadding: CGFloat = 13.0
        static var bottomPadding: CGFloat = 12.0
        static var leftPadding: CGFloat = 16.0
        static var rightPadding: CGFloat = 16.0
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.backgroundColor = UDColor.bgFloat

        addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Layout.leftPadding)
            make.top.bottom.lessThanOrEqualToSuperview().inset(Layout.bottomPadding)
            make.right.lessThanOrEqualToSuperview().inset(Layout.rightPadding)
        }
    }

    func setTitle(title: String, color: UIColor = .ud.textTitle) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = 24
        paragraphStyle.maximumLineHeight = 24
        self.titleLabel.attributedText = NSAttributedString(string: title, attributes: [.foregroundColor: color,
                                                                                        .font: UIFont.systemFont(ofSize: 16),
                                                                                        .paragraphStyle: paragraphStyle])
    }

    func setCornersRadius(corners: CACornerMask) {
        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = 10
        layer.maskedCorners = corners
    }
}

class CheckInConfigSwitchCell: CheckInConfigCell {
    let switchView: UISwitch = UISwitch.blueSwitch()
    var rxIsOn: RxCocoa.ControlProperty<Bool> { switchView.rx.isOn }
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    override init() {
        super.init()
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(switchView)
        addSubview(subTitleLabel)

        switchView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Layout.rightPadding)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(Layout.leftPadding)
            make.top.equalToSuperview().inset(Layout.bottomPadding)
            make.right.equalTo(switchView.snp.left).offset(-12)
        }

        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalToSuperview().inset(Layout.leftPadding)
            make.right.equalTo(switchView.snp.left).offset(-12)
            make.bottom.equalToSuperview().inset(Layout.bottomPadding)
        }
    }

    func setSubTitle(title: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        self.subTitleLabel.attributedText = NSAttributedString(string: title, attributes: [.foregroundColor: UIColor.ud.textPlaceholder,
                                                                                          .font: UIFont.systemFont(ofSize: 14),
                                                                                          .paragraphStyle: paragraphStyle])
    }
}

class CheckInConfigGoToCell: CheckInConfigCell {
    var click: (() -> Void)?

    let subTitle: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.btd_height = 20
        return label
    }()

    let gotoIndicator: UIImageView = {
        let icon = UIImageView(image: UDIcon.getIconByKey(.rightOutlined).renderColor(with: .n3))
        return icon
    }()

    override init() {
        super.init()
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(subTitle)
        addSubview(gotoIndicator)

        gotoIndicator.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Layout.rightPadding)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(12)
        }

        subTitle.snp.makeConstraints { make in
            make.right.equalTo(gotoIndicator.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.top.bottom.equalTo(titleLabel)
        }

        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(Layout.leftPadding)
            make.top.bottom.lessThanOrEqualToSuperview().inset(Layout.bottomPadding)
            make.right.lessThanOrEqualTo(subTitle.snp.left).offset(-12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        self.addGestureRecognizer(tap)
    }

    func setSubTitle(title: String) {
        self.subTitle.text = title
    }

    @objc
    private func tap() {
        click?()
    }
}

class CheckInConfigTitleCell: CheckInConfigCell {
    override init() {
        super.init()
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.titleLabel.textColor = UDColor.textPlaceholder
        self.titleLabel.font = .systemFont(ofSize: 14)
        self.titleLabel.btd_height = 20
        self.titleLabel.numberOfLines = 0

        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().inset(Layout.leftPadding)
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(8)
            make.right.lessThanOrEqualToSuperview().inset(Layout.rightPadding)
        }
    }

    override func setTitle(title: String, color: UIColor = UDColor.textPlaceholder) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.minimumLineHeight = 22
        paragraphStyle.maximumLineHeight = 22
        self.titleLabel.attributedText = NSAttributedString(string: title, attributes: [.foregroundColor: color,
                                                                                        .font: UIFont.systemFont(ofSize: 14),
                                                                                        .paragraphStyle: paragraphStyle])
    }
}
