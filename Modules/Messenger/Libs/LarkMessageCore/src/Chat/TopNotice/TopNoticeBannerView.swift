//
//  TopNoticeBannerView.swift
//  LarkMessageCore
//
//  Created by liluobin on 2021/11/3.
//
import Foundation
import UIKit
import SnapKit
import FigmaKit
import RichLabel
import UniverseDesignColor
import UniverseDesignShadow
import ByteWebImage
import LKCommonsLogging
import LarkContainer
import LarkMessengerInterface
import LarkModel

public final class TopNoticeImageVideoView: TopNoticeBaseBannerView, MessageDynamicAuthorityDelegate {
    static let logger = Logger.log(TopNoticeImageVideoView.self, category: "TopNoticeImageVideoView")

    private let messageDynamicAuthorityService: MessageDynamicAuthorityService?

    init(messageDynamicAuthorityService: MessageDynamicAuthorityService?) {
        self.messageDynamicAuthorityService = messageDynamicAuthorityService
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var imageView: ByteImageView = {
        let imageV = ByteImageView()
        imageV.contentMode = .scaleAspectFill
        imageV.layer.cornerRadius = 6
        imageV.clipsToBounds = true
        imageV.backgroundColor = UIColor.clear
        imageV.autoPlayAnimatedImage = true
        return imageV
    }()

    lazy var videoIcon: UIImageView = {
        let imageV = UIImageView()
        imageV.image = BundleResources.video_play
        return imageV
    }()

    private lazy var noPermissionPreviewLayerView: NoPermissonPreviewSmallLayerView = {
        let view = NoPermissonPreviewSmallLayerView()
        view.tapAction = { [weak self] _ in
            guard let self = self,
                  let window = self.window,
                  let model = self.model else { return }
            if !(self.messageDynamicAuthorityService?.dynamicAuthorityEnum.authorityAllowed ?? true) {
                model.chatSecurityControlService?.alertForDynamicAuthority(event: .receive,
                                                                           result: self.messageDynamicAuthorityService?.dynamicAuthorityEnum ?? .allow,
                                                                           from: window)
                return
            }
            if !model.permissionPreview.0 {
                var event: SecurityControlEvent = .localImagePreview
                switch model.type {
                case .key(_, let isVideo, _, _):
                    if isVideo {
                        event = .localVideoPreview
                    }
                default:
                    break
                }
                model.chatSecurityControlService?.authorityErrorHandler(event: event,
                                                                       authResult: model.permissionPreview.1,
                                                                       from: window, errorMessage: nil, forceToAlert: true)
            }
        }
        return view
    }()
    private func showNoPermissionPreviewLayer() {
        if noPermissionPreviewLayerView.superview == nil {
            self.addSubview(noPermissionPreviewLayerView)
            noPermissionPreviewLayerView.snp.makeConstraints({ make in
                make.left.equalToSuperview().offset(48)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 40, height: 40))
            })
        }
        noPermissionPreviewLayerView.isHidden = false
    }
    private func hideNoPermissionPreviewLayer() {
        noPermissionPreviewLayerView.isHidden = true
    }

    override func setupView() {
        super.setupView()
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(iconViewSize)
            make.left.equalToSuperview().offset(20)
            make.centerY.equalTo(self.titleLabel)
        }
        addSubview(imageView)
        imageView.addSubview(videoIcon)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(48)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        titleLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(96)
        }
        videoIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
    }

    override func onModelChanged() {
        self.messageDynamicAuthorityService?.delegate = self
        super.onModelChanged()
    }

    override func updateUI() {
        super.updateUI()
        guard let model = model else {
            return
        }
        videoIcon.isHidden = true
        switch model.type {
        case .key(let imagekey, let isVideo, _, _):
            if !(model.permissionPreview.0 && self.messageDynamicAuthorityService?.dynamicAuthorityEnum.authorityAllowed ?? true) {
                showNoPermissionPreviewLayer()
            } else {
                hideNoPermissionPreviewLayer()
                videoIcon.isHidden = !isVideo
                imageView.bt.setLarkImage(with: .default(key: imagekey), placeholder: model.placeholderImage, completion: { result in
                    if case .failure(let error) = result {
                        Self.logger.error("Image loading failed", error: error)
                    }
                })
            }
        case .sticker(let key, let stickerSetID):
            imageView.bt.setLarkImage(with: .sticker(key: key, stickerSetID: stickerSetID),
                                      placeholder: model.placeholderImage,
                                      completion: { result in
                if case .failure(let error) = result {
                    Self.logger.error("加载sticker失败", error: error)
                }
            })
        default:
            break
        }
    }

    // MARK: MessageDynamicAuthorityDelegate
    public var needAuthority: Bool {
        guard let model = self.model else { return false }
        switch model.type {
        case .key:
            return true
        default:
            return false
        }
    }
    public var authorityMessage: Message? {
        guard let model = self.model else { return nil }
        switch model.type {
        case .key(_, _, let authorityMessage, _):
            return authorityMessage
        default:
            return nil
        }
    }
    public func updateUIWhenAuthorityChanged() {
        self.updateUI()
    }
}

public final class TopNoticeTextView: TopNoticeBaseBannerView {

