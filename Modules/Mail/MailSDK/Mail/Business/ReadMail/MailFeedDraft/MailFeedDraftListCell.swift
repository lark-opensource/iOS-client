//
//  MailFeedDraftListCell.swift
//  MailSDK
//
//  Created by ByteDance on 2023/11/7.
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

protocol MailFeedDraftListCellDelegate: AnyObject {
    func didClickFlag(_ cell: MailFeedDraftListCell, cellModel: MailFeedDraftListCellViewModel)
}

// MARK: - ThreadListCell
class MailFeedDraftListCell: SwipeTableViewCell, MailThreadAppearance {
    
    let timeLabelFont = UIFont.systemFont(ofSize: 12)
    let nameFontSize: CGFloat = 17
    let nameLabelLeftMargin = 16
    var rootViewWidth = Display.width
    weak var mailDelegate: MailFeedDraftListCellDelegate?
    let disposeBag = DisposeBag()
    var rootSizeClassIsRegular: Bool = false
    var cellViewModel: MailFeedDraftListCellViewModel? {
        didSet {
            if let cellViewModel = cellViewModel {
                self.configureFeedDraftListCell(cellViewModel)
            }
        }
    }
    var threadAppearanceRef: ThreadSafeDataStructure.SafeAtomic<MailThreadAppearanceRef> = MailThreadAppearanceRef() + .readWriteLock
    var animator: Any?
    var displaysAsynchronously: Bool = false
    var clearContentsBeforeAsynchronouslyDisplay: Bool = true
    lazy var bgView = UIView()
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
        convLabel.isHidden = true
        
        self.frame.size.width = rootViewWidth - mailFeedDraftListViewConst.CellPadding
        
        self.contentView.frame.size.width = rootViewWidth - mailFeedDraftListViewConst.CellPadding
        self.contentView.frame.origin = CGPoint(x: 16, y: 0)
        // 需要先layout一次, 下面name label计算文本长度时需要用
        layoutIfNeeded()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        normalLayoutSubviews()
        self.frame.size.width = rootViewWidth - mailFeedDraftListViewConst.CellPadding
        // 调整内容视图的边距
        
