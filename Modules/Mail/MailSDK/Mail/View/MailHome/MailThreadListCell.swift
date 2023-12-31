//
//  MailThreadListCell.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/5/17.
//

import UIKit
import LarkUIKit
import LarkTag
import RustPB
import RxSwift
import LarkExtensions
import ThreadSafeDataStructure
import YYText
import LarkSwipeCellKit
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

protocol MailThreadListCellDelegate: AnyObject {
    func didClickFlag(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel)
}

@objc protocol MailLongPressDelegate: AnyObject {
    func cellLongPress(reconizer: MailLongPressGestureRecognizer, view: UIView)
}

// MARK: - ThreadListCell
class MailThreadListCell: SwipeTableViewCell, MailThreadAppearance {

    let timeLabelFont = UIFont.systemFont(ofSize: 12)
    let nameFontSize: CGFloat = 17
    let nameLabelLeftMargin = 16
    weak var mailDelegate: MailThreadListCellDelegate?
    let disposeBag = DisposeBag()
    var longPressGesture: MailLongPressGestureRecognizer?
    weak var longPressDelegate: MailLongPressDelegate?
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

    var rootSizeClassIsRegular: Bool = false

    var cellType: MailInboxType = .inbox {
        didSet {
            if cellType == .archived {
//                self.swipeEnabled = false
            }
        }
    }

    var cellViewModel: MailThreadListCellViewModel? {
        didSet {
            if let cellViewModel = cellViewModel {
                self.configureThreadListCell(cellViewModel)
            }
        }
    }

    var threadAppearanceRef: ThreadSafeDataStructure.SafeAtomic<MailThreadAppearanceRef> = MailThreadAppearanceRef() + .readWriteLock

    var isUnread: Bool = true
    var animator: Any?

    var displaysAsynchronously: Bool = false
    var clearContentsBeforeAsynchronouslyDisplay: Bool = true

    var isMultiSelecting: Bool = false {
        didSet {
            displaysAsynchronously = !isMultiSelecting
            clearContentsBeforeAsynchronouslyDisplay = !isMultiSelecting
        }
    }
    // MARK: life Circle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configUI(container: self.swipeView, displaysAsynchronously: displaysAsynchronously)
        self.selectionStyle = .none
        self.flagButton.addTarget(self, action: #selector(didClickFlagButton), for: .touchUpInside)
        // nameLabel截断适配暗黑模式
        var trucationTokenDark = NSMutableAttributedString(string: "...", attributes: [.font: nameLabel.font ?? UIFont.systemFont(ofSize: nameFontSize),
                                                                                  .foregroundColor: UIColor.ud.textTitle.alwaysDark])
        var trucationTokenlight = NSMutableAttributedString(string: "...", attributes: [.font: nameLabel.font ?? UIFont.systemFont(ofSize: nameFontSize),
                                                                                  .foregroundColor: UIColor.ud.textTitle.alwaysLight])

        if let label = nameLabel as? YYLabel {
            label.ud.setValue(forKeyPath: \.truncationToken,
                        dynamicProvider: UDDynamicProvider(trucationTokenlight, trucationTokenDark))
        }
        // 需要先layout一次, 下面name label计算文本长度时需要用
        layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setNeedsLayout()
//        layoutIfNeeded()
    }

