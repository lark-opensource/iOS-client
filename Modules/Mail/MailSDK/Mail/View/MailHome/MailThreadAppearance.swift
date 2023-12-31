//
//  MailThreadAppearance.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/15.
//

import UIKit
import LarkTag
import LarkUIKit
import ThreadSafeDataStructure
import YYText
import UniverseDesignTag
import UniverseDesignIcon
import UniverseDesignTheme
import UniverseDesignColor

protocol MailUILabel: UIView {
    func setText(_ text: String)
    var displaysAsynchronously: Bool { get set }
    var fadeOnHighlight: Bool { get set }
    var fadeOnAsynchronouslyDisplay: Bool { get set }
    var clearContentsBeforeAsynchronouslyDisplay: Bool { get set }
    var textColor: UIColor! { get set }
    var font: UIFont! { get set }
    var lineBreakMode: NSLineBreakMode { get set }
    var numberOfLines: Int { get set }
    var attributedText: NSAttributedString? { get set }
    var truncationToken: NSAttributedString? { get set }
    var mailUILabelRef: ThreadSafeDataStructure.SafeAtomic<MailUILabelRef> { get }
}

class MailUILabelRef {
    var displaysAsynchronously: Bool = true
    var fadeOnHighlight: Bool = false
    var fadeOnAsynchronouslyDisplay: Bool = true
    var clearContentsBeforeAsynchronouslyDisplay: Bool = true
    var numberOfLines: UInt = 0
    var truncationToken: NSAttributedString?
}

extension YYLabel: MailUILabel {
    var numberOfLines: Int {
        get { return Int(mailUILabelRef.value.numberOfLines) }
        set { mailUILabelRef.value.numberOfLines = UInt(newValue) }
    }

    var mailUILabelRef: ThreadSafeDataStructure.SafeAtomic<MailUILabelRef> {
        return ThreadSafeDataStructure.SafeAtomic<MailUILabelRef>(MailUILabelRef(), with: .readWriteLock)
    }

    func setText(_ text: String) {
        self.mailText = text
    }
}

extension UILabel: MailUILabel {
    var truncationToken: NSAttributedString? {
        get { return mailUILabelRef.value.truncationToken }
        set { mailUILabelRef.value.truncationToken = newValue }
    }

    var mailUILabelRef: ThreadSafeDataStructure.SafeAtomic<MailUILabelRef> {
        return ThreadSafeDataStructure.SafeAtomic<MailUILabelRef>(MailUILabelRef(), with: .readWriteLock)
    }

    var displaysAsynchronously: Bool {
        get { return mailUILabelRef.value.displaysAsynchronously }
        set { mailUILabelRef.value.displaysAsynchronously = newValue }
    }

    var fadeOnHighlight: Bool {
        get { return mailUILabelRef.value.fadeOnHighlight }
        set { mailUILabelRef.value.fadeOnHighlight = newValue }
    }

    var fadeOnAsynchronouslyDisplay: Bool {
        get { return mailUILabelRef.value.fadeOnAsynchronouslyDisplay }
        set { mailUILabelRef.value.fadeOnAsynchronouslyDisplay = newValue }
    }

    var clearContentsBeforeAsynchronouslyDisplay: Bool {
        get { return mailUILabelRef.value.clearContentsBeforeAsynchronouslyDisplay }
        set { mailUILabelRef.value.clearContentsBeforeAsynchronouslyDisplay = newValue }
    }

    func setText(_ text: String) {
        self.mailText = text
    }
}

