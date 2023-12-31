//
//  SecretBannerView.swift
//  SKCommon
//
//  Created by guoqp on 2022/6/21.
//  

import UIKit
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignNotice

public protocol SecretBannerViewDelegate: AnyObject {
    func secretBannerViewDidClickSetButton(_ view: SecretBannerView)
    func secretBannerViewDidClickLink(_ view: SecretBannerView, url: URL)
    func secretBannerClose(_ secretBannerView: SecretBannerView)
    func secretBannerViewDidClickSetConfirmButton(_ view: SecretBannerView)
}

public final class SecretBannerView: UIView, BannerItem {

    public enum BannerType {
        case hide
        case emptySecret
        case defaultSecret(title: String)
        case forcibleSecret(title: String?)//强制密级
        case autoMarkBanner(title: String)//自动打标
        case recommendMarkBanner(title: String)//推荐打标
        case forceRecommendMarkBanner(title: String)//强制推荐打标
        case unChangetype
    }
    private var presentingBannerTypeIsRecommend: Bool = false
    private var bannerType: BannerType = .emptySecret
    private var preferedWidth: CGFloat = 0.0
    private lazy var setButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.borderWidth = 0
        btn.backgroundColor = UIColor.clear
        btn.contentEdgeInsets = UIEdgeInsets.zero
        btn.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_SelectSecureLevel_mob, for: .normal)
        btn.layer.ud.setBorderColor(UDColor.primaryContentDefault)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
//        btn.setTitleColor(UDColor.textDisable, for: .disabled)
        btn.titleLabel?.font = UIFont.docs.pfsc(14)
//        btn.backgroundColor = UDColor.udtokenComponentOutlinedBg
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        btn.addTarget(self, action: #selector(setButtonAction), for: .touchUpInside)
        return btn
    }()


    private lazy var linkButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Security_Learnmore_web, for: .normal)
        btn.layer.ud.setBorderColor(UDColor.primaryContentDefault)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
//        btn.setTitleColor(UDColor.textDisable, for: .disabled)
        btn.titleLabel?.font = UIFont.docs.pfsc(14)
