//
//  ChatMessageCell.swift
//  ByteView
//
//  Created by wulv on 2020/12/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RichLabel
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit
import ByteViewNetwork

class ChatMessageCell: UITableViewCell {
    #if DEBUG
    private lazy var debugLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.functionDanger900
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    #endif

    private lazy var avatarView = ChatAvatarView()
    private var meetingUrl: String = ""
    private var isRelationTagEnabled = false

    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textPlaceholder
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var meLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var roleTag: UILabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.layer.cornerRadius = 4.0
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        label.contentMode = .center
        return label
    }()

    private lazy var externalTag: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: 4.0,
                                        bottom: 0.0,
                                        right: 4.0)
        label.font = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.cornerRadius = 4.0
        label.textAlignment = .center
        label.contentMode = .center
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        label.layer.masksToBounds = true
        return label
    }()


    private lazy var timeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var chatContentView: UIView = {
        let view = UIView()
        view.backgroundColor = UDChatMessageColorTheme.imMessageBgBubblesBlue
        view.layer.cornerRadius = 10
        view.accessibilityIdentifier = "chat_contentView"
        return view
    }()

    private lazy var translationItemView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    lazy var originalTextLabel: LKSelectionLabel = {
        let label = LKSelectionLabel(options: [.selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.3)),
                                               .cursorColor(UIColor.ud.colorfulBlue)])
        label.textColor = UIColor.ud.textTitle
        label.delegate = self
        label.selectionDelegate = self
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentPressed]
        label.activeLinkAttributes = [:]
        label.textVerticalAlignment = .middle
        label.accessibilityIdentifier = "chat_originalText_label"
        return label
    }()

    lazy var translatedTextLabel: LKSelectionLabel = {
        let label = LKSelectionLabel(options: [.selectionColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.3)),
                                               .cursorColor(UIColor.ud.colorfulBlue)])
        label.textColor = UIColor.ud.textTitle
        label.delegate = self
        label.selectionDelegate = self
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textCheckingDetecotor = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        label.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryContentPressed]
        label.activeLinkAttributes = [:]
        label.textVerticalAlignment = .middle
        label.accessibilityIdentifier = "chat_translatedText_label"
        return label
    }()

    private lazy var translationLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.attributedText = NSAttributedString(string: I18n.View_G_Translation_BoxDivider, config: .tinyAssist)
        return label
    }()

    private lazy var splitLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var yellowLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.colorfulYellow
        view.layer.cornerRadius = 1.5
        return view
    }()

    private lazy var translateButton: UIButton = {
        let button = UIButton()
        button.setImage(Self.translateImg, for: .normal)
        button.backgroundColor = UIColor.clear
        return button
    }()

    static var translateImg = UDIcon.getIconByKey(.translateOutlined, iconColor: UIColor.ud.B700, size: CGSize(width: 16, height: 16))

    private var translateLayoutConstraints: [Constraint] = []

    var tapAvatarClosure: (() -> Void)? {
        didSet {
            avatarView.clickClosure = tapAvatarClosure
        }
    }
    var tapLinkClosure: ((URL) -> Void)?

    var tapTranslateButtonClosure: (() -> Void)?

    var labelDragModeUpdateClosure: ((Bool) -> Void)?

    var labelRangeDidSelectedClosure: ((NSRange) -> Void)?

    var disposeBag: DisposeBag = DisposeBag()

    private weak var cellModel: ChatMessageCellModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        isUserInteractionEnabled = true
        selectionStyle = .none

        loadSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tapLinkClosure = nil
        disposeBag = DisposeBag()
        originalTextLabel.delegate = self
        translatedTextLabel.delegate = self
    }

    private func loadSubviews() {
        contentView.addSubview(avatarView)
        avatarView.layer.cornerRadius = Layout.AvatarSize.height * 0.5
        avatarView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(Layout.MarginLeading)
            maker.top.equalToSuperview().inset(Layout.AvatarMarginTop)
            maker.size.equalTo(Layout.AvatarSize)
        }

        #if DEBUG
        contentView.addSubview(debugLabel)
        debugLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(avatarView.snp.bottom).offset(20)
            maker.left.right.equalTo(avatarView)
            maker.height.equalTo(20)
        }
        #endif

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(avatarView.snp.right).offset(Layout.AvatarToName)
            maker.top.equalToSuperview().inset(Layout.AvatarMarginTop)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }

        contentView.addSubview(meLabel)
        meLabel.snp.makeConstraints { (maker) in
            maker.centerY.height.equalTo(nameLabel)
            maker.left.equalTo(nameLabel.snp.right)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }

        contentView.addSubview(roleTag)
        roleTag.snp.makeConstraints { (maker) in
            maker.left.equalTo(nameLabel.snp.right).offset(Layout.TagGap)
            maker.centerY.equalTo(nameLabel)
            maker.height.equalTo(Layout.LabelTagHeight)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }

        contentView.addSubview(externalTag)
        externalTag.snp.makeConstraints { (maker) in
            maker.left.equalTo(nameLabel.snp.right).offset(Layout.TagGap)
            maker.centerY.equalTo(nameLabel)
            maker.height.equalTo(Layout.LabelTagHeight)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }

        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(nameLabel.snp.right).offset(Layout.TimeGap)
            maker.centerY.height.equalTo(nameLabel)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }

        chatContentView.addSubview(originalTextLabel)
        originalTextLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(Layout.LabelMarginTopAndBottom)
            make.left.right.equalToSuperview().inset(Layout.LabelMarginLeftAndRight)
        }

        chatContentView.addSubview(translationItemView)
        translationItemView.snp.makeConstraints { (make) in
            let topConstraints = make.top.equalTo(originalTextLabel.snp.bottom).offset(6).constraint
            let othersConstraints = make.left.right.bottom.equalToSuperview().constraint
            self.translateLayoutConstraints.append(topConstraints)
            self.translateLayoutConstraints.append(othersConstraints)
        }

        translationItemView.addSubview(translationLabel)
        translationLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(12)
        }

        translationItemView.addSubview(splitLine)
        splitLine.snp.makeConstraints { (make) in
            make.left.equalTo(translationLabel.snp.right).offset(4)
            make.right.equalToSuperview().inset(12)
            make.height.equalTo(1)
            make.top.equalToSuperview().inset(9)
        }

        translationItemView.addSubview(yellowLine)
        yellowLine.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(8)
            make.top.equalTo(translationLabel.snp.bottom).offset(6)
            make.width.equalTo(3)
        }

        translationItemView.addSubview(translatedTextLabel)
        translatedTextLabel.snp.makeConstraints { (make) in
            make.left.equalTo(yellowLine.snp.right).offset(10)
            make.top.equalTo(translationLabel.snp.bottom).offset(6)
            make.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(8)
        }

        chatContentView.addSubview(translateButton)
        translateButton.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview().inset(1)
            make.width.height.equalTo(16)
        }

        contentView.addSubview(chatContentView)
        chatContentView.snp.makeConstraints { (maker) in
            maker.top.equalTo(nameLabel.snp.bottom).offset(Layout.ContentToName)
            maker.left.equalTo(nameLabel)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
            maker.bottom.equalToSuperview().inset(Layout.MarginBottom)
        }
    }

    private func updateLabelsConstraints() {
        let hostLeading = meLabel.isHidden ? nameLabel : meLabel
        roleTag.snp.remakeConstraints { (maker) in
            maker.left.equalTo(hostLeading.snp.right).offset(Layout.TagGap)
            maker.centerY.height.equalTo(nameLabel)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }
        let externalLeading = roleTag.isHidden ? (meLabel.isHidden ? nameLabel : meLabel) : roleTag
        externalTag.snp.remakeConstraints { (maker) in
            maker.left.equalTo(externalLeading.snp.right).offset(Layout.TagGap)
            maker.centerY.height.equalTo(nameLabel)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }
        let timeLeading = externalTag.isHidden ?
            (roleTag.isHidden ? (meLabel.isHidden ? nameLabel : meLabel) : roleTag) : externalTag
        timeLabel.snp.remakeConstraints { (maker) in
            maker.left.equalTo(timeLeading.snp.right).offset(Layout.TimeGap)
            maker.centerY.height.equalTo(nameLabel)
            maker.right.lessThanOrEqualToSuperview().inset(Layout.MarginTrailing)
        }
    }

    private func updateTranslateInfoConstraints(_ showRule: ShowRule) {
        switch showRule {
        case .showOrigin:
            translationItemView.isHidden = true
            translateButton.isHidden = true
            originalTextLabel.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(Layout.LabelMarginTopAndBottom)
                make.left.right.equalToSuperview().inset(Layout.LabelMarginLeftAndRight)
            }
            self.translateLayoutConstraints.forEach { $0.deactivate() }
        case .showTranslation:
            translationItemView.isHidden = true
            translateButton.isHidden = false
            originalTextLabel.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview().inset(Layout.LabelMarginTopAndBottom)
                make.left.right.equalToSuperview().inset(Layout.LabelMarginLeftAndRight)
            }
            self.translateLayoutConstraints.forEach { $0.deactivate() }
        case .showOriginAndTranslation:
            translationItemView.isHidden = false
            translateButton.isHidden = false
            originalTextLabel.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().inset(Layout.LabelMarginTopAndBottom)
                make.left.right.equalToSuperview().inset(Layout.LabelMarginLeftAndRight)
            }
            self.translateLayoutConstraints.forEach { $0.activate() }
        }
    }
}

