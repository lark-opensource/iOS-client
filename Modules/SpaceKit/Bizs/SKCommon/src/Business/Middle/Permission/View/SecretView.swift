//
//  SecretView.swift
//  SKCommon
//
//  Created by guoqp on 2022/8/4.
//
//  swiftlint:disable file_length

import Foundation
import SKUIKit
import SnapKit
import SKResource
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignCheckBox
import SKFoundation
import SwiftyJSON
import UniverseDesignNotice
import UniverseDesignDialog
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignTag
import UIKit

public final class SecretLevelItem {
    var selected: Bool = false
    let title: String
    let subTitle: String
    let description: String
    var levelLabel: SecretLevelLabel
    init(title: String, subTitle: String, description: String, selected: Bool, levelLabel: SecretLevelLabel) {
        self.title = title
        self.subTitle = subTitle
        self.selected = selected
        self.description = description
        self.levelLabel = levelLabel
    }
}

public final class SecretLevelItemView: UIView {
    private(set) var item: SecretLevelItem
    /// 选中密级
    var selectTap: ((SecretLevelItem) -> Void)?
    /// 点击"审批中"tagView
    var approvalCountTagViewTap: ((SecretLevelItem) -> Void)?

    private(set) var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()
    var isEnableTap = true
    var panelEnabled: Bool = true {
        didSet {
            checkBox.isEnabled = false
            isEnableTap = false
        }
    }
    
    private let mainTitleStackView: UIStackView = {
        let sv = UIStackView()
        sv.alignment = .top
        sv.axis = .horizontal
        sv.spacing = 8
        return sv
    }()
    
    private var mainLabel: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.textTitle
        l.font = UIFont.systemFont(ofSize: 16)
        l.numberOfLines = 0
        return l
    }()

    private var subTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.textPlaceholder
        l.font = UIFont.systemFont(ofSize: 14)
        l.numberOfLines = 0
        return l
    }()

    private var descriptionLabel: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.functionWarningContentDefault
        l.font = UIFont.systemFont(ofSize: 14)
        l.numberOfLines = 0
        return l
    }()

    private lazy var tagView: UDTag = {
        UDTag(withText: "")
    }()
    
    private let defaultTagView: UDTag = {
        let configure = UDTag.Configuration.text(BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Default_Tag, tagSize: .mini, colorScheme: .normal)
        let tag = UDTag(withText: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Default_Tag)
        tag.updateConfiguration(configure)
        return tag
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = UDColor.bgBody
//        view.layer.cornerRadius = 10
//        view.clipsToBounds = true

        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 4

        return view
    }()

    init(item: SecretLevelItem) {
        self.item = item
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody

        addSubview(checkBox)
        addSubview(stackView)

        checkBox.snp.makeConstraints { (make) in
            make.height.width.equalTo(20)
            make.left.top.equalToSuperview().inset(12)
        }

        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(12)
            make.leading.equalTo(checkBox.snp.trailing).offset(12)
        }
        
        mainTitleStackView.addArrangedSubview(mainLabel)
        if item.levelLabel.isDefault {
            mainTitleStackView.addArrangedSubview(defaultTagView)
        }
        stackView.addArrangedSubview(mainTitleStackView)
        stackView.addArrangedSubview(subTitleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(tagView)

        mainLabel.text = item.title
        subTitleLabel.text = item.subTitle
        descriptionLabel.text = item.description
        if UserScopeNoChangeFG.TYP.permissionSecretDetail {
            descriptionLabel.isHidden = true
        } else {
            descriptionLabel.isHidden = item.description.isEmpty || item.selected == false
        }
        checkBox.isSelected = item.selected

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))

        tagView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapApprovalCountTagView))
        tagView.addGestureRecognizer(tap)
    }

    public func updateState(selected: Bool) {
        if isEnableTap {
            item.selected = selected
            if UserScopeNoChangeFG.TYP.permissionSecretDetail {
                descriptionLabel.isHidden = true
            } else {
                descriptionLabel.isHidden = item.description.isEmpty || item.selected == false
            }
            checkBox.isSelected = item.selected
        } else {
            guard !selected else { return }
            UDToast.docs.showMessage(BundleI18n.SKResource.LarkCCM_Workspace_SecLevil_ManagePermRequired_Toast, on: self.window ?? self, msgType: .failure)
        }
    }
    func updateNumber(count: Int) {
        guard count > 0 else {
            tagView.isHidden = true
            return
        }
        tagView.isHidden = false
        let text = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_xpplRequested_Tag(count)

        let configure = UDTag.Configuration.text(
            text,
            tagSize: .small,
            colorScheme: UDTag.Configuration.ColorScheme.blue,
            isOpaque: false
        )
        tagView.updateConfiguration(configure)
    }

    @objc
    private func didTap() {
        selectTap?(item)
    }

    @objc
    private func tapApprovalCountTagView() {
        approvalCountTagViewTap?(item)
    }
}

