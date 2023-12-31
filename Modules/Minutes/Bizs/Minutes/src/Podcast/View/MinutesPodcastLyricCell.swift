//
//  MinutesPodcastLyricCell.swift
//  Minutes
//
//  Created by yangyao on 2021/4/1.
//

import YYText
import UniverseDesignColor
import Kingfisher
import MinutesFoundation
import Foundation

class MinutesPodcastLyricCell: UITableViewCell {
    struct LayoutContext {
        // 控件左间距
        static let leftMargin: CGFloat = 20
        // 控件右间距
        static let rightMargin: CGFloat = leftMargin
        // 控件上间距
        static let topMargin: CGFloat = 10
        // 控件下间距，上移了yyTextViewTopInset
        static var bottomMargin: CGFloat = 10 - yyTextViewTopInset
        // 控件间竖间距
        static let verticalOffset: CGFloat = 8

        static let yyTextFont: UIFont = UIFont.systemFont(ofSize: 17)

        static let yyTextTopMargin = topMargin
        // YYTextView 控件顶部间距，上移了yyTextViewTopInset
        static var yyTextViewTopMargin = yyTextTopMargin - yyTextViewTopInset

        static var yyTextViewTopMarginLarge: CGFloat = 12
        static var yyTextViewTopMarginLittle: CGFloat = 10

        // YYTextView inset
        // 1. 使多选的小圆圈能够完整显示
        // 2. 搜索关键字刚好在边缘，避免border被截
        static let yyTextViewLeftInset: CGFloat = 0
        static let yyTextViewTopInset: CGFloat = 0

        // YYTextView 控件左间距，左移了yyTextViewLeftInset
        static let yyTextViewLeftMargin = leftMargin - yyTextViewLeftInset

        static let yyTextLineHeight: CGFloat = 28
        static let specifiedTop: CGFloat = 100
    }

    var yyTextWidth: CGFloat {
        return self.bounds.width - LayoutContext.leftMargin - LayoutContext.rightMargin
    }

    var yyTextViewWidth: CGFloat {
        return yyTextWidth + LayoutContext.yyTextViewLeftInset * 2
    }

    var viewModel: MinutesPodcastLyricViewModel?
    var didTextTappedBlock: (() -> Void)?

    var didDoubleClicked: (() -> Void)?

    var result: (String, String)?
    var yyTextViewHeight: CGFloat = 0.0

    var highlightedTimer: Timer?

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
        return textView
    }()

    lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView()
        blurView.alpha = 0.1
        blurView.layer.cornerRadius = 8.0
        blurView.layer.masksToBounds = true
        blurView.effect = UIBlurEffect(style: .light)
        blurView.isHidden = true
        return blurView
    }()

    lazy var topButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(onClickTopButton), for: .touchDown)
        return button
    }()

    deinit {
        highlightedTimer?.invalidate()
        highlightedTimer = nil
    }

    func configure(_ viewModel: MinutesPodcastLyricViewModel, tag: NSInteger) {
        self.viewModel = viewModel

        contentTextView.selectionViewBackgroundColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.15)
        contentTextView.allowLongPressSelectionAlwaysAll = false

        calculateTextHeight()
        // YYText内部依赖，先设置size，否则layout会是nil
        contentTextView.frame = CGRect(x: 0, y: 0, width: yyTextViewWidth, height: yyTextViewHeight)
        let text = viewModel.attributedText

        text.yy_setTextHighlight(YYTextHighlight(), range: text.yy_rangeOfAll())
        contentTextView.attributedText = text
        contentTextView.tag = tag
        contentTextView.isUserInteractionEnabled = false
    }

    @objc func onClickTopButton() {
        blurView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.blurView.isHidden = true
        }
        didTextTappedBlock?()
    }

    func calculateTextHeight() {
        yyTextViewHeight = viewModel?.yyTextViewHeight ?? 0.0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(blurView)
        contentView.addSubview(contentTextView)
        contentView.addSubview(topButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        blurView.frame = CGRect(x: LayoutContext.yyTextViewLeftMargin / 2.0,
                                y: 0,
                                width: contentView.bounds.width - LayoutContext.yyTextViewLeftMargin,
                                height: contentView.bounds.height)

        if let vm = viewModel {
            contentTextView.frame = CGRect(x: LayoutContext.yyTextViewLeftMargin,
                                           y: vm.isCurrentLyric ? LayoutContext.yyTextViewTopMarginLarge: LayoutContext.yyTextViewTopMarginLittle,
                                           width: yyTextViewWidth,
                                           height: yyTextViewHeight)
        } else {
            contentTextView.frame = CGRect(x: LayoutContext.yyTextViewLeftMargin,
                                           y: LayoutContext.yyTextViewTopMarginLittle,
                                           width: yyTextViewWidth,
                                           height: yyTextViewHeight)
        }

        topButton.frame = contentView.bounds
    }
}
