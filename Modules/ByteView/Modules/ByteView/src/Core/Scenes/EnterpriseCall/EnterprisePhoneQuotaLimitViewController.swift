//
//  EnterprisePhoneQuotaLimitViewController.swift
//  ByteView
//
//  Created by bytedance on 2021/8/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import ByteViewMeeting
import ByteViewSetting
import ByteViewNetwork
import UniverseDesignIcon

class EnterprisePhoneQuotaLimitViewController: BaseViewController {

    lazy var phoneQuotaLimitView = EnterprisePhoneQuotaLimitView(frame: .zero)

    let userName: String
    let userId: String
    let dependency: MeetingDependency
    init(userName: String, userId: String, dependency: MeetingDependency) {
        self.userName = userName
        self.userId = userId
        self.dependency = dependency
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        setupViews()
        bindUIAction()
        bindViewModel()
    }

    func setupViews() {
        view.addSubview(phoneQuotaLimitView)
        phoneQuotaLimitView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    func bindViewModel() {
        bindTitle()
        bindTipsTitle()
        bindTipsInfo()
        bindUrgentBusinessLbl()
        bindVoiceCallLbl()
        bindDetailLbl()
        bindUIAction()
    }
    private func bindUIAction() {
        phoneQuotaLimitView.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        phoneQuotaLimitView.voiceCall.addTarget(self, action: #selector(phoneCall), for: .touchUpInside)
        phoneQuotaLimitView.detailButton.addTarget(self, action: #selector(jumpDetail), for: .touchUpInside)
    }

//    绑定UI控件以及更新参数
    func bindTitle() {
        phoneQuotaLimitView.updateTitle(title: I18n.View_MV_SearchCallLimits)
    }
    func bindTipsTitle() {
        phoneQuotaLimitView.updateTipsTitle(title: I18n.View_MV_SearchPhoneTips)
    }
    func bindTipsInfo() {
        phoneQuotaLimitView.updateTipsInfo(info: I18n.View_MV_HelloAdminControlled(self.userName))
    }
    func bindUrgentBusinessLbl() {
        phoneQuotaLimitView.updateUrgentBusinessLbl(lbl: I18n.View_MV_EmergencySosCall)
    }
    func bindVoiceCallLbl() {
        phoneQuotaLimitView.updateVoiceCallLbl(lbl: I18n.View_MV_CallAudioPhone)
    }
    func bindDetailLbl() {
        phoneQuotaLimitView.updateDetailLbl(lbl: I18n.View_MV_CheckManagementControls)
    }

    //  按钮功能实现
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func phoneCall() {
        let params: StartCallParams = .call(id: userId, source: .addressBookCard, isE2EeMeeting: false)
        MeetingManager.shared.startMeeting(.call(params), dependency: dependency, from: RouteFrom(self))
    }

    @objc func jumpDetail() {
        let urlStr = dependency.setting.enterpriseLimitLinkConfig.controlLink
        if !urlStr.isEmpty, let url = URL(string: urlStr) {
            dependency.router.push(url, context: [:], from: self, forcePush: false, animated: true, completion: nil)
        }
    }
}

class EnterprisePhoneQuotaLimitView: UIView {

    private enum Layout {
        static let titleLabelHeight: CGFloat = 24
        static let titleLabelTopSpacing: CGFloat = 54
        static let closeButtonSize = CGSize(width: 20, height: 20)
        static let closeButtonLeftSpacing: CGFloat = 16
        static let distanceToEdge: CGFloat = 16
        static let bgViewTopSpacing: CGFloat = 20
        static let bgViewBottomSpacing: CGFloat = 18
        static let deviceWarningIconSize = CGSize(width: 16, height: 16)
        static let deviceWarningIconTopSpacing: CGFloat = 18
        static let deviceWarningIconLeftSpacing: CGFloat = 12
        static let tipsTitleHeight: CGFloat = 20
        static let tipsTitleTopSpacing: CGFloat = 16
        static let tipsTitleLeftSpacing: CGFloat = 6
        static let tipsInfoTopSpacing: CGFloat = 12
        static let tipsInfoLeftRightSpacing: CGFloat = 12
        static let emergencySosTitleHeight: CGFloat = 20
        static let emergencySosTopSpacing: CGFloat = 40
        static let voiceCallButtonHeight: CGFloat = 48
        static let voiceCallButtonTopSpacing: CGFloat = 28
        static let voiceCallButtonCornerRadius: CGFloat = 4
        static let voiceCallButtonImageSize = CGSize(width: 20, height: 20)
        static let detailButtonHeight: CGFloat = 18
        static let detailButtonBottomSpacing: CGFloat = -39
        static let detailButtonImageSize = CGSize(width: 12, height: 12)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        autoLayoutSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//  标题
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.attributedText = NSAttributedString(string: " ", config: .h3)
        label.sizeToFit()
        return label
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.N800, size: Layout.closeButtonSize), for: .normal)
        return button
    }()

    lazy var deviceWarningIcon: UIImageView = {
        let image = UIImageView(image: UDIcon.getIconByKey(.warningColorful, size: Layout.deviceWarningIconSize))
        return image
    }()

    lazy var bgView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.bgBodyOverlay
        return v
    }()

//    提示标题
    lazy var tipsTitle: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.attributedText = NSAttributedString(string: " ", config: .boldBodyAssist)
        label.sizeToFit()
        return label
    }()

