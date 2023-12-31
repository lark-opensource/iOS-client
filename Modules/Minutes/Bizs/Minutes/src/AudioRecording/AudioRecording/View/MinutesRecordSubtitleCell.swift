//
//  MinutesRecordSubtitleCell.swift
//  Minutes
//
//  Created by yangyao on 2021/3/11.
//

import UIKit
import YYText
import UniverseDesignColor
import Kingfisher
import MinutesFoundation
import LarkEMM
import UniverseDesignIcon

class MinutesRecordSubtitleCell: UITableViewCell {
    struct LayoutContext {
        // 控件左间距
        static let leftMargin: CGFloat = 16
        // 控件右间距
        static let rightMargin: CGFloat = leftMargin
        // 控件上间距
        static let topMargin: CGFloat = 10
        // 控件下间距，上移了yyTextViewTopInset
        static let bottomMargin: CGFloat = 10 - yyTextViewTopInset
        // 控件间竖间距
        static let verticalOffset: CGFloat = 8
        // 控件间横间距
        static let horizontalOffset: CGFloat = 8

        static let yyTextFont: UIFont = UIFont.systemFont(ofSize: 16)

        static let yyTextTopMargin: CGFloat = 42
        // YYTextView 控件顶部间距，上移了yyTextViewTopInset
        static let yyTextViewTopMargin = yyTextTopMargin - yyTextViewTopInset

        // YYTextView inset
        // 1. 使多选的小圆圈能够完整显示
        // 2. 搜索关键字刚好在边缘，避免border被截
        static let yyTextViewLeftInset: CGFloat = 5
        static let yyTextViewTopInset: CGFloat = 10

        // YYTextView 控件左间距，左移了yyTextViewLeftInset
        static let yyTextViewLeftMargin = leftMargin - yyTextViewLeftInset

        static let yyTextLineHeight: CGFloat = 24
        static let specifiedTop: CGFloat = 24

