//
//  UnzipingView.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/10.
//

import Foundation
import UIKit
import UniverseDesignEmpty
import UniverseDesignIcon
import LarkSDKInterface
import LarkContainer

final class UnzipingView: UIView {
    private let userGeneralSettings: UserGeneralSettings
    private lazy var messengerFileConfig: MessengerFileConfig = {
        return userGeneralSettings.messengerFileConfig
    }()
    private lazy var emptyView: UDEmpty = {
        let view = UDEmpty(config: .init(type: .defaultPage))
        return view
    }()
    private lazy var progressStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center
        view.spacing = 0
        return view
    }()

    private lazy var progressBar: UIProgressView = {
        let view = UIProgressView()
        view.tintColor = UIColor.ud.colorfulBlue
        view.trackTintColor = UIColor.ud.udtokenProgressBg
        return view
    }()

    private lazy var progressLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textColor = .ud.textPlaceholder
        view.textAlignment = .right
        view.text = "0%"
        view.numberOfLines = 0
        return view
    }()

    private lazy var successIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.succeedColorful, size: CGSize(width: 16, height: 16))
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 14)
        view.textColor = .ud.textCaption
        view.numberOfLines = 0
        var typesString = ""
        for (index, type) in messengerFileConfig.format.enumerated() {
            if index != 0 {
                typesString += BundleI18n.LarkFile.Lark_Legacy_ReactionSeparator
            }
            typesString += type

        }
        view.text = BundleI18n.LarkFile.Lark_IMPreviewCompress_PreviewOnlyFileTypeLessG_Toast(typesString, FileDisplayInfoUtil.sizeStringFromSize(messengerFileConfig.sizeUpperLimit))
        return view
    }()

    private lazy var descriptionContainView: UIView = {
        let view = UIView()
        return view
    }()

    init(userGeneralSettings: UserGeneralSettings) {
        self.userGeneralSettings = userGeneralSettings
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(126)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(248)
        }
        addSubview(progressStackView)
        progressStackView.snp.makeConstraints { make in
            make.top.equalTo(emptyView.snp.bottom).offset(8)
            make.left.equalTo(64)
            make.right.equalTo(-64)
        }
        progressStackView.addArrangedSubview(progressBar)
        progressStackView.addArrangedSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.width.equalTo(39)
        }
        addSubview(descriptionContainView)
        descriptionContainView.snp.makeConstraints { make in
            make.top.equalTo(progressStackView.snp.bottom).offset(38)
            make.left.equalTo(64)
            make.right.equalTo(-64)
        }
        descriptionContainView.addSubview(successIcon)
        descriptionContainView.addSubview(descriptionLabel)
        successIcon.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.left.equalToSuperview()
            make.width.height.equalTo(16)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(successIcon.snp.right).offset(8)
        }
    }

    func setProgress(_ percentage: Float) {
        progressBar.progress = percentage
        progressLabel.text = "\(Int(percentage * 100))%"
    }

    func setEmptyViewConfig(description: String) {
        emptyView.update(config: .init(description: .init(descriptionText: description),
                                       imageSize: 60,
                                       spaceBelowImage: 8,
                                       spaceBelowDescription: 16,
                                       type: .custom(Resources.fileZip)))
    }
}