    override func setupView() {
        super.setupView()
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(iconViewSize)
            make.left.equalToSuperview().offset(20)
            make.centerY.equalTo(self.titleLabel)
        }
    }
}

public class TopNoticeBaseBannerView: UIView {

    public var model: TopNoticeBannerModel? {
        didSet {
            onModelChanged()
        }
    }

    let iconBackColor = UIColor.ud.colorfulOrange
    let iconViewSize: CGFloat = 20
    lazy var iconView: UIImageView = {
        let imageV = UIImageView()
        imageV.backgroundColor = iconBackColor
        imageV.image = Resources.topNotice_arrow
        imageV.contentMode = .center
        imageV.layer.cornerRadius = iconViewSize / 2
        return imageV
    }()

    lazy var titleLabel: LKLabel = {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        let label = LKLabel(frame: .zero)
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = UIColor.clear
        label.outOfRangeText = outOfRangeText
        label.autoDetectLinks = false
        return label
    }()

    lazy var fromLabel: LKLabel = {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textCaption,
            .font: UIFont.systemFont(ofSize: 12)
        ]
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: attributes)
        let label = LKLabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.backgroundColor = UIColor.clear
        label.outOfRangeText = outOfRangeText
        label.isUserInteractionEnabled = true
        return label
    }()

    lazy var bgView: UIView = {
        let backGroudView = UIView()
        backGroudView.backgroundColor = UIColor.ud.bgFloat
        backGroudView.layer.cornerRadius = 12
        backGroudView.layer.borderWidth = 0.5
        backGroudView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent, bindTo: self)
        backGroudView.clipsToBounds = true
        return backGroudView
    }()

    lazy var shadowView: UIView = {
        let view = UIView()
        view.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        view.layer.backgroundColor = UIColor.clear.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowRadius = 6
        view.layer.cornerRadius = 8
        view.clipsToBounds = false
        view.isUserInteractionEnabled = false
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        return view
    }()

    lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(Resources.close_topNotice_icon, for: .normal)
        btn.setImage(Resources.close_topNotice_icon, for: .highlighted)
        btn.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        return btn
    }()

    lazy var contentTapView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
        view.addGestureRecognizer(tap)
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        backgroundColor = UIColor.clear
        addSubview(contentTapView)
        addSubview(shadowView)
        shadowView.addSubview(bgView)
        addSubview(titleLabel)
        addSubview(fromLabel)
        addSubview(closeBtn)
        shadowView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-6)
            make.height.equalTo(60)
        }

        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentTapView.snp.makeConstraints { make in
            make.edges.equalTo(bgView)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(48)
            make.right.equalTo(closeBtn.snp.left).offset(-16)
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(22)
        }

        fromLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.height.equalTo(18)
            make.right.equalTo(closeBtn.snp.left).offset(-9)
            make.bottom.equalToSuperview().offset(-16)
        }

        /// 这里按钮要比图片大些 方便点击
        closeBtn.snp.makeConstraints { make in
            make.centerY.equalTo(contentTapView)
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    }

    func onModelChanged() {
        updateUI()
    }

    func updateUI() {
        guard let model = model else {
            return
        }
        titleLabel.attributedText = model.title
        updateFromLabelAttributeStringWithUserName(model.name)
    }

    @objc
    func btnClick(_ sender: UIButton) {
        self.model?.closeCallBack?(sender)
    }

    @objc
    func tapView() {
        self.model?.tapCallBack?()
    }

    func tapFromLabel() {
        self.model?.fromUserClick?(self.model?.fromChatter)
    }

    /// 获取attributeString
    func updateFromLabelAttributeStringWithUserName(_ name: String) {
        let text = BundleI18n.LarkMessageCore.__Lark_IMChatPin_UserPinnnedClickable_Text as NSString
        let startRange = text.range(of: "{{name}}")
        let paragraphStyle = NSMutableParagraphStyle()
        /// 设置富文本的内容以字符进行分割，防止内容中大量字母数字被解析成word过长而被省略，导致无法展示
        // swiftlint:disable ban_linebreak_byChar
        paragraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textCaption,
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]
        /// 如果匹配不到{{name}},使用降级策略
        if startRange.location == NSNotFound {
            self.fromLabel.attributedText = NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_IMChatPin_UserPinnnedClickable_Text(name),
                                      attributes: attributes)
            return
        }
        let muAttr = NSMutableAttributedString(string: BundleI18n.LarkMessageCore.Lark_IMChatPin_UserPinnnedClickable_Text(name),
                                               attributes: attributes)
        self.fromLabel.attributedText = nil
        self.fromLabel.removeLKTextLink()
        let nameRange = NSRange(location: startRange.location, length: (name as NSString).length)
        muAttr.addAttributes([.foregroundColor: UIColor.ud.textLinkNormal], range: nameRange)
        var link = LKTextLink(range: nameRange,
                              type: .link,
                              attributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                           .paragraphStyle: paragraphStyle],
                              activeAttributes: [.foregroundColor: UIColor.ud.textLinkNormal,
                                                 .paragraphStyle: paragraphStyle])
        link.linkTapBlock = { [weak self] (_, _) in
            self?.tapFromLabel()
        }
        self.fromLabel.addLKTextLink(link: link)
        self.fromLabel.attributedText = muAttr
    }
}