        static let timeHeight: CGFloat = 18
        static let textBorderWidth: CGFloat = 1.5
    }
    var yyTextViewWidth: CGFloat {
        return self.bounds.width - LayoutContext.leftMargin - LayoutContext.rightMargin + LayoutContext.yyTextViewLeftInset * 2
    }
    var viewModel: MinutesParagraphViewModel?
    // start time, stop time, 点击区域在window的位置, 高亮的区域
    var didTextTappedBlock: (((String?, String?, CGPoint?, CGRect?)?) -> Void)?

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 13)
        label.textAlignment = .right
        return label
    }()

    private lazy var commentsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        return label
    }()

    private lazy var commentsCountView: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(tappedComments), for: .touchUpInside)
        button.setBackgroundImage(UIImage.dynamicIcon(.iconReplyCnFilled, dimension: 20, color: UIColor.ud.colorfulYellow), for: .normal)
        button.addSubview(commentsCountLabel)
        return button
    }()

    private lazy var highlightedBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.fillColor = UIColor.ud.P200
        border.insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return border
    }()

    private lazy var searchBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.fillColor = UIColor.ud.Y200
        border.insets = UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0)
        return border
    }()

    private lazy var specifiedBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.fillColor = UIColor.ud.Y100
        border.strokeColor = UIColor.ud.Y600
        border.strokeWidth = LayoutContext.textBorderWidth
        border.insets = searchBorder.insets
        return border
    }()

    private lazy var commentsBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.N400
        border.bottomLineStrokeWidth = 1.0
        border.bottomLineType = YYTextBottomLineType(rawValue: 1)
        border.insets = highlightedBorder.insets
        return border
    }()

    private lazy var highlightedCommentsBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.fillColor = UIColor.ud.O200
        border.bottomLineStrokeColor = UIColor.ud.colorfulWathet
        border.bottomLineStrokeWidth = 1.0
        border.bottomLineType = YYTextBottomLineType(rawValue: 0)
        border.insets = highlightedBorder.insets
        return border
    }()

    var result: (String, String)?
    var yyTextViewHeight: CGFloat = 0.0
    var menuCommentsBlock: ((String, NSRange) -> Void)?
    var menuOriginalBlock: ((NSInteger) -> Void)?
    var showCommentsBlock: (() -> Void)?
    var copySuccessBlock: (() -> Void)?

    @objc func tappedComments() {
        showCommentsBlock?()
    }

    @objc func menuCopy(_ menu: UIMenuController) {
        if let text = contentTextView.copiedString() as? String {
            Device.pasteboard(token: DeviceToken.pasteboardRecord, text: text)
            copySuccessBlock?()
        }
    }

    @objc func menuComments(_ menu: UIMenuController) {
        if let text = contentTextView.copiedString() as? String {
            let selectedRange = contentTextView.selectedRange
            menuCommentsBlock?(text, selectedRange)
        }
    }

    @objc func menuSeeOrigin(_ menu: UIMenuController) {
        if let row = viewModel?.pIndex {
            menuOriginalBlock?(row)
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(menuCopy(_:)) {
            return true
        }
        if action == #selector(menuComments(_:)) {
            return true
        }
        if action == #selector(menuSeeOrigin(_:)) {
            return true
        }
        return false
    }

    lazy var contentTextView: YYTextView = {
        let textView = YYTextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.allowSelectionDot = false
        textView.allowShowMagnifierCaret = false
        textView.allowLongPressSelection = false
        textView.textContainerInset = UIEdgeInsets(top: LayoutContext.yyTextViewTopInset,
                                                   left: LayoutContext.yyTextViewLeftInset,
                                                   bottom: LayoutContext.yyTextViewTopInset,
                                                   right: LayoutContext.yyTextViewLeftInset)
        textView.allowsCopyAttributedString = false
//        textView.customMenu = normalMenu()
        return textView
    }()

    func hideMenu() {
        contentTextView.customMenu?.setMenuVisible(false, animated: true)
    }

    func hideSelectionDot() {
        contentTextView.hideSelectionDot()
    }

    func highlightRanges() {
        guard let viewModel = viewModel else { return }
        contentTextView.removeMySelectionRects()

        if viewModel.isLastParagraph, !viewModel.lastSentenceFinal, let range = viewModel.lastSentencesRange {
            let attributedText = viewModel.attributedText
            let attributes: [NSAttributedString.Key: Any] = [
                .font: MinutesRecordSubtitleCell.LayoutContext.yyTextFont,
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
            attributedText.addAttributes(attributes, range: range)
            contentTextView.attributedText = attributedText
        }
    }

    func configure(_ viewModel: MinutesParagraphViewModel, tag: NSInteger) {
        self.viewModel = viewModel
        timeLabel.text = viewModel.time
        commentsCountLabel.text = "\(viewModel.commentsCount)"

        timeLabel.sizeToFit()
        commentsCountLabel.sizeToFit()
        commentsCountView.isHidden = true

        contentTextView.selectionViewBackgroundColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.15)

        calculateTextHeight()
        // YYText内部依赖，先设置size，否则layout会是nil
        contentTextView.frame = CGRect(x: 0, y: 0, width: yyTextViewWidth, height: yyTextViewHeight)
        let text = viewModel.attributedText
        text.yy_setTextHighlight(YYTextHighlight(), range: text.yy_rangeOfAll())
        contentTextView.attributedText = text
        contentTextView.tag = tag
        highlightRanges()
    }

    func translateMenu() -> UIMenuController {
        let menuItems = [
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:))),
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_SeeOriginal, action: #selector(menuSeeOrigin(_:)))]
        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    func normalMenu() -> UIMenuController {
        let menuItems = [
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:))),
            UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Comment, action: #selector(menuComments(_:)))]
        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    func calculateTextHeight() {
        yyTextViewHeight = viewModel?.yyTextViewHeight ?? 0.0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(timeLabel)
        contentView.addSubview(commentsCountView)
        contentView.addSubview(contentTextView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let timeWidth = timeLabel.frame.width
        timeLabel.frame = CGRect(x: LayoutContext.leftMargin,
                                 y: LayoutContext.topMargin,
                                 width: timeWidth,
                                 height: LayoutContext.timeHeight)

        if viewModel?.commentsCount ?? 0 > 0 {
            let commentsWidth = commentsCountLabel.bounds.width + 10
            let commentsHeight = commentsCountLabel.bounds.height + 10
            commentsCountView.frame = CGRect(x: contentView.bounds.width - LayoutContext.rightMargin - commentsWidth,
                                             y: 0,
                                             width: 18,
                                             height: 18)
        }

        var center = timeLabel.center
        center = commentsCountView.center
        center.y = timeLabel.center.y
        commentsCountView.center = center

        center = commentsCountLabel.center
        center.x = commentsCountView.frame.width / 2.0
        center.y = commentsCountView.frame.height / 2.0 - 1
        commentsCountLabel.center = center

        contentTextView.frame = CGRect(x: LayoutContext.yyTextViewLeftMargin,
                                       y: LayoutContext.yyTextViewTopMargin,
                                       width: yyTextViewWidth,
                                       height: yyTextViewHeight)
    }
}
