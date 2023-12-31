//
//  MailAIGuideView.swift
//  MailSDK
//
//  Created by tanghaojin on 2023/7/16.
//

import Foundation
import LarkGuideUI
import UIKit
import SnapKit
import LarkLocalizations
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme

protocol MailAIGuideViewDelegate: AnyObject {
    func didAIGuideViewClickOpen(dialogView: GuideCustomView)
    func didAIGuideViewClickOk(dialogView: GuideCustomView)
}

final class MailAIGuideView : GuideCustomView {
    weak var aiDelegate: MailAIGuideViewDelegate?
    var defaultName: String = ""

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(delegate: LarkGuideUI.GuideCustomViewDelegate) {
        super.init(delegate: delegate)
        setupViews()
    }
    
    init(delegate: LarkGuideUI.GuideCustomViewDelegate ,
         aiDelegate: MailAIGuideViewDelegate,
         defaultName: String) {
        super.init(delegate: delegate)
        self.aiDelegate = aiDelegate
        self.defaultName = defaultName
        setupViews()
    }
    
    override var intrinsicContentSize: CGSize {
        var viewHeight: CGFloat = Layout.headerHeight
        let textPrepareSize = CGSize(width: Layout.viewWidth - Layout.contentInset * 2,
                                     height: CGFloat.greatestFiniteMagnitude)
        let titleHeight = titleText.sizeThatFits(textPrepareSize).height
        let detailHeight = detailText.sizeThatFits(textPrepareSize).height
        viewHeight += Layout.titleTop + titleHeight
        viewHeight += Layout.detailTop + detailHeight
        viewHeight += Layout.buttonTop + Layout.buttonHeight + Layout.buttonInset
        return CGSize(width: Layout.viewWidth, height: viewHeight)
    }
    
    func gradientLayer(leftColor: UIColor, rightColor: UIColor) -> CAGradientLayer {
        let gradientColors = [leftColor.cgColor, rightColor.cgColor]
        let gradientLocations: [NSNumber] = [0.0, 1.0]
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientLayer
    }
    func leftColor() -> UIColor {
        if isDarkMode() {
            return UIColor.ud.rgb(0x5E68E8)
        }
        return UIColor.ud.rgb(0x5B65F5)
    }
    func rightColor() -> UIColor {
        if isDarkMode() {
            return UIColor.ud.rgb(0x8B378B)
        }
        return UIColor.ud.rgb(0xDE81DE)
    }
    func isDarkMode() -> Bool {
        var isDark = false
        if #available(iOS 13.0, *) {
            isDark = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        return isDark
    }
    
