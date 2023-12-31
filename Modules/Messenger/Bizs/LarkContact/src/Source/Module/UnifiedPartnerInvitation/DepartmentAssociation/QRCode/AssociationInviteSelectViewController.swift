//
//  AssociationInviteSelectViewController.swift
//  LarkContact
//
//  Created by zhaoKejie on 2023/9/14.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignCheckBox
import UniverseDesignFont
import LarkMessengerInterface
import LarkButton
import EENavigator
import LarkContainer
import UniverseDesignButton

class AssociationInviteSelectViewController: BaseUIViewController, UITextViewDelegate {

    let router: CollaborationDepartmentViewControllerRouter

    let resolver: UserResolver

    lazy var helpTipsView: UITextView = {
        let textView = UITextView()
        // 创建富文本
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UDFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        let attributedString = NSMutableAttributedString(string: BundleI18n.LarkContact.Lark_B2B_Descrip_TrustedRelationshipBenefit, attributes: textAttributes)

        // 添加超链接

        let linkText = " " + BundleI18n.LarkContact.Lark_B2B_Link_HelpCenterArticle
        if let dependency = try? resolver.resolve(assert: UnifiedInvitationDependency.self),
           let urlStr = dependency.inviteB2bHelpUrl(),
           let url = URL(string: urlStr) {
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .link: url,
                .font: UDFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.ud.textLinkNormal
            ]
            let linkAttributedString = NSAttributedString(string: linkText, attributes: linkAttributes)
            attributedString.append(linkAttributedString)
        }
        textView.attributedText = attributedString
        textView.delegate = self
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.isScrollEnabled = false
        textView.backgroundColor = .ud.bgBody

        return textView
    }()

    lazy var internalBox: AssociationSelectBox = {
        let selectBox = AssociationSelectBox(associationType: .internal) {[weak self] _ in
            self?.handleSelect(type: .internal)
        }
        return selectBox
    }()

    lazy var externalBox: AssociationSelectBox = {
        let selectBox = AssociationSelectBox(associationType: .external) {[weak self] _ in
            self?.handleSelect(type: .external)
        }
        return selectBox
    }()

    lazy var nextButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .big
        let nextButton = UDButton(config)
        nextButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        nextButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        nextButton.setTitle(
            BundleI18n.LarkContact.Lark_TrustedOrg_Button_Next,
            for: .normal)
        nextButton.isEnabled = true
        nextButton.addTarget(self, action: #selector(tapButton), for: .touchUpInside)
        return nextButton
    }()

    @objc
    func tapButton() {
        router.pushCollaborationTenantInviteQRPage(contactType: associationType, self)
    }

    var associationType: AssociationContactType

    init(resolver: UserResolver, router: CollaborationDepartmentViewControllerRouter, associationType: AssociationContactType) {
        self.resolver = resolver
        self.router = router
        self.associationType = associationType
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkContact.Lark_B2B_Title_SelectTrustedRelationship
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(helpTipsView)
        helpTipsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(22)
        }
        self.view.addSubview(internalBox)
        internalBox.snp.makeConstraints { make in
            make.top.equalTo(helpTipsView.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }

        self.view.addSubview(externalBox)
        externalBox.snp.makeConstraints { make in
            make.top.equalTo(internalBox.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }

        self.view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
        }

        handleSelect(type: associationType)
    }

    func handleSelect(type: AssociationContactType) {
        associationType = type

        internalBox.updateSelection(type == .internal)
        externalBox.updateSelection(type == .external)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        router.pushAssociationInviteHelpURL(url: url, from: self)
        return false
    }

}