class ApprovalListCell: UITableViewCell {
    static let reuseIdentifier = "ApprovalListCell"
    static let cellHeight: CGFloat = 56
    var linkButtonTap: (() -> Void)?
    var avatarTap: (() -> Void)?

    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.N100
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAvatarViewAction))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()

    private lazy var nickLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textCaption
        return label
    }()

    private lazy var linkButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_SecLevII_CheckRequestProgress_Button, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UIFont.docs.pfsc(14)
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        btn.addTarget(self, action: #selector(linkButtonAction), for: .touchUpInside)
        return btn
    }()

    @objc
    private func linkButtonAction() {
        linkButtonTap?()
    }

    @objc
    private func clickAvatarViewAction() {
        avatarTap?()
    }

    func update(avatarURL: String, nickName: String, time: TimeInterval, canShowProgress: Bool) {
        linkButton.isHidden = !canShowProgress
        linkButton.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            if !canShowProgress {
                make.width.equalTo(0)
            }
        }

        if avatarURL.hasPrefix("http") {
            avatarView.kf.setImage(with: URL(string: avatarURL),
                                   placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder,
                                   options: nil, progressBlock: nil) { (_) in
            }
        }
        nickLabel.text = nickName
        let timeString = time.stampDateFormatter
        descriptionLabel.text = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_ByWhen(timeString)
    }


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        doInitUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func doInitUI() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(avatarView)
        contentView.addSubview(nickLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(linkButton)

        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(36)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
        avatarView.layer.cornerRadius = CGFloat(18)
        avatarView.layer.masksToBounds = true

        nickLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nickLabel.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(linkButton.snp.left).offset(-12)
        }

        linkButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }
}

class ApprovalListCellSectionHeaderView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = UDColor.textTitle
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        setupUI()
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(22)
            make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-22)
            make.top.bottom.equalToSuperview().inset(16)
        }
    }
}

public final class SecretApprovalDialog {
    public static func selfRepeatedApprovalDialog(cancel: (() -> Void)? = nil, define: @escaping () -> Void) -> UDDialog {
        let config = UDDialogUIConfig()
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_ConfirmSubmit_Title)
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_ConfirmSubmit_Text)

        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            cancel?()
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Submit_Button, dismissCompletion: {
            define()
        })
        return dialog
    }

    public static func otherRepeatedApprovalDialog(num: Int, name: String, approvalList: @escaping () -> Void, cancel: (() -> Void)? = nil, define: @escaping () -> Void) -> UDDialog {
        let config = UDDialogUIConfig()
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_ConfirmSubmit_Title)
        var keyWord = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_1Request_Mob
        var text = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_1RequestedBefore_Mob(name)
        if num > 1 {
            keyWord = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_NRequest_Mob(num)
            text = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_NRequestedBefore_Mob(num, name)
        }
        let content = ConfirmView(keyWord: keyWord, text: text)
        content.tap = {
            approvalList()
        }
        dialog.setContent(view: content)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            cancel?()
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_AdjustRequest_Submit_Button, dismissCompletion: {
            define()
        })
        return dialog
    }

    public static func sendApprovaSuccessDialog(showApprovals: @escaping () -> Void, define: @escaping () -> Void) -> UDDialog {
        let config = UDDialogUIConfig()
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Submitted_Title)
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Submitted_Text)

        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Submitted_Check_Button, dismissCheck: {
            showApprovals()
            return false
        })

        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Submitted_GotIt_Button, dismissCompletion: {
            define()
        })
        return dialog
    }

    public static func secretLevelUpgradeDialog(define: @escaping () -> Void) -> UDDialog {
        let config = UDDialogUIConfig()
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_ActionConfirm_Header)
        dialog.setContent(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Revokelast)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Cancel_Button_Mob)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Confirm_Button_Mob, dismissCompletion: {
            define()
        })
        return dialog
    }
}

