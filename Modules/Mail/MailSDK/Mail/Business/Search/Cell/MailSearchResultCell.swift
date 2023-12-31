//
//  MailSearchResultCell.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/8.
//

import UIKit
import LarkUIKit
import LarkTag
import ThreadSafeDataStructure
import UniverseDesignTheme
import UniverseDesignIcon
import UniverseDesignTag

protocol MailSearchLongPressDelegate: AnyObject {
    func cellLongPress(reconizer: MailLongPressGestureRecognizer)
}

protocol MailSearchResultCellDelegate: AnyObject {
    func didClickFlag(_ cell: MailSearchResultCell, cellModel: MailSearchResultCellViewModel)
}

class MailSearchResultCell: UITableViewCell, MailSearchTableViewCellProtocol, MailThreadAppearance {
    var vm: MailSearchCellViewModel? {
        return viewModel
    }

    private(set) var viewModel: MailSearchResultCellViewModel?
    var threadAppearanceRef: ThreadSafeDataStructure.SafeAtomic<MailThreadAppearanceRef> = MailThreadAppearanceRef() + .readWriteLock

    var longPressGesture: MailLongPressGestureRecognizer?
    weak var longPressDelegate: MailSearchLongPressDelegate?
    weak var delegate: MailSearchResultCellDelegate?
    var selectedIndexPath: IndexPath = IndexPath(row: 0, section: 0) {
        didSet {
            longPressGesture?.selectedIndexPath = selectedIndexPath
        }
    }
    var enableLongPress: Bool = false {
        didSet {
            updateLongPress()
        }
    }
    var lastingColorView: UIView?
    /// 单选状态下用作背景色 View
    private let bgView = UIView(frame: .zero)
    private var tagWidth: CGFloat = 0.0

    var rootSizeClassIsRegular: Bool = false
    var isMultiSelecting: Bool = false

    // MARK: left Circle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(bgView)

        let bgView = LastingColorView()
        bgView.lastingColor = UIColor.ud.bgBody
        self.selectedBackgroundView = bgView
//        self.selectedBackgroundView = makeLastingColorView()
//        lastingColorView = makeLastingColorView()
        // lastingColorView?.isHidden = true
        // self.insertSubview(lastingColorView!, belowSubview: contentView)
//        contentView.addSubview(lastingColorView!)
//        self.swipeTriggeredBackGroundColor = UIColor.ud.colorfulWathet

        setupUI()
        self.flagButton.addTarget(self, action: #selector(didClickFlagButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI () {
        configUI(container: contentView, displaysAsynchronously: false)
        attachmentIcon.isHidden = true
    }

    static func cellHeight(viewModel: MailSearchCellViewModel) -> CGFloat {
        return MailHomeControllerConst.CellHeight
    }

    func updateLongPress() {
        if !enableLongPress {
            return
        }
        longPressGesture = makeLongPressGesture()
        if let longPressGesture = longPressGesture {
            self.addGestureRecognizer(longPressGesture)
        }
    }