    func setupViews() {
        let viewWidth = self.intrinsicContentSize.width
        let viewHeight = self.intrinsicContentSize.height
        self.layer.backgroundColor = UIColor.ud.bgFloat.cgColor
        self.layer.ud.setShadow(type: .s4DownPri)
        self.layer.cornerRadius = Layout.containerCornerRadius
        self.clipsToBounds = true
        self.snp.makeConstraints { make in
            make.width.equalTo(viewWidth)
            make.height.equalTo(viewHeight)
        }
        self.addSubview(headerView)
        self.addSubview(footerView)
        headerView.addSubview(bannerView)
        footerView.addSubview(titleText)
        footerView.addSubview(detailText)
        footerView.addSubview(getButton)
        footerView.addSubview(tryButton)
        bannerView.addSubview(bannerLine1)
        bannerView.addSubview(bannerLine2)
        bannerView.addSubview(bannerLine3)
        bannerView.addSubview(bannerLine4)
        bannerLine4.addSubview(banneLine4Border)
        bannerView.addSubview(bannerInputView)
        bannerInputView.addSubview(grayInputBg)
        bannerInputView.addSubview(aiIcon)
        bannerInputView.addSubview(inputText)
        bannerView.addSubview(dragBar)
        
        headerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }
        bannerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(-20)
            make.width.equalTo(Layout.bannerWidth)
            make.height.equalTo(Layout.bannerHeight)
        }
        
        footerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        titleText.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.titleTop)
            make.left.equalToSuperview().inset(Layout.titleInset)
            make.right.equalToSuperview().inset(Layout.titleInset)
        }
        detailText.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(Layout.detailTop)
            make.left.equalToSuperview().inset(Layout.titleInset)
            make.right.equalToSuperview().inset(Layout.titleInset)
        }
        getButton.snp.makeConstraints { make in
            make.top.equalTo(detailText.snp.bottom).offset(Layout.buttonTop)
            make.left.equalToSuperview().inset(Layout.buttonInset)
            make.height.equalTo(Layout.buttonHeight)
            make.bottom.equalToSuperview().inset(Layout.buttonInset)
            make.width.equalTo(tryButton.snp.width)
        }
        tryButton.snp.makeConstraints { make in
            make.top.equalTo(getButton.snp.top)
            make.left.equalTo(getButton.snp.right).offset(Layout.buttonMargin)
            make.right.equalToSuperview().inset(Layout.buttonInset)
            make.height.equalTo(Layout.buttonHeight)
            make.bottom.equalToSuperview().inset(Layout.buttonInset)
        }
        bannerLine1.snp.makeConstraints { make in
            make.width.equalTo(Layout.bannerLineWidth)
            make.height.equalTo(Layout.bannerLineHeight)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(30)
        }
        bannerLine2.snp.makeConstraints { make in
            make.width.equalTo(Layout.bannerLineWidth)
            make.height.equalTo(Layout.bannerLineHeight)
            make.centerX.equalToSuperview()
            make.top.equalTo(bannerLine1.snp.bottom).offset(8)
        }
        bannerLine3.snp.makeConstraints { make in
            make.width.equalTo(Layout.bannerLineShortWidth)
            make.height.equalTo(Layout.bannerLineHeight)
            make.left.equalToSuperview().offset(Layout.bannerLineInset)
            make.top.equalTo(bannerLine2.snp.bottom).offset(8)
        }
        bannerLine4.snp.makeConstraints { make in
            make.centerY.equalTo(bannerLine3.snp.centerY)
            make.left.equalTo(bannerLine3.snp.left).offset(Layout.bannerLineShortWidth - 40)
            make.width.equalTo(Layout.bannerLineGraintWidth)
            make.height.equalTo(Layout.bannerLineGraintHeight)
        }
        banneLine4Border.snp.makeConstraints { make in
            make.width.equalTo(2)
            make.top.right.bottom.equalToSuperview()
        }
        bannerInputView.snp.makeConstraints { make in
            make.width.equalTo(Layout.bannerInputWidth)
            make.height.equalTo(Layout.bannerInputHeight)
            make.centerX.equalToSuperview()
            make.top.equalTo(bannerLine3.snp.bottom).offset(20)
        }
        grayInputBg.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(4)
            make.right.bottom.equalToSuperview().offset(-4)
        }
        aiIcon.snp.makeConstraints { make in
            make.width.equalTo(Layout.aiIconWidth)
            make.height.equalTo(Layout.aiIconWidth)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(20)
        }
        inputText.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(aiIcon.snp.right).offset(16)
            make.right.equalToSuperview().offset(-12)
        }
        dragBar.snp.makeConstraints { make in
            make.width.equalTo(Layout.bannerDragBarWidth)
            make.height.equalTo(Layout.bannerDragBarHeight)
            make.centerX.equalToSuperview()
            make.top.equalTo(bannerInputView.snp.bottom).offset(14)
        }
    }
    
    private let bannerView: UIImageView = {
        let view = UIImageView()
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 16
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.layer.ud.setShadow(type: .s2Down)
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()
    lazy var bannerLine1: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.containerCornerRadius
        view.clipsToBounds = true
        let gradientLayer = gradientLayer(leftColor: self.leftColor().withAlphaComponent(0.1),
                                          rightColor: self.rightColor().withAlphaComponent(0.1))
        gradientLayer.frame = CGRect(x: 0, y: 0,
                                     width: Layout.bannerLineWidth,
                                     height: Layout.bannerLineHeight)
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    lazy var bannerLine2: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.containerCornerRadius
        view.clipsToBounds = true
        let gradientLayer = gradientLayer(leftColor: self.leftColor().withAlphaComponent(0.1),
                                          rightColor:self.rightColor().withAlphaComponent(0.1))
        gradientLayer.frame = CGRect(x: 0, y: 0,
                                     width: Layout.bannerLineWidth,
                                     height: Layout.bannerLineHeight)
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    lazy var bannerLine3: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.containerCornerRadius
        view.clipsToBounds = true
        let gradientLayer = self.gradientLayer(leftColor: self.leftColor().withAlphaComponent(0.1),
                                               rightColor:self.rightColor().withAlphaComponent(0.1))
        gradientLayer.frame = CGRect(x: 0, y: 0,
                                     width: Layout.bannerLineShortWidth,
                                     height: Layout.bannerLineHeight)
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    lazy var bannerLine4: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        var leftColor = UIColor.ud.rgb(0xFFFFFF).withAlphaComponent(0)
        var rightColor = UIColor.ud.rgb(0xFFFFFF)
        if self.isDarkMode() {
            leftColor = UIColor.ud.rgb(0x2A2A2A).withAlphaComponent(0)
            rightColor = UIColor.ud.rgb(0x292929)
        }
        let gradientLayer = self.gradientLayer(leftColor: leftColor,
                                          rightColor: rightColor)
        gradientLayer.frame = CGRect(x: 0, y: 0,
                                     width: Layout.bannerLineGraintWidth,
                                     height: Layout.bannerLineGraintHeight)
        view.layer.insertSublayer(gradientLayer, at: 0)
        return view
    }()
    lazy var banneLine4Border: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.rgb(0x8B59DB)
        return view
    }()
    
    lazy var bannerInputView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.containerCornerRadius
        view.clipsToBounds = true
        let gradientLayer = self.gradientLayer(leftColor: self.leftColor(),
                                               rightColor: self.rightColor())
        gradientLayer.frame = CGRect(x: 0, y: 0,
                                     width: Layout.bannerInputWidth,
                                     height: Layout.bannerInputHeight)
        view.layer.insertSublayer(gradientLayer, at: 0)
        let maskLayer = CAShapeLayer()
        maskLayer.lineWidth = 4.0
        maskLayer.path = UIBezierPath(roundedRect: CGRect(x: 0,
                                                          y: 0,
                                                          width: Layout.bannerInputWidth,
                                                          height: Layout.bannerInputHeight),
                                      cornerRadius: Layout.containerCornerRadius).cgPath
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.black.cgColor
        gradientLayer.mask = maskLayer
        return view
    }()
    
    lazy var aiIcon: UIImageView = {
        let icon = UIImageView()
        icon.setImage(UDIcon.myaiColorful, tintColor: nil)
        return icon
    }()
    
    lazy var grayInputBg: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        return view
    }()
    
    lazy var inputText: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.MailSDK.Mail_MyAI_WelcomePage_MyAIWriting_Text
        label.textColor = UIColor.ud.textCaption
        label.font = Style.inputTextFont
        return label
    }()
    
    lazy var dragBar: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        view.backgroundColor = UIColor.ud.neutralColor6
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        return view
    }()
    
    private let footerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()
    
    private lazy var titleText: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.AIPrimaryFillDefault.toColor(withSize: CGSize(width: Layout.viewWidth - Layout.titleInset * 2,
                                                                                height: 28))
        label.font = Style.titleFont
        label.text = BundleI18n.MailSDK.Mail_MyAI_WelcomePage_MeetAI_aiName_Title(self.defaultName)
        label.numberOfLines = 0
        return label
    }()
    
    private let detailText: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = Style.detailTextFont
        label.text = BundleI18n.MailSDK.Mail_MyAI_WelcomePage_MeetAI_Desc
        label.numberOfLines = 0
        return label
    }()
    
    lazy var getButton: UIButton = {
        let btn = UIButton()
        btn.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        btn.layer.cornerRadius = Layout.containerCornerRadius
        btn.layer.borderWidth = 0.5
        btn.setTitle(BundleI18n.MailSDK.Mail_MyAI_WelcomePage_GotIt_Button, for: .normal)
        btn.setTitleColor(Style.buttonTextColor, for: .normal)
        btn.titleLabel?.font = Style.buttonTextFont
        btn.addTarget(self, action: #selector(didClickSkipBtn),
                     for: UIControl.Event.touchUpInside)
        return btn
    }()
    
    lazy var tryButton: UIButton = {
        let btn = UIButton()
        //btn.layer.borderColor = Style.buttonBgColor.cgColor
        btn.layer.cornerRadius = Layout.containerCornerRadius
        //btn.layer.borderWidth = 1
        btn.setTitle(BundleI18n.MailSDK.Mail_MyAI_WelcomePage_TryNow_Button, for: .normal)
        let buttonWidth = (Layout.viewWidth - Layout.buttonInset * 2 - Layout.buttonMargin) / 2
        let color = UDColor.AIPrimaryFillDefault.toColor(withSize: CGSize(width: buttonWidth,
                                                                          height: Layout.buttonHeight))
        btn.setTitleColor(UDColor.staticWhite, for: .normal)
        btn.titleLabel?.font = Style.buttonTextFont
        btn.backgroundColor = color
        btn.addTarget(self, action: #selector(didClickOkBtn),
                      for: UIControl.Event.touchUpInside)
        return btn
    }()
    
    @objc private func didClickSkipBtn() {
        closeGuideCustomView(view: self)
        aiDelegate?.didAIGuideViewClickOk(dialogView: self)
    }

    @objc private func didClickOkBtn() {
        closeGuideCustomView(view: self)
        aiDelegate?.didAIGuideViewClickOpen(dialogView: self)
    }
}

