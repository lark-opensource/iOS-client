//
//  ProfileHeaderView.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2017/6/9.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import LarkCore
import LarkUIKit
import LarkTag
import LarkSDKInterface
import LarkBizAvatar
import SnapKit
import LarkSetting
import EENavigator
import Homeric
import LKCommonsTracker
import RichLabel
import UniverseDesignIcon
import UniverseDesignColor
import LarkFocus
import LarkFocusInterface
import UIKit
import LarkContactComponent
import LKCommonsLogging
import LarkContainer

final class ProfileHeaderView: UIView {

    private static let logger = Logger.log(ProfileHeaderView.self, category: "Mine.ProfileHeaderView")
    lazy var avatarImageView: LarkMedalAvatar = {
        let avatar = LarkMedalAvatar(frame: .zero)
        return avatar
    }()

    /// Focus 状态
    lazy var focusView: FocusDisplayView = {
        let view = FocusDisplayView(userResolver: userResolver)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openFocusListController)))
        return view
    }()

    private lazy var infoTapArea: UIView = {
        let view = UIView()
        view.lu.addTapGestureRecognizer(action: #selector(pushInformationController), target: self, touchNumber: 1)
        return view
    }()

    lazy var isUnifiedComponentFG: Bool = userResolver.fg.staticFeatureGatingValue(with: "ios.profile.tenantname.unified_component")
    /// 公司+认证
    lazy var tenantContainerView = TenantContainerView()

    /// “请假中” 状态 tag
    lazy var workStatusLabel: PaddingUILabel = {
        let workStatusLabel = PaddingUILabel()
        workStatusLabel.paddingLeft = 5
        workStatusLabel.paddingRight = 5
        workStatusLabel.lu.addTapGestureRecognizer(action: #selector(deleteWorkStatusLabel), target: self, touchNumber: 1)
        workStatusLabel.textColor = UIColor.ud.colorfulRed
        workStatusLabel.color = UIColor.ud.R100
        workStatusLabel.font = UIFont.systemFont(ofSize: 11)
        workStatusLabel.numberOfLines = 0
        workStatusLabel.layer.cornerRadius = 2
        workStatusLabel.layer.masksToBounds = true
        return workStatusLabel
    }()

    private lazy var nameView: UIView = {
        let nameView = UIView()
        nameView.lu.addTapGestureRecognizer(action: #selector(didClickName), target: self, touchNumber: 1)
        return nameView
    }()

    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 22, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.isUserInteractionEnabled = true
        return nameLabel
    }()

    var tagView: MineTagView?

    lazy var chatterStatusLabel: ChatterStatusLabel = {
        let label = ChatterStatusLabel()
        label.showIfEmpty = true
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.font = UIFont.systemFont(ofSize: 12)
        label.iconColor = UIColor.ud.iconN3
        label.textColor = UIColor.ud.textPlaceholder
        label.backgroundColor = UIColor.ud.bgFloatOverlay
        label.descriptionView.linkAttributes = [.foregroundColor: UIColor.ud.textPlaceholder]
        label.isUserInteractionEnabled = true
        return label
    }()

    var authURL: URL?

    private lazy var myQrcodeIconView: UIImageView = {
        let myQrcodeIconView = UIImageView()
        myQrcodeIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        myQrcodeIconView.image = Resources.my_qrcode.ud.withTintColor(UIColor.ud.iconN3)
        return myQrcodeIconView
    }()
    private var arrowIconView: UIImageView = {
        let arrowIconView = UIImageView()
        arrowIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIconView.image = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)
        return arrowIconView
    }()

    private lazy var qrcodeContainerView: UIView = {
        let view = UIView()
        view.lu.addTapGestureRecognizer(action: #selector(didClickQrcode), target: self)
        return view
    }()

    var deleteBlock: (() -> Void)?
    /// 点击姓名行跳转
    var pushInformation: ((_ click: String, _ clickField: String) -> Void)?
    /// 跳转 Focus 列表
    var openFocusList: ((_ view: FocusDisplayView) -> Void)?
    var tenantNameContainView: LarkTenantNameViewInterface
    var companyContainView: UIView?

    private let userResolver: UserResolver
    init(userResolver: UserResolver, tenantNameService: LarkTenantNameService) {
        self.userResolver = userResolver
        let tenantNameUIConfig = LarkTenantNameUIConfig(
            tenantNameFont: UIFont.systemFont(ofSize: 12),
            tenantNameColor: UIColor.ud.textPlaceholder)
        self.tenantNameContainView = tenantNameService.generateTenantNameView(with: tenantNameUIConfig)
        super.init(frame: .zero)

        if self.isUnifiedComponentFG {
            companyContainView = tenantNameContainView
        } else {
            tenantContainerView.setContentHuggingPriority(.required, for: .vertical)
            tenantContainerView.setContentCompressionResistancePriority(.required, for: .vertical)
            companyContainView = tenantContainerView
        }
        Self.logger.info("isUnifiedComponentFG: \(isUnifiedComponentFG)")
        self.createNewViews()
        guard let companyContainView = companyContainView else {
            return
        }
        /// 请假中
        self.addSubview(workStatusLabel)
        workStatusLabel.snp.makeConstraints { (make) in
            let topOffSet = 6
            make.top.equalTo(companyContainView.snp.bottom).offset(topOffSet)
            make.left.equalTo(companyContainView)
            make.right.lessThanOrEqualToSuperview().offset(-Cons.hMargin)
        }

        /// 工作状态
        self.addSubview(chatterStatusLabel)
        chatterStatusLabel.snp.makeConstraints { (make) in
            let topOffSet = 12
            let bottomOffSet = -16
            make.left.equalTo(Cons.hMargin)
            make.top.equalTo(workStatusLabel.snp.bottom).offset(topOffSet)
            make.height.equalTo(28)
            make.bottom.equalToSuperview().offset(bottomOffSet)
            make.right.equalTo(-Cons.hMargin)
        }
        self.chatterStatusLabel.descriptionView.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(8)
            make.right.equalTo(-6)
        }
    }

    /// 新版界面：勿扰按钮 头像 名称+icon 租户名
    private func createNewViews() {
        /// 需要先加这个view，否则头像、名字等的点击事件会被覆盖
        addSubview(infoTapArea)
        /// 头像
        addSubview(avatarImageView)
        avatarImageView.onTapped = { [weak self] _ in
            self?.didClickAvatar()
        }
        avatarImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Cons.avatarSize)
            make.left.equalTo(Cons.hMargin)
            make.top.equalToSuperview()
        }

        /// 用来做点击事件
        addSubview(nameView)
        nameView.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.bottom).offset(4)
            make.leading.equalTo(Cons.hMargin)
            make.height.equalTo(Layout.nameHeight)
            make.right.equalTo(-Layout.nameViewRight)
        }

        /// 用户名
        nameView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.right.centerY.equalToSuperview()
        }
        guard let companyContainView = companyContainView else {
            return
        }
        /// 租户名容器
        addSubview(companyContainView)
        addSubview(qrcodeContainerView)
        companyContainView.lu.addTapGestureRecognizer(action: #selector(didClickTenant), target: self, touchNumber: 1)
        companyContainView.snp.makeConstraints { (make) in
            make.top.equalTo(nameView.snp.bottom)
            make.left.equalTo(nameLabel)
            make.right.equalTo(qrcodeContainerView)
            make.height.greaterThanOrEqualTo(20)
        }

        /// 我的二维码入口
        qrcodeContainerView.snp.makeConstraints { (make) in
            make.left.equalTo(nameView.snp.right)
            make.right.equalTo(-Layout.qrcodeContainerRight)
            make.height.equalTo(Layout.nameHeight)
            make.centerY.equalTo(nameView.snp.centerY)
        }

        qrcodeContainerView.addSubview(arrowIconView)
        arrowIconView.snp.makeConstraints { (make) in
            make.trailing.centerY.equalToSuperview()
            make.size.equalTo(Layout.profileArrowSize)
        }

        let enableQrcodeEntry = userResolver.fg.staticFeatureGatingValue(with: .contactOptForUI)
        if enableQrcodeEntry {
            qrcodeContainerView.addSubview(myQrcodeIconView)
            myQrcodeIconView.snp.makeConstraints { (make) in
                make.size.equalTo(Layout.qrcodeIconSize)
                make.centerY.equalToSuperview()
                make.trailing.equalTo(arrowIconView.snp.leading).offset(-Layout.qrcodeRightMargin)
            }
        }

        infoTapArea.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(companyContainView)
        }

        addSubview(focusView)
        focusView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.top.equalToSuperview().offset(6)
            make.left.greaterThanOrEqualTo(avatarImageView.snp.right).offset(Cons.hMargin)
        }

        // 根据 FG 判断是否展示个人状态入口
        focusView.isHidden = false
    }

    /// 设置当前的自定义状态（FocusStatus）
    func setFocusStatus(_ statusList: [ChatterFocusStatus]) {
        debugPrint("FLAG: Custom status push \(statusList.topActive)")
        focusView.configure(with: statusList, isEditable: true)
    }

    /// 设置当前是否在精简模式
    func setLeanModeStatus(status: Bool) {
        if status {
            avatarImageView.avatar.layer.borderWidth = 3
            avatarImageView.avatar.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
        } else {
            avatarImageView.avatar.layer.borderColor = nil
            avatarImageView.avatar.layer.borderWidth = 0
        }
    }

    func setName(_ name: String?, chatID: String, avatarKey: String, medalKey: String) {
        self.nameLabel.text = name
        self.avatarImageView.setAvatarByIdentifier(chatID,
                                           avatarKey: avatarKey,
                                           medalKey: medalKey,
                                           medalFsUnit: "",
                                           scene: .Detail,
                                           avatarViewParams: .init(sizeType: .size(Cons.avatarSize)),
                                           backgroundColorWhenError: UIColor.ud.textPlaceholder)
    }

    func setTenatLabel(tenantName: String,
                       authUrlString: String,
                       hasAuth: Bool,
                       isAuth: Bool) {
        guard let companyContainView = companyContainView else {
            return
        }
        if let tenantContainerView = companyContainView as? TenantContainerView {
            tenantContainerView.configUI(tenantName: tenantName,
                                              authUrlString: authUrlString,
                                              hasAuth: hasAuth,
                                              isAuth: isAuth)
        } else if let tenantContainerView = companyContainView as? LarkTenantNameViewInterface {
            tenantContainerView.config(tenantName: tenantName,
                                       authUrlString: authUrlString,
                                       hasShowTenantCertification: hasAuth,
                                       isTenantCertification: isAuth,
                                       tapCallback: nil)
            tenantContainerView.snp.remakeConstraints { (make) in
                make.top.equalTo(nameView.snp.bottom)
                make.left.equalTo(nameLabel)
                make.right.equalTo(qrcodeContainerView)
                make.height.greaterThanOrEqualTo(20)
            }
            self.layoutIfNeeded()
        }
    }

    func set(description: NSAttributedString, descriptionType: Chatter.DescriptionType, urlRangeMap: [NSRange: URL], textUrlRangeMap: [NSRange: String]) {
        self.chatterStatusLabel.set(description: description, descriptionType: descriptionType, urlRangeMap: urlRangeMap, textUrlRangeMap: textUrlRangeMap, showIcon: false)
        self.chatterStatusLabel.descriptionView.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(8)
            make.right.equalTo(-6)
        }
    }

    func setWorkStatus(_ workStatus: WorkStatus, deleteBlock: (() -> Void)?) {
        self.deleteBlock = deleteBlock
        if workStatus.hasStatus {
            let startTime = transformData(timeStamp: workStatus.startTime)
            let endTime = transformData(timeStamp: workStatus.endTime)
            if startTime == endTime {
                self.workStatusLabel.text = String(format: BundleI18n.LarkMine.Lark_Legacy_MineMainWorkdayTimeOneday, startTime)
            } else {
                self.workStatusLabel.text = String(format: BundleI18n.LarkMine.Lark_Legacy_MineMainWorkdayTime, startTime, endTime)
            }
            self.workStatusLabel.isHidden = false
        } else {
            self.workStatusLabel.isHidden = true
        }

        guard let companyContainView = companyContainView else {
            return
        }
        self.chatterStatusLabel.snp.remakeConstraints { (make) in
            let topOffSet = 12
            let bottomOffSet = -16
            if !self.workStatusLabel.isHidden {
                make.top.equalTo(workStatusLabel.snp.bottom).offset(topOffSet)
            } else {
                make.top.equalTo(companyContainView.snp.bottom).offset(topOffSet)
            }
            make.left.equalTo(Cons.hMargin)
            make.height.equalTo(28)
            make.bottom.equalToSuperview().offset(bottomOffSet)
            make.right.equalTo(-Cons.hMargin)
        }
    }

    private func transformData(timeStamp: Int64) -> String {
        let timeMatter = DateFormatter()
        timeMatter.dateFormat = "MM/dd"

        let timeInterval: TimeInterval = TimeInterval(timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)

        return timeMatter.string(from: date)
    }

    @objc
    func deleteWorkStatusLabel() {
        self.deleteBlock?()
    }

    @objc
    func pushInformationController() {
        self.pushInformation?("", "other_area")
    }

    @objc
    func didClickAvatar() {
        self.pushInformation?("", "avatar")
    }

    @objc
    func didClickName() {
        self.pushInformation?("", "name")
    }

    @objc
    func didClickTenant() {
        self.pushInformation?("certification", "company")
    }

    @objc
    func didClickQrcode() {
        self.pushInformation?("", "personal_link")
    }

    @objc
    func openFocusListController() {
        self.openFocusList?(focusView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProfileHeaderView {
    enum Layout {
        static let nameViewRight: CGFloat = 70
        static let nameHeight: CGFloat = 30
        static let qrcodeIconSize: CGSize = CGSize(width: 20, height: 20)
        static let qrcodeContainerRight: CGFloat = 16
        static let qrcodeRightMargin: CGFloat = 4
        static let profileArrowSize: CGSize = CGSize(width: 16, height: 16)
    }
}

// 包含租户名称和认知标识的容器view
final class TenantContainerView: UIView {
    var authURL: URL?
    var isAuth: Bool = false
    var isShowTagView: Bool = false
     var tenantLabel: LKLabel = {
         return LKLabel()
    }()

    var tagView: MineTagView = {
        let tagView = MineTagView()
        return tagView
    }()
    var openUrlBlock: ((URL) -> Void)?

    init() {
        super.init(frame: .zero)
        setupTenantLable(label: tenantLabel)
        self.addSubview(tenantLabel)
        tenantLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        self.addSubview(tagView)
        tagView.snp.makeConstraints { (make) in
            make.width.height.equalTo(0)
        }
    }
    private func setupTenantLable(label: LKLabel) {
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 200
        label.backgroundColor = .clear
        label.outOfRangeText = NSAttributedString(string: "...")
        label.lineSpacing = 5
        label.textVerticalAlignment = .bottom
        label.font = UIFont.systemFont(ofSize: 12)
        label.delegate = self
    }

    func configUI(tenantName: String,
                  authUrlString: String,
                  hasAuth: Bool,
                  isAuth: Bool) {
        self.isShowTagView = hasAuth
        let attributedText = NSMutableAttributedString(string: tenantName,
                                                       attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
        if hasAuth {
            let text = isAuth ? BundleI18n.LarkMine.Lark_FeishuCertif_Verif : BundleI18n.LarkMine.Lark_FeishuCertif_Unverif
            let font = UIFont.systemFont(ofSize: 12)
            let icon = isAuth ? Resources.auth_tag : nil
            let backgroundColor = isAuth ? UIColor.ud.udtokenTagBgTurquoise : UIColor.ud.udtokenTagNeutralBgNormal
            let textColor = isAuth ? UIColor.ud.udtokenTagTextSTurquoise : UIColor.ud.textCaption
            let attributedString = NSAttributedString(string: text,
                                                      attributes: [.foregroundColor: textColor,
                                                                   .font: font
                                                      ])
            tagView.configUI(backgroundColor: backgroundColor,
                             icon: icon,
                             font: font,
                             attributedString: attributedString)
            let attachmentStr = structAttachment(icon: icon,
                                                 font: font,
                                                 backgroundColor: backgroundColor,
                                                 attributedString: attributedString)
            if let url = URL(string: authUrlString) {
                self.authURL = url
                self.isAuth = isAuth
            }
            attributedText.append(attachmentStr)
        }
        self.tenantLabel.attributedText = attributedText
    }

    private var currentWidth: CGFloat = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        // RichLabel在更新宽度时渲染有问题，重新构建一个label实例来解决
        if currentWidth == bounds.width { return }
        currentWidth = bounds.width
        let attrStr = tenantLabel.attributedText
        let label = LKLabel()
        setupTenantLable(label: label)
        addSubview(label)
        label.snp.makeConstraints {
           $0.edges.equalTo(UIEdgeInsets.zero)
        }
        tenantLabel.removeFromSuperview()
        tenantLabel = label
        tenantLabel.preferredMaxLayoutWidth = bounds.width
        tenantLabel.attributedText = attrStr
    }

    private func structAttachment(icon: UIImage?,
                                  font: UIFont,
                                  backgroundColor: UIColor,
                                  attributedString: NSAttributedString) -> NSAttributedString {
        let tagView = createProfileTagView(icon: icon,
                                           font: font,
                                           backgroundColor: backgroundColor,
                                           attributedString: attributedString)
        let attachment = LKAttachment(view: tagView)
        attachment.margin = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
        attachment.fontAscent = font.ascender
        attachment.fontDescent = font.descender
        attachment.verticalAlignment = .middle
        let attachmentStr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                               attributes: [LKAttachmentAttributeName: attachment,
                                                            .foregroundColor: UIColor.ud.N00
                                               ])
        return attachmentStr
    }

    private func createProfileTagView(icon: UIImage?,
                                      font: UIFont,
                                      backgroundColor: UIColor,
                                      attributedString: NSAttributedString) -> MineTagView {
        let tagView = MineTagView()
        tagView.configUI(backgroundColor: backgroundColor,
                         icon: icon,
                         font: font,
                         attributedString: attributedString)
        tagView.frame = CGRect(x: 5, y: 0, width: tagView.getSize().width, height: tagView.getSize().height)
        return tagView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDisplayTagView() {
        let size = tagView.getSize()
        tenantLabel.snp.remakeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        tagView.setContentHuggingPriority(.required, for: .vertical)
        tagView.setContentCompressionResistancePriority(.required, for: .vertical)
        tagView.snp.remakeConstraints { (make) in
            make.left.equalTo(tenantLabel.snp.left)
            make.top.equalTo(tenantLabel.snp.bottom).offset(5)
            make.height.equalTo(size.height).priority(.required)
            make.width.equalTo(size.width)
            make.bottom.equalToSuperview()
        }
    }
}

extension TenantContainerView: LKLabelDelegate {

    public func shouldShowMore(_ label: RichLabel.LKLabel, isShowMore: Bool) {
        guard isShowMore, self.isShowTagView else {
            tagView.snp.remakeConstraints {
                $0.width.height.equalTo(0)
            }
            return
        }
        self.setDisplayTagView()
    }
}

private extension ProfileHeaderView {

    enum Cons {
        static var hMargin: CGFloat { 16 }
        static var avatarSize: CGFloat { 68 }
    }
}

// mine页专用tagView
final class MineTagView: UIView {
    lazy var iconView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        return label
    }()

    init() {
        super.init(frame: .zero)
        self.layer.cornerRadius = 4.0
        self.layer.masksToBounds = true
        self.addSubview(label)
        self.addSubview(iconView)
    }

    func configUI(backgroundColor: UIColor,
                  icon: UIImage?,
                  font: UIFont,
                  attributedString: NSAttributedString) {
        let isShowIcon = icon != nil
        self.backgroundColor = backgroundColor
        if isShowIcon {
            iconView.frame = CGRect(x: 4, y: 3, width: 12, height: 12)
        }
        if let icon = icon {
            iconView.image = icon
        }
        let width = (attributedString.string  as NSString).boundingRect(
            with: CGSize(width: Int.max, height: 20),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil).width
        label.frame = CGRect(x: iconView.frame.maxX + (isShowIcon ? 2 : 4), y: 0, width: width, height: 18)
        label.attributedText = attributedString
    }

    func getSize() -> CGSize {
        return CGSize(width: label.frame.maxX + 4, height: 18)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