// MARK: - Style
extension ChatMessageCell {
    private enum ShowRule {
        case showOrigin
        case showTranslation
        case showOriginAndTranslation
    }

    private enum Layout {
        static let AvatarSize: CGSize = CGSize(width: 28, height: 28)
        static let AvatarMarginTop: CGFloat = 12
        static let MarginLeading: CGFloat = 16
        static let MarginTop: CGFloat = 8
        static let MarginTrailing: CGFloat = 16
        static let MarginBottom: CGFloat = 12
        static let ContentToName: CGFloat = 4
        static let AvatarToName: CGFloat = 8
        static let TagGap: CGFloat = 4
        static let TimeGap: CGFloat = 8
        static let LabelMarginLeftAndRight: CGFloat = 12
        static let LabelMarginTopAndBottom: CGFloat = 8
        static let LabelTagHeight: CGFloat = 18
    }

    static func createNameAttributedString(with name: String?) -> NSAttributedString? {
        guard let name = name else { return nil }
        return NSAttributedString(string: name, config: .tinyAssist)
    }

    static func createMeAttributedString(with me: String?) -> NSAttributedString? {
        guard let me = me else { return nil }
        return NSAttributedString(string: me, config: .tinyAssist)
    }

    static func createRoleAttributedString(with role: String?) -> NSAttributedString? {
        guard let role = role else { return nil }
        return NSAttributedString(string: role, config: .assist, alignment: .center)
    }

