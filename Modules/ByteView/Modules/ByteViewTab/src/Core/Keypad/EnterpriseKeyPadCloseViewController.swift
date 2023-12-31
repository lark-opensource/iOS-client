//
//  EnterpriseKeyPadCloseViewController.swift
//  ByteView
//
//  Created by helijian on 2022/5/31.
//

import UIKit
import SnapKit
import ByteViewCommon
import LarkIllustrationResource
import UniverseDesignIcon
import ByteViewUI
import ByteViewSetting

class EnterpriseKeyPadCloseViewController: BaseViewController {

    struct Layout {
        static let heightOfNav: CGFloat = 44
        static let leftAndRightInset: CGFloat = 16
        static let insertOfLabels: CGFloat = 20
        static let insertOfImageAndButton: CGFloat = 24
        static let insertOfLabelAndImage: CGFloat = 8
    }

    lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var backButton: UIBarButtonItem = {
        let barInset: CGFloat = Display.iPhoneXSeries ? 8 : 4
        let color = UIColor.ud.iconN1
        let highlighedColor = UIColor.ud.N500
        var icon: UDIconType = Display.pad ? .closeOutlined : .leftOutlined
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: color), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: highlighedColor), for: .highlighted)
        actionButton.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -barInset, bottom: 0, right: barInset)
        return UIBarButtonItemFactory.create(customView: actionButton, size: CGSize(width: 32, height: 44))
    }()

    private let openServiceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.attributedText = .init(string: I18n.View_G_PhoneSystemSlogan, config: .h1)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let detaildescLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.attributedText = .init(string: I18n.View_G_PhoneSystemExplain(), config: VCFontConfig(fontSize: 14, lineHeight: 22, fontWeight: .regular))
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var moreInfoButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.setTitle(I18n.View_G_LearnMore_Button, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
        return button
    }()

    private let telephoneImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = LarkIllustrationResource.Resources.initializationFunctionTelephoneconference
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let viewModel: MeetTabViewModel
    init(viewModel: MeetTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.leftBarButtonItem = backButton
        setNavigationBarBgColor(.ud.bgBody)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(containerView)
        containerView.addSubview(openServiceLabel)
        containerView.addSubview(detaildescLabel)
        containerView.addSubview(telephoneImageView)
        containerView.addSubview(moreInfoButton)
        setupViews()
    }

    // disable-lint: duplicated code
    private func setupViews() {
        let centerYOffset = CGFloat((Layout.heightOfNav + VCScene.safeAreaInsets.top) / 2)
        containerView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(-centerYOffset)
            maker.right.left.equalToSuperview().inset(Display.phone ? 16 : 99)
        }
        openServiceLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.left.right.equalToSuperview().inset(10)
        }
        detaildescLabel.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(10)
            maker.top.equalTo(openServiceLabel.snp.bottom).offset(Layout.insertOfLabels)
        }
        telephoneImageView.snp.makeConstraints { maker in
            maker.top.equalTo(detaildescLabel.snp.bottom).offset(Layout.insertOfLabelAndImage)
            maker.size.equalTo(CGSize(width: 250, height: 250))
            maker.centerX.equalToSuperview()
        }
        moreInfoButton.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(telephoneImageView.snp.bottom).offset(Layout.insertOfImageAndButton)
            maker.height.equalTo(48)
            maker.bottom.equalToSuperview()
        }
    }
    // enable-lint: duplicated code

    @objc func tapped(_ sender: Any) {
        guard let url = URL(string: viewModel.setting.pstnInviteConfig.url) else { return }
        self.viewModel.router?.push(url, context: ["from": "byteView"], from: self.vc.topMost, forcePush: true, animated: true)
    }
}