private class ConfirmView: UIView {
    private var allRanges: [NSRange] = []
    private var keyWordRange: NSRange?
    var tap: (() -> Void)?

    private var label: UILabel = {
        let label = UILabel()
        label.isUserInteractionEnabled = true
        label.textAlignment = .center
        label.sizeToFit()
        label.numberOfLines = 0
        return label
    }()

    init(keyWord: String, text: String) {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        label.attributedText = contentAttributedString(keyWord: keyWord, text: text)
        if let range = keyWordRange {
            self.allRanges.append(range)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTitleLable(_:)))
        self.label.addGestureRecognizer(tap)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapTitleLable(_ ges: UITapGestureRecognizer) {
        let characterIndex = characterIndexAtPoint(ges.location(in: ges.view))
        guard let attributedText = self.label.attributedText,
              characterIndex >= 0,
              characterIndex < attributedText.length,
              allRanges.count > 0 else {
            return
        }
        let ranges = allRanges
        for index in 0..<ranges.count {
            let range = ranges[index]
            if characterIndex >= range.location && (characterIndex <= range.location + range.length) {
                tap?()
            }
        }
    }

    private func characterIndexAtPoint(_ location: CGPoint) -> Int {
        guard let titleLabelAttributedText = self.label.attributedText else { return 0 }
        let textStorage = NSTextStorage(attributedString: titleLabelAttributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: self.label.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.maximumNumberOfLines = 100
        textContainer.lineBreakMode = self.label.lineBreakMode
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        return layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    }

    private func contentAttributedString(keyWord: String, text: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UDColor.textTitle,
                                                         .font: UIFont.systemFont(ofSize: 16),
                                                         .paragraphStyle: paragraph]

        let attrStr = NSMutableAttributedString(string: text, attributes: attributes)
        let keyWordRange = (text as NSString).range(of: keyWord)
        if keyWordRange.length > 0 {
            attrStr.addAttributes([.foregroundColor: UDColor.primaryContentDefault], range: keyWordRange)
            self.keyWordRange = keyWordRange
        }
        return attrStr
    }
}

public final class ApprovalReviewersView: UIView {
    var click: ((SecretLevelApprovalReviewer) -> Void)?
    var width: Float = 0.0
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
//        view.layer.cornerRadius = 10
//        view.clipsToBounds = true

        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .leading
        view.spacing = 4

        return view
    }()


    func update(reviewers: [SecretLevelApprovalReviewer]) {
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            make.height.equalTo(28)
        }

        for item in reviewers {
            let view = AvatarTitleView(url: item.avatarKey, title: item.name)
            view.click = { [weak self] in
                guard let self = self else { return }
                self.click?(item)
            }
            if width > 0 {
                view.snp.makeConstraints { make in
                    make.width.lessThanOrEqualTo(width / (Float)(reviewers.count))
                }
            }
            stackView.addArrangedSubview(view)
        }
    }

    init(reviewers: [SecretLevelApprovalReviewer]) {
        super.init(frame: .zero)
        update(reviewers: reviewers)
    }

    init() {
        super.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


private class AvatarTitleView: UIView {
    var click: (() -> Void)?
    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.N100
        imageView.layer.cornerRadius = CGFloat(10)
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var nickLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textTitle
        label.numberOfLines = 1
//        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    init(url: String, title: String) {
        super.init(frame: .zero)
        addSubview(avatarView)
        addSubview(nickLabel)

        avatarView.backgroundColor = .clear
        nickLabel.text = title

        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20.0)
            make.centerY.equalToSuperview()
            make.leading.top.equalToSuperview().offset(4)
        }

        nickLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(4)
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }

        let avatarURL = url
        if avatarURL.hasPrefix("http") {
            avatarView.kf.setImage(with: URL(string: avatarURL),
                                   placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder,
                                   options: nil, progressBlock: nil) { (_) in
            }
        }

        backgroundColor = UDColor.udtokenTagNeutralBgNormal
        layer.cornerRadius = CGFloat(14)
        layer.masksToBounds = true

        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAction))
        addGestureRecognizer(tap)
    }

    @objc
    func clickAction() {
        click?()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
