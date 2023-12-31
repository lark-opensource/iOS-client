//
//  AppDetailApplyOrNoPermissionHeaderView.swift
//  LarkAppCenter
//
//  Created by houjihu on 2021/6/16.
//

import LarkUIKit
import SnapKit

/// 申请使用/无权限删除机器人headerView
/// 支持若干种视图组合展示：
/// 1. !你没有权限使用此应用，无法与机器人单聊或打开应用。「申请使用应用」
/// 2. !仅群主和添加者可删除此机器人。
/// 3. !你没有权限使用此应用，无法与机器人单聊或打开应用。「申请使用应用」
///     仅群主和添加者可删除此机器人。
/// 4. !你没有权限使用此应用，无法与机器人单聊或打开应用。
///     仅群主和添加者可删除此机器人。
class AppDetailApplyOrNoPermissionHeaderView: UITableViewHeaderFooterView {
    /// reuse id
    static let headerReuseID = "AppDetailApplyOrNoPermissionHeaderViewReuseID"
    static let logoViewSize: CGSize = CGSize(width: 16, height: 16)
    static let horizontalMargin: CGFloat = 16.0
    static let logoTextHorizontalMargin: CGFloat = 4.0
    static let logoTextVerticalMargin: CGFloat = -0.5
    static let logoTopMargin: CGFloat = 16.0
    static let invisibleTextViewLinkTextColor = UIColor.ud.primaryContentDefault
    static let textFont = UIFont.systemFont(ofSize: 14.0)
    static let textColor = UIColor.ud.textPlaceholder

    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()
    /// Item的图标
    private lazy var logoView: UIImageView = {
        let logoView = UIImageView(image: BundleResources.LarkOpenPlatform.AppDetail.icon_warning_outlined)
        return logoView
    }()
    /// 可见性提示label
    private lazy var invisibleTextView: UITextView = {
        let textView = UITextView()
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: Self.invisibleTextViewLinkTextColor]
        textView.backgroundColor = .clear
        textView.textAlignment = .left
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        return textView
    }()
    /// 权限提示label
    private lazy var noPermissionLabel: UILabel = {
        let label = UILabel()
        label.font = Self.textFont
        label.textColor = Self.textColor
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.text = BundleI18n.GroupBot.Lark_GroupBot_CustomAppPermissionDesc
        label.numberOfLines = 0
        return label
    }()

    private var containerWidth: CGFloat = 0.0
    private var applyForUseOnClick: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundView = UIView(frame: self.bounds)
        backgroundView?.backgroundColor = .clear
        contentView.addSubview(container)
        container.addSubview(logoView)
        container.addSubview(invisibleTextView)
        container.addSubview(noPermissionLabel)
    }

    /// 布局，支持多次调用
    /// 可展示可见性，权限提示可选展示
    private func setupContraintsForInvisibleAndOptionalPermissionViews(showNoPermissionLabel: Bool) {
        container.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Self.horizontalMargin)
        }

        logoView.snp.remakeConstraints { (make) in
            make.size.equalTo(Self.logoViewSize)
            make.left.equalToSuperview()
            make.top.equalToSuperview().inset(Self.logoTopMargin)
        }

        invisibleTextView.snp.remakeConstraints { (make) in
            make.left.equalTo(logoView.snp.right).offset(Self.logoTextHorizontalMargin)
            make.right.equalToSuperview()
            make.top.equalTo(logoView.snp.top).offset(Self.logoTextVerticalMargin)
        }

        noPermissionLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(logoView.snp.right).offset(Self.logoTextHorizontalMargin)
            make.right.equalToSuperview()
            make.top.equalTo(invisibleTextView.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
            if !showNoPermissionLabel {
                make.height.equalTo(0)
            }
        }
    }

    /// 布局，支持多次调用
    /// 仅展示权限提示
    private func setupContraintsForOnlyPermissionViews() {
        container.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(Self.horizontalMargin)
        }

        logoView.snp.remakeConstraints { (make) in
            make.size.equalTo(Self.logoViewSize)
            make.left.equalToSuperview()
            make.top.equalToSuperview().inset(Self.logoTopMargin)
        }

        invisibleTextView.snp.remakeConstraints { (make) in
            make.width.height.equalTo(0)
            make.center.equalToSuperview()
        }

        noPermissionLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(logoView.snp.right).offset(Self.logoTextHorizontalMargin)
            make.right.equalToSuperview()
            make.top.equalTo(logoView.snp.top).offset(Self.logoTextVerticalMargin)
            make.bottom.equalToSuperview()
        }
    }

    /// 更新视图。针对是否有权限删除机器人或者可见性，展示不同文案
    func updateViews(
        containerWidth: CGFloat,
        showInvisibleTip: Bool,
        canApplyAccessWhenInVisible: Bool?,
        noPermission: Bool?,
        applyForUseOnClick: (() -> Void)?
    ) {
        self.containerWidth = containerWidth
        self.applyForUseOnClick = applyForUseOnClick

        invisibleTextView.attributedText = Self.buildAttributedString(canApplyAccessWhenInVisible: canApplyAccessWhenInVisible)

        if showInvisibleTip {
            setupContraintsForInvisibleAndOptionalPermissionViews(showNoPermissionLabel: (noPermission == true))
        } else {
            setupContraintsForOnlyPermissionViews()
        }
    }

    /// 构建提示语的AttributeString
    static func buildAttributedString(canApplyAccessWhenInVisible: Bool?) -> NSAttributedString {
        // Setting the attributes
        let tipAttributes = [
            NSAttributedString.Key.font: Self.textFont,
            NSAttributedString.Key.foregroundColor: Self.textColor
            ] as [NSAttributedString.Key: Any]

        let showApply = canApplyAccessWhenInVisible == true
        /// 你没有权限使用此应用，无法与机器人单聊或打开应用
        let tipText: String = BundleI18n.GroupBot.Lark_GroupBot_NoAccessToBotDesc
        /// 申请使用应用
        let linkText: String = BundleI18n.AppDetail.AppDetail_Application_Mechanism_ApplyAccess
        let text = showApply ? tipText + " " + linkText : tipText
        let attributedString = NSMutableAttributedString(string: text)

        attributedString.setAttributes(tipAttributes, range: NSRange(location: 0, length: tipText.count))
        if showApply {
            // Set substring to be the link
            /// 默认兜底跳转链接
            let linkUrl = NSURL() as URL
            let linkAttributes = [
                NSAttributedString.Key.link: linkUrl,
                NSAttributedString.Key.font: Self.textFont,
                NSAttributedString.Key.foregroundColor: Self.invisibleTextViewLinkTextColor
                ] as [NSAttributedString.Key: Any]
            attributedString.setAttributes(linkAttributes, range: NSRange(location: text.count - linkText.count, length: linkText.count))
        }
        return attributedString
    }

    @objc
    func applyForUse() {
        applyForUseOnClick?()
    }
}


// MARK: 交互事件
extension AppDetailApplyOrNoPermissionHeaderView: UITextViewDelegate {
    /// 跳转「获取企业自建应用」
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        applyForUse()
        return false
    }
}
