//
//  MailTopAttachmentGuideView.swift
//  MailSDK
//
//  Created by Ender on 2023/6/9.
//

import Foundation
import LarkGuideUI
import UniverseDesignTheme
import UniverseDesignIcon

protocol MailTopAttachmentGuideViewDelegate: AnyObject {
    func didTopAttachmentClickConfirm(location: MailAttachmentLocation)
    func didTopAttachmentClickSkip()
}

final class MailTopAttachmentGuideView: GuideCustomView {
    weak var topAttachmentGuideDelegate: MailTopAttachmentGuideViewDelegate?
    private var attachmentLocation: MailAttachmentLocation = .bottom

    init(delegate: LarkGuideUI.GuideCustomViewDelegate, topAttachmentGuideDelegate: MailTopAttachmentGuideViewDelegate) {
        super.init(delegate: delegate)
        self.topAttachmentGuideDelegate = topAttachmentGuideDelegate
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var buttonTopDivider = UIView()
    private lazy var buttonMidDivider = UIView()

    private lazy var title: UILabel = {
        let title = UILabel()
        title.textColor = UIColor.ud.textTitle
        title.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.maximumLineHeight = Layout.titleLineHeight
        paragraphStyle.minimumLineHeight = Layout.titleLineHeight
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        title.attributedText = NSAttributedString(string: BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_FeatureNotice_Title, attributes: attributes)
        return title
    }()

    private lazy var desc: UILabel = {
        let desc = UILabel()
        desc.textColor = UIColor.ud.textCaption
        desc.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.maximumLineHeight = Layout.descLineHeight
        paragraphStyle.minimumLineHeight = Layout.descLineHeight
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                          NSAttributedString.Key.paragraphStyle: paragraphStyle]
        desc.attributedText = NSAttributedString(string: BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_FeatureNotice_Desc, attributes: attributes)
        return desc
    }()