//    提示内容
    lazy var tipsInfo: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.attributedText = NSAttributedString(string: " ", config: .tinyAssist)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()

    lazy var emergencySos: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.attributedText = NSAttributedString(string: "", config: .bodyAssist)
        label.sizeToFit()
        return label
    }()


    lazy var voiceCall: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.layer.cornerRadius = Layout.voiceCallButtonCornerRadius
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.titleLabel?.attributedText = NSAttributedString(string: "", config: .h4)
        let icon = UDIcon.getIconByKey(.callNetOutlined, iconColor: .ud.primaryOnPrimaryFill, size: Layout.voiceCallButtonImageSize)
        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .highlighted)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)
        return button
    }()

//  按钮两侧的四点图
    lazy var leftFourDotView: UIView = {
        return FourDotView()
    }()
    lazy var rightFourDotView: UIView = {
        return FourDotView()
    }()

    lazy var detailButton: UIButton = {
        let button = UIButton(type: .custom)
        let normalColor = UIColor.ud.textPlaceholder
        button.setTitleColor(normalColor, for: .normal)
        button.titleLabel?.attributedText = NSAttributedString(string: "", config: .tinyAssist)
        let icon = UDIcon.getIconByKey(.rightOutlined, iconColor: normalColor, size: Layout.detailButtonImageSize)
        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .highlighted)
        button.titleLabel?.sizeToFit()
        return button
    }()

    func updateTitle(title: String) {
        titleLabel.text = title

    }
    func updateTipsTitle(title: String) {
        tipsTitle.text = title

    }
    func updateTipsInfo(info: String) {
        tipsInfo.text = info
    }
    func updateVoiceCallLbl(lbl: String) {
        voiceCall.setTitle(lbl, for: .normal)
    }
    func updateUrgentBusinessLbl(lbl: String) {
        emergencySos.text = lbl
    }
    func updateDetailLbl(lbl: String) {
        detailButton.setTitle(lbl, for: .normal)
//        自动定位右侧图标
        if let imgOffset = detailButton.imageView?.bounds.size.width {
            detailButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -imgOffset - 8, bottom: 0, right: imgOffset)
        }
        if let titleOffSet = detailButton.titleLabel?.bounds.size.width {
            detailButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: titleOffSet, bottom: 0, right: -titleOffSet)
        }
    }

    private func setupSubviews() {
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(bgView)
        addSubview(deviceWarningIcon)
        addSubview(tipsTitle)
        addSubview(tipsInfo)
        addSubview(emergencySos)
        addSubview(leftFourDotView)
        addSubview(rightFourDotView)
        addSubview(voiceCall)
        addSubview(detailButton)
    }

    private func autoLayoutSubviews() {
        titleLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.titleLabelHeight)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(Layout.titleLabelTopSpacing)
        }

        closeButton.snp.makeConstraints { (maker) in
            maker.size.equalTo(Layout.closeButtonSize)
            maker.centerY.equalTo(titleLabel)
            maker.left.equalTo(Layout.closeButtonLeftSpacing)
        }

        bgView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview().inset(Layout.distanceToEdge)
            maker.top.equalTo(titleLabel.snp.bottom).offset(Layout.bgViewTopSpacing)
        }

        deviceWarningIcon.snp.makeConstraints {(maker) in
            maker.size.equalTo(Layout.deviceWarningIconSize)
            maker.top.equalTo(bgView).offset(Layout.deviceWarningIconTopSpacing)
            maker.left.equalTo(bgView).offset(Layout.deviceWarningIconLeftSpacing)

        }
        tipsTitle.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.tipsTitleHeight)
            maker.top.equalTo(bgView).offset(Layout.tipsTitleTopSpacing)
            maker.left.equalTo(deviceWarningIcon.snp.right).offset(Layout.tipsTitleLeftSpacing)
        }
        tipsInfo.snp.makeConstraints { (maker) in
            maker.top.equalTo(tipsTitle.snp.bottom).offset(Layout.tipsInfoTopSpacing)
            maker.left.right.equalTo(bgView).inset(Layout.tipsInfoLeftRightSpacing)
        }
        bgView.snp.makeConstraints { (maker) in
            maker.bottom.equalTo(tipsInfo).offset(Layout.bgViewBottomSpacing)
        }

        emergencySos.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.emergencySosTitleHeight)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(bgView.snp.bottom).offset(Layout.emergencySosTopSpacing)
        }
        leftFourDotView.snp.makeConstraints {(maker) in
            maker.width.height.equalTo(10)
            maker.centerY.equalTo(emergencySos)
            maker.right.equalTo(emergencySos.snp.left).offset(-8)
        }
        rightFourDotView.snp.makeConstraints {(maker) in
            maker.width.height.equalTo(10)
            maker.centerY.equalTo(emergencySos)
            maker.left.equalTo(emergencySos.snp.right).offset(8)
        }
        voiceCall.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.voiceCallButtonHeight)
            maker.top.equalTo(emergencySos.snp.bottom).offset(Layout.voiceCallButtonTopSpacing)
            maker.left.right.equalToSuperview().inset(Layout.distanceToEdge)
        }

        detailButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.detailButtonHeight)
            maker.centerX.equalToSuperview()
            maker.bottom.equalTo(Layout.detailButtonBottomSpacing)
        }
    }
}