    func setUnread(_ unread: Bool, animated: Bool) {
        if isMultiSelecting {
            return
        }
        let closure = {
            self.configureUnreadIcon(unread)
            self.titleLabel.font = unread ? UIFont.systemFont(ofSize: 14, weight: .semibold) : UIFont.systemFont(ofSize: 14)
            if unread {
                self.nameLabel.font = UIFont.systemFont(ofSize: self.nameFontSize, weight: .semibold)
                self.draftLabel.font = UIFont.systemFont(ofSize: self.nameFontSize, weight: .semibold)
            } else {
                self.nameLabel.font = UIFont.systemFont(ofSize: self.nameFontSize)
                self.draftLabel.font = UIFont.systemFont(ofSize: self.nameFontSize)
            }
        }

        if #available(iOS 10, *), animated {
            var localAnimator = self.animator as? UIViewPropertyAnimator
            localAnimator?.stopAnimation(true)

            localAnimator = unread ? UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.4) : UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1.0)
            localAnimator?.addAnimations(closure)
            localAnimator?.startAnimation()

            self.animator = localAnimator

        } else {
            closure()
        }
    }

    private func updateLayouts(edit: Bool) {
        let isOutbox = cellViewModel?.currentLabelID == Mail_LabelId_Outbox && FeatureManager.open(.newOutbox)
        let padding = edit || isOutbox ? MailThreadCellConstants.largeTitleLeftPadding : MailThreadCellConstants.titleLeftPadding
        [nameContainer, titleLabel, folderTag, bottomLine].forEach {
            $0.snp.updateConstraints { make in
                make.left.equalTo(padding)
            }
        }

        if !edit, let cellViewModel = cellViewModel {
            configureUnreadIcon(cellViewModel.isUnread)
        } else {
            unreadIcon.isHidden = true
        }
        // 编辑状态下需要更新一下已回复/转发标记的布局
        replyTag.snp.updateConstraints { (make) in
            make.left.equalTo(edit ? 20 : 10)
        }
    }

    private func normalLayoutSubviews() {
        var targetBgColor = caculateBackgroundColor()
        if isSelected {
            targetBgColor = UIColor.ud.fillHover
        }
        if rootSizeClassIsRegular {
            selectedBgView.isHidden = !(isHighlighted || isSelected)
            bottomLine.isHidden = isHighlighted || isSelected
        } else {
            selectedBgView.isHidden = true
            bottomLine.isHidden = false
        }
        swipeView.backgroundColor = (isSelected || isSelected) ? UIColor.clear : targetBgColor
        // 有透明度问题
        updateColor(isHighlighted || isSelected ? UIColor.clear : swipeView.backgroundColor)
        backgroundView?.isHidden = isHighlighted || isSelected
        multiSelecteView.isHidden = true
    }

    private func editingLayoutSubViews() {
        var targetBgColor = caculateBackgroundColor()
        if isHighlighted {
            targetBgColor = caculateBackgroundColor(ignoreHighlight: true)
        }

        swipeView.backgroundColor = (isSelected || isSelected) ? UIColor.clear : targetBgColor
        updateColor(swipeView.backgroundColor)
        if rootSizeClassIsRegular {
            selectedBgView.isHidden = true
            bottomLine.isHidden = isHighlighted || isSelected
        }

        multiSelecteView.isSelected = isSelected
        multiSelecteView.frame = CGRect(x: 0, y: 0, width: 48, height: self.bounds.height)
        multiSelecteView.isHidden = false
        // externalLabel.backgroundColor = UIColor.ud.R100
        /// 编辑状态/布局变化后，需要重新设置下 labels
        if let cellViewModel = cellViewModel {
            configLabels(cellViewModel)
        }
    }

    private func updateColor(_ bgColor: UIColor?) {
        nameLabel.backgroundColor = bgColor
        timeLabel.backgroundColor = bgColor
        titleLabel.backgroundColor = bgColor
        descLabel.backgroundColor = bgColor
        attachmentIcon.backgroundColor = bgColor
        priorityIcon.backgroundColor = bgColor
    }

    // MARK: config
    private func configureThreadListCell(_ mailThread: MailThreadListCellViewModel) {
        isUnread = mailThread.isUnread
        configureUnreadIcon(mailThread.isUnread)
        configureReplyTag(mailThread)
        // namelabel的展示文本依赖于timeLabel的展示文本，不要改变顺序。
        configureTimeLabel(mailThread)
        configureNameLabel(mailThread, timeLabel.mailText ?? "")
        configureConv(mailThread)
        configureTitleLabel(mailThread)
        configureDescLabel(mailThread)
        configLabels(mailThread)
        configFlagButton(mailThread)

        /// status icons
        configureAttachment(mailThread)
        configurePriority(mailThread)
        configScheduleInfo(mailThread)
        configShareIcon(mailThread)
        // configExternal(isExternal: mailThread.isExternal) //先注释 避免后面加回来

        configureForOutbox(mailThread)
    }

    func configLabels(_ mailThread: MailThreadListCellViewModel) {
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
        guard let mailsLabels = mailThread.displayLabels, !mailsLabels.isEmpty else {
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
                tagLabels.append(CommonCustomTagView.createTagView(text: "···", fontColor: UIColor.ud.udtokenTagNeutralTextNormal,
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

    func configureUnreadIcon(_ isUnread: Bool) {
        unreadIcon.isHidden = !isUnread
        if !isMultiSelecting {
            swipeView.backgroundColor = caculateBackgroundColor()
        }
        let nameFontSize = nameFontSize
        var leftMargin = nameLabelLeftMargin
        if isUnread {
            if UDFontAppearance.isCustomFont {
                nameLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .semibold)
                draftLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .semibold)
            } else {
                nameLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .bold)
                draftLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .bold)
            }
        } else {
            nameLabel.font = UIFont.systemFont(ofSize: nameFontSize)
            draftLabel.font = UIFont.systemFont(ofSize: nameFontSize)
        }
        if UDFontAppearance.isCustomFont {
            titleLabel.font = isUnread ? UIFont.systemFont(ofSize: 14, weight: .semibold) : UIFont.systemFont(ofSize: 14)
        } else {
            titleLabel.font = isUnread ? UIFont.systemFont(ofSize: 14, weight: .bold) : UIFont.systemFont(ofSize: 14)
        }
    }

    func configureReplyTag(_ mailThead: MailThreadListCellViewModel) {
        guard FeatureManager.open(.repliedMark, openInMailClient: true) else {
            replyTag.isHidden = true
            return
        }
        replyTag.isHidden = (mailThead.replyTagType == .notReply)
        if mailThead.replyTagType == .reply {
            replyTag.image = UDIcon.replyFilled.withRenderingMode(.alwaysTemplate)
        } else if mailThead.replyTagType == .forward {
            replyTag.image = UDIcon.forwardFilled.withRenderingMode(.alwaysTemplate)
        }
    }

    func configureNameLabel(_ mailThread: MailThreadListCellViewModel, _ time: String) {
        nameLabel.displaysAsynchronously = displaysAsynchronously
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.numberOfLines = 1
        nameLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay // 这样渲染的内容会滞后得有点可怕
        let nameFontSize = nameFontSize
        setNameLabelText(mailThread, time)
        var leftMargin = nameLabelLeftMargin
        if mailThread.isUnread {
            if UDFontAppearance.isCustomFont {
                nameLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .semibold)
                draftLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .semibold)
            } else {
                nameLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .bold)
                draftLabel.font = UIFont.systemFont(ofSize: nameFontSize, weight: .bold)
            }
        } else {
            nameLabel.font = UIFont.systemFont(ofSize: nameFontSize)
            draftLabel.font = UIFont.systemFont(ofSize: nameFontSize)
        }
        nameLabel.backgroundColor = swipeView.backgroundColor