        self.contentView.frame.size.width = rootViewWidth - mailFeedDraftListViewConst.CellPadding
        self.contentView.frame.origin = CGPoint(x: 16, y: 0)
        
    }
    
    private func normalLayoutSubviews() {
        self.backgroundColor = .clear
        bottomLine.isHidden = true
        selectedBgView.isHidden = true
        swipeView.backgroundColor = isHighlighted || isSelected ? UIColor.ud.fillPressed : UIColor.ud.bgBody
        self.contentView.backgroundColor = isHighlighted || isSelected ? UIColor.ud.bgBody : .clear
        // 有透明度问题
        updateColor(UIColor.clear)
        multiSelecteView.isHidden = true
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
    private func configureFeedDraftListCell(_ mailDraft: MailFeedDraftListCellViewModel) {
        // namelabel的展示文本依赖于timeLabel的展示文本，不要改变顺序。
        configureTimeLabel(mailDraft)
        configureNameLabel(mailDraft, timeLabel.mailText ?? "")
        configureTitleLabel(mailDraft)
        configureDescLabel(mailDraft)
        configFlagButton(mailDraft)
        configLabels(mailDraft)
        /// status icons
        configureAttachment(mailDraft)
        configurePriority(mailDraft)
        nameContainer.snp.updateConstraints { make in
            make.left.equalTo(mailFeedDraftListViewConst.titleLeftPadding)
        }
        descContainer.snp.remakeConstraints { (make) in
            make.left.equalTo(mailFeedDraftListViewConst.titleLeftPadding)
            make.top.equalTo(titleLabel.snp.bottom).offset(4).priority(.medium)
            make.right.lessThanOrEqualToSuperview().offset(-36)
            make.height.equalTo(20)
        }
        unreadIcon.isHidden = true
        bottomLine.isHidden = true
    }

    func configLabels(_ mailDraft: MailFeedDraftListCellViewModel) {
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
        guard let mailsLabels = mailDraft.displayLabels, !mailsLabels.isEmpty else {
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

    func configureNameLabel(_ mailDraft: MailFeedDraftListCellViewModel, _ time: String) {
        nameLabel.displaysAsynchronously = displaysAsynchronously
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.numberOfLines = 1
        nameLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay // 这样渲染的内容会滞后得有点可怕
        let nameFontSize = nameFontSize
        setNameLabelText(mailDraft, time)
        var leftMargin = nameLabelLeftMargin
        nameLabel.font = UIFont.systemFont(ofSize: nameFontSize)
        draftLabel.font = UIFont.systemFont(ofSize: nameFontSize)
        nameLabel.backgroundColor = UIColor.clear
    }

    func setNameLabelText(_ mailDraft: MailFeedDraftListCellViewModel, _ time: String) {
        // 展示逻辑文档旧(发件箱) https://bytedance.feishu.cn/space/doc/doccnYv0KpjJV3kJ1CtcMSIbsoa
        // 展示逻辑文档新(收件箱) https://bytedance.feishu.cn/docs/doccnkXx9PC7d7JXdZUOd4DAjMc#bEXOE4
        var margin = mailDraft.hasAttachment ? MailThreadCellConstants.titleIconWidth + MailThreadCellConstants.titleIconSpace : 0
        let nameFont =  UIFont.systemFont(ofSize: nameFontSize)
        nameLabel.setText(mailDraft.getDisplayName(time, self.contentView.bounds.width - margin, nameFont: nameFont) ?? BundleI18n.MailSDK.Mail_ThreadList_NoName)
    }

    final func configureTimeLabel(_ mailDraft: MailFeedDraftListCellViewModel) {
        timeLabel.displaysAsynchronously = displaysAsynchronously
        timeLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        timeLabel.font = timeLabelFont
        timeLabel.backgroundColor = UIColor.clear
        timeLabel.mailText = getTimeLabelText(time: mailDraft.lastmessageTime)
    }

    func getTimeLabelText(time: Int64) -> String {
        return ProviderManager.default.timeFormatProvider?.relativeDate(time / 1000, showTime: false) ?? ""
    }

    func configureTitleLabel(_ mailDraft: MailFeedDraftListCellViewModel) {
        titleLabel.displaysAsynchronously = displaysAsynchronously
        titleLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        titleLabel.font =  UIFont.systemFont(ofSize: 14)
        titleLabel.truncationToken = NSMutableAttributedString(string: "...",
                                                               attributes: [.font: titleLabel.font ?? UIFont.systemFont(ofSize: 14),
                                                                            .foregroundColor: titleLabel.textColor ?? UIColor.ud.textTitle])
        titleLabel.setText(mailDraft.title)
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(mailFeedDraftListViewConst.titleLeftPadding)
            make.right.equalToSuperview().offset(-16).priority(.medium)
            make.top.equalTo(nameContainer.snp.bottom).offset(4).priority(.medium)
            make.height.equalTo(20)
        }
    }

    func configureDescLabel(_ mailDraft: MailFeedDraftListCellViewModel) {
        descLabel.displaysAsynchronously = displaysAsynchronously
        descLabel.backgroundColor = UIColor.clear
        descLabel.clearContentsBeforeAsynchronouslyDisplay = clearContentsBeforeAsynchronouslyDisplay
        
        draftLabel.isHidden = false
        draftLabel.snp.updateConstraints { make in
            make.size.equalTo(CGSize(width: draftLabel.text?.getWidth(font: draftLabel.font) ?? 43, height: 22))
        }
        nameLabel.snp.updateConstraints { make in
            make.left.equalTo(draftLabel.snp.right).offset(4)
        }
        descLabel.setText(mailDraft.desc.getDesc())
    }

    func configureAttachment(_ mailDraft: MailFeedDraftListCellViewModel) {
        attachmentIcon.backgroundColor = UIColor.clear
        attachmentIcon.isHidden = !mailDraft.hasAttachment
    }

    func configurePriority(_ mailDraft: MailFeedDraftListCellViewModel) {
        guard FeatureManager.open(.mailPriority, openInMailClient: false) else {
            priorityIcon.isHidden = true
            return
        }
        if mailDraft.priorityType == .high {
            priorityIcon.backgroundColor = UIColor.clear
            priorityIcon.image = MailPriorityType.high.toIcon().ud.withTintColor(.ud.functionDangerContentDefault)
            priorityIcon.isHidden = false
        } else if mailDraft.priorityType == .low {
            priorityIcon.backgroundColor = UIColor.clear
            priorityIcon.image = MailPriorityType.low.toIcon().ud.withTintColor(.ud.iconN3)
            priorityIcon.isHidden = false
        } else {
            priorityIcon.isHidden = true
        }
    }

    func configFlagButton(_ mailDraft: MailFeedDraftListCellViewModel) {
        flagButton.backgroundColor = .clear
        flagButton.isSelected = mailDraft.isFlagged
        if mailDraft.isFlagged {
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
        flagButton.isHidden = false
        descContainer.snp.updateConstraints { (make) in
            make.right.lessThanOrEqualToSuperview().offset(-36)
        }
        tagWrapperView.snp.updateConstraints { (make) in
            make.right.equalToSuperview().offset(-42).priority(.medium)
        }
    }

    @objc
    func didClickFlagButton() {
        if let viewModel = cellViewModel {
            flagButton.isSelected = !flagButton.isSelected
            mailDelegate?.didClickFlag(self, cellModel: viewModel)
        }
    }
}


// MARK: - 空状态
class MailFeedDraftListEmptyCell: UITableViewCell {
    enum EmptyCellStatus {
        case canRetry
        case noNet
        case none
    }

    var centerYOffset: CGFloat = 0.0 {
        didSet {
            container.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.centerY.equalToSuperview().offset(-centerYOffset)
            }
        }
    }

    var isUnreadEmpty: Bool = false {
        didSet {
            self.actionButton.isHidden = canRetry || !isUnreadEmpty
        }
    }
    var isStrangerEmpty: Bool = false {
        didSet {
            guard status == .none else {
                titleLabel.isHidden = false
                emptyIcon.isHidden = false
                return
            }
            titleLabel.isHidden = isStrangerEmpty
            emptyIcon.isHidden = isStrangerEmpty
        }
    }
    var canRetry: Bool = false {
        didSet {
            emptyIcon.image = canRetry ? Resources.feed_error_icon : Resources.feed_empty_data_icon
            titleLabel.text = BundleI18n.MailSDK.Mail_Common_NetworkError // "网络错误 请点击重试"
            titleLabel.sizeToFit()
            self.actionButton.isHidden = true
        }
    }
    var status: EmptyCellStatus = .none {
        didSet {
            switch status {
            case .canRetry:
                emptyIcon.image = Resources.feed_error_icon
                titleLabel.text = BundleI18n.MailSDK.Mail_Common_NetworkError
            case .noNet:
                emptyIcon.image = Resources.feed_error_icon
                titleLabel.text = BundleI18n.MailSDK.Mail_ThreadList_NoNetwork
            case .none:
                emptyIcon.image = Resources.feed_empty_data_icon
            }
            titleLabel.sizeToFit()
        }
    }
    var type = "" {
        didSet {
            guard !isUnreadEmpty else {
                titleLabel.text = BundleI18n.MailSDK.Mail_ThreadList_ReadAllTip(type)
                return
            }
            titleLabel.text = BundleI18n.MailSDK.Mail_List_Empty(type)
            titleLabel.sizeToFit()
        }
    }
    fileprivate lazy var container = UIView()
    fileprivate lazy var titleLabel = self.makeTitleLabel()
    fileprivate lazy var emptyIcon = self.makeEmptyIcon()
    fileprivate lazy var actionButton = self.makeActionButton()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    func setup() {
        // container
        addSubview(container)
        container.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview().offset(-centerYOffset)
        }
        [titleLabel, emptyIcon, actionButton].forEach {
            container.addSubview($0)
        }

        self.backgroundColor = UIColor.clear
        emptyIcon.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(emptyIcon.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.centerX.equalToSuperview()
        }
        titleLabel.sizeToFit()
        actionButton.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        selectedBackgroundView = UIView()
    }

    // MARK: - Make
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.MailSDK.Mail_List_Empty(type)
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        return label
    }

    private func makeEmptyIcon() -> UIImageView {
        let imageview = UIImageView()
        imageview.image = Resources.feed_empty_data_icon
        return imageview
    }

    private func makeActionButton() -> UILabel {
        let label = UILabel()
        label.text = BundleI18n.MailSDK.Mail_Label_ClearFilter
        label.textColor = UIColor.ud.primaryContentDefault
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }
}