    func makeLongPressGesture() -> MailLongPressGestureRecognizer {
        let longPressGesture = MailLongPressGestureRecognizer.init(target: self, action: #selector(MailThreadListCell.enterMultiSelect(_:)))
        return longPressGesture
    }

    @objc
    func enterMultiSelect(_ sender: MailLongPressGestureRecognizer) {
        longPressDelegate?.cellLongPress(reconizer: sender)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let longPressGesture = longPressGesture {
            removeGestureRecognizer(longPressGesture)
        }
        longPressGesture = nil
    }

    func set(viewModel: MailSearchCellViewModel, searchText: String?) {
        self.viewModel = viewModel as? MailSearchResultCellViewModel
        guard let vm = self.viewModel else {
            return
        }
        configureNameLabel(vm)
        configureTimeLabel(vm)
        configureConv(vm)
        configureTitleLabel(vm)
        configureDescLabel(vm)
        configureAttachment(vm)
        configurePriority(vm)
        configureLabels(vm)
        // configExternal(vm)
        configFlagButton(vm)
    }

    @objc
    func didClickFlagButton() {
        if let viewModel = self.viewModel {
            flagButton.isSelected = !flagButton.isSelected
            delegate?.didClickFlag(self, cellModel: viewModel)
        }
    }

    func configFlagButton(_ viewModel: MailSearchResultCellViewModel) {
        flagButton.isSelected = viewModel.isFlagged
        if viewModel.isFlagged {
            if rootSizeClassIsRegular {
                flagButton.setImage(Resources.mail_cell_icon_flag_selected, for: .normal)
            } else {
                flagButton.setImage(UDIcon.flagFilled.withRenderingMode(.alwaysTemplate), for: .normal)
                flagButton.tintColor = UIColor.ud.colorfulRed
            }
        } else {
            flagButton.setImage(UDIcon.flagOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
            flagButton.tintColor = UIColor.ud.iconN3
        }

        func hideFlagButton() -> Bool {
            if viewModel.currentLabelID == Mail_LabelId_SEARCH_TRASH_AND_SPAM {
                return true
            }
            return false
        }

        if hideFlagButton() {
            flagButton.isHidden = true
            descContainer.snp.updateConstraints { (make) in
                make.right.lessThanOrEqualToSuperview().offset(-16)
            }
            tagWrapperView.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-18).priority(.medium)
            }
        } else {
            flagButton.isHidden = false
            descContainer.snp.updateConstraints { (make) in
                make.right.lessThanOrEqualToSuperview().offset(-36)
            }
            tagWrapperView.snp.updateConstraints { (make) in
                make.right.equalToSuperview().offset(-42).priority(.medium)
            }
        }
    }