    static func createExternalAttributedString(with external: String?) -> NSAttributedString? {
        guard let external = external else { return nil }
        return NSAttributedString(string: external, config: .assist, alignment: .center)
    }

    static func createTimeAttributedString(with time: String?) -> NSAttributedString? {
        guard let time = time else { return nil }
        return NSAttributedString(string: time, config: .tinyAssist)
    }

    static func createContentAttributedString(with content: NSMutableAttributedString?) -> NSAttributedString? {
        guard let content = content else { return nil }
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 22
        style.maximumLineHeight = 22
        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        let text = NSMutableAttributedString(attributedString: content)
        text.addAttributes([.paragraphStyle: style, .font: font, .foregroundColor: UIColor.ud.textTitle],
                              range: NSRange(location: 0, length: text.length))
        return text
    }
}

// MARK: - Public
extension ChatMessageCell {

    func config(with viewModel: ChatMessageCellModel) {
        cellModel = viewModel
        avatarView.content = viewModel.avatar
        avatarView.clickEnable = viewModel.canTapAvatar

        #if DEBUG
        debugLabel.text = String(viewModel.position)
        debugLabel.sizeToFit()
        #endif

        nameLabel.attributedText = viewModel.name
        meLabel.attributedText = viewModel.me
        meLabel.isHidden = viewModel.me == nil

        self.isRelationTagEnabled = viewModel.meeting.setting.isRelationTagEnabled
        if isRelationTagEnabled {
            var external = viewModel.relationTag?.relationText
            if viewModel.hasRequestRelationTag, external == nil {
                external = viewModel.external?.string
            }
            externalTag.text = external
            externalTag.isHidden = external == nil
        } else {
            externalTag.text = viewModel.external?.string
            externalTag.isHidden = viewModel.external == nil
        }
        timeLabel.attributedText = viewModel.time

        meetingUrl = viewModel.meetingURL

        let roleConfig = viewModel.roleRelay.value
        roleTag.text = roleConfig?.role
        roleTag.textColor = roleConfig?.textColor
        roleTag.backgroundColor = roleConfig?.tagBgColor
        roleTag.isHidden = roleConfig == nil
        updateLabelsConstraints()

        disposeBag = DisposeBag()
        viewModel.roleRelay
            .skip(1)
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] roleConfig in
                self?.roleTag.text = roleConfig?.role
                self?.roleTag.backgroundColor = roleConfig?.tagBgColor
                self?.roleTag.textColor = roleConfig?.textColor
                self?.roleTag.isHidden = roleConfig == nil
                self?.updateLabelsConstraints()
            })
            .disposed(by: disposeBag)

        viewModel.nameRelay
            .skip(1)
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .bind(to: nameLabel.rx.attributedText)
            .disposed(by: disposeBag)

        if viewModel.me == nil {
            chatContentView.backgroundColor = UIColor.ud.vcTokenMeetingBgChatBubblesGrey
        } else {
            chatContentView.backgroundColor = UDChatMessageColorTheme.imMessageBgBubblesBlue
        }

        translatedTextLabel.isHidden = viewModel.content == nil || viewModel.translationContent == nil
        if translatedTextLabel.isHidden {
            originalTextLabel.attributedText = viewModel.content == nil ? viewModel.translationContent : viewModel.content
            let showRule: ShowRule = viewModel.translationContent == nil ? .showOrigin : .showTranslation
            updateTranslateInfoConstraints(showRule)
        } else {
            originalTextLabel.attributedText = viewModel.content
            translatedTextLabel.attributedText = viewModel.translationContent
            updateTranslateInfoConstraints(.showOriginAndTranslation)
        }
        requestRelationTagIfNeeded()
    }

    func updatePreferredMaxLayoutWidth(with tableViewWidth: CGFloat) {
        let otherWidth = Layout.MarginLeading + Layout.AvatarSize.width + Layout.AvatarToName + Layout.MarginTrailing + 2 * Layout.LabelMarginLeftAndRight
        originalTextLabel.preferredMaxLayoutWidth = tableViewWidth - otherWidth
        if !originalTextLabel.isHidden {
            translatedTextLabel.preferredMaxLayoutWidth = tableViewWidth - otherWidth - 13
        } else {
            translatedTextLabel.preferredMaxLayoutWidth = tableViewWidth - otherWidth
        }
    }

    func getBubbleView() -> UIView? {
        return self.chatContentView
    }

    func getcontentLabel(location: CGPoint) -> UIView? {
        guard !contentView.subviews.isEmpty else {
            return nil
        }
        var stack = contentView.subviews
        while let view = stack.popLast() {
            if view.isHidden { continue }
            let locationInView = self.convert(location, to: view)
            if view.bounds.contains(locationInView) && view is LKSelectionLabel {
                return view
            }
            for v in view.subviews {
                stack.append(v)
            }
        }
        return nil
    }
}