extension MailAIGuideView {
    enum Layout {
        static let viewWidth: CGFloat = 300
        static let viewHeight: CGFloat = 370
        static let headerHeight: CGFloat = 190
        static let containerCornerRadius: CGFloat = 8
        static let contentInset: CGFloat = 20
        static let bannerHeight: CGFloat = 168 + 20
        static let bannerWidth: CGFloat = 240
        static let titleTop: CGFloat = 24
        static let titleInset: CGFloat = 20
        static let detailTop: CGFloat = 8
        static let buttonRadius: CGFloat = 6
        static let buttonInset: CGFloat = 20
        static let buttonHeight: CGFloat = 48
        static let buttonWidth: CGFloat = 248
        static let buttonTop: CGFloat = 24
        static let buttonMargin: CGFloat = 12
        static let bannerLineWidth: CGFloat = 208
        static let bannerLineHeight: CGFloat = 16
        static let bannerLineShortWidth: CGFloat = 84
        static let bannerLineGraintWidth: CGFloat = 42
        static let bannerLineGraintHeight: CGFloat = 20
        static let bannerLineInset: CGFloat = 16
        static let bannerInputWidth: CGFloat = 220
        static let bannerInputHeight: CGFloat = 46
        static let bannerDragBarWidth: CGFloat = 80
        static let bannerDragBarHeight: CGFloat = 4
        static let aiIconWidth: CGFloat = 20
        
    }
    enum Style {
        static let titleFont: UIFont = .systemFont(ofSize: 20.0, weight: .medium)
        static let detailTextFont: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
        static let inputTextFont: UIFont = .systemFont(ofSize: 14.0, weight: .regular)
        static let buttonTextFont: UIFont = .systemFont(ofSize: 17.0, weight: .regular)
        static let buttonBgColor: UIColor = UIColor.ud.lineBorderCard
        static let buttonTextColor: UIColor = UIColor.ud.textTitle
        static let bgViewBackgroundColor = UIColor.ud.primaryFillHover.alwaysLight
    }
}
