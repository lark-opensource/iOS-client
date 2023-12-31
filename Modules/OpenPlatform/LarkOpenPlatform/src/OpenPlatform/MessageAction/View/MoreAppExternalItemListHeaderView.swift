//
//  MoreAppExternalItemListHeaderView.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/11.
//

import RichLabel
import UIKit
import LarkUIKit
import EENavigator
import RxSwift
import LKCommonsLogging
import Swinject
import RoundedHUD
import LarkOPInterface
import UniverseDesignColor
import UniverseDesignIcon
import LarkContainer

/// 常用应用或操作header view
/// 支持如下显示模式：
/// Message Action:
/// 1. 我的常用， 长按拖拽卡片调整排序
/// 2. 我的常用
///    暂无常用，可在下方点击+进行添加
/// Plus Menu:
/// 1. 我的常用「？」， 长按拖拽卡片调整排序
/// 2. 我的常用「？」
///    可在下方点击+添加应用到常用，使其在菜单展示
class MoreAppExternalItemListHeaderView: UICollectionReusableView {
    /// header标识
    static let identifier = String(describing: MoreAppExternalItemListHeaderView.self)
    /// 无常用应用时的view高度: 16+24+16+64+4+8
    static func viewHeightWithNoExternalItems(containerViewWidth: CGFloat) -> CGFloat {
        let dashedViewHeight = Self.dashedViewHeightWithNoExternalItems(containerViewWidth: containerViewWidth)
        Self.dashedViewHeight = dashedViewHeight
        let viewHeight = Self.refrencedViewHeightWithNoExternalItems - (Self.refrencedDashedViewHeightWithNoExternalItems - dashedViewHeight)
        return viewHeight
    }
    /// dashedView高度需要自适应：1-2行文字的适配规则不同，保持上下间距14pt
    static func dashedViewHeightWithNoExternalItems(containerViewWidth: CGFloat) -> CGFloat {
        let superviewWidth = Self.dashedViewWidthWithNoExternalItems(containerViewWidth: containerViewWidth)
        let emptyTipLabelBoundingBox = emptyTipLabelBoundingBoxWithNoExternalItems(superviewWidth: superviewWidth)
        let emptyTipLabelHeight = ceil(emptyTipLabelBoundingBox.height)
        let dashedViewHeight = emptyTipLabelHeight + 2 * Self.emptyTipLabelVerticalInset
        return max(dashedViewHeight, 0)
    }
    static func dashedViewWidthWithNoExternalItems(containerViewWidth: CGFloat) -> CGFloat {
        return containerViewWidth - 2 * Self.horizontalInset
    }
    /// dashedView高度需要自适应：1-2行文字的适配规则不同，保持上下间距14pt
    static func emptyTipLabelBoundingBoxWithNoExternalItems(superviewWidth: CGFloat) -> CGRect {
        /// label最大宽度
        let emptyTipLabelWidth: CGFloat = superviewWidth - 2 * Self.emptyTipLabelHorizontalInset
        let constraintRect = CGSize(width: emptyTipLabelWidth, height: .greatestFiniteMagnitude)
        let boundingBox = Self.emptyTipLabelText.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: Self.emptyTipLabelFont],
            context: nil
        )
        return boundingBox.integral
    }
    static let refrencedViewHeightWithNoExternalItems: CGFloat = 116.0
    static let refrencedDashedViewHeightWithNoExternalItems: CGFloat = 64.0
    static var dashedViewHeight: CGFloat = 64.0
    /// 具有常用应用时的view高度: 16+24+4+8
    static let viewHeightWithExternalItems: CGFloat = 52.0
    /// 横向间距
    static let horizontalInset: CGFloat = 16.0

    /// 业务场景
    private var bizScene: BizScene = .addMenu

    /// header标题
    private lazy var tipTitle: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .left
        title.numberOfLines = 1
        /// 使title的内容更易拉伸
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return title
    }()
    /// header标题描述
    private lazy var tipDescription: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.MessageAction.LarkOpen_MsgShortcuts_LongPressDragDesc
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .right
        label.numberOfLines = 1
        /// 使description的内容更易收缩
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    /// 空提示文案视图
    private lazy var dashedView: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var dashedViewBorderLayer = CAShapeLayer()
    static var emptyTipLabelText: String { BundleI18n.MessageAction.Lark_OpenPlatform_ScMblAddFreqDesc }
    static let emptyTipLabelFont = UIFont.systemFont(ofSize: 14)
    static let emptyTipLabelHorizontalInset: CGFloat = 24
    static let emptyTipLabelVerticalInset: CGFloat = 14
    private lazy var emptyTipLabel: UILabel = {
        let tipLabel = UILabel()
        tipLabel.text = Self.emptyTipLabelText
        tipLabel.font = Self.emptyTipLabelFont
        tipLabel.textColor = UIColor.ud.textPlaceholder
        tipLabel.textAlignment = .left
        tipLabel.numberOfLines = 0
        return tipLabel
    }()

    private weak var containerView: UIView?

    /// 是否有推荐应用
    private var hasAvailableItem: Bool = false
    /// 推荐应用个数是否超过1
    private var availableItemCountGreaterThan1: Bool = false

    private var showHelpIcon: Bool {
        return (bizScene == .addMenu)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(tipTitle)
        addSubview(tipDescription)
        addSubview(dashedView)
        /// 设置子视图
        dashedView.addSubview(emptyTipLabel)
        updateViews()
        if showHelpIcon {
            tipTitle.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(tipTextTapped))
            tipTitle.addGestureRecognizer(tap)
        }
    }

    func updateViews(
        bizScene: BizScene,
        hasAvailableItem: Bool,
        availableItemCountGreaterThan1: Bool,
        containerView: UIView
    ) {
        self.bizScene = bizScene
        self.hasAvailableItem = hasAvailableItem
        self.availableItemCountGreaterThan1 = availableItemCountGreaterThan1
        self.containerView = containerView
        updateViews()
    }

    private func updateViews() {
        updateViewConstraints()
        tipTitle.attributedText = getTipAttributedString()
        tipDescription.isHidden = !hasAvailableItem || !availableItemCountGreaterThan1
    }

    private var shouldDashedViewHidden: Bool {
        return hasAvailableItem
    }

    /// 布局，支持多次调用
    private func updateViewConstraints() {
        tipTitle.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.left.equalToSuperview().inset(Self.horizontalInset)
        }
        tipDescription.snp.remakeConstraints { make in
            make.centerY.equalTo(tipTitle)
            make.right.equalToSuperview().inset(Self.horizontalInset)
            make.left.greaterThanOrEqualTo(tipTitle.snp.right).offset(8)
        }
        dashedView.snp.remakeConstraints { make in
            // 无应用列表，则不展示tip
            make.top.equalTo(tipTitle.snp.bottom).offset(!shouldDashedViewHidden ? 16 : 0)
            make.left.right.equalToSuperview().inset(Self.horizontalInset)
        }
        dashedView.isHidden = shouldDashedViewHidden
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let containerViewWidth = containerView?.op_width ?? 0
        dashedView.op_height = Self.dashedViewHeightWithNoExternalItems(containerViewWidth: containerViewWidth)
        let dashedViewWidth = Self.dashedViewWidthWithNoExternalItems(containerViewWidth: containerViewWidth)
        dashedView.op_width = dashedViewWidth
        // 不满一行时，文本居中；否则居左对齐
        emptyTipLabel.op_size = Self.emptyTipLabelBoundingBoxWithNoExternalItems(superviewWidth: dashedViewWidth).size
        if let superview = emptyTipLabel.superview {
            emptyTipLabel.op_centerX = superview.op_width / 2
            emptyTipLabel.op_centerY = superview.op_height / 2
        }
        refreshDashedViewBorder()
    }

    private func refreshDashedViewBorder() {
        let dashedViewBounds = dashedView.bounds
        if let sublayers = dashedView.layer.sublayers, sublayers.contains(dashedViewBorderLayer) {
            dashedViewBorderLayer.frame = dashedViewBounds
            dashedViewBorderLayer.path = UIBezierPath(roundedRect: dashedViewBounds, cornerRadius: 8).cgPath
            return
        }

        /// 虚线描边
        let viewBorder = dashedViewBorderLayer
        viewBorder.lineWidth = 1
        viewBorder.strokeColor = (UIColor.ud.N400 & UIColor.ud.rgb(0x505050)).cgColor
        viewBorder.lineDashPattern = [4, 4]
        viewBorder.fillColor = nil
        viewBorder.frame = dashedViewBounds
        viewBorder.path = UIBezierPath(roundedRect: dashedViewBounds, cornerRadius: 8).cgPath
        dashedView.layer.addSublayer(viewBorder)
    }

    private func getTipAttributedString() -> NSAttributedString {
        var tip = BundleI18n.MessageAction.Lark_OpenPlatform_ScFreqUsed
        let font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.textTitle
        ]
        if showHelpIcon {
            tip = tip + " "
        }
        let fullText = NSMutableAttributedString(string: tip, attributes: baseAttributes)
        if !showHelpIcon {
            return fullText
        }

        let imageAttatchment = NSTextAttachment()
        imageAttatchment.image = UDIcon.maybeOutlined.ud.withTintColor(UIColor.ud.iconN3)
        let imageWidth: CGFloat = 20.0
        imageAttatchment.bounds = CGRect(x: 0, y: (font.capHeight - imageWidth).rounded() / 2, width: imageWidth, height: imageWidth)
        let imageString = NSAttributedString(attachment: imageAttatchment)
        fullText.append(imageString)
        return fullText
    }

    @objc
    func tipTextTapped() {
        guard let mainWindow = Navigator.shared.mainSceneWindow else {
            assertionFailure()
            return
        }
        let alertController = MoreAppExternalItemListTipModalController()
        Navigator.shared.present(alertController, from: mainWindow, animated: true)
    }
}
