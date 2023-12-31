//
//  MinutesSubtitleCell.swift
//  Minutes
//
//  Created by yangyao on 2021/1/12.
//

import UIKit
import YYText
import UniverseDesignColor
import Kingfisher
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignEmpty
import LarkEMM
import SnapKit

import LarkContainer
import LarkAccountInterface

class MinutesSubtitleCell: UITableViewCell {
    struct LayoutContext {
        // 控件左间距
        static let leftMargin: CGFloat = 48
        // 控件右间距
        static let rightMargin: CGFloat = 26
        // 控件上间距
        static let topMargin: CGFloat = 10
        // 控件下间距，上移了yyTextViewTopInset
        static let bottomMargin: CGFloat = 20 - yyTextViewTopInset
        // 控件间竖间距
        static let verticalOffset: CGFloat = 8
        // 控件间横间距
        static let horizontalOffset: CGFloat = 8

        static let yyTextFont: UIFont = UIFont.systemFont(ofSize: 16)

        static let yyTextTopMargin: CGFloat = 35
        // YYTextView 控件顶部间距，上移了yyTextViewTopInset
        static let yyTextViewTopMargin = yyTextTopMargin - yyTextViewTopInset

        // YYTextView inset
        // 1. 使多选的小圆圈能够完整显示
        // 2. 搜索关键字刚好在边缘，避免border被截
        static let yyTextViewLeftInset: CGFloat = 5
        static let yyTextViewTopInset: CGFloat = 5

        // YYTextView 控件左间距，左移了yyTextViewLeftInset
        static let yyTextViewLeftMargin = leftMargin - yyTextViewLeftInset

        static let yyTextLineHeight: CGFloat = 28
        static let specifiedTop: CGFloat = 24

        // 头像大小
        static let imageSize: CGFloat = 24
        static let subscriptImageSize: CGFloat = 14
        static let textBorderWidth: CGFloat = 1.5
    }

    // YYTextView 内容宽度，即文字绘制的宽度
    var yyTextWidth: CGFloat = 0
    // YYTextView 控件宽度，由于内容往中间缩进，因此宽度加上inset
    var yyTextViewWidth: CGFloat = 0

