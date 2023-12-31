//
//  DriveUploadCellIndicator.swift
//  SpaceKit
//
//  Created by Da Lei on 2019/2/27.
//

import Foundation
import Lottie
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor

protocol DriveUploadCellIndicatorDelegate: AnyObject {
    func driveUploadCellIndicator(_ indicator: DriveUploadCellIndicator, didClick retryButton: UIButton)
}

class DriveUploadCellIndicator: UIView {

    weak var delegate: DriveUploadCellIndicatorDelegate?

    private(set) lazy var completedLottieIcon: LOTAnimationView = {
        let animation = AnimationViews.driveUploadCheckAnimation
        animation.backgroundColor = UIColor.clear
        animation.autoReverseAnimation = false
        animation.loopAnimation = false
        animation.contentMode = .scaleAspectFill
        addSubview(animation)
        return animation
    }()

    private(set) lazy var progressBar: DriveCircleProgressBar = {
        let bar = DriveCircleProgressBar()
        bar.lineWidth = 2
        bar.isHidden = true
        addSubview(bar)
        return bar
    }()
    
    private(set) lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textPlaceholder
        label.backgroundColor = .clear
        label.isHidden = true
        label.sizeToFit()
        addSubview(label)
        return label
    }()

    private(set) lazy var retryButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.isHidden = true
        btn.setTitle(BundleI18n.SKResource.Drive_Drive_Retry, for: .normal)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.setTitleColor(UIColor.ud.colorfulBlue.withAlphaComponent(0.53), for: .highlighted)
        btn.setTitleColor(UDColor.iconDisabled, for: .disabled)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.titleLabel?.sizeToFit()
        btn.addTarget(self, action: #selector(didClickRetryButton(sender:)), for: .touchUpInside)
        addSubview(btn)
        return btn
    }()
    
    private(set) lazy var retryIcon: UIImageView = {
        let view = UIImageView()
        view.isHidden = true
        view.image = UDIcon.warningColorful
        view.backgroundColor = .clear
        addSubview(view)
        return view
    }()
    
    private(set) lazy var waitingLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.backgroundColor = .clear
        label.textColor = UDColor.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = BundleI18n.SKResource.Drive_Drive_WaitingForUpload
        label.sizeToFit()
        addSubview(label)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        completedLottieIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-12)
            make.width.height.equalTo(24)
        }

        progressBar.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
            make.width.height.equalTo(16)
        }
        
        progressLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
            make.right.equalTo(progressBar.snp.left).offset(-8)
        }

        retryIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-17)
            make.width.height.equalTo(16.5)
        }
        
        retryButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(retryIcon.snp.left).offset(-8.75)
            make.height.equalTo(40)
        }
        
        waitingLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
            make.left.greaterThanOrEqualToSuperview()
            make.height.equalTo(36)
        }
    }

    func render(status: DriveUploadStatus) {
        completedLottieIcon.isHidden = true
        progressBar.isHidden = true
        retryButton.isHidden = true
        progressLabel.isHidden = true
        retryIcon.isHidden = true
        waitingLabel.isHidden = true
        switch status {
        case .waiting:
            waitingLabel.isHidden = false
        case .uploading(let progress):
            progressBar.isHidden = false
            progressLabel.isHidden = false
            progressBar.progress = progress
            progressLabel.text = "\(Int(progress * 100))%"
        case .broken, .canceled:
            retryButton.isHidden = false
            retryIcon.isHidden = false
        case .completed:
            completedLottieIcon.isHidden = false
            completedLottieIcon.play()
        case .failNoRetry:
            retryButton.isHidden = true
            retryIcon.isHidden = true
        }
    }

    @objc
    func didClickRetryButton(sender: UIButton) {
        delegate?.driveUploadCellIndicator(self, didClick: sender)
    }
}
