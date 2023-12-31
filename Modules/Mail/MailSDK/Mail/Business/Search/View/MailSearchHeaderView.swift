//
//  MailSearchHeaderView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/4/11.
//

import UIKit
import SnapKit
import UniverseDesignButton
import Lottie

enum MailSearchHeaderStatus {
    case none
    case search
    case searching
    case searchSuccess
    case searchFail
    case searchFinish
}

protocol MailSearchHeaderViewDelegate: AnyObject {
    func headerViewDidClickedSearch(_ headerView: MailSearchHeaderView, status: MailSearchHeaderStatus)
}

class MailSearchHeaderView: UITableViewHeaderFooterView {
    weak var delegate: MailSearchHeaderViewDelegate?
    private(set) var height: CGFloat = 52.0
    var status: MailSearchHeaderStatus = .search {
        didSet {
            configStatusView()
        }
    }

    private lazy var titleLabel = self.makeTitleLabel()
    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }

    private var failedToLoadTextLen: CGFloat = 0
    private lazy var retryView = self.makeRetryView()
    private func makeRetryView() -> UIView {
        let retryView = UIView()
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        let failText = BundleI18n.MailSDK.Mail_ThirdClinet_FailedToLoad
        label.text = failText
        self.failedToLoadTextLen = failText.getTextWidth()

        let retryBtn = UIButton()
        retryBtn.setTitle(BundleI18n.MailSDK.Mail_ThirdClinet_Retry, for: .normal)
        retryBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        retryBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        retryBtn.layer.borderWidth = 1.0
        retryBtn.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        retryBtn.layer.cornerRadius = 6
        retryBtn.layer.masksToBounds = true

        retryView.addSubview(label)
        label.sizeToFit()
        label.snp.makeConstraints { (make) in
            //make.right.equalTo(retryView.snp.centerX).offset(-4)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalTo(failedToLoadTextLen + 8)
        }

        retryView.addSubview(retryBtn)
        retryBtn.snp.makeConstraints { (make) in
            //make.left.equalTo(retryView.snp.centerX).offset(4)
            make.left.equalTo(label.snp.right).offset(8)
            make.size.equalTo(CGSize(width: 72, height: 28))
        }

        return retryView
    }
    private let loadingView: LOTAnimationView = {
        let animation = AnimationViews.spinAnimation
        animation.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        animation.backgroundColor = UIColor.clear
        animation.contentMode = .scaleAspectFit
        return animation
    }()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupViews()
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickHeader)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.clipsToBounds = true
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        titleLabel.isHidden = true
        titleLabel.isUserInteractionEnabled = false
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        retryView.isHidden = true
        retryView.isUserInteractionEnabled = false
        addSubview(retryView)
        retryView.sizeToFit()
        retryView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(failedToLoadTextLen + 80)
        }
        loadingView.isHidden = true
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        configStatusView()
    }

    func configStatusView() {
        switch status {
        case .none:
            titleLabel.isHidden = true
            retryView.isHidden = true
            loadingView.isHidden = true
            loadingView.stop()
            
        case .search:
            retryView.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = BundleI18n.MailSDK.Mail_ThirdClinet_SearchInServer
            titleLabel.textColor = UIColor.ud.primaryContentDefault
            titleLabel.font = UIFont.systemFont(ofSize: 16)
            loadingView.isHidden = true
            loadingView.stop()

        case .searching:
            titleLabel.isHidden = true
            retryView.isHidden = true
            // 动画loading
            loadingView.isHidden = false
            loadingView.play()

        case .searchSuccess:
            retryView.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = BundleI18n.MailSDK.Mail_ThirdClinet_SearchResultsInServer
            titleLabel.textColor = UIColor.ud.textTitle
            titleLabel.font = UIFont.systemFont(ofSize: 14)
            loadingView.isHidden = true
            loadingView.stop()

        case .searchFail:
            retryView.isHidden = false
            titleLabel.isHidden = true
            loadingView.isHidden = true
            loadingView.stop()

        case .searchFinish:
            retryView.isHidden = true
            titleLabel.isHidden = false
            titleLabel.text = BundleI18n.MailSDK.Mail_ThirdClinet_NoMoreResults
            titleLabel.textColor = UIColor.ud.textPlaceholder
            titleLabel.font = UIFont.systemFont(ofSize: 12)
            loadingView.isHidden = true
            loadingView.stop()
        }
    }

    @objc
    func didClickHeader() {
        delegate?.headerViewDidClickedSearch(self, status: status)
    }
}
