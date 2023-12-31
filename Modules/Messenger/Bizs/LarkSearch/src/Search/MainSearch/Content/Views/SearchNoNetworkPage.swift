//
//  SearchNoNetworkPage.swift
//  LarkSearch
//
//  Created by Patrick on 29/9/2022.
//

import UIKit
import Foundation
import LarkSearchCore

final class SearchNoNetworkPage: NiblessView {
    enum Status {
        case show(SearchError)
        case hide
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .ud.textTitle
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_NoInternetCheckSettings_RetryMobile, for: .normal)
        button.setTitleColor(.ud.textTitle, for: .normal)
        button.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)
        button.layer.cornerRadius = 6
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        button.layer.borderWidth = 1
        button.backgroundColor = .ud.udtokenComponentOutlinedBg
        return button
    }()

    private let container = UIView()

    var retryAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    func setup(withError error: SearchError, backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        switch error {
        case .timeout, .offline:
            titleLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_InternetErrorNoResults_TitlePC
            descriptionLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_NoInternetCheckSettings_NoticeMobile
        case .serverError:
            titleLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_ServerError_Text
            descriptionLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_ServerError_Desc
        }
    }

    private func setupViews() {
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(descriptionLabel)
        container.addSubview(retryButton)
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(54)
            make.bottom.equalToSuperview().inset(355)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
        }

        retryButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 96, height: 36))
        }
    }

    @objc
    private func didTapRetry() {
        retryAction?()
    }
}
