//
//  ExternalInviteGuideController.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/12/25.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LarkContainer
import LarkMessengerInterface
import UniverseDesignColor
import UniverseDesignTheme

private extension ExternalInviteGuideController {
    enum Layout {
        static let titleSide = 22.0
        static let guideIconTop = 64.0
        static let guideIconWidth = 120.0
        static let guideIconHeight = 120.0
        static let descTop = 64.0
        static let descSide = 55.0
        static let tipTop = 16.0
        static let tipSide = 55.0
        static let ctaSide = 16.0
        static let ctaHeight = 48.0
        static let ctaBottom = 58.0
    }
}

final class ExternalInviteGuideController: BaseUIViewController {
    private let fromEntrance: ExternalInviteSourceEntrance

    init(fromEntrance: ExternalInviteSourceEntrance) {
        self.fromEntrance = fromEntrance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutPageSubviews()
    }

    @objc
    func clickToInvite() {
        Tracer.trackInvitePeopleExternalGuideClick(source: fromEntrance.rawValue)
        dismiss(animated: true, completion: nil)
    }

    override func closeBtnTapped() {
        Tracer.trackInvitePeopleExternalGuideClose(source: fromEntrance.rawValue)
        if let closeCallback = closeCallback {
            closeCallback()
        } else {
            super.closeBtnTapped()
        }
    }
}

private extension ExternalInviteGuideController {
    func layoutPageSubviews() {
        view.backgroundColor = UIColor.ud.bgBody

        let containerView = UIView()
        view.addSubview(containerView)

        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        titleLabel.text = BundleI18n.LarkContact.Lark_Guide_ExternalContactsPopupTitle
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)

        let iconView = UIImageView()
        let image = Resources.invite_external_guide
        iconView.image = image
        containerView.addSubview(iconView)

        let tagLabel = InsetsLabel(
            frame: .zero,
            insets: UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        )
        tagLabel.backgroundColor = UIColor.ud.primaryFillSolid02
        tagLabel.layer.cornerRadius = 2.0
        tagLabel.layer.masksToBounds = true
        tagLabel.textColor = UIColor.ud.functionInfoContentDefault
        tagLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        tagLabel.setText(
            text: BundleI18n.LarkContact.Lark_Status_ExternalTag,
            lineSpacing: 4.0
        )
        containerView.addSubview(tagLabel)

        let descLabel = InsetsLabel(frame: .zero, insets: .zero)
        descLabel.textColor = UIColor.ud.textTitle
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        descLabel.setHtml(
            BundleI18n.LarkContact.Lark_Guide_ExternalContactsPopupContent,
            forceLineSpacing: 4
        )
        containerView.addSubview(descLabel)

        let tipLabel = InsetsLabel(frame: .zero, insets: .zero)
        tipLabel.textColor = UIColor.ud.textPlaceholder
        tipLabel.textAlignment = .center
        tipLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        tipLabel.numberOfLines = 0
        tipLabel.setText(
            text: BundleI18n.LarkContact.Lark_Guide_ExternalContactsPopupContentReminder,
            lineSpacing: 4.0
        )
        containerView.addSubview(tipLabel)

        let ctaButton = UIButton(type: .custom)
        ctaButton.backgroundColor = UIColor.ud.primaryContentDefault
        ctaButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        ctaButton.layer.cornerRadius = 4.0
        ctaButton.layer.masksToBounds = true
        ctaButton.setTitle(BundleI18n.LarkContact.Lark_Guide_ExternalContactsPopupButton, for: .normal)
        ctaButton.addTarget(self, action: #selector(clickToInvite), for: .touchUpInside)
        view.addSubview(ctaButton)

        containerView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-72)
            make.leading.trailing.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.titleSide)
        }
        iconView.snp.makeConstraints { (make) in
            make.width.equalTo(Layout.guideIconWidth)
            make.height.equalTo(Layout.guideIconHeight)
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.guideIconTop)
        }
        tagLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(iconView.snp.trailing).offset(-2)
            make.bottom.equalTo(iconView).offset(-20)
        }
        descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(Layout.descTop)
            make.leading.trailing.equalToSuperview().inset(Layout.descSide)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(descLabel.snp.bottom).offset(Layout.tipTop)
            make.leading.trailing.equalToSuperview().inset(Layout.tipSide)
            make.bottom.equalToSuperview()
        }
        ctaButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().inset(Display.iPhoneXSeries ? Layout.ctaBottom : 44)
            make.leading.trailing.equalToSuperview().inset(Layout.ctaSide)
            make.height.equalTo(Layout.ctaHeight)
        }

        view.layoutIfNeeded()
    }
}