//        btn.backgroundColor = UDColor.udtokenComponentOutlinedBg
        btn.contentEdgeInsets = UIEdgeInsets.zero
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        btn.addTarget(self, action: #selector(linkButtonAction), for: .touchUpInside)
        return btn
    }()
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        return btn
    }()
    
    private var leadingIconImageView: UIImageView = UIImageView()
    private var titleLabel: UILabel = UILabel()
    weak public var uiDelegate: BannerUIDelegate?
    weak public var actionDelegate: SecretBannerViewDelegate?
    public var itemType: SKBannerContainer.ItemType {
        return .secretLevel
    }
    
    public var contentView: UIView {
        return self
    }
    
    public private(set) var secLabelTitleName: String = ""

    public func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        self.preferedWidth = preferedWidth
        updateSuperViewHeight()
    }

    private func updateSuperViewHeight() {
        guard self.preferedWidth > 0 else { return }
        let size = CGSize(width: preferedWidth - 16 - 16 - 16 - 8, height: .infinity)
        let titleLabelSize = titleLabel.sizeThatFits(size)
        let titleLabelW = titleLabelSize.width
        let titleLabelH = titleLabelSize.height
        let buttonHeight: CGFloat = 20
        let iconW: CGFloat = 16
        let height: CGFloat
        let setButtonW = setButton.sizeThatFits(CGSizeMake(preferedWidth, 50)).width
        let linkButtonW = linkButton.sizeThatFits(CGSizeMake(preferedWidth, 50)).width

        if 16 + iconW + 8 + titleLabelW + 10 + setButtonW + 16 + linkButtonW + 16 > preferedWidth {
            /// 一行放不下, 分行
            height = 12 + titleLabelH + 4 + buttonHeight + 12
            layuoutStyleMultiLine()
        } else {
            /// 一行放得下，不分行
            height = 12 + titleLabelH + 12
            layuoutStylelLine()
        }

        DocsLogger.info("titleLabelW \(titleLabelW) setButtonW \(setButtonW), \(linkButtonW)")
        uiDelegate?.shouldUpdateHeight(self, newHeight: height)
    }

    private func layuoutStylelLine() {
        /// 文案和按钮同一行
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(leadingIconImageView.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        
        setButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setButton.snp.remakeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        
        linkButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        linkButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        linkButton.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(setButton.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(setButton.snp.height)
        }
    }

    private func layuoutStyleMultiLine() {
        /// 文案和按钮不同一行
        titleLabel.snp.remakeConstraints { make in
            make.leading.equalTo(leadingIconImageView.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-16)
        }
        setButton.snp.remakeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-12)
        }

        linkButton.snp.remakeConstraints { make in
            make.top.equalTo(setButton.snp.top)
            make.leading.equalTo(setButton.snp.trailing).offset(16)
            make.height.equalTo(setButton.snp.height)
        }
        
        if case .autoMarkBanner = bannerType {
            setButton.isHidden = true
            linkButton.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
                make.leading.equalTo(titleLabel.snp.leading)
                make.height.equalTo(20)
                make.bottom.equalToSuperview().offset(-12)
            }
        }
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.primaryFillSolid01
        self.addSubview(leadingIconImageView)
        self.addSubview(titleLabel)
        self.addSubview(setButton)
        self.addSubview(linkButton)
        self.addSubview(closeButton)

        titleLabel.numberOfLines = 0

        leadingIconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.height.width.equalTo(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setBannerType(_ type: SecretBannerView.BannerType) {
        self.bannerType = type
        switch type {
        case .emptySecret:
            let text = BundleI18n.SKResource.LarkCCM_Workspace_Security_SecurityStrategyReq_mob
            setBannerNormalStyle(with: text)
            secLabelTitleName = ""
        case let .defaultSecret(title):
            let text = BundleI18n.SKResource.LarkCCM_Workspace_Security_DefaultSetting_mob(title)
            setBannerNormalStyle(with: text)
            secLabelTitleName = title
        case let .forcibleSecret(title):
            let text: String
            if let title = title {
                text = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_RequirWithDefault_Banner(title)
            } else {
                text = BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requir_Banner
            }
            setBannerForcibleStyle(with: text)
            secLabelTitleName = title ?? ""
        case let .autoMarkBanner(title):
            let text = BundleI18n.SKResource.LarkCCM_Workspace_AutoSecLevil_Adjusted_Banner(title)
            setBannerNormalStyle(with: text)
            secLabelTitleName = title
            setCloseButtonStyle()
        case let .recommendMarkBanner(title):
            let text = BundleI18n.SKResource.LarkCCM_Workspace_AutoSecLevil_Recommend_Banner(title)
            setConfirmButton()
            setBannerNormalStyle(with: text)
            secLabelTitleName = title
            setCloseButtonStyle()
        case let .forceRecommendMarkBanner(title):
            let text = BundleI18n.SKResource.LarkCCM_Workspace_AutoSecLevil_RequiredWithRecom_Banner(title)
            setConfirmButton()
            setBannerForcibleStyle(with: text)
            secLabelTitleName = title
        default: break
        }
        updateSuperViewHeight()
    }
    
    func setConfirmButton() {
        setButton.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_AutoSecLevil_Recommend_Confirm, for: .normal)
        setButton.removeTarget(self, action: nil, for: .touchUpInside)
        setButton.addTarget(self, action: #selector(setButtonConFirmAction), for: .touchUpInside)
    }
    
    func setBannerNormalStyle(with text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PingFangSC-Regular", size: 14),
            .foregroundColor: UIColor.ud.textTitle
        ]
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: attributes
        )

        leadingIconImageView.image = UDIcon.getIconByKey(.safeFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.textLinkHover)
        titleLabel.attributedText = attributedText
        backgroundColor = UDColor.primaryFillSolid01
    }
    
    func setBannerForcibleStyle(with text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "PingFangSC-Regular", size: 14),
            .foregroundColor: UIColor.ud.textTitle
        ]
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: attributes
        )

        leadingIconImageView.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 16, height: 16))
        titleLabel.attributedText = attributedText
        backgroundColor = UDColor.functionWarningFillSolid02
    }
    
    func setCloseButtonStyle() {
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(10)
            make.width.equalTo(12)
            make.height.equalTo(12)
        }
    }
}

extension SecretBannerView {
    @objc
    private func setButtonAction() {
        actionDelegate?.secretBannerViewDidClickSetButton(self)
    }
    @objc
    private func setButtonConFirmAction() {
        actionDelegate?.secretBannerViewDidClickSetConfirmButton(self)
    }
    @objc
    private func linkButtonAction() {
        do {
            let url = try HelpCenterURLGenerator.generateURL(article: .secretBannerHelpCenter)
            actionDelegate?.secretBannerViewDidClickLink(self, url: url)
        } catch {
            DocsLogger.error("failed to generate helper center URL when linkButtonAction from secret banner", error: error)
        }
    }
    
    @objc
    private func closeButtonAction() {
        actionDelegate?.secretBannerClose(self)
    }
    
}
