//
//  LarkTenantNameView.swift
//  LarkContactComponent
//
//  Created by ByteDance on 2023/3/22.
//

import Foundation
import UIKit
import RustPB
import SnapKit
import RichLabel
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTag

public class LarkTenantNameView: UIStackView, LarkTenantNameViewInterface {
    
    public let uiConfig: LarkTenantNameUIConfig
    var isShowTagView: Bool = false
    var tapCallback: (() -> Void)?
    var tagViewSize: CGSize?
    let tagViewDefaultSize = CGSizeMake(0, 0)

    lazy var textLabel: LKLabel = {
        let label = LKLabel()
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle, .font: UIFont.systemFont(ofSize: 12)]
        label.numberOfLines = 2
        label.backgroundColor = .clear
        label.outOfRangeText = NSAttributedString(string: "...", attributes: attributes)
        label.textVerticalAlignment = .bottom
        return label
    }()

    lazy var tagView: UDTag = {
        let tagView = UDTag(frame: .zero)
        return tagView
    }()

    lazy var newlineWrapper: UIView = {
        let newlineWrapper = UIView()
        newlineWrapper.isHidden = true
        return newlineWrapper
    }()

    public init(uiConfig: LarkTenantNameUIConfig) {
        self.uiConfig = uiConfig
        super.init(frame: .zero)

        setupView()
        if self.uiConfig.isSupportAuthClick {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tagViewOnTapped))
            textLabel.addGestureRecognizer(tapGesture)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        if uiConfig.isOnlySingleLineDisplayed {
            addSubview(textLabel)
            textLabel.snp.makeConstraints { (make) in
                make.left.top.bottom.right.equalToSuperview()
            }
            textLabel.numberOfLines = 1
        } else {
            axis = .vertical
            addArrangedSubview(textLabel)
            addArrangedSubview(newlineWrapper)
            textLabel.numberOfLines = 2
        }
        if uiConfig.isShowCompanyAuth {
            addSubview(tagView)
        }
        textLabel.delegate = self
    }

    /// 配置数据
    /// - Parameter tenantInfo: 租户信息
    public func config(tenantInfo: LarkTenantInfo) -> (tenantName: String, hasShowCompanyAuth: Bool) {
        let tenantName = fetchSecurityTenantName(tenantInfo: tenantInfo)
        let hasShowTenantCertification = fetchWhetherShowCompanyAuth(tenantInfo: tenantInfo, tenantName: tenantName)
        configTenantName(tenantName: tenantName, tapCallback: tenantInfo.tapCallback)
        guard self.uiConfig.isShowCompanyAuth,
                hasShowTenantCertification,
                let certificationInfo = tenantInfo.certificationInfo else {
            updateTenantNameDisplay(hasShowTenantCertification: false)
            return (tenantName, false)
        }
        updateTenantNameDisplay(hasShowTenantCertification: true)
        isShowTagView = hasShowTenantCertification
        let isTenantCertification = (certificationInfo.certificateStatus == .certificated)
        setCompanyAuth(tenantName: tenantName, isTenantCertification: isTenantCertification)
        return (tenantName, hasShowTenantCertification)
    }
    
    /// 配置数据
    public func config(tenantName: String,
                       authUrlString: String,
                       hasShowTenantCertification: Bool,
                       isTenantCertification: Bool,
                       tapCallback: (() -> Void)?) {
        configTenantName(tenantName: tenantName, tapCallback: tapCallback)
        guard self.uiConfig.isShowCompanyAuth,
                hasShowTenantCertification else {
            updateTenantNameDisplay(hasShowTenantCertification: false)
            return
        }
        updateTenantNameDisplay(hasShowTenantCertification: true)
        isShowTagView = hasShowTenantCertification
        setCompanyAuth(tenantName: tenantName, isTenantCertification: isTenantCertification)
    }
    
    /// 数据转换 V1 -> V2
    public func transFormCertificationInfo(v1CertificationInfo: V1CertificationInfo) -> V2CertificationInfo {
        var certificationInfo: V2CertificationInfo = V2CertificationInfo()
        certificationInfo.isShowCertSign = v1CertificationInfo.isShowCertSign
        var certificateStatus = RustPB.Contact_V2_GetUserProfileResponse.UserInfo.CertificateStatus()
        switch v1CertificationInfo.certificateStatus {
        case .uncertificated:
            certificateStatus = .uncertificated
        case .certificated:
            certificateStatus = .certificated
        case .expired:
            certificateStatus = .expired
        case .teamCertificated:
            certificateStatus = .teamCertificated
        @unknown default:
            certificateStatus = .uncertificated
        }
        certificationInfo.certificateStatus = certificateStatus
        certificationInfo.tenantCertificationURL = v1CertificationInfo.tenantCertificationURL
        return certificationInfo
    }

    /// 数据转换basicV1 -> V2
    public func transFormCertificationInfo(basicV1CertificationInfo: BasicV1CertificationInfo) -> V2CertificationInfo {
        var certificationInfo: V2CertificationInfo = V2CertificationInfo()
        certificationInfo.isShowCertSign = basicV1CertificationInfo.isShowCertSign
        var certificateStatus = RustPB.Contact_V2_GetUserProfileResponse.UserInfo.CertificateStatus()
        switch basicV1CertificationInfo.certificateStatus {
        case .uncertificated:
            certificateStatus = .uncertificated
        case .certificated:
            certificateStatus = .certificated
        case .expired:
            certificateStatus = .expired
        case .teamCertificated:
            certificateStatus = .teamCertificated
        @unknown default:
            certificateStatus = .uncertificated
        }
        certificationInfo.certificateStatus = certificateStatus
        return certificationInfo
    }

    private func configTenantName(tenantName: String,
                                  tapCallback: (() -> Void)?) {
        let attrTenantName = structTenantAttrName(tenantName: tenantName)
        self.textLabel.attributedText = attrTenantName
        if self.uiConfig.isSupportAuthClick {
            self.textLabel.tapableRangeList = [NSRange(location: 0, length: tenantName.count)]
            self.tapCallback = tapCallback
        }
    }

    private func updateTenantNameDisplay(hasShowTenantCertification: Bool) {
        tagView.isHidden = !hasShowTenantCertification
        guard uiConfig.isOnlySingleLineDisplayed else {
            return
        }
        if hasShowTenantCertification {
            textLabel.snp.remakeConstraints { (make) in
                make.left.top.bottom.equalToSuperview()
            }
        } else {
            textLabel.snp.remakeConstraints { (make) in
                make.left.top.bottom.right.equalToSuperview()
            }
        }
    }

    /// 私有方法-配置数据
    private func setCompanyAuth(tenantName: String, isTenantCertification: Bool) {
        let attributedText = structTenantAttrName(tenantName: tenantName)
        configAuthTagView(isTenantCertification: isTenantCertification)
        if uiConfig.isOnlySingleLineDisplayed {
            let tagViewSize = self.tagViewSize ?? self.tagViewDefaultSize
            tagView.snp.remakeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalTo(textLabel.snp.right).offset(Cons.authLeftPadding)
                make.width.equalTo(tagViewSize.width)
                make.right.lessThanOrEqualToSuperview()
            }
            self.textLabel.attributedText = attributedText
        } else {
            let attachmentStr = structAttachment(tagView: tagView)
            attributedText.append(attachmentStr)
            self.textLabel.attributedText = attributedText
        }
    }

    /// 私有方法-配置认证信息
    private func configAuthTagView(isTenantCertification: Bool) {
        let text = isTenantCertification ? BundleI18n.LarkContactComponent.Lark_FeishuCertif_Verif : BundleI18n.LarkContactComponent.Lark_FeishuCertif_Unverif
        let icon = isTenantCertification ? UDIcon.verifyFilled.ud.withTintColor(UIColor.ud.udtokenTagTextSTurquoise) : nil
        let backgroundColor = isTenantCertification ? UIColor.ud.udtokenTagBgTurquoise : UIColor.ud.udtokenTagNeutralBgNormal
        let textColor = isTenantCertification ? UIColor.ud.udtokenTagTextSTurquoise : UIColor.ud.textCaption
        let config = UDTag.Configuration(
            icon: icon,
            text: text,
            height: Cons.authHeight,
            backgroundColor: backgroundColor,
            cornerRadius: Cons.authCornerRadius,
            horizontalMargin: Cons.authIconTextSpacing,
            iconTextSpacing: Cons.authHMargin,
            textAlignment: .center,
            textColor: textColor,
            iconSize: Cons.authIconSize,
            iconColor: nil,
            font: Cons.authTextFont
        )
        tagView.updateConfiguration(config)
        let tagViewSize = UDTag.sizeToFit(configuration: config)
        tagView.frame.size = tagViewSize
        self.tagViewSize = tagViewSize
    }

    func structTenantAttrName(tenantName: String) -> NSMutableAttributedString {
        let attributedText = NSMutableAttributedString(
            string: tenantName,
            attributes: [
                .foregroundColor: uiConfig.tenantNameColor,
                .font: uiConfig.tenantNameFont
            ]
        )
        return attributedText
    }

    private func structAttachment(tagView: UIView) -> NSAttributedString {
        let attachment = LKAttachment(view: tagView)
        attachment.margin = UIEdgeInsets(top: 0, left: Cons.authLeftPadding, bottom: 0, right: -Cons.authLeftPadding)
        attachment.fontAscent = Cons.authTextFont.ascender
        attachment.fontDescent = Cons.authTextFont.descender
        attachment.verticalAlignment = .middle
        let attachmentStr = NSAttributedString(
            string: LKLabelAttachmentPlaceHolderStr,
            attributes: [
                LKAttachmentAttributeName: attachment
            ]
        )
        return attachmentStr
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.preferredMaxLayoutWidth = getTenantNamePreferredMaxLayoutWidth()
        textLabel.invalidateIntrinsicContentSize()
    }

    func getTenantNamePreferredMaxLayoutWidth() -> CGFloat {
        let tagViewSize = self.tagViewSize ?? self.tagViewDefaultSize
        let tagWidth: CGFloat = tagView.isHidden ? 0 : tagViewSize.width
        let singleLineWidth = bounds.width - tagWidth - Cons.authLeftPadding
        let preferredMaxLayoutWidth = self.uiConfig.isOnlySingleLineDisplayed ? singleLineWidth : bounds.width
        return preferredMaxLayoutWidth
    }

    func adjustCustomViewPosition(newLine: Bool) {
        if newLine {
            newlineWrapper.isHidden = false
            tagView.removeFromSuperview()
            newlineWrapper.addSubview(tagView)
            let tagViewSize = self.tagViewSize ?? self.tagViewDefaultSize
            tagView.snp.remakeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
                make.size.equalTo(tagViewSize)
            }
        } else {
            newlineWrapper.isHidden = true
        }
    }
    
    @objc
    func tagViewOnTapped() {
        self.tapCallback?()
    }
    
    public func fetchSecurityTenantName(tenantInfo: LarkTenantInfo) -> String {
        switch tenantInfo.tenantNameStatus {
        case .visible:
            return tenantInfo.tenantName
        case .notFriend:
            return tenantInfo.isFriend ? tenantInfo.tenantName : BundleI18n.LarkContactComponent.Lark_IM_Profile_AddAsExternalContactToViewOrgInfo_Placeholder
        case .hide:
            return BundleI18n.LarkContactComponent.Lark_IM_Profile_UserHideOrgInfo_Placeholder
        case .unknown:
            break
        @unknown default:
            break
        }
        return tenantInfo.tenantName
    }

    private func fetchWhetherShowCompanyAuth(tenantInfo: LarkTenantInfo, tenantName: String? = nil) -> Bool {
        let tenantName = tenantName ?? fetchSecurityTenantName(tenantInfo: tenantInfo)
        let isTenantNameStatusLegal = checkTenantNameStatus(isFriend: tenantInfo.isFriend, tenantNameStatus: tenantInfo.tenantNameStatus)
        guard !tenantName.isEmpty,
              isTenantNameStatusLegal,
                let certificationInfo = tenantInfo.certificationInfo,
                certificationInfo.isShowCertSign,
                certificationInfo.certificateStatus != .teamCertificated else { return false }
        return true
    }

    func checkTenantNameStatus(isFriend: Bool,
                               tenantNameStatus: RustPB.Basic_V1_TenantNameStatus) -> Bool {
        switch tenantNameStatus {
        case .visible:
            return true
        case .notFriend:
            return isFriend ? true : false
        case .hide:
            return false
        case .unknown:
            break
        @unknown default:
            break
        }
        return true
    }
}

extension LarkTenantNameView: LKLabelDelegate {

    func attributedLabel(_ label: LKLabel,
                         index: Int,
                         didSelectText text: String,
                         didSelectRange range: NSRange) -> Bool {
        return true
    }

    public func shouldShowMore(_ label: RichLabel.LKLabel, isShowMore: Bool) {
        guard isShowTagView, !uiConfig.isOnlySingleLineDisplayed, uiConfig.isShowCompanyAuth else { return }
        self.adjustCustomViewPosition(newLine: isShowMore)
    }
}

extension LarkTenantNameView {
    enum Cons {
        static var authLeftPadding: CGFloat { 6 }
        static var authIconTextSpacing: CGFloat { 4 }
        static var authHMargin: CGFloat { 2 }
        static var authIconSize: CGSize { CGSizeMake(12, 12) }
        static var authTextFont: UIFont { UIFont.systemFont(ofSize: 12) }
        static var authHeight: CGFloat { 18 }
        static var authCornerRadius: CGFloat { 4 }
    }
}
