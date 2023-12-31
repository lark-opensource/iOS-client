//
//  LoadingView.swift
//  Calendar
//
//  Created by zhuchao on 2018/2/4.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import LarkUIKit
import MobileCoreServices
import CalendarFoundation
import UniverseDesignTheme
import UniverseDesignEmpty
import UniverseDesignButton
import UniverseDesignFont
import UniverseDesignColor

final class LoadingView: UIControl {
    private let loadingView: LoadingPlaceholderView = {
        let loading = LoadingPlaceholderView()
        loading.isHidden = true
        loading.backgroundColor = UIColor.clear
        loading.label.text = BundleI18n.Calendar.Calendar_Common_LoadingCommon
        loading.label.font = UIFont.cd.regularFont(ofSize: 16)
        return loading
    }()
    private let failView: FaildView = FaildView()

    private let textLabel: UILabel = UILabel.cd.textLabel()

    init(displayedView: UIView, centerYMultiplier: CGFloat = 375.0 / 503.0) {
        self.centerYMultiplier = centerYMultiplier
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        layout(with: displayedView)
        hideSelf()
    }

    private func layout(with displayedView: UIView) {
        layoutSelf(view: displayedView)
        layoutLoadingView(self.loadingView)
        layoutFailView(self.failView)
    }

    func hideSelf() {
        self.isHidden = true
    }

    func showLoading() {
        self.isHidden = false
        bringSubviewToFront(self.loadingView)
        self.loadingView.isHidden = false
        self.loadingView.animationView.startSkeletonAnimation()
        self.failView.isHidden = true
    }

    func remove() {
        self.removeFromSuperview()
    }

    func showFailed(title: String = BundleI18n.Calendar.Calendar_Common_FailedToLoad,
                    image: UIImage = UDEmptyType.loadingFailure.defaultImage(),
                    withRetry retry: (() -> Void)? = nil) {
        self.isHidden = false
        bringSubviewToFront(self.failView)
        self.failView.update(title: title, image: image, retry: retry)
        self.loadingView.isHidden = true
        self.failView.isHidden = false
    }

    private func layoutSelf(view: UIView) {
        view.addSubview(self)
        snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private let centerYMultiplier: CGFloat

    private func layoutFailView(_ failView: FaildView) {
        addSubview(failView)
        failView.snp.makeConstraints { (make) in
            make.left.right.centerY.equalTo(self)
        }
    }

    private func layoutLoadingView(_ loadingView: LoadingPlaceholderView) {
        addSubview(loadingView)
        loadingView.container.snp.remakeConstraints { (make) in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).multipliedBy(self.centerYMultiplier)
        }
    }

    func show(image: UIImage, title: String) {
        let imageView = UIImageView(image: image)

        let titleLabel = UILabel()
        titleLabel.font = UDFont.body2
        titleLabel.textColor = UDColor.textCaption
        titleLabel.text = title
        titleLabel.textAlignment = .center

        let content = UIView()
        content.addSubview(imageView)
        content.addSubview(titleLabel)

        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(100)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.height.equalTo(20)
        }

        addSubview(content)
        content.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).multipliedBy(self.centerYMultiplier)
        }
        self.loadingView.isHidden = true
        bringSubviewToFront(content)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class FaildView: UIView {
    private let imgView = UIImageView()
    private var retryAction: (() -> Void)?
    private let label = UILabel()
    private lazy var retryBtn: UDButton = {
        let button = UDButton.primaryBlue
        button.setTitle(I18n.Calendar_Attachment_Retry, for: .normal)
        button.addTarget(self, action: #selector(taped), for: .touchUpInside)
        return button
    }()
    init() {
        super.init(frame: .zero)
        layoutImageView(imgView)
        layoutTitleLabel(label)
        layoutRetryBtn(retryBtn)
    }

    @objc
    private func taped() {
        retryAction?()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, image: UIImage, retry: (() -> Void)? = nil) {
        label.text = title
        imgView.image = image
        retryAction = retry
        retryBtn.isHidden = retry == nil
    }

    private func layoutImageView(_ imgView: UIImageView) {
        addSubview(imgView)
        imgView.isUserInteractionEnabled = false
        imgView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(100)
        }
    }

    private func layoutTitleLabel(_ titleLabel: UILabel) {
        label.font = UIFont.cd.font(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        titleLabel.textAlignment = .center
        addSubview(titleLabel)
        titleLabel.isUserInteractionEnabled = false
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(imgView.snp.bottom).offset(12)
            make.height.equalTo(20)
        }
    }

    private func layoutRetryBtn(_ button: UIButton) {
        addSubview(button)
        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(label.snp.bottom).offset(16)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        imgView.sizeToFit()
        let imageSize = imgView.bounds.size
        label.sizeToFit()
        let textSize = label.bounds.size
        size.height = imageSize.height + textSize.height + 10// 边距
        size.width = max(imageSize.width, textSize.width)
        return size
    }
}
