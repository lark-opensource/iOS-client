//
//  SearchSpotlightStatusView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/3/13.
//

import UIKit
import LarkUIKit
import LarkCore
import SnapKit
import UniverseDesignIcon
import UniverseDesignLoading
import LarkContainer
import LarkMessengerInterface

final class SearchSpotlightStatusView: UIView {
    let defalutHeight: CGFloat = 48
    var didTapView: (() -> Void)?

    var status: SearchResultViewState.SpotlightState = .spotlightFinishLoading
    let loadingView = UDLoading.presetSpin(loadingText: BundleI18n.LarkSearch.Lark_Legacy_InLoading, textDistribution: .horizonal)
    let retryView = UIView()
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        self.addGestureRecognizer(tap)

        self.addSubview(retryView)
        retryView.backgroundColor = .clear

        let iconView = UIImageView(image: UDIcon.cloudFailedOutlined.ud.withTintColor(.ud.iconN1))

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_InternetErrorLimitedSearch_NoticeMobile
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle

        let retryLabel = UILabel()
        retryLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        retryLabel.textAlignment = .right
        retryLabel.text = BundleI18n.LarkSearch.Lark_ASLSearch_WeakNetworkNotice_InternetErrorLimitedSearch_RetryMobile
        retryLabel.font = UIFont.systemFont(ofSize: 14)
        retryLabel.textColor = UIColor.ud.textLinkNormal

        retryView.addSubview(iconView)
        retryView.addSubview(titleLabel)
        retryView.addSubview(retryLabel)

        retryView.snp.makeConstraints { make in
            make.top.bottom.centerX.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }

        iconView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(4)
        }

        retryLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing).offset(12)
        }

        retryView.isHidden = true
    }

    public func updateStatus(_ status: SearchResultViewState.SpotlightState) {
        self.status = status
        switch status {
        case .spotlightFinishLoading:
            loadingView.reset()
            loadingView.isHidden = false
            retryView.isHidden = true
        case .spotlightFinishSearchError:
            loadingView.isHidden = true
            retryView.isHidden = false
        @unknown default:
            break
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad(), !service.isCompactStatus() {
            self.backgroundColor = UIColor.clear
        } else {
            self.backgroundColor = UIColor.ud.bgBody
        }
    }

    @objc
    private func tapAction(_ sender: UIGestureRecognizer) {
        guard status == .spotlightFinishSearchError else { return }
        didTapView?()
    }
}
