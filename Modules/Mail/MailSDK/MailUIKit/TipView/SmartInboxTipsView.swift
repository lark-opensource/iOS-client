//
//  SmartInboxTipsView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/8/31.
//

import Foundation
import LarkGuideUI
import UniverseDesignIcon
// onboard改为统一使用SingleBubble展示，这个View没用了
class SmartInboxTipsView: GuideCustomView {

    enum TipType {
        case labelPop, previewCardPop
    }

}

class StrangerTipsView: GuideCustomView {

    var dismissCallback: (() -> Void)?
    let color = UIColor.ud.bgPricolor
    let titleColor = UIColor.ud.primaryContentDefault
    var yOffset: CGFloat = 0

    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor.ud.staticWhite
        button.setTitle(BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_GotIt, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return button
    }()

    let tipsView = UIView()
    private let tipsWidth: CGFloat = 288
    private let iconWidthHeight: CGFloat = 16
    private let triangleWidth: CGFloat = 24
    private let triangleHeight: CGFloat = 10
    private let xOffset: CGFloat = Display.pad ? 81 : 11
    private lazy var triangleXOffset: CGFloat = self.xOffset + 132
    private let marginLeft: CGFloat = 20
    private let btnPaddingTop: CGFloat = 24
    private let iconPaddingTop: CGFloat = 12
    private let titleIconMarginTop: CGFloat = 10
    private let titlePaddingTop: CGFloat = 8
    private let titlePaddingLeft: CGFloat = 4
    private let dismissBtnWidth: CGFloat = 96
    private let dismissBtnHeight: CGFloat = 36

    @objc
    func dismiss() {
        closeGuideCustomView(view: self)
        dismissCallback?()
    }

    init(delegate: GuideCustomViewDelegate, yOffset: CGFloat = 0) {
        super.init(delegate: delegate)
        backgroundColor = .clear
        self.yOffset = yOffset
        setupViews()
        setupViewByCAShapeLayer()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(tipsView)
        tipsView.backgroundColor = color
        tipsView.layer.cornerRadius = 8
        tipsView.layer.shadowColor = UIColor.ud.primaryPri600.withAlphaComponent(0.3).cgColor
        tipsView.layer.shadowOffset = CGSize(width: 0, height: 12)
        tipsView.layer.shadowRadius = 24
        tipsView.snp.makeConstraints { (make) in
            make.top.equalTo(yOffset)
            make.width.equalTo(tipsWidth)
            make.bottom.centerX.equalToSuperview()
        }

        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_Title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor.ud.staticWhite
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byCharWrapping
        tipsView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.equalTo(marginLeft)
            make.right.equalToSuperview().offset(-marginLeft)
        }
        titleLabel.preferredMaxLayoutWidth = titleLabel.alignmentRect(forFrame: titleLabel.frame).size.width

        let allowIcon = UIImageView()
        allowIcon.image = UDIcon.yesOutlined.withRenderingMode(.alwaysTemplate)
        allowIcon.tintColor = UIColor.ud.staticWhite
        tipsView.addSubview(allowIcon)
        allowIcon.snp.makeConstraints { (make) in
            make.left.equalTo(marginLeft)
            make.top.equalTo(titleLabel.snp.bottom).offset(titleIconMarginTop)
            make.width.height.equalTo(iconWidthHeight)
        }

        let allowSubTitle = UILabel()
        allowSubTitle.text = BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_AllowSender
        allowSubTitle.numberOfLines = 0
        allowSubTitle.lineBreakMode = .byWordWrapping
        allowSubTitle.font = UIFont.systemFont(ofSize: 14)
        allowSubTitle.textColor = UIColor.ud.staticWhite
        tipsView.addSubview(allowSubTitle)
        allowSubTitle.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(titlePaddingTop)
            make.left.equalTo(allowIcon.snp.right).offset(titlePaddingLeft)
            make.right.equalToSuperview().offset(-marginLeft)
        }
        allowSubTitle.sizeToFit()

        let rejectIcon = UIImageView()
        rejectIcon.image = UDIcon.noOutlined.withRenderingMode(.alwaysTemplate)
        rejectIcon.tintColor = UIColor.ud.staticWhite
        tipsView.addSubview(rejectIcon)
        rejectIcon.snp.makeConstraints { (make) in
            make.left.equalTo(marginLeft)
            make.top.equalTo(allowSubTitle.snp.bottom).offset(titleIconMarginTop)
            make.width.height.equalTo(iconWidthHeight)
        }

        let rejectSubTitle = UILabel()
        rejectSubTitle.text = BundleI18n.MailSDK.Mail_StrangerMail_StrangerEmailsFeaturePopUp_RejectSender
        rejectSubTitle.numberOfLines = 0
        rejectSubTitle.lineBreakMode = .byWordWrapping
        rejectSubTitle.font = UIFont.systemFont(ofSize: 14)
        rejectSubTitle.textColor = UIColor.ud.staticWhite
        tipsView.addSubview(rejectSubTitle)
        rejectSubTitle.snp.makeConstraints { (make) in
            make.top.equalTo(allowSubTitle.snp.bottom).offset(titlePaddingTop)
            make.left.equalTo(allowIcon.snp.right).offset(titlePaddingLeft)
            make.right.equalToSuperview().offset(-marginLeft)
        }
        rejectSubTitle.sizeToFit()

        tipsView.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { (make) in
            make.right.equalTo(-marginLeft)
            make.top.equalTo(rejectSubTitle.snp.bottom).offset(btnPaddingTop)
            make.width.equalTo(dismissBtnWidth)
            make.height.equalTo(dismissBtnHeight)
        }

        tipsView.snp.remakeConstraints { (make) in
            make.left.equalTo(xOffset)
            make.top.equalTo(yOffset + triangleHeight)
            make.width.equalTo(tipsWidth)
            make.bottom.equalTo(dismissButton.snp.bottom).offset(marginLeft)
        }
    }

    func setupViewByCAShapeLayer() {
        let triangleView = UIView()
        triangleView.isUserInteractionEnabled = false
        triangleView.frame = CGRect(x: triangleXOffset, y: yOffset, width: triangleWidth, height: triangleHeight)
        addSubview(triangleView)
        let triangleLayer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: triangleHeight))
        path.addLine(to: CGPoint(x: triangleWidth / 2.0, y: 0))
        path.addLine(to: CGPoint(x: triangleWidth, y: triangleHeight))
        triangleLayer.path = path.cgPath
        triangleView.layer.addSublayer(triangleLayer)
        triangleLayer.ud.setFillColor(color)
    }
}

