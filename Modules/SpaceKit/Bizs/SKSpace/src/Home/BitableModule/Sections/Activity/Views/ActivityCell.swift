//
//  ActivityCell.swift
//  Demo
//
//  Created by yinyuan on 2023/4/17.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignAvatar
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignTag
import ByteWebImage
import SKCommon
import SKFoundation
import LarkAvatarComponent
import AvatarComponent
import SKResource
import LarkAccountInterface
import SKUIKit
import LarkTag

class ActivityCollectionViewCell: UICollectionViewCell {
    
    static let height: CGFloat = 60
    
    private let cellView: ActivityCell = ActivityCell(style: .home)
    
    private lazy var selectedView: UIView = {
        let view = UIView()
        let innerView = UIView()
        view.addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview()
        }
        
        innerView.backgroundColor = UDColor.fillHover
        innerView.layer.cornerRadius = 4
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundView = nil
        selectedBackgroundView = selectedView
        
        contentView.addSubview(cellView)
        cellView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.right.equalToSuperview()    // 右侧做淡出效果，此处不留边距
            make.top.bottom.equalToSuperview().inset(8)
        }
    }
    
    func update(data: HomePageData?, delegate: ActivityCellDelegate? = nil) {
        cellView.update(data: data, delegate: delegate)
    }
}

protocol ActivityTableViewErrorCellDelegate: AnyObject {
    func activityErrorReload()
}

class ActivityTableViewErrorCell: UICollectionViewCell {
    
    static let height: CGFloat = 60
    
    weak var delegate: ActivityTableViewErrorCellDelegate?
    
    private lazy var label: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        view.text = BundleI18n.SKResource.Bitable_Workspace_UnableToLoadData_Description
        view.textAlignment = .center
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundView = nil
        
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tap)
    }
    
    @objc
    private func tap() {
        delegate?.activityErrorReload()
    }
}

protocol ActivityTableViewEmptyCellDelegate: AnyObject {
    func activityEmptyTaped()
}

class ActivityTableViewEmptyCell: UICollectionViewCell {
    
    static let height: CGFloat = 74
    
    weak var delegate: ActivityTableViewEmptyCellDelegate?
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = EmptyBundleResources.image(named: "emptyPositiveActivityAction1")
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private lazy var rightStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [title, desc])
        view.axis = .vertical
        view.spacing = 2
        return view
    }()
    
    private lazy var title: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 16)
        view.textColor = UDColor.textTitle
        view.numberOfLines = 1
        view.lineBreakMode = .byTruncatingTail
        return view
    }()
    
    private lazy var desc: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        view.numberOfLines = 3
        view.lineBreakMode = .byTruncatingTail
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundView = nil
        
        contentView.addSubview(imageView)
        contentView.addSubview(rightStackView)
        
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(14)
            make.width.height.equalTo(74)
            make.top.equalToSuperview()
        }
        
        rightStackView.snp.makeConstraints { make in
            make.left.equalTo(imageView.snp.right).offset(8)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(6)
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        addGestureRecognizer(tap)
    }
    
    @objc
    private func tap() {
        delegate?.activityEmptyTaped()
    }
    
    func update(activityEmptyConfig: ActivityEmptyConfig?) {
        title.text = activityEmptyConfig?.title ?? BundleI18n.SKResource.Bitable_Workspace_Mobile_NoRecentActivity_Title
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.19
        paragraphStyle.lineBreakMode = .byTruncatingTail
        desc.attributedText = NSMutableAttributedString(
            string: activityEmptyConfig?.desc ?? BundleI18n.SKResource.Bitable_Workspace_Mobile_NoRecentActivity_Desc,
            attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
    }
}

class ActivityTableViewCell: UITableViewCell {
        
    private let cellView: ActivityCell = ActivityCell()
    
    private lazy var selectedView: UIView = {
        let view = UIView()
        let innerView = UIView()
        view.addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(4)
            make.top.bottom.equalToSuperview()
        }
        
        innerView.backgroundColor = UDColor.fillHover
        innerView.layer.cornerRadius = 4
        
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundView = nil
        selectedBackgroundView = selectedView
        backgroundColor = .clear
        contentView.addSubview(cellView)
        