    private lazy var previewBottomAttach: MailTopAttachmentGuidePreview = {
        let preview = MailTopAttachmentGuidePreview(isTopAttachment: false)
        preview.addTarget(self, action: #selector(didClickBottomAttachment), for: .touchUpInside)
        return preview
    }()

    private lazy var previewTopAttach: MailTopAttachmentGuidePreview = {
        let preview = MailTopAttachmentGuidePreview(isTopAttachment: true)
        preview.addTarget(self, action: #selector(didClickTopAttachment), for: .touchUpInside)
        return preview
    }()

    private lazy var skipButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentView_SkipButton, for: .normal)
        btn.setTitleColor(UIColor.ud.textTitle, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.addTarget(self, action: #selector(didClickSkipButton), for: .touchUpInside)
        return btn
    }()

    private lazy var confirmButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentView_ConfirmButton, for: .normal)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.addTarget(self, action: #selector(didClickConfirmButton), for: .touchUpInside)
        return btn
    }()

    @objc
    private func didClickSkipButton() {
        closeGuideCustomView(view: self)
        topAttachmentGuideDelegate?.didTopAttachmentClickSkip()
    }

    @objc
    private func didClickConfirmButton() {
        closeGuideCustomView(view: self)
        topAttachmentGuideDelegate?.didTopAttachmentClickConfirm(location: attachmentLocation)
    }

    @objc
    private func didClickBottomAttachment() {
        attachmentLocation = .bottom
        previewTopAttach.isSelected = false
        previewBottomAttach.isSelected = true
    }

    @objc
    private func didClickTopAttachment() {
        attachmentLocation = .top
        previewTopAttach.isSelected = true
        previewBottomAttach.isSelected = false
    }

    private lazy var previewHeight = max(previewTopAttach.intrinsicContentSize.height, previewBottomAttach.intrinsicContentSize.height)

    override public var intrinsicContentSize: CGSize {
        let textPrepareSize = CGSize(width: Layout.onboardWidth - Layout.contentInset * 2,
                                     height: CGFloat.greatestFiniteMagnitude)
        let titleHeight = title.sizeThatFits(textPrepareSize).height
        let descHeight = desc.sizeThatFits(textPrepareSize).height
        let onboardHeight = Layout.titleTop + titleHeight + Layout.descTop + descHeight + Layout.previewTop + previewHeight + Layout.buttonTop + Layout.buttonHeight
        return CGSize(width: Layout.onboardWidth, height: onboardHeight)
    }

    func setupViews() {
        if #available(iOS 13.0, *) {
            let correctTrait = UITraitCollection(userInterfaceStyle: UDThemeManager.getRealUserInterfaceStyle())
            UITraitCollection.current = correctTrait
            overrideUserInterfaceStyle = UDThemeManager.getRealUserInterfaceStyle()
        }

        self.clipsToBounds = true
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.cornerRadius = Layout.onboardCornerRadius
        self.snp.makeConstraints { (make) in
            make.width.equalTo(self.intrinsicContentSize.width)
            make.height.equalTo(self.intrinsicContentSize.height)
        }

        addSubview(title)
        addSubview(desc)
        addSubview(previewTopAttach)
        addSubview(previewBottomAttach)
        addSubview(skipButton)
        addSubview(confirmButton)
        addSubview(buttonTopDivider)
        addSubview(buttonMidDivider)
        title.snp.makeConstraints { make in
            make.top.equalTo(Layout.titleTop)
            make.left.right.equalToSuperview().inset(Layout.contentInset)
        }
        desc.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(Layout.descTop)
            make.left.right.equalToSuperview().inset(Layout.contentInset)
        }
        previewBottomAttach.setupViews(hasTag: attachmentLocation == .bottom)
        previewBottomAttach.isSelected = (attachmentLocation == .bottom)
        previewBottomAttach.snp.makeConstraints { make in
            make.top.equalTo(desc.snp.bottom).offset(Layout.previewTop)
            make.left.equalTo(Layout.contentInset)
            make.height.equalTo(previewHeight)
            make.width.equalTo(Layout.previewWidth)
        }
        previewTopAttach.setupViews(hasTag: attachmentLocation == .top)
        previewTopAttach.isSelected = (attachmentLocation == .top)
        previewTopAttach.snp.makeConstraints { make in
            make.top.equalTo(previewBottomAttach.snp.top)
            make.right.equalTo(-Layout.contentInset)
            make.height.equalTo(previewHeight)
            make.width.equalTo(Layout.previewWidth)
        }
        skipButton.snp.makeConstraints { make in
            make.top.equalTo(previewBottomAttach.snp.bottom).offset(Layout.buttonTop)
            make.left.bottom.equalToSuperview()
            make.width.equalTo(Layout.onboardWidth / 2.0 - 1)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(skipButton.snp.top)
            make.right.bottom.equalToSuperview()
            make.width.equalTo(Layout.onboardWidth / 2.0 - 1)
            make.height.equalTo(Layout.buttonHeight)
        }
        buttonTopDivider.backgroundColor = UIColor.ud.lineDividerDefault
        buttonTopDivider.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(skipButton.snp.top)
            make.height.equalTo(1)
        }
        buttonMidDivider.backgroundColor = UIColor.ud.lineDividerDefault
        buttonMidDivider.snp.makeConstraints { make in
            make.top.equalTo(skipButton.snp.top).offset(1)
            make.bottom.equalTo(skipButton.snp.bottom)
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
        }
    }
}

extension MailTopAttachmentGuideView {
    private enum Layout {
        static let onboardCornerRadius: CGFloat = 8
        static let onboardWidth: CGFloat = 303
        static let contentInset: CGFloat = 20
        static let titleTop: CGFloat = 20
        static let descTop: CGFloat = 8
        static let previewTop: CGFloat = 20
        static let buttonTop: CGFloat = 20
        static let titleLineHeight: CGFloat = 24
        static let descLineHeight: CGFloat = 22
        static let previewWidth: CGFloat = 120
        static let buttonHeight: CGFloat = 50
    }
}