// 为了让tableviewcell能有首页thread的样式但是又不想走继承的方式
// 为什么这里要class？因为struct下面的extension会提示'self' is immutable，懒得加muting
/// 实现这个协议会获得首页threadlist的cell的样式，如果不想出事，请在init里面调用configUI
protocol MailThreadAppearance: AnyObject {
    var bottomLine: UIView { get set }
    var unreadIcon: UIView { get set }
    var replyTag: UIImageView { get set }
    var shareIcon: UIImageView { get set }
    var markLaterIcon: UIImageView { get set }
    var nameLabel: MailUILabel { get set }
    var convLabel: YYLabel { get set }
    var timeLabel: YYLabel { get set }
    var titleLabel: MailUILabel { get set }
    var descContainer: UIStackView { get set }
//    var descIcon: UIImageView { get set }
    var descLabel: UILabel { get set }
    var attachmentIcon: UIImageView { get set }
    var priorityIcon: UIImageView { get set }
    var threadAppearanceRef: ThreadSafeDataStructure.SafeAtomic<MailThreadAppearanceRef> { get } // 这个是这些默认属性存储的本体
    var externalLabel: YYLabel { get set }
    var flagButton: UIButton { get set }
    var scheduleIcon: UIImageView { get set }
    var scheduleTimeIcon: UIImageView { get set }
    var scheduleTimeLabel: YYLabel { get set }
    var statusIconsContainer: UIStackView { get set }
    var folderTag: UDTag { get set }
    var selectedBgView: UIView { get set }
    var timeContainer: UIStackView { get set }
    var multiSelecteView: MailThreadListMultiSelectView { get set }
    var leadingIconView: UIImageView { get set }

    /// 在创建cell合适的实际去调用初始化各个组件
    func configUI(container: UIView, displaysAsynchronously: Bool)
}

struct MailThreadCellConstants {
    static let titleIconWidth: CGFloat = 14.0
    static let titleIconSpace: CGFloat = 8.0
    static let titleLeftPadding: CGFloat = 28
    static let largeTitleLeftPadding: CGFloat = 48
}

class MailThreadAppearanceRef {
    var bottomLine: UIView!
    var unreadIcon: UIView!
    var replyTag: UIImageView?
    var shareIcon: UIImageView!
    var markLaterIcon: UIImageView!
    var nameContainer: UIStackView!
    var draftLabel: YYLabel!
    var nameLabel: MailUILabel!
    var convLabel: YYLabel!
    var timeLabel: YYLabel!
    var titleLabel: MailUILabel!
    var descContainer: UIStackView!
//    var descIcon: UIImageView = .init(image: nil)
    var descLabel: UILabel = .init()
    var attachmentIcon: UIImageView = .init(image: nil)
    var priorityIcon: UIImageView?
    var tagWrapperView: MailThreadCustomTagWrapper!
    var externalLabel: YYLabel!
    var starButton: UIButton!
    var scheduleIcon: UIImageView = .init(image: nil)
    var scheduleTimeIcon: UIImageView = .init(image: nil)
    var scheduleTimeLabel: YYLabel!
    var statusIconsContainer: UIStackView!
    var folderTag: UDTag!
    var selectedBgView: UIView = .init()
    var timeContainer: UIStackView!
    var multiSelecteView: MailThreadListMultiSelectView!
    var leadingIconView: UIImageView = .init(image: nil)
}

extension MailThreadAppearance where Self: UITableViewCell {

    /// init方法里面务必调用一下创建各个子组件好吗？
    // nolint: long_function -- 一个较复杂 cell 的初始化，包含各个元素 layout，已用空行分块 & 注释，不影响代码可读性
    func configUI(container: UIView, displaysAsynchronously: Bool) {
        let titlePadding = MailThreadCellConstants.titleLeftPadding
        let titleIconWidth = MailThreadCellConstants.titleIconWidth
        let titleIconSpace = MailThreadCellConstants.titleIconSpace

        selectedBgView = UIView()
        container.addSubview(selectedBgView)
        selectedBgView.backgroundColor = UIColor.ud.fillSelected
        selectedBgView.layer.cornerRadius = 6
        selectedBgView.layer.masksToBounds = true
        selectedBgView.isHidden = true
        selectedBgView.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.right.equalTo(-6)
            make.top.bottom.equalToSuperview()
        }

        // 未读小红点
        unreadIcon = UIView()
        container.addSubview(unreadIcon)
        unreadIcon.backgroundColor = UIColor.ud.functionInfoContentDefault
        unreadIcon.frame = CGRect(x: 12, y: 20, width: 8, height: 8)
        unreadIcon.layer.cornerRadius = 4
        unreadIcon.layer.masksToBounds = true

