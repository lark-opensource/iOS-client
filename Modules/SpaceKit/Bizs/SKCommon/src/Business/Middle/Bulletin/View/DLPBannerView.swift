//
//  DLPBannerView.swift
//  SKCommon
//
//  Created by peilongfei on 2022/7/18.
//  


import UIKit
import SKUIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignNotice
import SKFoundation

public protocol DLPBannerViewDelegate: AnyObject {
    func shouldClose(_ dlpBannerView: DLPBannerView)
    func shouldOpenLink(_ dlpBannerView: DLPBannerView, _ url: URL)
}

public final class DLPBannerView: UIView, BannerItem {
    
    public weak var bannerDelegate: DLPBannerViewDelegate?
    
    public weak var uiDelegate: BannerUIDelegate?
    
    public var itemType: SKBannerContainer.ItemType {
        return .DLP
    }
    
    public var contentView: UIView {
        return self
    }
    
    private lazy var iconImage: UIImageView = {
        let iv = UIImageView()
        iv.image = UDIcon.warningColorful
        iv.tintColor = UDColor.functionWarningContentDefault
        return iv
    }()
    
    private lazy var contentLabel: UILabel = {
        let lb = UILabel()
        lb.font = UIFont.docs.pfsc(14)
        lb.textColor = UDColor.textTitle
        lb.numberOfLines = 0
        lb.text = BundleI18n.SKResource.LarkCCM_Docs_DLP_ExternalSharing_Off
        return lb
    }()
    
    private lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        return btn
    }()
    
    private lazy var moreButton: UIButton = {
        let btn = UIButton()
        btn.titleLabel?.font = UIFont.docs.pfsc(14)
        btn.setTitle(BundleI18n.SKResource.LarkCCM_Docs_DLP_Link_LearnMore, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        btn.addTarget(self, action: #selector(moreButtonAction), for: .touchUpInside)
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        return btn
    }()
    
    private lazy var padContainer: UIView = {
        let v = UIView()
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if SKDisplay.pad {
            setupPadUI()
        } else {
            setupUI()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UDColor.functionWarningFillSolid02
        
        addSubview(iconImage)
        addSubview(contentLabel)
        addSubview(closeButton)
        addSubview(moreButton)
        
        iconImage.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(14)
            make.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(16)
        }
        
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(40)
            make.trailing.equalToSuperview().inset(38)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(18)
            make.width.equalTo(12)
            make.height.equalTo(12)
        }
        
        moreButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(40)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(20)
        }
    }
    
    private func setupPadUI() {
        backgroundColor = UDColor.functionWarningFillSolid02
        
        addSubview(padContainer)
        addSubview(closeButton)
        padContainer.addSubview(iconImage)
        padContainer.addSubview(contentLabel)
        padContainer.addSubview(moreButton)
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(14)
            make.width.height.equalTo(16)
        }
        
        padContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(9)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-40)
        }
        
        iconImage.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(iconImage.snp.trailing).offset(8)
        }
        
        moreButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        moreButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(contentLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.height.equalTo(22)
        }
    }
    
    public func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        guard preferedWidth > 0 else { return }

        let noticeHeight: CGFloat
        if SKDisplay.pad {
            moreButton.sizeToFit()
            let moreButtonWidth = moreButton.bounds.width
            let labelWidth = preferedWidth - 16 - 40 - 16 - 8 - 16 - moreButtonWidth
            noticeHeight = contentLabel.calculateLabelHeight(textWidth: labelWidth) + 9 + 9
        } else {
            let labelWidth = preferedWidth - 40 - 38
            noticeHeight = contentLabel.calculateLabelHeight(textWidth: labelWidth) + 12 + 4 + 20 + 12
        }
        uiDelegate?.shouldUpdateHeight(self, newHeight: noticeHeight)
    }
}

extension DLPBannerView {
    
    @objc
    private func closeButtonAction() {
        bannerDelegate?.shouldClose(self)
    }
    
    @objc
    private func moreButtonAction() {
        do {
            let url = try HelpCenterURLGenerator.generateURL(article: .dlpBannerHelpCenter)
            bannerDelegate?.shouldOpenLink(self, url)
        } catch {
            DocsLogger.error("failed to generate helper center URL when moreButtonAction from dlp banner", error: error)
        }
    }
}