// MARK: - Delegate
extension ChatMessageCell: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        guard let tapLinkClosure = tapLinkClosure, url != URL(string: meetingUrl) else { return }
        tapLinkClosure(url)
    }
}

extension ChatMessageCell: LKSelectionLabelDelegate {
    func selectionDragModeUpdate(_ inDragMode: Bool) {
        guard let labelDragModeUpdateClosure = labelDragModeUpdateClosure else { return }
        labelDragModeUpdateClosure(inDragMode)
    }

    func selectionRangeDidUpdate(_ range: NSRange) {
    }

    func selectionRangeDidSelected(_ range: NSRange, didSelectedAttrString: NSAttributedString, didSelectedRenderAttributedString: NSAttributedString) {
        labelRangeDidSelectedClosure?(range)
    }

    func selectionRangeText(_ range: NSRange, didSelectedAttrString: NSAttributedString, didSelectedRenderAttributedString: NSAttributedString) -> String? {
        return ""
    }

    func selectionRangeHandleCopy(selectedText: String) -> Bool {
        return false
    }
}

extension ChatMessageCell {
    func requestRelationTagIfNeeded() {
        cellModel?.getRelationTag { [weak self] external in
            Util.runInMainThread {
                self?.showExternalTag(external?.string)
            }
        }
    }

    private func showExternalTag(_ external: String?) {
        if external != nil {
            externalTag.text = external
            externalTag.isHidden = false
        } else {
            externalTag.text = cellModel?.external?.string
            externalTag.isHidden = cellModel?.external == nil
        }
        updateLabelsConstraints()
    }
}