        cellView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }
    
    func update(data: HomePageData?, delegate: ActivityCellDelegate? = nil, showHighlighted: Bool = false) {
        cellView.update(data: data, delegate: delegate)
        
        if showHighlighted {
            self.backgroundColor = .ud.Y100
            UIView.animate(withDuration: 0.2, delay: 0.4) { [weak self] in
                self?.backgroundColor = .clear
            }
        } else {
            self.backgroundColor = .clear
        }
    }
}

protocol ActivityCellDelegate: AnyObject {
    func profileClick(data: HomePageData?)
}

private enum ActivityCellStyle {
    case normal
    case home
}

private class ActivityCell: UIView {
    
    private weak var delegate: ActivityCellDelegate?
    
    private let style: ActivityCellStyle

    private lazy var profileImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UDColor.B100
        view.layer.cornerRadius = style == .home ? 20 : 22
        view.layer.masksToBounds = true
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileClick))
        view.addGestureRecognizer(tap)
        _ = view.addGradientLoadingView()
        return view
    }()
    
    private lazy var rightContent: UIStackView = {
        let view = style == .home ? UIStackView(arrangedSubviews: [userNameStackView, contentLabel]) : UIStackView(arrangedSubviews: [userNameStackView, contentLabel, bottomInfoStackView])
        view.axis = .vertical
        return view
    }()
    
    private lazy var userNameStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [userNameLabel, titleTagView, UIView()])
        view.axis = .horizontal
        view.spacing = 4
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    lazy var titleTagView: UDTag = {
        let view = UDTag(configuration: .text(LarkTag.Tag.defaultTagInfo(for: .robot).title ?? "", colorScheme: .yellow))
        view.sizeClass = .mini
        return view
    }()
    
    private lazy var bottomInfoStackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [timeLabel, dotLabel, docsIconImageView, docsLabel])
        view.axis = .horizontal
        view.spacing = 4
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return view
    }()
    
    private lazy var userNameLabel: UILabel = {
        let view = UILabel()
        view.numberOfLines = 1
        view.lineBreakMode = .byTruncatingTail
        view.font = style == .home ? UIFont.systemFont(ofSize: 16) : UIFont.systemFont(ofSize: 16, weight: .medium)
        view.textColor = UDColor.textTitle
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        _ = view.addGradientLoadingView(cornerRadius: 6)
        return view
    }()
    
    private class GradientLabel: UILabel {
        private lazy var gradientLayer: CAGradientLayer = {
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor]
            gradientLayer.locations = [0.0, 0.9, 0.95, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0)
            return gradientLayer
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // 开启右侧的渐变淡出效果，主要是为了优化 @人员 标签被中间截断
        func enbaleGradient() {
            layer.mask = gradientLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            // 靠右
            gradientLayer.frame = self.bounds
            let start = (frame.width - 64.0 + 64.0 * 0.25) / frame.width
            let end = (frame.width - 64.0 + 64.0 * 0.75) / frame.width
            gradientLayer.locations = [0.0, NSNumber(value: start), NSNumber(value: end), 1.0]
        }
    }
    
    private lazy var contentLabel: UILabel = {
        let view = GradientLabel()
        view.font = font
        view.textColor = style == .home ? UDColor.textCaption : UDColor.textTitle
        view.numberOfLines = style == .home ? 1 : 6
        if style == .home {
            view.enbaleGradient()
        } else {
            view.lineBreakMode = .byTruncatingTail
        }
        _ = view.addGradientLoadingView(cornerRadius: 6)
        return view
    }()
    
    private lazy var timeLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    private lazy var dotLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.text = "·"
        return view
    }()
    
    private lazy var docsIconImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.fileLinkBitableOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.textPlaceholder
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    private lazy var docsLabel: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }()
    
    init(style: ActivityCellStyle = .normal) {
        self.style = style
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        layer.masksToBounds = false // 富文本布局有时候会溢出，需要允许溢出显示
        
        addSubview(profileImageView)
        addSubview(rightContent)
        
        rightContent.setCustomSpacing(6, after: userNameStackView)
        rightContent.setCustomSpacing(6, after: contentLabel)
        
        profileImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.height.width.equalTo(style == .home ? 40 : 44)
        }
        
        rightContent.snp.makeConstraints { make in
            make.left.equalTo(profileImageView.snp.right).offset(12)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        docsIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
        
        userNameLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
        }
        
        titleTagView.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        
        if style == .home {
            contentLabel.snp.makeConstraints { make in
                make.height.equalTo(22)
            }
        }
    }
    
    var data: HomePageData?
    
    private let font = UIFont.systemFont(ofSize: 14)
    
    private func formatText(_ content: String?) -> NSAttributedString? {
        guard let content = content else {
            return nil
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        let yOffset: CGFloat = -5
        return FeedMessageModel.getContentAttrString(content: content, attributes: attributes, atSelfYOffset: yOffset)
    }
    
    func update(data: HomePageData?, delegate: ActivityCellDelegate? = nil) {
        self.data = data
        self.delegate = delegate
        
        if let data = data {
            userNameLabel.hideGradientLoadingView()
            contentLabel.hideGradientLoadingView()
            profileImageView.hideGradientLoadingView()
            
            if let teamMessage = data.teamMessage {
                bottomInfoStackView.isHidden = true
                profileImageView.image = UDIcon.robotFilled.ud.resized(to: CGSize(width: 20, height: 20)).ud.withTintColor(UDColor.primaryContentDefault)
                profileImageView.contentMode = .center
                userNameLabel.text = BundleI18n.SKResource.Bitable_Workspace_BaseTeamGreeting_Title
                contentLabel.attributedText = formatText(style == .home ? teamMessage.content.replace(with: " ", for: "\n") : teamMessage.content)
                titleTagView.isHidden = true
                return
            }
            
            bottomInfoStackView.isHidden = false
            profileImageView.contentMode = .scaleAspectFit
            
            if let noticeInfo = data.noticeInfo, data.messageType == .notice {
                userNameLabel.text = noticeInfo.fromUser?.nameI18n
                if let avatarKey = noticeInfo.fromUser?.avatarKey, let userID = noticeInfo.fromUser?.userID {
                    profileImageView.bt.setLarkImage(with: .avatar(key: avatarKey, entityID: userID, params: .init(sizeType: .middle)))
                } else if let avatarUrl = noticeInfo.fromUser?.avatarUrl {
                    profileImageView.bt.setImage(URL(string: avatarUrl))
                } else {
                    profileImageView.image = nil
                }
                contentLabel.attributedText = formatContent(noticeInfo: noticeInfo, content: noticeInfo.contentModel)
                titleTagView.isHidden = true
            } else if let cardInfo = data.cardInfo, data.messageType == .card {
                if let avatarKey = cardInfo.sender?.avatarKey, let chatID = cardInfo.chatID {
                    profileImageView.bt.setLarkImage(with: .avatar(key: avatarKey, entityID: chatID, params: .init(sizeType: .middle)))
                } else {
                    profileImageView.image = nil
                }
                userNameLabel.text = cardInfo.sender?.name
                titleTagView.isHidden = false
                let contentStr: String
                if let title = cardInfo.contentModel?.title, !title.isEmpty {
                    contentStr = BundleI18n.SKResource.Bitable_Workspace_MessageFromBotWithTitle_Description(title)
                } else {
                    contentStr = BundleI18n.SKResource.Bitable_Workspace_MessageFromBot_Description
                }
                contentLabel.attributedText = formatText(contentStr)
            } else {
                titleTagView.isHidden = true
                userNameLabel.text = nil
                profileImageView.image = nil
            }
            
            if let time = data.noticeInfo?.noticeTime ?? data.cardInfo?.noticeTime {
                timeLabel.text = TimeInterval(Double(time) / 1000).stampDateFormatter
            } else {
                timeLabel.text = ""
            }
            
            let docsName = data.noticeInfo?.docName ?? ""
            let docsNameEmpty = docsName.isEmpty
            dotLabel.isHidden = docsNameEmpty
            docsIconImageView.isHidden = docsNameEmpty
            docsLabel.isHidden = docsNameEmpty
            docsLabel.text = docsName
            
        } else {
            userNameLabel.text = "        "
            contentLabel.text = "                                                        "
            bottomInfoStackView.isHidden = true
            titleTagView.isHidden = true
            profileImageView.image = nil
        }
    }
    
    @objc
    func profileClick() {
        delegate?.profileClick(data: data)
    }
    
    private func formatContent(noticeInfo: HomePageData.NoticeInfo, content: HomePageData.NoticeInfo.Content?) -> NSAttributedString {
        let contentAttrStr = NSMutableAttributedString()
        
        
        let comment_owner_name = content?.commentOwnerNameI18n ?? ""
//        let comment_owner_id = content?.comment_owner_id ?? ""
        
        var reactionAttrString: NSAttributedString?
        var contentStr: String = content?.commentContentForFeedI18n ?? ""
        if let content = content {
            if noticeInfo.noticeType == .BEAR_COMMENT_ADD_REACTION, let reaction_key = content.reaction_key, !reaction_key.isEmpty {
                reactionAttrString = FeedMessageModel.getReactionAttrString(contentReactionKey: reaction_key, targetHeight: font.figmaHeight, yOffset: -5)
            } else if let pictures = content.picturesI18n, !pictures.isEmpty {
                contentStr += pictures.replace(with: "[", for: "&#91;").replace(with: "]", for: "&#93;")
            }
        }
        var name = comment_owner_name
        if comment_owner_name.isEmpty {
            name = noticeInfo.fromUser?.nameI18n ?? ""
        }
        let userName = name.isEmpty ? "" : "<at type=\"0\" href=\"\" token=\"\(name)\">@\(name)</at>"
        
        var targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_ReceiveMessage_mobile
        if noticeInfo.noticeStatus == .NORMAL {
            if noticeInfo.noticeType == .BEAR_COMMNET_ADD_COMMENT {
                targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_comment_mobile(contentStr)
            } else if noticeInfo.noticeType == .BEAR_COMMNET_ADD_REPLY_NOTIFY_UPSTAIRS {
                targetContent = BundleI18n.SKResource.Bitable_Workspace_Common_Notifications_replyComment_mobile(contentStr)
            } else if noticeInfo.noticeType == .BEAR_COMMNET_FINISH_COMMENT {
                targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_ResolveComment_mobile(userName, contentStr)
            } else if noticeInfo.noticeType == .BEAR_COMMNET_REOPEN_COMMENT {
                targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_ReopenComment_mobile(contentStr)
            } else if noticeInfo.noticeType == .BEAR_MENTION_AT_IN_CONTENT {
                let docName = "<at type=\"8\" href=\"\(noticeInfo.linkURL?.absoluteString ?? "")\" token=\"\(noticeInfo.linkURL?.lastPathComponent ?? "")\">\(noticeInfo.docName)</at>"
                targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_mention_mobile(docName)
            } else if noticeInfo.noticeType == .BEAR_COMMENT_ADD_REACTION {
                targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_ReactToYourComment_mobile(contentStr)
            }
        } else if noticeInfo.noticeStatus == .COMMENT_DELETE {
            targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_CommentDeleted_mobile
        } else if noticeInfo.noticeStatus == .COMMENT_FINISH {
            targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_UserCommentResolved_mobile(userName, contentStr)
        } else if noticeInfo.noticeStatus == .COMMENT_REACTION_FINISH {
            targetContent = BundleI18n.SKResource.Bitable_Workspace_emojiReactionResolved_mobile(userName)
        } else if noticeInfo.noticeStatus == .FINISH_TO_REOPEN {
            targetContent = BundleI18n.SKResource.Bitable_Workspace_Notifications_ReopenComment_mobile(contentStr)
        } else if noticeInfo.noticeStatus == .COMMENT_REACTION_DELETE {
            targetContent = BundleI18n.SKResource.Bitable_Workspace_emojiReactionRecalled_mobile
        }
        
        if let targetContentAttrString = formatText(targetContent) {
            contentAttrStr.append(targetContentAttrString)
        }
        if let reactionAttrString = reactionAttrString {
            contentAttrStr.append(NSAttributedString(string: "\n"))
            contentAttrStr.append(reactionAttrString)
        }
        return contentAttrStr
    }
}

