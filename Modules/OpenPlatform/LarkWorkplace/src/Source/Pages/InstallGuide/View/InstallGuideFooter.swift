//
//  InstallGuideFooter.swift
//  LarkWorkplace
//
//  Created by tujinqiu on 2020/3/13.
//

import UIKit
import LarkUIKit
import RichLabel

final class InstallGuideFooter: UIView {
    enum Action {
        case selectAll(selected: Bool)
        case install
        case gotoClause
    }

    private let checkbox: Checkbox = {
        let box = Checkbox()
        box.setupAppCenterStyle()
        box.addTarget(self, action: #selector(checkboxChanged(sender:)), for: .valueChanged)
        return box
    }()

    private let checkboxLabel: UILabel = {
        let label = UILabel()
        // font 使用 ud token 初始化
        // swiftlint:disable init_font_with_token
        label.font = UIFont.systemFont(ofSize: 16)
        // swiftlint:enable init_font_with_token
        label.textColor = UIColor.ud.textTitle
        label.isUserInteractionEnabled = true
        label.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallSelectAll
        return label
    }()
    private let seletctedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        return label
    }()

    private let installBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6
        button.backgroundColor = UIColor.ud.primaryContentLoading
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallApp, for: .normal)
        button.isEnabled = false
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 9, bottom: 0, right: 9)
        button.addTarget(self, action: #selector(tapInstallBtn(sender:)), for: .touchUpInside)
        return button
    }()

    private let tipLabel: LKLabel = {
        let label = LKLabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = .clear
        label.numberOfLines = 0
        return label
    }()
    private let viewWidth: CGFloat

    var seletctedCount: Int {
        didSet {
            if seletctedCount > 0 {
                installBtn.isEnabled = true
                installBtn.backgroundColor = UIColor.ud.primaryContentDefault
                showEnableTip(viewWidth: viewWidth)
            } else {
                installBtn.isEnabled = false
                installBtn.backgroundColor = UIColor.ud.primaryContentLoading
                showGrayTip(viewWidth: viewWidth)
            }
            seletctedLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallSelected(seletctedCount)
        }
    }

    var isAllSelected: Bool {
        didSet {
            checkbox.setOn(on: isAllSelected)
        }
    }

    var isReinstall: Bool {
        didSet {
            installBtn.setTitle(isReinstall ?
                BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideReinstallApp :
                BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallApp, for: .normal)
        }
    }

    var actionHandler: ((Action) -> Void)?

    init(viewWidth: CGFloat) {
        self.seletctedCount = 0
        self.isAllSelected = false
        self.isReinstall = false
        self.viewWidth = viewWidth

        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.top.equalToSuperview().offset(19)
            make.left.equalToSuperview().offset(16)
        }

        addSubview(checkboxLabel)
        checkboxLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(8)
            make.centerY.equalTo(checkbox)
        }
        let ges = UITapGestureRecognizer(target: self, action: #selector(tapCheckbox))
        checkboxLabel.addGestureRecognizer(ges)

        addSubview(seletctedLabel)
        seletctedLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkboxLabel.snp.right).offset(10)
            make.centerY.equalTo(checkboxLabel)
        }

        addSubview(installBtn)
        installBtn.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.centerY.equalTo(checkboxLabel)
            make.right.equalToSuperview().offset(-16)
        }

        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-16)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(52)
            make.right.equalToSuperview().offset(-16)
        }

        showGrayTip(viewWidth: viewWidth)

        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 4
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
        layer.shadowOpacity = 0.17
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func checkboxChanged(sender: Checkbox) {
        actionHandler?(.selectAll(selected: sender.on))
    }

    @objc
    private func tapCheckbox() {
        checkbox.setOn(on: !checkbox.on)
        actionHandler?(.selectAll(selected: checkbox.on))
    }

    @objc
    private func tapInstallBtn(sender: UIButton) {
        actionHandler?(.install)
    }

    private func showGrayTip(viewWidth: CGFloat) {
        tipLabel.preferredMaxLayoutWidth = viewWidth - 16 * 2
        tipLabel.removeLKTextLink()
        let clause = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallClausePlaceholder
        let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallClauseAll(clause)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3.5
        let attrs = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let attributedString = NSMutableAttributedString(string: str, attributes: attrs)
        tipLabel.attributedText = attributedString
    }

    private func showEnableTip(viewWidth: CGFloat) {
        tipLabel.preferredMaxLayoutWidth = viewWidth - 16 * 2
        let clause = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallClausePlaceholder
        let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GuideInstallClauseAll(clause)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3.5
        let attrs = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
            NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
            NSAttributedString.Key.paragraphStyle: style
        ]
        let attributedString = NSMutableAttributedString(string: str, attributes: attrs)
        let range = (attributedString.string as NSString).range(of: clause)
        if range.location != NSNotFound {
            var link = LKTextLink(
                range: range,
                type: .link,
                attributes: [.foregroundColor: UIColor.ud.textLinkNormal],
                activeAttributes: [.foregroundColor: UIColor.ud.textLinkPressed]
            )
            link.linkTapBlock = { [weak self] (_, _) in
                self?.actionHandler?(.gotoClause)
            }
            tipLabel.addLKTextLink(link: link)
        }
        tipLabel.attributedText = attributedString
    }
}