class AssociationSelectBox: UIView {
    init(associationType: AssociationContactType, selectCallback: @escaping ((Bool) -> Void)) {

        self.associationType = associationType
        self.selectCallback = selectCallback

        checkbox = UDCheckBox(boxType: .single) { udCheckBox in
            selectCallback(udCheckBox.isSelected)
        }

        super.init(frame: .zero)

        self.addSubview(checkbox)
        self.addSubview(titleLabel)
        self.addSubview(subtitleLabel)
        self.addSubview(descLine)
        self.addSubview(descLabel)
        self.addSubview(moreDescButton)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onSelectItemTapped))
        self.addGestureRecognizer(tapGesture)
        self.backgroundColor = .ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let associationType: AssociationContactType

    let checkbox: UDCheckBox

    let selectCallback: ((Bool) -> Void)

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = associationType.titleText
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .ud.textTitle
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = associationType.subtitleText
        label.font = .systemFont(ofSize: 14)
        label.textColor = .ud.textCaption

        return label
    }()

    lazy var descLine: UIView = {
        let lineView = UIView()
        lineView.backgroundColor = .ud.lineDividerDefault
        return lineView
    }()

    lazy var descLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        label.attributedText = NSAttributedString(
            string: associationType.descText,
            attributes: [.paragraphStyle: paragraphStyle,
                         .font: UIFont.systemFont(ofSize: 14),
                         .foregroundColor: UIColor.ud.textPlaceholder]
        )
        return label
    }()

    lazy var moreDescButton: UIButton = {
        let button = UIButton()
        let selectImage = Resources.hideMoreSize16
        let image = Resources.showDetailSize16
        button.setImage(image, for: .normal)
        button.setImage(selectImage, for: .selected)
        button.addTarget(self, action: #selector(onDescButtonTapped), for: .touchUpInside)
        return button
    }()

    @objc
    func onDescButtonTapped() {
        moreDescButton.isSelected = !moreDescButton.isSelected
        layoutSubviews()
    }

    @objc
    func onSelectItemTapped() {
        selectCallback(checkbox.isSelected)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderWidth = 1
        layer.cornerRadius = 8
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        self.layer.ud.setShadow(type: .s2Down)

        checkbox.snp.remakeConstraints { make in
            make.size.equalTo(16)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(32)
        }

        titleLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(44)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(24)
        }

        subtitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(titleLabel)
            make.height.greaterThanOrEqualTo(22)
            if !moreDescButton.isSelected {
                make.bottom.equalToSuperview().inset(16)
            }
        }

        moreDescButton.snp.remakeConstraints { make in
            make.size.equalTo(16)
            make.top.equalToSuperview().offset(32)
            make.right.equalToSuperview().inset(16)
        }

        if moreDescButton.isSelected {
            descLine.isHidden = false
            descLabel.isHidden = false

            descLine.snp.remakeConstraints { make in
                make.height.equalTo(1)
                make.left.right.equalToSuperview().inset(16)
                make.top.equalTo(subtitleLabel.snp.bottom).offset(15)
            }

            descLabel.snp.remakeConstraints { make in
                make.top.equalTo(descLine.snp.bottom).offset(12)
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(12.5)
            }
        } else {
            descLine.isHidden = true
            descLabel.isHidden = true
        }

    }

    func updateSelection(_ selected: Bool) {
        self.checkbox.isSelected = selected
    }

}

extension AssociationContactType {
    var titleText: String {
        switch self {
        case .internal:
            return BundleI18n.LarkContact.Lark_B2B_Menu_InternalOrg
        case .external:
            return BundleI18n.LarkContact.Lark_B2B_Menu_ExternalOrg
        }
    }

    var subtitleText: String {
        switch self {
        case .internal:
            return BundleI18n.LarkContact.Lark_B2B_Descrip_MutualHighTrust
        case .external:
            return BundleI18n.LarkContact.Lark_B2B_Descrip_MutualLowTrust
        }
    }

    var descText: String {
        switch self {
        case .internal:
            return BundleI18n.LarkContact.Lark_B2B_Descrip_MutualInternalOrg
        case .external:
            return BundleI18n.LarkContact.Lark_B2B_Descrip_MutualExternalOrg
        }
    }
}
