//
//  CustomTemplateTipView.swift
//  SKBrowser
//
//  Created by 曾浩泓 on 2022/1/2.
//  

import UIKit
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignNotice

protocol CustomTemplateTipViewDelegate: AnyObject {
    func templateTipViewDidClickUseButton(_ templateTipView: CustomTemplateTipView)
    func templateTipViewDidClickLink(_ templateTipView: CustomTemplateTipView)
}

class CustomTemplateTipView: UIView, BannerItem {
    enum TemplateType {
        case ugc(username: String, isOwner: Bool)
        case pgc(usedCount: Int?)
    }
    
    private lazy var useButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 6
        btn.setTitle(BundleI18n.SKResource.CreationMobile_Template_UseThisTemplate, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        btn.setTitleColor(UDColor.primaryContentDefault, for: .disabled)
        btn.titleLabel?.font = UIFont.docs.pfsc(14)
        btn.backgroundColor = UDColor.udtokenComponentOutlinedBg
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        btn.addTarget(self, action: #selector(useButtonAction), for: .touchUpInside)
        btn.isEnabled = false
        return btn
    }()
    private lazy var noticeView: UDNotice = {
        let attributedText = NSAttributedString()
        var config = createNoticeConfig()
        let view = UDNotice(config: config)
        view.delegate = self
        return view
    }()
    weak var uiDelegate: BannerUIDelegate?
    weak var actionDelegate: CustomTemplateTipViewDelegate?
    var itemType: SKBannerContainer.ItemType {
        return .template
    }
    
    var contentView: UIView {
        return self
    }

    func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        uiDelegate?.shouldUpdateHeight(self, newHeight: 44)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(noticeView)
        self.addSubview(useButton)
        self.backgroundColor = noticeView.backgroundColor
        noticeView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(useButton.snp.leading)
        }
        useButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(28)
            useButton.titleLabel?.sizeToFit()
            if let width = useButton.titleLabel?.frame.width {
                make.width.equalTo(width + 16)
            }
        }
        setUseButtonEnable(false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTemplateType(_ type: CustomTemplateTipView.TemplateType) {
        switch type {
        case let .pgc(usedCount):
            setGalleryTemplateUsedCount(usedCount)
        case let .ugc(username, isOwner):
            setUserName(username, isOwner: isOwner)
        }
    }
    
    func setUseButtonEnable(_ enable: Bool) {
        _setUseButtonEnableStyle(enable: enable)
        useButton.isEnabled = enable
    }
    
    /// 设置按钮的enable样式，仍可响应点击
    func setUseButtonEnableUIStyle(_ enable: Bool) {
        _setUseButtonEnableStyle(enable: enable)
        useButton.isEnabled = true
    }
    
    private func _setUseButtonEnableStyle(enable: Bool) {
        let color = enable ? UDColor.primaryContentDefault : UDColor.textDisabled
        useButton.setTitleColor(color, for: .normal)
        useButton.setTitleColor(color, for: .disabled)
        useButton.layer.ud.setBorderColor(enable ? UDColor.primaryContentDefault : UDColor.textDisabled)
    }

    private func setGalleryTemplateUsedCount(_ usedCount: Int?) {
        var text: String
        if SKDisplay.pad, let usedCount = usedCount {
            text = BundleI18n.SKResource.CreationMobile_Template_ProvidedByDocsUsedBy1() + BundleI18n.SKResource.CreationMobile_Template_ProvidedByDocsUsedBy2(usedCount)
        } else {
            text = BundleI18n.SKResource.CreationMobile_Template_ProvidedByDocs()
        }
        let templateCenter = BundleI18n.SKResource.CreationMobile_Template_AppNameTemplateCenter()
        let attributedString = createAttributedString(
            text: text,
            highlightRange: NSString(string: text).range(of: templateCenter)
        )
        var config = createNoticeConfig(with: attributedString)
        noticeView.updateConfigAndRefreshUI(config)
    }
    
    private func setUserName(_ name: String, isOwner: Bool) {
        let atUser = "@\(name)"
        let text = BundleI18n.SKResource.CreationMobile_Template_TemplateCreatedBy(atUser)
        let attributedString = createAttributedString(
            text: text,
            highlightRange: NSString(string: text).range(of: atUser)
        )
        var config = createNoticeConfig(with: attributedString)
        noticeView.updateConfigAndRefreshUI(config)
    }
    
    private func createAttributedString(text: String, highlightRange: NSRange?) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 30, weight: .medium),
            .foregroundColor: UIColor.ud.textTitle
        ]
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: attributes
        )
        if let highlightRange = highlightRange {
            attributedText.addAttribute(.link, value: "atUser://", range: highlightRange)
        }
        return attributedText
    }
    private func createNoticeConfig(with attributedText: NSAttributedString? = nil) -> UDNoticeUIConfig {
        var config = UDNoticeUIConfig(type: .info, attributedText: attributedText ?? NSAttributedString())
        config.leadingIcon = UDIcon.getIconByKey(.templateColorful, size: CGSize(width: 16, height: 16))
        config.lineBreakMode = .byTruncatingTail
        return config
    }
}

extension CustomTemplateTipView {
    @objc
    private func useButtonAction() {
        actionDelegate?.templateTipViewDidClickUseButton(self)
    }
}

extension CustomTemplateTipView: UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {}
    
    func handleTrailingButtonEvent(_ button: UIButton) {}
    
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        actionDelegate?.templateTipViewDidClickLink(self)
    }
}