    var viewModel: MinutesParagraphViewModel?
    // start time, stop time, 点击区域在window的位置, 高亮的区域
    var didTextTappedBlock: (((String?, String?, CGPoint?, CGRect?, Phrase?)?) -> Void)?
    var commentsViewArrs: [UIView] = []

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = LayoutContext.imageSize / 2
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(tappedAvatar(_:)))
        tap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tap)
        return imageView
    }()

    private lazy var avatarSubscriptView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.layer.masksToBounds = true
        imageView.layer.borderColor = UIColor.ud.staticWhite.cgColor
        imageView.layer.borderWidth = 1.0
        imageView.layer.cornerRadius = LayoutContext.subscriptImageSize/2.0
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(tappedAvatar(_:)))
        tap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tap)
        return imageView
    }()

    let avatarBackView = UIView()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.isUserInteractionEnabled = true
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var commentsCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9, weight: .medium)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .center
        return label
    }()

    private lazy var commentsCountView: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(tappedComments), for: .touchUpInside)
        button.setBackgroundImage(UIImage.dynamicIcon(.iconReplyCnFilled, dimension: 20, color: UIColor.ud.colorfulYellow), for: .normal)
        button.addSubview(commentsCountLabel)
        commentsCountLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(-1)
        }
        return button
    }()

    private lazy var titleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill

        let container = UIView()
        stack.addArrangedSubview(container)

        container.addSubview(nameLabel)
        container.addSubview(editSpeakerView)
        container.addSubview(timeLabel)

        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        editSpeakerView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(6)
            make.centerY.equalTo(nameLabel)
            make.height.equalTo(14)
            make.right.lessThanOrEqualToSuperview()
        }
        return stack
    }()

    func setEditSpeakerHidden(_ isHidden: Bool) {
        editSpeakerView.isHidden = isHidden
        if isHidden {
            timeLabel.snp.remakeConstraints { make in
                make.left.equalTo(nameLabel.snp.right).offset(6)
                make.centerY.equalTo(nameLabel)
                make.height.equalTo(14)
                make.top.bottom.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        } else {
            timeLabel.snp.remakeConstraints { make in
                make.left.equalTo(editSpeakerView.snp.right).offset(6)
                make.centerY.equalTo(nameLabel)
                make.height.equalTo(14)
                make.top.bottom.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        }
    }

    private lazy var topStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center

        stack.addArrangedSubview(avatarBackView)
        avatarBackView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutContext.imageSize)
        }
        avatarBackView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        avatarBackView.addSubview(avatarSubscriptView)
        avatarSubscriptView.snp.makeConstraints { make in
            make.width.height.equalTo(LayoutContext.subscriptImageSize)
            make.right.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(2)
        }
        avatarSubscriptView.isHidden = true
        stack.setCustomSpacing(8, after: avatarBackView)
        stack.addArrangedSubview(titleStack)
        stack.addArrangedSubview(commentsCountView)
        commentsCountView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        return stack
    }()

    private lazy var editSpeakerView: EditSpeakerView = {
        let ev = EditSpeakerView()
        ev.isHidden = true
        ev.editButton.addTarget(self, action: #selector(editSpeakerAction), for: .touchUpInside)
        return ev
    }()

    lazy var contentTextView: YYTextView = {
        let textView = YYTextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.allowSelectionDot = false
        textView.allowShowMagnifierCaret = false
        textView.textContainerInset = UIEdgeInsets(top: LayoutContext.yyTextViewTopInset,
                                                   left: LayoutContext.yyTextViewLeftInset,
                                                   bottom: LayoutContext.yyTextViewTopInset,
                                                   right: LayoutContext.yyTextViewLeftInset)
        textView.allowsCopyAttributedString = false
        textView.customMenu = normalMenu()

        textView.textTapEndAction = { [weak self] (containerView, text, range, rect) in
            let result = self?.viewModel?.foundWordRanges(with: range)
            self?.result = result

            let filter = self?.viewModel?.dPhrases.first(where: {$0.range.intersection(range) != nil })
            self?.didTextTappedBlock?((result?.0, result?.1, nil, nil, filter))
        }
        return textView
    }()

    private lazy var highlightedBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.cornerRadius = 6
        border.fillColor = UIColor.ud.colorfulBlue
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
        border.fillColor = UIColor.ud.Y350
        border.strokeColor = UIColor.ud.P500
        border.strokeWidth = LayoutContext.textBorderWidth
        border.insets = searchBorder.insets
        return border
    }()

    private lazy var commentsBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.cornerRadius = 6
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.Y200
        border.bottomLineStrokeWidth = 2.0
        border.insets = highlightedBorder.insets
        return border
    }()

    private lazy var ccmCommentsBorder: YYTextBorder = {
        let border = YYTextBorder(fill: .clear, cornerRadius: 6)
        border.cornerRadius = 6
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.Y100
        border.bottomLineStrokeWidth = 2.0
        border.bottomLineType = YYTextBottomLineType(rawValue: 0)
        border.insets = highlightedBorder.insets
        return border
    }()

    private lazy var highlightedCommentsBorder: YYTextBorder = {
        let border = YYTextBorder(fill: UIColor.ud.Y100, cornerRadius: 6)
        border.cornerRadius = 6
        border.fillColor = UIColor.ud.Y100
        border.bottomLineStrokeColor = UIColor.ud.Y350
        border.bottomLineStrokeWidth = 2.0
        border.insets = highlightedBorder.insets
        return border
    }()

    private lazy var dictBorder: YYTextBorder = {
        let border = YYTextBorder()
        border.cornerRadius = 6
        border.fillColor = .clear
        border.bottomLineStrokeColor = UIColor.ud.N400
        border.bottomLineStrokeWidth = 1.0
        border.bottomLineType = .dottedLine
        return border
    }()

    var result: (String, String)?
    var yyTextViewHeight: CGFloat = 0.0
    var menuCommentsBlock: ((String, NSRange) -> Void)?
    var menuOriginalBlock: ((NSInteger) -> Void)?
    var showCommentsBlock: ((Bool) -> Void)?
    var didTappedComment: ((Bool, String?) -> Void)?

    var copySuccessBlock: (() -> Void)?
    var openProfileBlock: ((MinutesParagraphViewModel?) -> Void)?
    var editSpeakerBlock: ((Paragraph) -> Void)?

    var isSpeakerEditing: Bool = false {
        didSet {
            if isSpeakerEditing {
                setEditSpeakerHidden(false)
                nameLabel.isHidden = true
                if let iconType = viewModel?.paragraph.speaker?.iconType, iconType == 1 {
                    avatarSubscriptView.isHidden = true
                }
            } else {
                setEditSpeakerHidden(true)
                avatarBackView.isHidden = !isShowName
                nameLabel.isHidden = !isShowName
                timeLabel.isHidden = false
                if viewModel?.isClip == true {
                    commentsCountView.isHidden = true
                } else {
                    commentsCountView.isHidden = !((viewModel?.commentsCount ?? 0) > 0)
                }
                if viewModel?.isInCCMfg == true {
                    commentsCountView.isHidden = true
                }
                if let iconType = viewModel?.paragraph.speaker?.iconType, iconType == 1 {
                    avatarSubscriptView.isHidden = false
                }
                if !isShowName {
                    avatarSubscriptView.isHidden = true
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(topStack)
        topStack.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-26)
            make.top.equalToSuperview()
            make.height.equalTo(36)
        }
        contentView.addSubview(contentTextView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private var isShowName = true

    @objc func tappedAvatar(_ sender: UITapGestureRecognizer) {
        openProfileBlock?(viewModel)
    }

    @objc func tappedComments() {
        showCommentsBlock?(viewModel?.couldComment ?? false)
    }

    @objc func menuCopy(_ menu: UIMenuController) {
        if let text = contentTextView.copiedString() as? String {
            Device.pasteboard(token: DeviceToken.pasteboardSubtitle, text: text)
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

    @objc func editSpeakerAction() {
        if let p = viewModel?.paragraph {
            editSpeakerBlock?(p)
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

    func hideMenu() {
        contentTextView.customMenu?.setMenuVisible(false, animated: true)
    }

    func hideSelectionDot() {
        contentTextView.hideSelectionDot()
    }

    // 合并区间，eg: {3, 1}, {3, 3}, {4, 2}, {6, 2} 合并成 {3, 5}
    private func findUnion(_ dataSource: [NSRange]?) -> [NSRange] {
        guard let dataSource = dataSource else {
            return []
        }
        var newRanges: [NSRange] = []
        for range in dataSource {
            let left = range.location
            let right = range.location + range.length
            if var last = newRanges.last {
                if last.location + last.length < left {
                    newRanges.append(range)
                } else {
                    last.length = max(last.location + last.length, right) - last.location
                    newRanges[newRanges.count - 1] = last
                }
            } else {
                newRanges.append(range)
            }
        }
        return newRanges
    }

    func highlightRanges() {
        guard let viewModel = viewModel else { return }
        contentTextView.removeMySelectionRects()

        let newHighlightedRanges: [NSRange] = findUnion(viewModel.highlightedRanges)
        let newSearchRanges: [NSRange] = findUnion(viewModel.searchRanges)
        let newCommentsRanges: [NSRange] = findUnion(viewModel.commentsRanges)

        let mutableText = viewModel.attributedText.mutableCopy() as? NSMutableAttributedString
        // normal
        newHighlightedRanges.forEach { (range) in
            contentTextView.setMySelectionRects(highlightedBorder, range: range, lineSeperate: false)
            if !hasIntersection(range: range, newSearchRanges: newSearchRanges, newCommentsRanges: newCommentsRanges, viewModel: viewModel) {
                mutableText?.addAttributes([.foregroundColor: UIColor.ud.primaryOnPrimaryFill], range: range)
            }
        }
        contentTextView.attributedText = mutableText

        if viewModel.isClip {
            handleDict()
            return
        }
        let border = viewModel.isInCCMfg ? ccmCommentsBorder : commentsBorder
        // comment
        newCommentsRanges.forEach { (range) in
            contentTextView.setMySelectionRects(border, range: range)
        }
        if let highlightedCommentsRange = viewModel.highlightedCommentsRange {
            contentTextView.setMySelectionRects(highlightedCommentsBorder, range: highlightedCommentsRange)
        }
        if let selectedRange = viewModel.selectedRange {
            contentTextView.setMySelectionRects(highlightedCommentsBorder, range: selectedRange)
        }

        // search
        newSearchRanges.forEach { (range) in
            contentTextView.setMySelectionRects(searchBorder, range: range)
        }
        if let specifiedRange = viewModel.specifiedRange {
            contentTextView.setMySelectionRects(specifiedBorder, range: specifiedRange)
        }

        handleDict()
    }

    func handleDict() {
        guard let viewModel = viewModel else { return }
        if !viewModel.isInTranslationMode {
            viewModel.dPhrases.forEach { (phrase) in
                self.contentTextView.setMySelectionRects(self.dictBorder, range: phrase.range)
            }
        }
    }

    func hasIntersection(range: NSRange, newSearchRanges: [NSRange], newCommentsRanges: [NSRange], viewModel: MinutesParagraphViewModel) -> Bool {
        for item in newSearchRanges {
            if let tmp = range.intersection(item) {
                return true
            }
        }
        guard let highlightedCommentsRange = viewModel.highlightedCommentsRange else {
            return false
        }
        for item in newCommentsRanges {
            if let tmp = range.intersection(item) {
                return true
            }
        }
        return false
    }

    func configure(_ viewModel: MinutesParagraphViewModel, tag: NSInteger, showName: Bool = true, isClip: Bool) {
        isShowName = showName
        self.viewModel = viewModel

        self.yyTextWidth = viewModel.textWidth

        self.yyTextViewWidth = yyTextWidth

        avatarImageView.setAvatarImage(with: viewModel.avatarUrl, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))
        if let iconType = viewModel.paragraph.speaker?.iconType {
            if iconType == 1 {
                //1, can edit
                avatarSubscriptView.isHidden = false
                avatarSubscriptView.image = BundleResources.Minutes.minutes_speaker_canedit
            } else if iconType == 2 {
                //2. ai confirm
                avatarSubscriptView.isHidden = false
                avatarSubscriptView.setAvatarImage(with: viewModel.roomUrl, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: LayoutContext.subscriptImageSize, color: UIColor.ud.N300))
            } else {
                //no type
                if viewModel.roomUrl.absoluteString.isEmpty == false, !viewModel.roomUrl.isFileURL {
                    avatarSubscriptView.isHidden = false
                    avatarSubscriptView.setAvatarImage(with: viewModel.roomUrl, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: LayoutContext.subscriptImageSize, color: UIColor.ud.N300))
                } else {
                    avatarSubscriptView.isHidden = true
                }
            }
        } else {
            avatarSubscriptView.isHidden = true
        }
        nameLabel.text = viewModel.name
        timeLabel.text = viewModel.time
        commentsCountLabel.text = "\(viewModel.commentsCount)"

        avatarBackView.isHidden = !showName
        nameLabel.isHidden = (!showName || isSpeakerEditing)

        commentsCountLabel.sizeToFit()
        if !viewModel.isClip {
            commentsCountView.isHidden = !(viewModel.commentsCount > 0)
        } else {
            commentsCountView.isHidden = true
        }
        if viewModel.isInCCMfg {
            commentsCountView.isHidden = true
        }

        contentTextView.selectionViewBackgroundColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.15)
        if isClip {
            contentTextView.allowLongPressSelection = viewModel.isInTranslationMode
        } else {
            contentTextView.allowLongPressSelection = true
        }
        contentTextView.allowLongPressSelectionAlwaysAll = viewModel.isInTranslationMode

        calculateTextHeight()
        // YYText内部依赖，先设置size，否则layout会是nil
        contentTextView.frame = CGRect(x: LayoutContext.yyTextViewLeftMargin,
                                       y: LayoutContext.yyTextViewTopMargin,
                                       width: self.yyTextViewWidth,
                                       height: yyTextViewHeight)
        contentTextView.tag = tag
        contentTextView.attributedText = viewModel.attributedText
        highlightRanges()

        if viewModel.isInTranslationMode {
            contentTextView.customMenu = translateMenu()
        } else {
            contentTextView.customMenu = normalMenu()
        }

        editSpeakerView.config(with: viewModel)
        if viewModel.isInCCMfg {
            configCommentView()
        }
    }

    func calculateCommentsHeight(_ line: Int) -> CGFloat {
        return 0
    }

    class CommentButton: UIButton {
        var commentId: String?
    }

    func configCommentView() {
        commentsViewArrs.forEach { $0.removeFromSuperview() }
        commentsViewArrs.removeAll()

        guard let vm = viewModel else { return }

        for kv in vm.lineCommentsCount {
            let line = kv.key
            let count = kv.value

            var countValue: String = "\(count)"

            let label = UILabel()
            label.font = .systemFont(ofSize: 9, weight: .medium)
            label.textColor = UIColor.ud.primaryOnPrimaryFill
            label.textAlignment = .center
            label.text = countValue
            let button: CommentButton = CommentButton(type: .custom, padding: 10)
            button.commentId = viewModel?.lineCommentsId[line]?.first?.0
            button.addTarget(self, action: #selector(onTappedComment(_:)), for: .touchUpInside)
            button.setBackgroundImage(UIImage.dynamicIcon(.iconReplyCnFilled, dimension: 20, color: UIColor.ud.colorfulYellow), for: .normal)
            button.addSubview(label)

            label.snp.remakeConstraints { (maker) in
                maker.centerX.equalToSuperview()
                maker.centerY.equalToSuperview().offset(-1)
            }
            contentView.addSubview(button)

            let textHeight: CGFloat = viewModel?.lineHeight[line]?.origin.y ?? 0.0

            let offsetY: CGFloat = LayoutContext.yyTextViewTopMargin + textHeight
            button.snp.remakeConstraints { (maker) in
                maker.width.height.equalTo(18)
                maker.right.equalToSuperview().offset(-5)
                maker.top.equalToSuperview().offset(offsetY)
            }
            button.isHidden = countValue == "0"

            commentsViewArrs.append(button)
        }
    }

    @objc func onTappedComment(_ sender: CommentButton) {
        let commentId = sender.commentId
        let shouldShow = viewModel?.couldComment ?? false
        didTappedComment?(shouldShow, commentId)
    }

    func translateMenu() -> UIMenuController {
        var menuItems: [UIMenuItem] = []
        if viewModel?.isClip == false {
            menuItems.append(UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:))))
        }
        menuItems.append(UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_SeeOriginal, action: #selector(menuSeeOrigin(_:))))

        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    func normalMenu() -> UIMenuController {
        var menuItems: [UIMenuItem] = []

        if viewModel?.isClip == false {
            menuItems.append(UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy, action: #selector(menuCopy(_:))))
        }

        if viewModel?.couldComment == true {
            menuItems.append(UIMenuItem(title: BundleI18n.Minutes.MMWeb_G_Comment, action: #selector(menuComments(_:))))
        }

        let menuController = UIMenuController.shared
        menuController.menuItems = menuItems
        return menuController
    }

    func calculateTextHeight() {
        yyTextViewHeight = viewModel?.yyTextViewHeight ?? 0.0
    }

    func highlightedRect() -> CGRect {
        viewModel?.updateHighlightedRect()
        let rect = viewModel?.highlightedRect ?? CGRect.zero
        return contentTextView.convert(rect, to: superview) ?? CGRect.zero
    }
}

extension MinutesSubtitleCell {

    class EditSpeakerView: UIView {

        private lazy var nameLabel: UILabel = {
            let label = UILabel()
            label.textColor = UIColor.ud.textTitle
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//            label.setContentHuggingPriority(.required, for: .horizontal)
//            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            return label
        }()

        private lazy var editImageView: UIImageView = {
            let iv = UIImageView(image: UDIcon.getIconByKey(.editOutlined, iconColor: UIColor.ud.iconN2))
            return iv
        }()

        lazy var editButton: UIControl = {
            let ctr = UIControl()
            ctr.layer.cornerRadius = 4
            ctr.backgroundColor = UIColor.ud.fillHover

            ctr.addSubview(nameLabel)
            nameLabel.snp.makeConstraints { (maker) in
                maker.left.equalTo(4)
                maker.centerY.equalToSuperview()
            }

            ctr.addSubview(editImageView)
            editImageView.snp.makeConstraints { (maker) in
                maker.width.height.equalTo(14)
                maker.left.equalTo(nameLabel.snp.right).offset(4)
                maker.right.equalTo(-4)
                maker.centerY.equalToSuperview()
            }

            return ctr
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear

            addSubview(editButton)
            editButton.snp.makeConstraints { (maker) in
                maker.top.left.bottom.equalToSuperview()
                maker.height.equalTo(22)
                maker.right.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func config(with viewModel: MinutesParagraphViewModel) {
            nameLabel.text = viewModel.name
        }
    }
}

class MinutesSubtitleEmptyCell: UITableViewCell {
    static let viewHeight: CGFloat = 240

    private let minutesSubtitleEmptyType: UDEmptyType = .noContent

    lazy var emptyImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.image = minutesSubtitleEmptyType.defaultImage()
        return imageView
    }()

    lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.text = BundleI18n.Minutes.MMWeb_G_NoTranscript
        label.numberOfLines = 0
        return label
    }()

    // longMeetingNoContentTips: 超16小时没有文字生成
    func update(supportASR: Bool, longMeetingNoContentTips: Bool) {
        if supportASR {
            emptyLabel.text = longMeetingNoContentTips ? BundleI18n.Minutes.MMWeb_G_VideoLengthOverNoText : BundleI18n.Minutes.MMWeb_G_NoTranscript
        } else {
            emptyLabel.text = BundleI18n.Minutes.MMWeb_G_ThisLanguageNoTranscriptionNow
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(emptyImageView)
        contentView.addSubview(emptyLabel)

        layoutSubviewsManually()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviewsManually() {
        emptyImageView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(-14)
        }
        emptyLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(emptyImageView.snp.bottom).offset(8)
            maker.left.equalToSuperview().offset(10)
            maker.right.equalToSuperview().offset(-10)
        }
    }
}

class MinutesSubtitleTransformingCell: UITableViewCell {
    static let viewHeight: CGFloat = 240

    lazy var tranformingView: MinutesSubtitlesTransformingView = {
        let view = MinutesSubtitlesTransformingView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(tranformingView)
        layoutSubviewsManually()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSubviewsManually() {
        tranformingView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.centerY.equalToSuperview().offset(-30)
        }
    }
}