final class FourDotView: UIView {
    var size: CGFloat = 3
    lazy var leftUpDot = getDotView(size)
    lazy var rightUpDot = getDotView(size)
    lazy var leftDownDot = getDotView(size)
    lazy var rightDownDot = getDotView(size)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        autoLayoutSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addSubview(leftUpDot)
        addSubview(rightUpDot)
        addSubview(leftDownDot)
        addSubview(rightDownDot)
    }

    func autoLayoutSubviews() {
        leftUpDot.snp.makeConstraints {(maker) in
            maker.width.height.equalTo(size)
            maker.top.left.equalToSuperview()
        }
        rightUpDot.snp.makeConstraints {(maker) in
            maker.width.height.equalTo(size)
            maker.top.right.equalToSuperview()
        }
        leftDownDot.snp.makeConstraints {(maker) in
            maker.width.height.equalTo(size)
            maker.bottom.left.equalToSuperview()
        }
        rightDownDot.snp.makeConstraints {(maker) in
            maker.width.height.equalTo(size)
            maker.bottom.right.equalToSuperview()
        }
    }

    func getDotView(_ size: CGFloat) -> UIView {
        let v = UIView()
        v.layer.cornerRadius = size / 2.0
        v.backgroundColor = UIColor.ud.primaryFillSolid03
        return v
    }
}