//        let attr = NSMutableAttributedString(string: nameLabel.text ?? "")
//        attr.addAttributes([.font: nameLabel.font, .foregroundColor: nameLabel.textColor], range: NSRange(location: 0, length: attr.length))
//        let size = attr.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
//                                     options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
//        let yyContainer = YYTextContainer(size: size)
//        nameLabel.textLayout = YYTextLayout(container: yyContainer, text: attr)
    }

    func setNameLabelText(_ mailThread: MailThreadListCellViewModel, _ time: String) {
        // 展示逻辑文档旧(发件箱) https://bytedance.feishu.cn/space/doc/doccnYv0KpjJV3kJ1CtcMSIbsoa
        // 展示逻辑文档新(收件箱) https://bytedance.feishu.cn/docs/doccnkXx9PC7d7JXdZUOd4DAjMc#bEXOE4
        var margin = mailThread.hasAttachment ? MailThreadCellConstants.titleIconWidth + MailThreadCellConstants.titleIconSpace : 0
        margin += mailThread.scheduleSendMessageCount > 0 ? MailThreadCellConstants.titleIconWidth + MailThreadCellConstants.titleIconSpace : 0
        let fontWeight: UIFont.Weight = UDFontAppearance.isCustomFont ? .semibold : .bold
        let nameFont = mailThread.isUnread ? UIFont.systemFont(ofSize: nameFontSize, weight: fontWeight) : UIFont.systemFont(ofSize: nameFontSize)
        nameLabel.setText(mailThread.getDisplayName(time, self.contentView.bounds.width - margin,
                                                    inDraftLabel: cellViewModel?.currentLabelID == Mail_LabelId_Draft,
                                                    nameFont: nameFont) ?? BundleI18n.MailSDK.Mail_ThreadList_NoName)
    }

    final func configureTimeLabel(_ mailThread: MailThreadListCellViewModel) {
        timeLabel.displaysAsynchronously = displaysAsynchronously
        timeLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        timeLabel.font = timeLabelFont
        timeLabel.backgroundColor = swipeView.backgroundColor
        timeLabel.mailText = getTimeLabelText(time: mailThread.lastmessageTime)

        /// shared 内不显示时间
        timeLabel.isHidden = mailThread.currentLabelID == Mail_LabelId_SHARED
    }

    func getTimeLabelText(time: Int64) -> String {
        return ProviderManager.default.timeFormatProvider?.relativeDate(time / 1000, showTime: false) ?? ""
    }

    func configureConv(_ mailThread: MailThreadListCellViewModel) {
        convLabel.displaysAsynchronously = displaysAsynchronously
        convLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        var convWidth = 16
        var count = ""
        if mailThread.convCount < 100 {
            count = String(mailThread.convCount)
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
        if mailThread.convCount > 1 {
            convLabel.isHidden = false
            if mailThread.convCount < 10 {

            } else if mailThread.convCount < 100 {
                convWidth = 20
            } else {
                convWidth = 24
            }
        } else {
            convWidth = 0
            convLabel.isHidden = true
        }
        convLabel.snp.updateConstraints { (make) in
            make.width.equalTo(convWidth)
        }
    }

    func configureTitleLabel(_ mailThread: MailThreadListCellViewModel) {
        titleLabel.displaysAsynchronously = displaysAsynchronously
        titleLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        let fontWeight: UIFont.Weight = UDFontAppearance.isCustomFont ? .semibold : .bold
        titleLabel.font = mailThread.isUnread ? UIFont.systemFont(ofSize: 14, weight: fontWeight) : UIFont.systemFont(ofSize: 14)
        titleLabel.truncationToken = NSMutableAttributedString(string: "...",
                                                               attributes: [.font: titleLabel.font ?? UIFont.systemFont(ofSize: 14),
                                                                            .foregroundColor: titleLabel.textColor ?? UIColor.ud.textTitle])
//        titleLabel.updateMailText(mailThread.title)
        titleLabel.setText(mailThread.title)
        titleLabel.backgroundColor = swipeView.backgroundColor
    }

    func configureDescLabel(_ mailThread: MailThreadListCellViewModel) {
        descLabel.displaysAsynchronously = displaysAsynchronously
        descLabel.backgroundColor = swipeView.backgroundColor
        descLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        if let draft = mailThread.draft {
            draftLabel.isHidden = false
            draftLabel.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: draftLabel.text?.getWidth(font: draftLabel.font) ?? 43, height: 22))
            }
            nameLabel.snp.updateConstraints { make in
                make.left.equalTo(draftLabel.snp.right).offset(4)
            }
            descLabel.setText(draft.getDesc())