        // 已回复/转发标记
        replyTag = UIImageView()
        container.addSubview(replyTag)
        replyTag.image = UDIcon.replyFilled.withRenderingMode(.alwaysTemplate)
        replyTag.tintColor = UIColor.ud.iconN3
        replyTag.isHidden = true
        replyTag.snp.makeConstraints { (make) in
            make.left.equalTo(10)
            make.top.equalTo(42.5)
            make.width.height.equalTo(12)
        }

        timeContainer = UIStackView()
        timeContainer.axis = .horizontal
        timeContainer.distribution = .fill
        timeContainer.alignment = .trailing
        container.addSubview(timeContainer)

        nameContainer = UIStackView()
        nameContainer.axis = .horizontal
        nameContainer.spacing = 4
        nameContainer.distribution = .equalSpacing // .fill //
        nameContainer.alignment = .trailing
        container.addSubview(nameContainer)

        statusIconsContainer = UIStackView()
        statusIconsContainer.axis = .horizontal
        statusIconsContainer.spacing = titleIconSpace
        statusIconsContainer.distribution = .fill
        statusIconsContainer.alignment = .trailing
        container.addSubview(statusIconsContainer)
        statusIconsContainer.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(nameContainer.snp.right).offset(8)
            make.right.equalTo(timeContainer.snp.left).offset(-8)
            make.height.equalTo(14)
            make.centerY.equalTo(unreadIcon)
        }

        // draft Title
        draftLabel = YYLabel()
        draftLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        draftLabel.displaysAsynchronously = displaysAsynchronously
        draftLabel.fadeOnHighlight = false
        draftLabel.fadeOnAsynchronouslyDisplay = false
        draftLabel.textColor = UIColor.ud.functionDangerContentDefault
        draftLabel.font = UIFont.systemFont(ofSize: 16.0)
        draftLabel.text = BundleI18n.MailSDK.Mail_Drafts_DraftsItem
        draftLabel.isHidden = true
        nameContainer.addArrangedSubview(draftLabel)
        draftLabel.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 0, height: 22))
        }

        // name
        nameLabel = displaysAsynchronously ? YYLabel() : UILabel()
        nameLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelHomeNamesKey
        nameLabel.setContentCompressionResistancePriority(.dragThatCannotResizeScene, for: .horizontal)
        nameLabel.displaysAsynchronously = displaysAsynchronously
        nameLabel.fadeOnHighlight = false
        nameLabel.fadeOnAsynchronouslyDisplay = false
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 16.0)
        nameContainer.addArrangedSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(draftLabel.snp.right)
            make.height.equalTo(22)
        }

        nameContainer.snp.makeConstraints { make in
            make.left.equalTo(titlePadding)
            make.top.equalTo(13)
            make.height.equalTo(22)
        }

        bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.left.equalTo(titlePadding)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        // time
        timeLabel = YYLabel()
        timeLabel.displaysAsynchronously = displaysAsynchronously
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeContainer.addArrangedSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
        }

        scheduleTimeLabel = YYLabel()
        scheduleTimeLabel.displaysAsynchronously = displaysAsynchronously
        scheduleTimeLabel.font = UIFont.systemFont(ofSize: 12)
        timeContainer.addArrangedSubview(scheduleTimeLabel)
        scheduleTimeLabel.isHidden = true
        scheduleTimeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
        }

        timeContainer.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalTo(unreadIcon)
            make.height.equalTo(18)
        }

        // convcount
        convLabel = YYLabel()
        convLabel.accessibilityIdentifier = "CONV"
        convLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        convLabel.textColor = UIColor.ud.udtokenTagNeutralTextNormal
        convLabel.textAlignment = .center
        // if set on view. it will effected by cell highlight
        convLabel.layer.ud.setBackgroundColor(UIColor.ud.udtokenTagNeutralBgNormal)
        convLabel.layer.cornerRadius = 4
        convLabel.layer.masksToBounds = true
        convLabel.displaysAsynchronously = displaysAsynchronously
        convLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        container.addSubview(convLabel)
        convLabel.snp.makeConstraints { make in
            make.right.equalTo(timeContainer.snp.right)
            make.top.equalTo(timeContainer.snp.bottom).offset(6)
            make.width.height.equalTo(16)
        }

        // 邮件重要程度的icon
        priorityIcon = UIImageView()
        priorityIcon.contentMode = .scaleAspectFit
        priorityIcon.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        priorityIcon.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusIconsContainer.addArrangedSubview(priorityIcon)
        priorityIcon.isHidden = true
        priorityIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: titleIconWidth, height: titleIconWidth))
            make.centerY.equalToSuperview()
        }
        
        // 邮件分享图标
        shareIcon = UIImageView()
        shareIcon.image = Resources.mail_cell_share_icon
        shareIcon.contentMode = .scaleAspectFit
        shareIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        shareIcon.setContentHuggingPriority(.required, for: .horizontal)
        statusIconsContainer.addArrangedSubview(shareIcon)
        shareIcon.isHidden = true
        shareIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.centerY.equalToSuperview()
        }

        // 定时发送icon
        scheduleIcon = UIImageView()
        scheduleIcon.image = UDIcon.sentScheduledOutlined.withRenderingMode(.alwaysTemplate)
        scheduleIcon.tintColor = .ud.iconN3
        scheduleIcon.contentMode = .scaleAspectFit
        scheduleIcon.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        scheduleIcon.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusIconsContainer.addArrangedSubview(scheduleIcon)
        scheduleIcon.isHidden = true
        scheduleIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: titleIconWidth, height: titleIconWidth))
            make.centerY.equalToSuperview()
        }

        // 附件前的icon
        attachmentIcon = UIImageView()
        attachmentIcon.image = UDIcon.attachmentOutlined.withRenderingMode(.alwaysTemplate)
        attachmentIcon.tintColor = UIColor.ud.iconN3
        attachmentIcon.contentMode = .scaleAspectFit
        attachmentIcon.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        attachmentIcon.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusIconsContainer.addArrangedSubview(attachmentIcon)
        attachmentIcon.isHidden = true
        attachmentIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: titleIconWidth, height: titleIconWidth))
            make.centerY.equalToSuperview()
        }
        
        
        
        scheduleTimeIcon = UIImageView()
        scheduleTimeIcon.image = UDIcon.sentScheduledOutlined.withRenderingMode(.alwaysTemplate)
        scheduleTimeIcon.tintColor = .ud.primaryContentDefault
        scheduleTimeIcon.contentMode = .scaleAspectFit
        statusIconsContainer.addArrangedSubview(scheduleTimeIcon)
        scheduleTimeIcon.isHidden = true
        scheduleTimeIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: titleIconWidth, height: titleIconWidth))
            make.centerY.equalToSuperview()
        }

        folderTag = UDTag(text: "", textConfig: UDTagConfig.TextConfig.init(textColor: UIColor.ud.udtokenTagNeutralTextNormal, backgroundColor: UIColor.ud.udtokenTagNeutralBgNormal))
        folderTag.layer.cornerRadius = 4.0
        folderTag.layer.masksToBounds = true
        folderTag.isHidden = true
        container.addSubview(folderTag)
        folderTag.snp.makeConstraints { make in
            make.left.equalTo(titlePadding)
            make.width.equalTo(0).priority(.medium)
            make.top.equalTo(nameLabel.snp.bottom).offset(4).priority(.medium)
        }

        // title
        titleLabel = displaysAsynchronously ? YYLabel() : UILabel()
        titleLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelHomeTitleKey
        titleLabel.displaysAsynchronously = displaysAsynchronously
        titleLabel.fadeOnHighlight = false
        titleLabel.fadeOnAsynchronouslyDisplay = false
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(titlePadding)
            make.right.lessThanOrEqualTo(convLabel.snp.left).offset(-4).priority(.medium)
            make.top.equalTo(nameContainer.snp.bottom).offset(4).priority(.medium)
            make.height.equalTo(20)
        }

        // 摘要的容器
        descContainer = UIStackView()
        descContainer.axis = .horizontal
        descContainer.spacing = 4
        descContainer.alignment = .center
        container.addSubview(descContainer)
        descContainer.snp.makeConstraints { (make) in
            make.left.equalTo(folderTag.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(4).priority(.medium)
            make.right.lessThanOrEqualToSuperview().offset(-36)
            make.height.equalTo(20)
        }

        // 摘要
        descLabel = UILabel()
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.displaysAsynchronously = displaysAsynchronously
        descLabel.fadeOnHighlight = false
        descLabel.fadeOnAsynchronouslyDisplay = false
        descLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        descLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelHomeDescKey
        descLabel.textColor = UIColor.ud.textPlaceholder
        descContainer.addArrangedSubview(descLabel)

        // Labels
        tagWrapperView = MailThreadCustomTagWrapper()
        tagWrapperView.spacing = 4.0
        tagWrapperView.alignment = .trailing
        container.addSubview(tagWrapperView)
        tagWrapperView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(descContainer.snp.right).offset(4)
            //make.top.equalTo(titleLabel.snp.bottom).offset(4).priority(.medium)
            make.centerY.equalTo(descLabel)
            make.width.lessThanOrEqualTo(0).priority(.required)
            make.right.equalToSuperview().offset(-42).priority(.medium)
        }

        // flag
        flagButton = UIButton(type: .custom)
        flagButton.setImage(UDIcon.flagOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        flagButton.contentEdgeInsets = .zero
        flagButton.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        // flagButton.imageView?.frame = CGRect(x: 6, y: 6, width: 20, height: 20)
        flagButton.imageView?.contentMode = .scaleAspectFill
        // flagButton.imageRect(forContentRect: CGRect(x: 6, y: 6, width: 20, height: 20))
        container.addSubview(flagButton)
        flagButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.BtnHomeFlagKey
        flagButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 32, height: 32))
            make.right.equalToSuperview().offset(-8)
            make.top.equalTo(titleLabel.snp.bottom).offset(-2).priority(.medium)
        }

        multiSelecteView = MailThreadListMultiSelectView()
        container.addSubview(multiSelecteView)
        setTitleColor()

        leadingIconView = UIImageView()
        leadingIconView.contentMode = .scaleAspectFit
        leadingIconView.isHidden = true
        leadingIconView.image = UDIcon.warningOutlined.withRenderingMode(.alwaysTemplate)
        container.addSubview(leadingIconView)
        leadingIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(14)
            make.width.height.equalTo(20)
        }
    }

    func setTitleColor() {
        timeLabel.textColor = UIColor.ud.textPlaceholder
        nameLabel.textColor = UIColor.ud.textTitle
        scheduleTimeLabel.ud.setValue(
            forKeyPath: \.textColor,
            light: UIColor.ud.primaryContentDefault.alwaysLight,
            dark: UIColor.ud.primaryContentDefault.alwaysDark
        )
        convLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        titleLabel.textColor = UIColor.ud.textTitle
        descLabel.textColor = UIColor.ud.textPlaceholder
    }
}

