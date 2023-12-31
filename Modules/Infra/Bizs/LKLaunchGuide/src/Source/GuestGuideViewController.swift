//
//  GuestGuideViewController.swift
//  LKLaunchGuide
//
//  Created by Meng on 2020/7/31.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

final class GuestGuideViewController: UIViewController {
    private let closeButton = UIButton(frame: .zero)
    private let guideImage = UIImageView(frame: .zero)
    private let titleLabel = UILabel(frame: .zero)
    private let detailLabel = UILabel(frame: .zero)
    private let startButton = UIButton(frame: .zero)

    var closeAction: (() -> Void)?
    var startAction: (() -> Void)?

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupLayouts()
    }

    @objc
    private func didTapCloseButton() {
        closeAction?()
    }

    @objc
    private func didTapStartButton() {
        startAction?()
    }
}

extension GuestGuideViewController {
    private func setupViews() {
        view.addSubview(closeButton)
        view.addSubview(guideImage)
        view.addSubview(titleLabel)
        view.addSubview(detailLabel)
        view.addSubview(startButton)

        view.backgroundColor = UIColor.ud.bgBody
        closeButton.setImage(Resources.LKLaunchGuide.close, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        guideImage.image = Resources.LKLaunchGuide.vc_guide
        titleLabel.text = BundleI18n.LKLaunchGuide.Lark_UserGrowth_TitleVCTouristEndPage
        titleLabel.font = .boldSystemFont(ofSize: 22.0)
        titleLabel.textColor = UIColor.ud.textTitle
        detailLabel.text = BundleI18n.LKLaunchGuide.Lark_UserGrowth_DescVCTouristEndPage
        detailLabel.font = .systemFont(ofSize: 14.0)
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.numberOfLines = 0
        detailLabel.textAlignment = .center
        startButton.setTitle(BundleI18n.LKLaunchGuide.Lark_UserGrowth_ButtonVCTouristEndPage, for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 17.0)
        startButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        startButton.backgroundColor = UIColor.ud.primaryContentDefault
        startButton.layer.cornerRadius = 4.0
        startButton.addTarget(self, action: #selector(didTapStartButton), for: .touchUpInside)
    }

    private func setupLayouts() {
        closeButton.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(20.0)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16.0)
            make.size.equalTo(CGSize(width: 24.0, height: 24.0))
        }

        guideImage.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).inset(185.0)
            make.size.equalTo(CGSize(width: 210.0, height: 170.0))
        }

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(guideImage.snp.bottom).offset(42.0)
        }

        detailLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        detailLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        detailLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(21.0)
            make.leading.lessThanOrEqualToSuperview().inset(16.0)
            make.trailing.lessThanOrEqualToSuperview().inset(16.0)
        }

        startButton.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16.0)
            make.height.equalTo(48.0)
            make.top.equalTo(detailLabel.snp.bottom).offset(32.0)
        }
    }
}