fileprivate final class MailTopAttachmentGuidePreview: UIButton {
    private lazy var container = UIView() // 套个最外层容器，用来屏蔽UIView点击事件
    private lazy var bottomContainer = UIView()
    private lazy var bottomContent = UIView()
    private lazy var body = UIView()
    private lazy var bodyBg = UIView() // 有圆角和阴影，需要一个背景层来做阴影
    private lazy var attachmentContainer = UIView()
    private lazy var attachment1 = UIView()
    private lazy var attachment1Name = UIView()
    private lazy var attachment1Info = UIView()
    private lazy var attachment2 = UIView()
    private lazy var attachment2Name = UIView()
    private lazy var attachment2Info = UIView()
    private lazy var text1 = UIView()
    private lazy var text2 = UIView()
    private lazy var text3 = UIView()

    private lazy var avatar: UIImageView = {
        let view = UIImageView()
        view.layer.cornerRadius = 14
        view.image = Resources.avatar_person
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 9)
        label.text = BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentView_UserName("UX Daily")
        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 8)
        label.text = BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentView_EmailAddress(emailAddress: "uxdaily@company.com")
        return label
    }()

    private lazy var attachmentIconWord: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.fileWordColorful
        return view
    }()

    private lazy var attachmentIconVideo: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.fileVideoColorful
        return view
    }()

    private lazy var buttonTitle: UILabel = {
        let title = UILabel()
        title.numberOfLines = 0
        title.text = isTopAttachment
            ? BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_FeatureNotice_AboveText
            : BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_FeatureNotice_BelowText
        title.baselineAdjustment = .alignCenters
        title.font = UIFont.systemFont(ofSize: 12)
        return title
    }()

    private lazy var buttonTag: UILabel = {
        let tag = UILabel()
        tag.text = BundleI18n.MailSDK.Mail_SettingsMobile_AttachmentPlacement_FeatureNotice_CurrentView
        tag.textAlignment = .center
        tag.baselineAdjustment = .alignCenters
        tag.font = UIFont.systemFont(ofSize: 10)
        tag.layer.cornerRadius = 4
        return tag
    }()

    private let isTopAttachment: Bool

    fileprivate override var isSelected: Bool {
        didSet {
            if isSelected {
                self.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
                self.bottomContainer.backgroundColor = UIColor.ud.primaryContentDefault
                self.buttonTitle.textColor = UIColor.ud.primaryOnPrimaryFill
                self.buttonTag.layer.backgroundColor = UIColor.ud.N0015.cgColor
                self.buttonTag.textColor = UIColor.ud.primaryOnPrimaryFill
            } else {
                self.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
                self.bottomContainer.backgroundColor = UIColor.ud.bgBodyOverlay
                self.buttonTitle.textColor = UIColor.ud.textPlaceholder
                self.buttonTag.layer.backgroundColor = UIColor.ud.fillTag.cgColor
                self.buttonTag.textColor = UIColor.ud.udtokenTagNeutralTextNormal
            }
        }
    }

    init(isTopAttachment: Bool) {
        self.isTopAttachment = isTopAttachment
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buttonTagWidth() -> CGFloat {
        let tagPrepareSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Layout.tagLineHeight)
        let tagWidth = buttonTag.sizeThatFits(tagPrepareSize).width
        return tagWidth + Layout.textPadding * 2
    }

    private enum ButtonLayoutType {
        case horizontal
        case vertical
    }

    private func buttonTextNumberOfLinesAndLayout() -> (Int, ButtonLayoutType) {
        let tagWidth = buttonTagWidth()
        var layout: ButtonLayoutType = .horizontal
        var titlePrepareSize = CGSize(width: Layout.previewWidth - Layout.textInset * 2 - tagWidth - Layout.textPadding,
                                     height: CGFloat.greatestFiniteMagnitude)
        var textHeight = buttonTitle.sizeThatFits(titlePrepareSize).height
        var numberOfLines = Int(ceil(textHeight / Layout.titleLineHeight))
        if numberOfLines > 1 {
            // 一行放不下，变成上下布局，title 可用宽度需重新计算
            layout = .vertical
            titlePrepareSize = CGSize(width: Layout.previewWidth - Layout.textInset * 2,
                                      height: CGFloat.greatestFiniteMagnitude)
            textHeight = buttonTitle.sizeThatFits(titlePrepareSize).height
            numberOfLines = Int(ceil(textHeight / Layout.titleLineHeight))
        }
        return (numberOfLines, layout)
    }

    private func bottomContainerHeight() -> CGFloat {
        let (numberOfLines, layout) = buttonTextNumberOfLinesAndLayout()
        if layout == .horizontal {
            return Layout.buttonTopButtom * 2 + Layout.titleLineHeight
        } else {
            return Layout.buttonTopButtom + Layout.titleLineHeight * CGFloat(numberOfLines) + Layout.tagLineHeight + Layout.tagBottom
        }
    }

    override var intrinsicContentSize: CGSize {
        let previewHeight = Layout.previewBodyTop + Layout.previewBodyHeight + Layout.previewBodyBottom + bottomContainerHeight()
        return CGSize(width: Layout.previewWidth, height: previewHeight)
    }

    func setupViews(hasTag: Bool) {
        self.layer.cornerRadius = Layout.previewCornerRadius
        self.layer.borderWidth = Layout.previewBorderWidth
        self.clipsToBounds = true

        addSubview(container)
        container.isUserInteractionEnabled = false
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.addSubview(bodyBg)
        container.addSubview(bottomContainer)
        bottomContainer.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        bottomContainer.addSubview(bottomContent)
        bottomContent.addSubview(buttonTitle)
        if buttonTextNumberOfLinesAndLayout().1 == .horizontal {
            bottomContent.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(Layout.buttonTopButtom)
                make.centerX.equalToSuperview()
            }
            buttonTitle.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            if hasTag {
                bottomContent.addSubview(buttonTag)
                buttonTitle.snp.remakeConstraints { make in
                    make.left.centerY.equalToSuperview()
                }
                buttonTag.snp.makeConstraints { make in
                    make.right.centerY.equalToSuperview()
                    make.left.equalTo(buttonTitle.snp.right).offset(Layout.textPadding)
                    make.height.equalTo(Layout.tagLineHeight)
                    make.width.equalTo(buttonTagWidth())
                }
            }
        } else {
            bottomContent.snp.makeConstraints { make in
                make.top.equalTo(Layout.buttonTopButtom)
                make.bottom.equalTo(-Layout.tagBottom)
                make.centerX.equalToSuperview()
            }
            buttonTitle.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            if hasTag {
                bottomContent.addSubview(buttonTag)
                buttonTitle.snp.remakeConstraints { make in
                    make.top.centerX.equalToSuperview()
                }
                buttonTag.snp.makeConstraints { make in
                    make.top.equalTo(buttonTitle.snp.bottom)
                    make.centerX.bottom.equalToSuperview()
                    make.height.equalTo(Layout.tagLineHeight)
                    make.width.equalTo(buttonTagWidth())
                }
            }
        }

        bodyBg.layer.ud.setShadow(type: .s3Down)
        bodyBg.snp.makeConstraints { make in
            make.top.equalTo(Layout.previewBodyTop)
            make.bottom.equalTo(bottomContainer.snp.top).offset(-Layout.previewBodyBottom)
            make.left.equalTo(Layout.previewBodyLeft)
            make.width.equalTo(Layout.previewBodyWidth)
            make.height.equalTo(Layout.previewBodyHeight)
        }

        bodyBg.addSubview(body)
        body.backgroundColor = UIColor.ud.bgBody
        body.layer.cornerRadius = 8
        body.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        body.layer.borderWidth = 1
        body.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        body.addSubview(avatar)
        body.addSubview(nameLabel)
        body.addSubview(addressLabel)
        body.addSubview(attachmentContainer)
        body.addSubview(text1)
        body.addSubview(text2)
        body.addSubview(text3)

        avatar.snp.makeConstraints { make in
            make.height.width.equalTo(24)
            make.top.equalTo(10)
            make.left.equalTo(8)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.left.equalTo(avatar.snp.right).offset(6)
            make.height.equalTo(18)
        }
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(23)
            make.left.equalTo(nameLabel.snp.left)
            make.height.equalTo(13)
        }

        attachmentContainer.backgroundColor = UIColor.ud.B300
        attachmentContainer.layer.cornerRadius = 6
        text1.backgroundColor = UIColor.ud.N300
        text1.layer.cornerRadius = 2
        text2.backgroundColor = UIColor.ud.N300
        text2.layer.cornerRadius = 2
        text3.backgroundColor = UIColor.ud.N300
        text3.layer.cornerRadius = 2

        if isTopAttachment {
            attachmentContainer.snp.makeConstraints { make in
                make.top.equalTo(avatar.snp.bottom).offset(8)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(30)
            }
            text1.snp.makeConstraints { make in
                make.top.equalTo(attachmentContainer.snp.bottom).offset(6)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(8)
            }
            text2.snp.makeConstraints { make in
                make.top.equalTo(text1.snp.bottom).offset(6)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(8)
            }
            text3.snp.makeConstraints { make in
                make.top.equalTo(text2.snp.bottom).offset(6)
                make.left.equalTo(8)
                make.width.equalTo(48)
                make.height.equalTo(8)
            }
        } else {
            text1.snp.makeConstraints { make in
                make.top.equalTo(avatar.snp.bottom).offset(8)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(8)
            }
            text2.snp.makeConstraints { make in
                make.top.equalTo(text1.snp.bottom).offset(6)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(8)
            }
            text3.snp.makeConstraints { make in
                make.top.equalTo(text2.snp.bottom).offset(6)
                make.left.equalTo(8)
                make.width.equalTo(48)
                make.height.equalTo(8)
            }
            attachmentContainer.snp.makeConstraints { make in
                make.top.equalTo(text3.snp.bottom).offset(6)
                make.left.right.equalToSuperview().inset(8)
                make.height.equalTo(30)
            }
        }

        attachmentContainer.addSubview(attachment1)
        attachmentContainer.addSubview(attachment2)

        attachment1.backgroundColor = UIColor.ud.bgBody
        attachment1.layer.cornerRadius = 4
        attachment1.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(64)
        }
        attachment2.backgroundColor = UIColor.ud.bgBody
        attachment2.layer.cornerRadius = 4
        attachment2.snp.makeConstraints { make in
            make.left.equalTo(attachment1.snp.right).offset(4)
            make.right.top.bottom.equalToSuperview().inset(4)
        }

        attachment1.addSubview(attachmentIconWord)
        attachment1.addSubview(attachment1Name)
        attachment1.addSubview(attachment1Info)
        attachmentIconWord.snp.makeConstraints { make in
            make.height.width.equalTo(14)
            make.top.equalTo(4)
            make.left.equalTo(3)
        }
        attachment1Name.backgroundColor = UIColor.ud.B200
        attachment1Name.layer.cornerRadius = 2
        attachment1Name.snp.makeConstraints { make in
            make.top.equalTo(5.5)
            make.left.equalTo(attachmentIconWord.snp.right).offset(1)
            make.height.equalTo(4)
            make.width.equalTo(38)
        }
        attachment1Info.backgroundColor = UIColor.ud.B200
        attachment1Info.layer.cornerRadius = 2
        attachment1Info.snp.makeConstraints { make in
            make.top.equalTo(attachment1Name.snp.bottom).offset(3)
            make.left.equalTo(attachment1Name.snp.left)
            make.height.equalTo(4)
            make.width.equalTo(18)
        }

        attachment2.addSubview(attachmentIconVideo)
        attachment2.addSubview(attachment2Name)
        attachment2.addSubview(attachment2Info)
        attachmentIconVideo.snp.makeConstraints { make in
            make.height.width.equalTo(14)
            make.top.equalTo(4)
            make.left.equalTo(3)
        }
        attachment2Name.backgroundColor = UIColor.ud.B200
        attachment2Name.layer.cornerRadius = 2
        attachment2Name.snp.makeConstraints { make in
            make.top.equalTo(5.5)
            make.left.equalTo(attachmentIconVideo.snp.right).offset(1)
            make.height.equalTo(4)
            make.width.equalTo(38)
        }
        attachment2Info.backgroundColor = UIColor.ud.B200
        attachment2Info.layer.cornerRadius = 2
        attachment2Info.snp.makeConstraints { make in
            make.top.equalTo(attachment2Name.snp.bottom).offset(3)
            make.left.equalTo(attachment2Name.snp.left)
            make.height.equalTo(4)
            make.width.equalTo(18)
        }
    }
}

extension MailTopAttachmentGuidePreview {
    private enum Layout {
        static let previewCornerRadius: CGFloat = 6
        static let previewBorderWidth: CGFloat = 1
        static let previewWidth: CGFloat = 120
        static let textInset: CGFloat = 8
        static let textPadding: CGFloat = 4
        static let titleLineHeight: CGFloat = 18
        static let tagLineHeight: CGFloat = 16
        static let previewBodyTop: CGFloat = 12
        static let previewBodyBottom: CGFloat = 16
        static let previewBodyLeft: CGFloat = 16
        static let previewBodyWidth: CGFloat = 120 // 因为部分边框/圆角处理复杂，直接做大一点然后切掉
        static let previewBodyHeight: CGFloat = 122
        static let buttonTopButtom: CGFloat = 5
        static let tagBottom: CGFloat = 8
    }
}
