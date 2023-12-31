//
//  SubtitleHistoryCell.swift
//  ByteView
//
//  Created by kiri on 2020/6/10.
//

import UIKit
import RichLabel
import RxSwift

class SubtitleHistoryCell: SubtitleHistoryBaseCell, LKSelectionLabelDelegate {
    private static let minTextLineHeight: CGFloat = 22
    private static let textBaselineOffsetFactor: CGFloat = 4.0
    private static let minCellHeight: CGFloat = 40.0
    private static let defaultFontSize: CGFloat = 16
    private static let contentLeftMargin: CGFloat = 52
    private static let contentRightMargin: CGFloat = 16
    private static var attributes: [NSAttributedString.Key: Any] = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = minTextLineHeight
        style.maximumLineHeight = 0
        let baselineOffset = (minTextLineHeight - 18) / textBaselineOffsetFactor
        return [.font: UIFont.systemFont(ofSize: defaultFontSize),
                .foregroundColor: UIColor.ud.textTitle,
                .paragraphStyle: style,
                .baselineOffset: baselineOffset]
    }()

    var contentLabel = LKSelectionLabel(options: [.selectionColor(UIColor.ud.primaryFillHover.withAlphaComponent(0.5)),
                                                          .cursorColor(UIColor.ud.primaryContentDefault)])
    private var menuRect: CGRect = .zero
    private var selectRange: NSRange? // 用户长按选择范围
    private var _selectedRange: NSRange? // 当前选择搜索范围

    var normalTextAttributes: [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = Self.minTextLineHeight
        style.maximumLineHeight = 0
        style.alignment = isAlignRight ? .right : .left
        let baselineOffset = (Self.minTextLineHeight - 18) / Self.textBaselineOffsetFactor
        return [.font: UIFont.systemFont(ofSize: Self.defaultFontSize),
                .foregroundColor: UIColor.ud.textTitle,
                .paragraphStyle: style,
                .baselineOffset: baselineOffset]
    }

    var contentText: NSMutableAttributedString? {
        guard let attributedText = viewModel?.translatedContent else { return nil }
        attributedText.setAttributes(normalTextAttributes,
                                     range: NSRange(0 ..< attributedText.length))
        return attributedText
    }

    var matchedRanges: [NSRange]? {
        viewModel?.ranges
    }

    var selectedRange: NSRange? {
        get {
            _selectedRange
        }
        set {
            _selectedRange = newValue
            updateContent()
        }
    }

    var isAlignRight: Bool = false

    override func setup() {
        super.setup()
        menuAnchorView = contentLabel

        contentLabel.font = .systemFont(ofSize: Self.defaultFontSize)
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.backgroundColor = .clear
        contentLabel.lineBreakMode = .byWordWrapping
        contentLabel.numberOfLines = 0
        contentLabel.setContentHuggingPriority(.required, for: .horizontal)
        contentLabel.setContentHuggingPriority(.required, for: .vertical)
        contentLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        contentLabel.selectionDelegate = self

        self.contentView.addSubview(contentLabel)

        NotificationCenter.default.rx.notification(UIMenuController.didHideMenuNotification)
            .subscribe(onNext: { [weak self] (_) in
                if let label = self?.contentLabel, label.inSelectionMode {
                    label.inSelectionMode = false
                }
            }).disposed(by: rx.disposeBag)
    }

    static func getCellHeight(with vm: SubtitleViewData, width: CGFloat) -> CGFloat {
        var attributedText = vm.translatedContent
        var lineOffset: CGFloat = 0
        if vm.identifier == SubtitleHistoryBehaviorCell.description() {
            let title = vm.behaviorDescText ?? ""
            attributedText = NSMutableAttributedString(string: "(\(title))")
        }
        if vm.identifier == SubtitleHistoryDocCell.description() {
            let title = vm.behaviorDocLinkTitle ?? ""
            let behaviorText = vm.behaviorDescText ?? ""
            attributedText = NSMutableAttributedString(string: "(\(behaviorText)  \(title))")
            lineOffset = 4
        }
        attributedText.setAttributes(attributes,
                                     range: NSRange(0 ..< attributedText.length))
        let maxWidth = width - Self.contentLeftMargin - Self.contentRightMargin
        let layout = LKTextLayoutEngineImpl()
        layout.attributedText = attributedText
        layout.preferMaxWidth = maxWidth
        _ = layout.layout(size: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        let textHeight = layout.textSize.height + lineOffset
        return textHeight
    }

    override func updateViewModel(vm: SubtitleViewData) -> CGFloat {
        _ = super.updateViewModel(vm: vm)
        updateContent()
        vm.updateWordEnd()

        guard let viewModel = self.viewModel, self.containerWidth > 0 else { return 0 }
        if viewModel.needMerge == false {
        // 正常显示
            avatarImageView.isHidden = false
            titleLabel.isHidden = false
            timeLabel.isHidden = false
        } else {
            avatarImageView.isHidden = true
            titleLabel.isHidden = true
            timeLabel.isHidden = true
        }
        let offsetY: CGFloat = viewModel.needMerge ? 4 : 30
        let width: CGFloat = containerWidth - Self.contentLeftMargin - Self.contentRightMargin
        contentLabel.preferredMaxLayoutWidth = width
        contentLabel.frame = CGRect(x: Self.contentLeftMargin, y: offsetY, width: width, height: cellHeight)
        return 0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.isHidden = false
        timeLabel.isHidden = false
        avatarImageView.isHidden = false
        avatarImageView.setAvatarInfo(.asset(nil))
    }

    private func updateContent() {
        guard let attributedText = contentText,
              let ranges = matchedRanges else {
            contentLabel.attributedText = nil
            return
        }

        for range in ranges where range.location + range.length <= attributedText.length {
            // 设置命中的背景色
            // bug: LKLabel在iOS12上第一个字符的.backgroundColor显示不出来，LKBackgroundColorAttributeName可以显示
            let color = UIColor.ud.sunflower
            attributedText.addAttributes([LKBackgroundColorAttributeName: color, .backgroundColor: color], range: range)
        }

        if let range = selectedRange, ranges.contains(range),
            range.location + range.length <= attributedText.length {
            //设置选中的背景色
            let color = UIColor.ud.Y350
            attributedText.addAttributes([LKBackgroundColorAttributeName: color, .backgroundColor: color], range: range)
        }
        contentLabel.attributedText = attributedText
    }

    override func showMenu() {
        super.showMenu()
        contentLabel.inSelectionMode = true
        if let attributedText = contentLabel.attributedText {
            let range = NSRange(0 ..< attributedText.length)
            contentLabel.initSelectedRange = range
            self.selectRange = range
        }
    }

    override func copy(_ sender: Any?) {
        if let r = self.selectRange, let text = contentLabel.text, let range = Range(r, in: text) {
            self.service?.security.copy(String(text[range]), token: .subtitlePageCopySubtitle)
        }
        SubtitleTracksV2.trackCopySubtitle()
        Toast.show(I18n.View_G_CopiedSuccessfully)
        contentLabel.inSelectionMode = false
    }

    func selectionDragModeUpdate(_ inDragMode: Bool) {
    }

    func selectionRangeDidUpdate(_ range: NSRange) {
        let start = contentLabel.startCursor.rect
        let end = contentLabel.endCursor.rect
        guard start.height > 0 && end.height > 0 else {
            return
        }

        self.selectRange = range
        let menu = UIMenuController.shared
        let x: CGFloat
        let width: CGFloat
        if start.origin.y == end.origin.y {
            x = min(start.origin.x, end.origin.x)
            width = abs(start.origin.x - end.origin.x)
        } else {
            x = 0
            width = contentLabel.frame.width
        }
        let y = start.origin.y
        let height = (end.origin.y + end.size.height - y)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        if !self.menuRect.equalTo(rect) {
            self.menuRect = rect
            menu.setTargetRect(rect, in: contentLabel)
        }
    }

    func selectionRangeDidSelected(_ range: NSRange, didSelectedAttrString: NSAttributedString,
                                   didSelectedRenderAttributedString: NSAttributedString) {
    }
}