// 方便cell使用的便捷透传
extension MailThreadAppearance where Self: UITableViewCell {
    var bottomLine: UIView {
        get { return threadAppearanceRef.value.bottomLine }
        set { threadAppearanceRef.value.bottomLine = newValue }
    }
    var unreadIcon: UIView {
        get { return threadAppearanceRef.value.unreadIcon }
        set { threadAppearanceRef.value.unreadIcon = newValue }
    }
    var replyTag: UIImageView {
        get { return threadAppearanceRef.value.replyTag ?? UIImageView() }
        set { threadAppearanceRef.value.replyTag = newValue }
    }
    var shareIcon: UIImageView {
        get { return threadAppearanceRef.value.shareIcon }
        set { threadAppearanceRef.value.shareIcon = newValue }
    }
    var markLaterIcon: UIImageView {
        get { return threadAppearanceRef.value.markLaterIcon }
        set { threadAppearanceRef.value.markLaterIcon = newValue }
    }
    var nameContainer: UIStackView {
        get { return threadAppearanceRef.value.nameContainer }
        set { threadAppearanceRef.value.nameContainer = newValue }
    }
    var draftLabel: YYLabel {
        get { return threadAppearanceRef.value.draftLabel }
        set { threadAppearanceRef.value.draftLabel = newValue }
    }
    var nameLabel: MailUILabel {
        get { return threadAppearanceRef.value.nameLabel }
        set { threadAppearanceRef.value.nameLabel = newValue }
    }
    var convLabel: YYLabel {
        get { return threadAppearanceRef.value.convLabel }
        set { threadAppearanceRef.value.convLabel = newValue }
    }
    var timeLabel: YYLabel {
        get { return threadAppearanceRef.value.timeLabel }
        set { threadAppearanceRef.value.timeLabel = newValue }
    }
    var titleLabel: MailUILabel {
        get { return threadAppearanceRef.value.titleLabel }
        set { threadAppearanceRef.value.titleLabel = newValue }
    }
    var descContainer: UIStackView {
        get { return threadAppearanceRef.value.descContainer }
        set { threadAppearanceRef.value.descContainer = newValue }
    }
//    var descIcon: UIImageView {
//        get { return threadAppearanceRef.value.descIcon }
//        set { threadAppearanceRef.value.descIcon = newValue }
//    }
    var descLabel: UILabel {
        get { return threadAppearanceRef.value.descLabel }
        set { threadAppearanceRef.value.descLabel = newValue }
    }
    var attachmentIcon: UIImageView {
        get { return threadAppearanceRef.value.attachmentIcon }
        set { threadAppearanceRef.value.attachmentIcon = newValue }
    }
    var priorityIcon: UIImageView {
        get { return threadAppearanceRef.value.priorityIcon ?? UIImageView() }
        set { threadAppearanceRef.value.priorityIcon = newValue }
    }
    var tagWrapperView: MailThreadCustomTagWrapper {
        get { return threadAppearanceRef.value.tagWrapperView }
        set { threadAppearanceRef.value.tagWrapperView = newValue }
    }
    var externalLabel: YYLabel {
        get { return threadAppearanceRef.value.externalLabel }
        set { threadAppearanceRef.value.externalLabel = newValue }
    }
    var flagButton: UIButton {
        get { return threadAppearanceRef.value.starButton }
        set { threadAppearanceRef.value.starButton = newValue }
    }
    var scheduleIcon: UIImageView {
        get { return threadAppearanceRef.value.scheduleIcon }
        set { threadAppearanceRef.value.scheduleIcon = newValue }
    }
    var scheduleTimeIcon: UIImageView {
        get { return threadAppearanceRef.value.scheduleTimeIcon }
        set { threadAppearanceRef.value.scheduleTimeIcon = newValue }
    }
    var scheduleTimeLabel: YYLabel {
        get { return threadAppearanceRef.value.scheduleTimeLabel }
        set { threadAppearanceRef.value.scheduleTimeLabel = newValue }
    }
    var statusIconsContainer: UIStackView {
        get { return threadAppearanceRef.value.statusIconsContainer }
        set { threadAppearanceRef.value.statusIconsContainer = newValue }
    }
    var folderTag: UDTag {
        get { return threadAppearanceRef.value.folderTag }
        set { threadAppearanceRef.value.folderTag = newValue }
    }
    var selectedBgView: UIView {
        get { return threadAppearanceRef.value.selectedBgView }
        set { threadAppearanceRef.value.selectedBgView = newValue }
    }
    var timeContainer: UIStackView {
        get { return threadAppearanceRef.value.timeContainer }
        set { threadAppearanceRef.value.timeContainer = newValue }
    }
    var multiSelecteView: MailThreadListMultiSelectView {
        get { return threadAppearanceRef.value.multiSelecteView }
        set { threadAppearanceRef.value.multiSelecteView = newValue }
    }

    var leadingIconView: UIImageView {
        get { return threadAppearanceRef.value.leadingIconView }
        set { threadAppearanceRef.value.leadingIconView = newValue }
    }
}

// DarkMode
extension YYLabel {

}
