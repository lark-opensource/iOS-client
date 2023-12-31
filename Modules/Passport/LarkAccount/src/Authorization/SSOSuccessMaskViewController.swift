//
//  SSOSuccessMaskViewController.swift
//  LarkWeb
//
//  Created by Yiming Qu on 2019/11/6.
//

import UIKit
import SnapKit
import LKCommonsTracker
import RxSwift
import LarkUIKit
import Homeric
import LKCommonsLogging
import UniverseDesignColor

class SSOSuccessView: UIView {

    let imageView: UIImageView = UIImageView(image: SSOVerifyResources.sso_success_tip)

    let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = I18N.Lark_Login_SSO_TitleOfManualGoback
        lbl.textColor = UIColor.ud.textTitle
        lbl.font = .systemFont(ofSize: 24, weight: .medium)
        lbl.adjustsFontSizeToFitWidth = true
        return lbl
    }()

    let descriptionLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = I18N.Lark_Login_SSO_DescriptionOfManualGoback
        lbl.textColor = UIColor.ud.textTitle
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 14)
        lbl.numberOfLines = 0
        return lbl
    }()

    init() {
        super.init(frame: CGRect.zero)
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(SSOVerifyResources.sso_success_tip.size.width).priority(.medium)
            make.height.equalTo(imageView.snp.width).multipliedBy(SSOVerifyResources.sso_success_tip.size.height / SSOVerifyResources.sso_success_tip.size.width).priority(.required)
            make.left.greaterThanOrEqualToSuperview().priority(.required)
            make.right.lessThanOrEqualToSuperview().priority(.required)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(Layout.imageTitleSpace)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleDescriptionSpace)
            make.left.right.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct Layout {
        static let imageTitleSpace: CGFloat = 43
        static let titleDescriptionSpace: CGFloat = 6
    }
}

class SSOSuccessMaskViewController: UIViewController {

    let logger = Logger.plog(SSOSuccessMaskViewController.self, category: "SuiteLogin.SSOSuccessMaskViewController")
    let successView: SSOSuccessView = SSOSuccessView()

    let closeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(SSOVerifyResources.sso_mask_close, for: .normal)
        return btn
    }()

    lazy var systemBackMaskView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.rgb(0x357DF5)
        v.layer.cornerRadius = backHeight / 2.0
        return v
    }()

    var backHeight: CGFloat {
        if Display.pad {
            return statusBarHeight
        } else {
            return Layout.backHeight
        }
    }

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        Tracker.post(TeaEvent(Homeric.SSO_MASK_PAGE_SHOW))
        setupUI()
    }

    deinit {
        Tracker.post(TeaEvent(Homeric.SSO_MASK_PAGE_DISMISS))
    }

    private func setupUI() {
        view.backgroundColor = UIColor.ud.rgba(0xD9000000)

        view.addSubview(systemBackMaskView)
        view.addSubview(closeBtn)
        view.addSubview(successView)

        systemBackMaskView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Layout.backLeftPadding)
            if Display.iPhoneXSeries {
                make.top.equalToSuperview().offset(Layout.backTopPaddingForIPhoneXSeries)
            } else {
                make.top.equalToSuperview().offset(Layout.backTopPaddingForNormal)
            }
            make.size.equalTo(CGSize(width: Layout.backWidth, height: backHeight))
        }
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Layout.closePading)
            make.right.equalToSuperview().offset(-Layout.closePading)
            make.size.equalTo(SSOVerifyResources.sso_close_btn.size)
        }
        successView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(Layout.padding)
            make.right.equalToSuperview().offset(-Layout.padding)
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private var statusBarHeight: CGFloat {
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            if let statusManager = view.window?.windowScene?.statusBarManager {
                return statusManager.statusBarFrame.size.height
            } else {
                self.logger.warn("fail get status bar height not found WindowScene")
                return Layout.backHeight
            }
        } else {
            return UIApplication.shared.statusBarFrame.size.height
        }
        #else
        return UIApplication.shared.statusBarFrame.size.height
        #endif
    }

    struct Layout {
        static let padding: CGFloat = 31
        static let closePading: CGFloat = 14
        // for anomalous screen e.g., iPhone X
        static let backTopPaddingForIPhoneXSeries: CGFloat = 24
        static let backTopPaddingForNormal: CGFloat = 0
        static let backLeftPadding: CGFloat = 4
        static let backWidth: CGFloat = 90
        static let backHeight: CGFloat = 20
    }
}
