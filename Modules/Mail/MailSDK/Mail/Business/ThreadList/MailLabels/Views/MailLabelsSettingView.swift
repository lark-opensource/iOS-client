//
//  MailLabelsSettingView.swift
//  MailSDK
//
//  Created by majx on 2019/10/28.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import LarkInteraction
import UniverseDesignTheme
import UniverseDesignIcon

protocol MailLabelsSettingViewDelegate: AnyObject {
    func didClickManageLabelsButton()
}

class MailLabelsSettingView: UIView {
    private var disposeBag = DisposeBag()
    weak var delegate: MailLabelsSettingViewDelegate?
    private let button = UIButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(button)
        self.addSubview(iconView)
        self.addSubview(topBorder)
        self.addSubview(titleLabel)

        button.addTarget(self, action: #selector(didClickLabelSetting), for: .touchUpInside)
        let image = UIImage.lu.fromColor(UIColor.ud.bgBody)
        button.setBackgroundImage(image, for: .normal)
        let highImage = UIImage.lu.fromColor(UIColor.ud.fillHover)
        button.setBackgroundImage(highImage, for: .highlighted)
        button.tintColor = UIColor.ud.textTitle
        button.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelListManageBtnKey
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints({ (make) in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        })
        topBorder.snp.makeConstraints { (make) in
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.left.equalTo(16)
            make.right.equalToSuperview()
            make.top.equalTo(0)
        }
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .hover()
                )
            )
            self.addLKInteraction(pointer)
        }
    }

    lazy var topBorder: UIView = {
        let border = UIView()
        border.backgroundColor = UIColor.ud.lineDividerDefault
        return border
    }()

    // MARK: - views
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.image = UDIcon.mailSettingOutlined.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = UIColor.ud.iconN1
        return iconView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        var title = Store.settingData.folderOpen() ? BundleI18n.MailSDK.Mail_ManageFoldersLabels_Button : BundleI18n.MailSDK.Mail_CustomLabels_ManageLabels
        title = Store.settingData.mailClient ? BundleI18n.MailSDK.Mail_ThirdClient_ManageFolder : title
        titleLabel.attributedText = genTitle(title)
        return titleLabel
    }()

    private func genTitle(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 20
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .left
        return NSAttributedString(string: text,
                                  attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .regular),
                                               .foregroundColor: UIColor.ud.N900,
                                               .paragraphStyle: paragraphStyle])
    }

    @objc
    func didClickLabelSetting() {
        delegate?.didClickManageLabelsButton()
    }
}