//            descLabel.updateMailText(textColor: UIColor.ud.textPlaceholder,
//                                     String(draft.prefix(100))
//                                        .components(separatedBy: .controlCharacters).joined(separator: " "))
        } else {
            draftLabel.isHidden = true
            draftLabel.snp.updateConstraints { make in
                make.size.equalTo(CGSize(width: 0, height: 22))
            }
            nameLabel.snp.updateConstraints { make in
                make.left.equalTo(draftLabel.snp.right)
            }
            descLabel.setText(mailThread.desc.getDesc())
        }
    }

    func configureForOutbox(_ mailThread: MailThreadListCellViewModel) {
        let isOutbox = FeatureManager.open(.newOutbox) && mailThread.currentLabelID == Mail_LabelId_Outbox
        leadingIconView.isHidden = !isOutbox
        if isOutbox {
            let isSendFailed = cellViewModel?.deliveryState == .sendError
            leadingIconView.image = (isSendFailed ? UDIcon.warningOutlined : UDIcon.sentOutlined).withRenderingMode(.alwaysTemplate)
            leadingIconView.tintColor = isSendFailed ? .ud.functionDangerContentDefault : .ud.primaryContentDefault
        }
    }

    func configureAttachment(_ mailThread: MailThreadListCellViewModel) {
        attachmentIcon.backgroundColor = swipeView.backgroundColor
        attachmentIcon.isHidden = !mailThread.hasAttachment
    }

    func configurePriority(_ mailThread: MailThreadListCellViewModel) {
        guard FeatureManager.open(.mailPriority, openInMailClient: false) else {
            priorityIcon.isHidden = true
            return
        }
        if mailThread.priorityType == .high {
            priorityIcon.backgroundColor = swipeView.backgroundColor
            priorityIcon.image = MailPriorityType.high.toIcon().ud.withTintColor(.ud.functionDangerContentDefault)
            priorityIcon.isHidden = false
        } else if mailThread.priorityType == .low {
            priorityIcon.backgroundColor = swipeView.backgroundColor
            priorityIcon.image = MailPriorityType.low.toIcon().ud.withTintColor(.ud.iconN3)
            priorityIcon.isHidden = false
        } else {
            priorityIcon.isHidden = true
        }
    }

    func configShareIcon(_ mailThread: MailThreadListCellViewModel) {
        hiddenShareIcon(true)
    }

    func hiddenShareIcon(_ hidden: Bool) {
        shareIcon.isHidden = hidden
    }

    func configScheduleInfo(_ mailThread: MailThreadListCellViewModel) {

        let scheduleCount = mailThread.scheduleSendMessageCount
        let currentLabelID = mailThread.currentLabelID

        if scheduleCount > 0 {
            if currentLabelID == Mail_LabelId_Scheduled {
                hiddenScheduleTime(false)
                hiddenScheduleIcon(true)
                scheduleTimeLabel.font = timeLabelFont
//                scheduleTimeLabel.updateMailText(textColor: UIColor.ud.primaryContentDefault,
//                                                 getTimeLabelText(time: mailThread.scheduleSendTimestamp))
                scheduleTimeLabel.mailText = getTimeLabelText(time: mailThread.scheduleSendTimestamp)
            } else {
                hiddenScheduleTime(true)
                hiddenScheduleIcon(false)
            }
        } else {
            hiddenScheduleIcon(true)
            hiddenScheduleTime(true)
        }
    }

    func hiddenScheduleTime(_ hidden: Bool) {
        scheduleTimeIcon.isHidden = hidden
        scheduleTimeLabel.isHidden = hidden
        timeLabel.isHidden = !hidden
    }

    func hiddenScheduleIcon(_ hidden: Bool) {
        scheduleIcon.isHidden = hidden
    }

    func configFlagButton(_ mailThread: MailThreadListCellViewModel) {
        flagButton.backgroundColor = .clear
        flagButton.isSelected = mailThread.isFlagged
        if mailThread.isFlagged {
            if rootSizeClassIsRegular {
                flagButton.setImage(Resources.mail_cell_icon_flag_selected, for: .normal)
                flagButton.tintColor = UIColor.ud.colorfulRed
            } else {
                flagButton.setImage(UDIcon.flagFilled.withRenderingMode(.alwaysTemplate), for: .normal)
                flagButton.tintColor = UIColor.ud.colorfulRed
            }
        } else {
            flagButton.setImage(UDIcon.flagOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
            flagButton.tintColor = UIColor.ud.iconN3
        }
        func hideFlagButton() -> Bool {
            if mailThread.currentLabelID == Mail_LabelId_Trash
                || mailThread.currentLabelID == Mail_LabelId_Spam
                || mailThread.currentLabelID == Mail_LabelId_SHARED
                || mailThread.currentLabelID == Mail_LabelId_Outbox
                || mailThread.permissionCode == .view
                || mailThread.permissionCode == .edit {
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

    @objc
    func didClickFlagButton() {
        if let viewModel = cellViewModel {
            flagButton.isSelected = !flagButton.isSelected
            mailDelegate?.didClickFlag(self, cellModel: viewModel)
        }
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
        longPressDelegate?.cellLongPress(reconizer: sender, view: self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let longPressGesture = longPressGesture {
            removeGestureRecognizer(longPressGesture)
        }
        longPressGesture = nil
    }
}

// MARK: muti select
extension MailThreadListCell {

}

// extension MailThreadListCell {
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        super.traitCollectionDidChange(previousTraitCollection)
//        scheduleTimeLabel.textColor = UIColor.ud.primaryContentDefault
//        nameLabel.textColor = UIColor.ud.textTitle
//        descLabel.textColor = UIColor.ud.textPlaceholder
//        timeLabel.textColor = UIColor.ud.textPlaceholder
//    }
// }

extension String {
    func getDesc() -> String {
        return String(self.prefix(100)).components(separatedBy: .controlCharacters).joined(separator: " ")
    }
}

// MARK: helper
extension MailThreadListCell {
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
