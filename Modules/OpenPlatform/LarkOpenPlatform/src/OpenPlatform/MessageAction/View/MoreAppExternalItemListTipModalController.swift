//
//  MoreAppExternalItemListTipModalController.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/17.
//

import RichLabel
import UIKit
import LarkUIKit
import EENavigator
import RxSwift
import LKCommonsLogging
import Swinject
import RoundedHUD
import LarkOPInterface
class MoreAppExternalItemListTipModalController: UIViewController {
    private let backgroundView: UIView = UIView()
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.text = BundleI18n.LarkOpenPlatform.Lark_OpenPlatform_ShortcutsPreviewTtl
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16.0)
        label.textColor = UIColor.ud.textCaption
        label.text = BundleI18n.MessageAction.Lark_OpenPlatform_ScPcFreqHoverTip
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        return label
    }()
    private lazy var placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        let isChinese = (BundleI18n.currentLanguage == .zh_CN)
        let imageChinese = UIImage.dynamic(light: BundleResources.LarkOpenPlatform.user_display_config_placehold, dark: BundleResources.LarkOpenPlatform.user_display_config_placehold_darkmode)
        let imageEn = UIImage.dynamic(light: BundleResources.LarkOpenPlatform.user_display_config_placehold_en, dark: BundleResources.LarkOpenPlatform.user_display_config_placehold_en_darkmode)
        imageView.image = isChinese ? imageChinese : imageEn
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.10).cgColor
        imageView.layer.borderWidth = 0.8
        return imageView
    }()
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
    private lazy var dismissBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.MessageAction.Lark_OpenPlatform_ScIGotItBttn, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return button
    }()

    private let transition: DimmingTransition

    public init() {
        self.transition = DimmingTransition()
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(305)
        }

        let horizontalInset = 20
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(horizontalInset)
            make.top.equalToSuperview().offset(24)
        }

        container.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(horizontalInset)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
        }

        container.addSubview(placeholderImageView)
        placeholderImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(descriptionLabel.snp.bottom).offset(12)
            make.size.equalTo(CGSize(width: 264, height: 230))
        }

        container.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(placeholderImageView.snp.bottom).offset(24)
            make.height.equalTo(1)
        }

        dismissBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        container.addSubview(dismissBtn)
        dismissBtn.snp.makeConstraints { (make) in
            make.top.equalTo(lineView.snp.bottom).offset(12)
            make.bottom.equalToSuperview().offset(-13)
            make.height.equalTo(24)
            make.left.right.equalToSuperview()
        }
    }

    @objc
    func hide() {
        self.dismiss(animated: true, completion: nil)
    }
}
