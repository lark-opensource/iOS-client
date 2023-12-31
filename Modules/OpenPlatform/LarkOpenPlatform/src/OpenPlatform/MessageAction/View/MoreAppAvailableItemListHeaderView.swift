//
//  MoreAppAvailableItemListHeaderView.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/11.
//

import RichLabel
import LarkUIKit

/// 更多应用或操作header view
/// 支持如下显示模式：
/// Message Action:
/// 更多
/// 1. 可使用企业已安装的应用操作，也可「自建应用操作」
/// 2. 没有更多应用操作了，试试「自建应用操作」
/// Plus Menu:
/// 更多
/// 1. 可使用企业已安装的应用，也可「自建应用」
/// 2. 没有更多应用了，试试「自建应用」
class MoreAppAvailableItemListHeaderView: UICollectionReusableView {
    /// header标识
    static let identifier = String(describing: MoreAppAvailableItemListHeaderView.self)
    /// view高度 link tip隐藏
    static let viewHeightWithLinkTipsHidden: CGFloat = 84.0
    /// view高度 link tip显示
    static let referencedViewHeightWithLinkTipsShowing: CGFloat = 108.0
    static let referencedTipViewHeight: CGFloat = 20.0
    /// 显示link tip时的view高度: 12+8+16+48+8+8+8
    /// 1-2行文字的适配规则不同
    static func viewHeightWithLinkTipsShowing(containerViewWidth: CGFloat, hasAvailableItem: Bool) -> CGFloat {
        let tipViewHeight = Self.tipLabelBoundingBox(superviewWidth: containerViewWidth, hasAvailableItem: hasAvailableItem).height
        let viewHeight = Self.referencedViewHeightWithLinkTipsShowing - (Self.referencedTipViewHeight - tipViewHeight)
        return viewHeight
    }
    static func tipLabelBoundingBox(superviewWidth: CGFloat, hasAvailableItem: Bool) -> CGRect {
        /// label最大宽度
        let tipLabelWidth: CGFloat = superviewWidth - 2 * Self.horizontalInset
        let constraintRect = CGSize(width: tipLabelWidth, height: .greatestFiniteMagnitude)
        let boundingBox = Self.buildAttributedString(hasAvailableItem: hasAvailableItem).boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            context: nil
        )
        return boundingBox.integral
    }
    /// 横向间距
    static let horizontalInset: CGFloat = 16.0
    /// 有可用应用文案
    static var tipText: String { BundleI18n.MessageAction.Lark_OpenPlatform_ScCustomAppDesc }
    /// 无可用应用文案
    static var tipTextNoUsableApp: String { BundleI18n.MessageAction.Lark_OpenPlatform_ScNoMoreAppsTryDesc }
    /// 「企业自建应用」文本
    static var linkText: String { BundleI18n.MessageAction.Lark_OpenPlatform_ScCustomAppHyperlink }
    /// 文案字体
    static let tipFont: UIFont = .systemFont(ofSize: 14.0)

    /// textView跳转代理
    private weak var delegate: UITextViewDelegate?
    /// 设置是否隐藏
    private var linkTipsHidden: Bool = true

    /// section分割视图
    private lazy var sectionSeperatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBase
        return view
    }()

    /// header标题
    private lazy var tipTitle: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        title.textColor = UIColor.ud.textTitle
        title.text = BundleI18n.MessageAction.Lark_OpenPlatform_ScMoreTtl
        title.numberOfLines = 1
        return title
    }()

    /// 提示文案
    private lazy var tipTextView: UITextView = {
        let textView = UITextView()
        textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal]
        textView.textAlignment = .left
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets.zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        return textView
    }()

    /// 是否有推荐应用
    private var hasAvailableItem: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(sectionSeperatorView)
        addSubview(tipTitle)
        addSubview(tipTextView)
        updateViews()
    }

    func updateViews(
        textViewDelegate: UITextViewDelegate,
        linkTipsHidden: Bool,
        hasAvailableItem: Bool
    ) {
        self.hasAvailableItem = hasAvailableItem
        self.delegate = textViewDelegate
        self.linkTipsHidden = linkTipsHidden
        tipTextView.delegate = delegate
        tipTextView.isHidden = linkTipsHidden
        updateViews()
    }

    private func updateViews() {
        updateViewConstraints()
        tipTextView.attributedText = Self.buildAttributedString(hasAvailableItem: hasAvailableItem)
    }

    /// 布局，支持多次调用
    private func updateViewConstraints() {
        sectionSeperatorView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.height.equalTo(8)
        }
        tipTitle.snp.remakeConstraints { (make) in
            make.top.equalTo(sectionSeperatorView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(Self.horizontalInset)
        }
        tipTextView.snp.remakeConstraints { (make) in
            make.top.equalTo(tipTitle.snp.bottom).offset(linkTipsHidden ? 0 : 8)
            make.left.right.equalToSuperview().inset(Self.horizontalInset)
            // 无link不展示tip
            if linkTipsHidden {
                make.height.equalTo(0)
            }
        }
    }

    /// 构建提示语的AttributeString
    static func buildAttributedString(hasAvailableItem: Bool) -> NSAttributedString {
        /// 默认兜底跳转链接
        let linkUrl = NSURL() as URL
        // Setting the attributes
        let linkAttributes = [
            NSAttributedString.Key.link: linkUrl,
            NSAttributedString.Key.font: Self.tipFont,
            NSAttributedString.Key.foregroundColor: UIColor.ud.textLinkNormal
            ] as [NSAttributedString.Key: Any]

        let tipColor = UIColor.ud.textCaption
        let tipAttributes = [
            NSAttributedString.Key.font: Self.tipFont,
            NSAttributedString.Key.foregroundColor: tipColor
            ] as [NSAttributedString.Key: Any]

        let tipText: String
        if hasAvailableItem {
            tipText = Self.tipText
        } else {
            tipText = Self.tipTextNoUsableApp
        }
        let linkText: String = Self.linkText
        let text = tipText + " " + linkText
        let attributedString = NSMutableAttributedString(string: text)

        // Set substring to be the link
        attributedString.setAttributes(tipAttributes, range: NSRange(location: 0, length: tipText.count))
        attributedString.setAttributes(linkAttributes, range: NSRange(location: text.count - linkText.count, length: linkText.count))
        return attributedString
    }
}