    func configureNameLabel(_ viewModel: MailSearchResultCellViewModel) {
        var color = UIColor.ud.textTitle
        if #available(iOS 13.0, *) {
            color = UDThemeManager.getRealUserInterfaceStyle() == .light ? UIColor.ud.textTitle.alwaysLight : UIColor.ud.textTitle.alwaysDark
        }
//        nameLabel.truncationToken = NSMutableAttributedString(string: "...",
//                                                              attributes: [.font: nameLabel.font ?? UIFont.systemFont(ofSize: 17),
//                                                                           .foregroundColor: color])
//        nameLabel.lineBreakMode = .byTruncatingTail
//        nameLabel.numberOfLines = 1
//        self.nameLabel.text = viewModel.from
//        let font = UIFont.systemFont(ofSize: 17)
//        if !viewModel.isRead {
//            self.nameLabel.font = font
//            self.nameLabel.snp.updateConstraints { (make) in
//                make.left.equalTo(32)
//            }
//        } else {
//            self.nameLabel.font = font
//            self.nameLabel.snp.updateConstraints { (make) in
//                make.left.equalTo(16)
//            }
//        }
        var font = UIFont.systemFont(ofSize: 17)
        if !viewModel.isRead {
            font = UIFont.boldSystemFont(ofSize: 17)
        }
        // 是否出现未读红点
        self.unreadIcon.isHidden = viewModel.isRead
        // 已回复/转发标记
        if FeatureManager.open(.repliedMark, openInMailClient: true) {
            self.replyTag.isHidden = (viewModel.replyTagType == .notReply)
            if viewModel.replyTagType == .reply {
                self.replyTag.image = UDIcon.replyFilled.withRenderingMode(.alwaysTemplate)
            } else if viewModel.replyTagType == .forward {
                self.replyTag.image = UDIcon.forwardFilled.withRenderingMode(.alwaysTemplate)
            }
        } else {
            replyTag.isHidden = true
        }
        draftLabel.isHidden = !viewModel.hasDraft
        draftLabel.font = font
        if viewModel.hasDraft {
            draftLabel.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: draftLabel.text?.getWidth(font: draftLabel.font) ?? 43, height: 22))
            }
            nameLabel.snp.updateConstraints { make in
                make.left.equalTo(draftLabel.snp.right).offset(4)
            }
        } else {
            draftLabel.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: 0, height: 22))
            }
            nameLabel.snp.updateConstraints { make in
                make.left.equalTo(draftLabel.snp.right)
            }
        }
        let attrValue: (UIFont, UIColor) = (font, color)
        self.nameLabel.attributedText = SearchHelper.AttributeText
            .searchHighlightAttributeText(attributedString: NSAttributedString(string: viewModel.from),
                                          keywords: viewModel.highlightString,
                                          highlightColor: UIColor.ud.primaryContentDefault,
                                          attr: attrValue)
    }

    final func configureTimeLabel(_ viewModel: MailSearchResultCellViewModel) {
        self.timeLabel.text = ProviderManager.default.timeFormatProvider?.relativeDate(viewModel.lastMessageTimestamp / 1000, showTime: false)
        self.timeLabel.font = UIFont.systemFont(ofSize: 12)
    }

    func configureConv(_ viewModel: MailSearchResultCellViewModel) {
        var convWidth = 16
        var count = ""
        if viewModel.msgNum < 100 {
            count = String(viewModel.msgNum)
        } else {
            count = "..."
            convWidth = 20
        }
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let text = NSAttributedString(
            string: count,
            attributes: [
                .font: convLabel.font.copy(),
                .foregroundColor: UIColor.ud.udtokenTagNeutralTextNormal.copy(),
                .paragraphStyle: style
            ]
        )
        convLabel.attributedText = text
        if viewModel.msgNum > 1 {
            self.convLabel.isHidden = false
            if viewModel.msgNum < 10 {
            } else if viewModel.msgNum < 100 {
                convWidth = 20
            } else {
                convWidth = 24
            }
        } else {
            convWidth = 0
            self.convLabel.isHidden = true
        }
        convLabel.snp.updateConstraints { (make) in
            make.width.equalTo(convWidth)
        }
    }

    func configureTitleLabel(_ viewModel: MailSearchResultCellViewModel) {
        // 这里还要补一个 逻辑
        if let folder = MailTagDataManager.shared.getFolderModel(viewModel.folders),
           !folder.name.isEmpty {
            self.folderTag.isHidden = false
            var name = ""
            if folder.id != Mail_LabelId_SHARED,
                let text = folder.id.menuResource.text {
                name = text
            } else {
                name = folder.name
            }
            if name.utf16.count > 7 {
                name = name.prefix(6) + "..."
            }
            folderTag.text = name
            tagWidth = name.getTextWidth(font: .systemFont(ofSize: 12, weight: .medium), height: 20) + 6
            folderTag.snp.updateConstraints { make in
                make.width.equalTo(tagWidth).priority(.medium)
            }
            titleLabel.snp.updateConstraints { make in
                make.left.equalTo(MailThreadCellConstants.titleLeftPadding + tagWidth + 6)
            }
        } else {
            folderTag.isHidden = true
            tagWidth = 0.0
        }
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        let title = viewModel.subject.isEmpty ? BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty : viewModel.subject
        var color = UIColor.ud.textTitle
        if #available(iOS 13.0, *) {
            color = UDThemeManager.getRealUserInterfaceStyle() == .light ? UIColor.ud.textTitle.alwaysLight : UIColor.ud.textTitle.alwaysDark
        }
        let attrValue: (UIFont, UIColor) = (viewModel.isRead ? UIFont.systemFont(ofSize: 14) : UIFont.boldSystemFont(ofSize: 14), color)
        self.titleLabel.attributedText = SearchHelper.AttributeText.searchHighlightAttributeText(attributedString: NSAttributedString(string: title),
                                                                                                 keywords: viewModel.highlightString + viewModel.highlightSubject,
                                                                                                highlightColor: UIColor.ud.primaryContentDefault,
                                                                                                attr: attrValue)
    }

    func configureDescLabel(_ viewModel: MailSearchResultCellViewModel) {
        let str = viewModel.msgSummary.replacingOccurrences(of: "\n", with: "")
        let attrValue: (UIFont, UIColor) = (UIFont.systemFont(ofSize: 14), UIColor.ud.textPlaceholder)
        self.descLabel.attributedText = SearchHelper.AttributeText.searchHighlightAttributeText(attributedString: NSAttributedString(string: str),
                                                                                                keywords: viewModel.highlightString,
                                                                                                highlightColor: UIColor.ud.primaryContentDefault,
                                                                                                attr: attrValue)
    }

    func configureAttachment(_ viewModel: MailSearchResultCellViewModel) {
        if viewModel.hasAttachment {
            attachmentIcon.isHidden = false
        } else {
            attachmentIcon.isHidden = true
        }
    }

    func configurePriority(_ viewModel: MailSearchResultCellViewModel) {
        guard FeatureManager.open(.mailPriority, openInMailClient: true) else {
            priorityIcon.isHidden = true
            return
        }
        if viewModel.priorityType == .high {
            priorityIcon.image = MailPriorityType.high.toIcon().ud.withTintColor(.ud.functionDangerContentDefault)
            priorityIcon.isHidden = false
        } else if viewModel.priorityType == .low {
            priorityIcon.image = MailPriorityType.low.toIcon().ud.withTintColor(.ud.iconN3)
            priorityIcon.isHidden = false
        } else {
            priorityIcon.isHidden = true
        }
    }

    //
    func configureLabels(_ viewModel: MailSearchResultCellViewModel) {
        func cleanTagWrapper() {
            // clean lark mail label
            tagWrapperView.clean()
            tagWrapperView.snp.updateConstraints { (make) in
                make.width.lessThanOrEqualTo(0).priority(.required)
            }
            tagWrapperView.setNeedsLayout()
            tagWrapperView.layoutIfNeeded()
        }

        func textWidth(_ text: String, font: UIFont) -> CGFloat {
            let textWidth = (text as NSString).size(withAttributes: [NSAttributedString.Key.font: font]).width
            return textWidth
        }
        /// 无标签，则清空标签视图
        let mailsLabels = viewModel.labels.filter({ !$0.isSystem })
        guard !mailsLabels.isEmpty else {
            tagWrapperView.isHidden = true
            cleanTagWrapper()
            return
        }
        tagWrapperView.isHidden = false
        var tagLabels: [CustomTagElement] = []
        var index = 0
        // show lark tags
        for label in mailsLabels {
            let fontColor = UIColor.mail.argb(label.displayFontColor)
            let bgColor = UIColor.mail.argb(label.displayBgColor)
            /// 邮件协作fg关闭时，不显示 share label
            /// 标签超过剩余显示宽度，则以 ... 作为尾部标签
            if index > 2, label.id != Mail_LabelId_SHARED {
                tagLabels.append(CommonCustomTagView.createTagView(text: "...", fontColor: UIColor.ud.udtokenTagNeutralTextNormal,
                                                                   bgColor: UIColor.ud.udtokenTagNeutralBgNormal, omitTag: true))
                break
            } else {
                tagLabels.append(CommonCustomTagView.createTagView(text: label.displayName, fontColor: fontColor, bgColor: bgColor))
            }
            index += 1
        }
        tagWrapperView.maxTagCount = tagLabels.count
        tagWrapperView.setElements(tagLabels)
        let maxWidth = floor(max(self.contentView.frame.width - 74, 0))
        tagWrapperView.snp.updateConstraints { (make) in
            make.width.lessThanOrEqualTo(maxWidth).priority(.required)
        }
        tagWrapperView.setNeedsLayout()
        tagWrapperView.layoutIfNeeded()
    }
}

extension MailSearchResultCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        unreadIcon.backgroundColor = UIColor.ud.functionInfoContentDefault

        if !isMultiSelecting {
            normalLayoutSubviews()
        } else {
            editingLayoutSubViews()
        }
        updateLayouts(edit: isMultiSelecting)
    }

    private func normalLayoutSubviews() {
        var targetBgColor = caculateBackgroundColor()
        if isSelected {
            targetBgColor = UIColor.ud.fillHover
        }
        selectedBackgroundView?.backgroundColor = .clear
        selectedBackgroundView?.isHidden = true
        lastingColorView?.isHidden = true
        lastingColorView?.backgroundColor = targetBgColor
        backgroundColor = targetBgColor
        // 有透明度问题
        updateColor(isHighlighted || isSelected ? UIColor.clear : targetBgColor)
        backgroundView?.isHidden = isHighlighted || isSelected
        multiSelecteView.isHidden = true
    }

    private func editingLayoutSubViews() {
        lastingColorView?.isHidden = true
        selectedBackgroundView?.isHidden = true

        var targetBgColor = caculateBackgroundColor()
        if isHighlighted {
            targetBgColor = caculateBackgroundColor(ignoreHighlight: true)
        }
        backgroundColor = targetBgColor
        updateColor(isHighlighted || isSelected ? UIColor.clear : targetBgColor)

        multiSelecteView.isSelected = isSelected
        multiSelecteView.frame = CGRect(x: 0, y: 0, width: 48, height: self.bounds.height)
        multiSelecteView.isHidden = false
    }

    private func updateLayouts(edit: Bool) {
        let leftPadding = MailThreadCellConstants.titleLeftPadding
        let largeLeftPadding = MailThreadCellConstants.largeTitleLeftPadding
        if !edit {
            nameContainer.snp.updateConstraints { make in
                make.left.equalTo(leftPadding)
            }
            folderTag.snp.updateConstraints { make in
                make.left.equalTo(leftPadding)
            }
            if tagWidth != 0.0 {
                titleLabel.snp.updateConstraints { make in
                    make.left.equalTo(leftPadding + tagWidth + 6)
                }
            } else {
                titleLabel.snp.updateConstraints { make in
                    make.left.equalTo(leftPadding)
                }
            }
            if let cellViewModel = viewModel {
                unreadIcon.isHidden = cellViewModel.isRead
            }
            replyTag.snp.updateConstraints { make in
                make.left.equalTo(10)
            }
        } else {
            nameContainer.snp.updateConstraints { make in
                make.left.equalTo(largeLeftPadding)
            }
            folderTag.snp.updateConstraints { make in
                make.left.equalTo(largeLeftPadding)
            }
            if tagWidth != 0.0 {
                titleLabel.snp.updateConstraints { make in
                    make.left.equalTo(largeLeftPadding + tagWidth + 6)
                }
            } else {
                titleLabel.snp.updateConstraints { make in
                    make.left.equalTo(largeLeftPadding)
                }
            }
            unreadIcon.isHidden = true
            replyTag.snp.updateConstraints { make in
                make.left.equalTo(20)
            }
        }
    }

    private func updateColor(_ bgColor: UIColor?) {
        nameLabel.backgroundColor = bgColor
        timeLabel.backgroundColor = bgColor
        titleLabel.backgroundColor = bgColor
        descLabel.backgroundColor = bgColor
        attachmentIcon.backgroundColor = bgColor
    }

    func caculateBackgroundColor(ignoreHighlight: Bool = false) -> UIColor {
        var targetBgColor = UIColor.clear
        if !ignoreHighlight && isHighlighted {
            targetBgColor = UIColor.ud.fillHover
        } else if Display.pad {
            targetBgColor = UIColor.ud.bgBody
        } else {
            targetBgColor = UIColor.ud.bgBody
        }
        return targetBgColor
    }
}
