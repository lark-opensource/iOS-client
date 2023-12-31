//
//  FileDownloadView.swift
//  LarkFile
//
//  Created by SuPeng on 12/12/18.
//

import UIKit
import Foundation
import UniverseDesignLoading

protocol FileDownloadViewDelegate: AnyObject {
    func downloadViewDidClickClose(_ downloadView: FileDownloadView)
    func downloadViewDidClickBottomButton(_ downloadView: FileDownloadView)
}

enum FileDownloadViewStatus {
    case origin, prepareToDownload, dowloading(percentage: Float, rate: Int64), pause(percentage: Float), fail, finish, decode, decodeFail
}

final class FileDownloadView: UIView {
    weak var delegate: FileDownloadViewDelegate?

    private(set) var status: FileDownloadViewStatus = .origin

    private let size: String
    private let remainSize: () -> String

    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let rateLabel = UILabel()
    private let progressStackView = UIStackView()
    private let progressView = UIProgressView()
    private let closeButton = UIButton()
    private let finishButton = UIButton()
    private let leftLabel = UILabel()
    private let decodeFailLabel = UILabel()
    let bottomButton = UIButton()
    private let decodeSpinView = UDLoading.presetSpin(size: .normal)

    init(icon: UIImage, name: String, size: String, remainSize: @escaping () -> String) {
        self.size = size
        self.remainSize = remainSize

        super.init(frame: .zero)

        backgroundColor = UIColor.ud.N00

        addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = icon

        addSubview(nameLabel)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.text = name
        nameLabel.numberOfLines = 0
        nameLabel.textAlignment = .center
        nameLabel.font = UIFont.systemFont(ofSize: 17)

        addSubview(rateLabel)
        rateLabel.textColor = UIColor.ud.textPlaceholder
        rateLabel.numberOfLines = 1
        rateLabel.textAlignment = .center
        rateLabel.font = UIFont.systemFont(ofSize: 14)
        rateLabel.isHidden = true

        progressStackView.isHidden = true
        progressStackView.axis = .horizontal
        progressStackView.distribution = .fill
        progressStackView.alignment = .center
        progressStackView.spacing = 12
        addSubview(progressStackView)

        progressView.tintColor = UIColor.ud.colorfulBlue
        progressView.trackTintColor = UIColor.ud.N300
        progressStackView.addArrangedSubview(progressView)

        decodeSpinView.isHidden = true
        addSubview(decodeSpinView)

        closeButton.setImage(Resources.file_download_close, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        progressStackView.addArrangedSubview(closeButton)

        finishButton.isHidden = true
        finishButton.setImage(Resources.file_download_finish, for: .normal)
        progressStackView.addArrangedSubview(finishButton)

        leftLabel.isHidden = true
        leftLabel.textColor = UIColor.ud.colorfulBlue
        leftLabel.font = UIFont.systemFont(ofSize: 12)
        leftLabel.numberOfLines = 0
        addSubview(leftLabel)

        decodeFailLabel.isHidden = true
        decodeFailLabel.textColor = UIColor.ud.colorfulRed
        decodeFailLabel.font = UIFont.systemFont(ofSize: 12)
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        decodeFailLabel.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        decodeFailLabel.textAlignment = .center
        decodeFailLabel.text = BundleI18n.LarkFile.Lark_IM_SecureChat_UnableToDecryptFile_Desc
        addSubview(decodeFailLabel)

        bottomButton.clipsToBounds = true
        bottomButton.layer.cornerRadius = 4
        bottomButton.backgroundColor = UIColor.ud.colorfulBlue
        bottomButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        bottomButton.addTarget(self, action: #selector(bottomButtonDidClick), for: .touchUpInside)
        addSubview(bottomButton)

        set(status: .origin)

        if UIDevice.current.userInterfaceIdiom == .phone {
            layoutForPhone()
        } else {
            layoutForPad()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutForPhone() {
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 70, height: 70))
            make.centerX.equalToSuperview()
            make.top.equalTo(107)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.left.equalTo(25)
            make.right.equalTo(-25)
        }

        rateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.left.equalTo(25)
            make.right.equalTo(-25)
        }

        progressStackView.snp.makeConstraints { (make) in
            make.left.equalTo(45)
            make.right.equalToSuperview().offset(-45)
            make.top.equalTo(nameLabel.snp.bottom).offset(50)
        }

        decodeSpinView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(53)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        finishButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        leftLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(progressView.snp.leading)
            make.trailing.equalTo(progressView.snp.trailing)
            make.top.equalTo(progressView.snp.bottom).offset(10)
        }

        decodeFailLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(nameLabel.snp.bottom).offset(48)
        }

        bottomButton.snp.makeConstraints { (make) in
            make.left.equalTo(82.5)
            make.right.equalToSuperview().offset(-82.5)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-82.5)
        }
    }

    private func layoutForPad() {

        let wrapperGuide = UILayoutGuide()
        addLayoutGuide(wrapperGuide)
        wrapperGuide.snp.makeConstraints { (make) in
            make.centerY.equalTo(self).offset(-42)
            make.centerX.equalTo(self)
            make.left.equalTo(self).priority(.low)
            make.right.equalTo(self).priority(.low)
            make.width.lessThanOrEqualTo(450).priority(.high)
        }

        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 70, height: 70))
            make.centerX.equalTo(wrapperGuide)
            make.top.equalTo(wrapperGuide)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.left.equalTo(wrapperGuide).offset(25)
            make.right.equalTo(wrapperGuide).offset(-25)
        }

        progressStackView.snp.makeConstraints { (make) in
            make.left.equalTo(wrapperGuide).offset(45)
            make.right.equalTo(wrapperGuide).offset(-45)
            make.top.equalTo(nameLabel.snp.bottom).offset(47)
        }

        decodeSpinView.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(53)
            make.centerX.equalToSuperview()
        }

        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        finishButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        leftLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(progressView.snp.leading)
            make.trailing.equalTo(progressView.snp.trailing)
            make.top.equalTo(progressView.snp.bottom).offset(10)
        }

        decodeFailLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.top.equalTo(nameLabel.snp.bottom).offset(48)
        }

        bottomButton.snp.makeConstraints { (make) in
            make.left.equalTo(wrapperGuide).offset(45)
            make.right.equalTo(wrapperGuide).offset(-45)
            make.width.equalTo(277)
            make.height.equalTo(48)
            make.top.equalTo(leftLabel.snp.bottom).offset(47)
            make.bottom.equalTo(wrapperGuide)
        }
    }

    @objc
    private func closeButtonDidClick() {
        delegate?.downloadViewDidClickClose(self)
    }

    @objc
    private func bottomButtonDidClick() {
        delegate?.downloadViewDidClickBottomButton(self)
    }

    func set(status: FileDownloadViewStatus, authorityControlDeny: Bool = false) {
        self.status = status
        decodeSpinView.isHidden = true
        decodeFailLabel.isHidden = true
        switch status {
        case .origin:
            progressStackView.isHidden = true
            leftLabel.isHidden = true
            bottomButton.isHidden = true
        case .prepareToDownload:
            progressStackView.isHidden = true
            leftLabel.isHidden = true
            bottomButton.isHidden = false
            bottomButton.layer.borderWidth = 0
            bottomButton.backgroundColor = UIColor.ud.colorfulBlue
            bottomButton.setTitle(BundleI18n.LarkFile.Lark_Legacy_Download + "(" + size + ")", for: .normal)
            bottomButton.setTitleColor(UIColor.ud.N00, for: .normal)
        case .dowloading(percentage: let percentage, rate: let rate):
            progressStackView.isHidden = false
            progressView.progress = percentage
            //添加速率
            if rate > 0 {
                rateLabel.isHidden = false
                rateLabel.text = String(format: "%.1f", Double(rate) / Double((1024 * 1024))) + "MB/s"
            } else {
                rateLabel.isHidden = true
            }
            progressView.tintColor = UIColor.ud.colorfulBlue
            closeButton.isHidden = false
            finishButton.isHidden = true
            leftLabel.isHidden = true
            bottomButton.isHidden = false
            bottomButton.backgroundColor = UIColor.ud.N00
            bottomButton.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
            bottomButton.layer.borderWidth = 1
            bottomButton.setTitle(BundleI18n.LarkFile.Lark_Legacy_FileSuspendDownload, for: .normal)
            bottomButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        case .pause(percentage: let percentage):
            rateLabel.isHidden = true
            progressStackView.isHidden = false
            progressView.progress = percentage
            progressView.tintColor = UIColor.ud.colorfulBlue
            closeButton.isHidden = false
            finishButton.isHidden = true
            leftLabel.isHidden = true
            bottomButton .isHidden = false
            bottomButton.layer.borderWidth = 0
            bottomButton.backgroundColor = UIColor.ud.colorfulBlue
            bottomButton.setTitle(BundleI18n.LarkFile.Lark_Legacy_FileResumeDownload + "(" + remainSize() + ")", for: .normal)
            bottomButton.setTitleColor(UIColor.ud.N00, for: .normal)
        case .fail:
            rateLabel.isHidden = true
            progressStackView.isHidden = false
            progressView.tintColor = UIColor.ud.colorfulRed
            closeButton.isHidden = false
            finishButton.isHidden = true
            leftLabel.isHidden = false
            leftLabel.textColor = UIColor.ud.colorfulRed
            /// 这里只展示一行，尽可能多的展示内容
            // swiftlint:disable ban_linebreak_byChar
            leftLabel.lineBreakMode = .byCharWrapping
            // swiftlint:enable ban_linebreak_byChar
            leftLabel.text = authorityControlDeny ? BundleI18n.LarkFile.Lark_Audit_BlockedActionsDueToPermissionSettings(BundleI18n.LarkFile.Lark_Audit_BlockedActionDownloadFile)
                : BundleI18n.LarkFile.Lark_Legacy_FileDownloadFail
            bottomButton .isHidden = false
            bottomButton.layer.borderWidth = 0
            bottomButton.backgroundColor = UIColor.ud.colorfulBlue
            bottomButton.setTitle(BundleI18n.LarkFile.Lark_Legacy_ReDownload, for: .normal)
            bottomButton.setTitleColor(UIColor.ud.N00, for: .normal)
        case .finish:
            rateLabel.isHidden = true
            progressStackView.isHidden = false
            progressView.tintColor = UIColor.ud.colorfulBlue
            progressView.progress = 1.0
            closeButton.isHidden = true
            finishButton.isHidden = false
            leftLabel.isHidden = false
            leftLabel.textColor = UIColor.ud.colorfulBlue
            leftLabel.text = BundleI18n.LarkFile.Lark_Legacy_UnsupportedFormatPleaseUseOtherApp
            bottomButton.isHidden = false
            bottomButton.setTitle(BundleI18n.LarkFile.Lark_Legacy_OpenInAnotherApp, for: .normal)
            let (textColor, backgroundColor, borderWidth, borderColor) = authorityControlDeny
                ? (UIColor.ud.N400, UIColor.ud.N00, 1, UIColor.ud.N400)
                : (UIColor.ud.N00, UIColor.ud.colorfulBlue, 0, UIColor.ud.N400)
            bottomButton.setTitleColor(textColor, for: .normal)
            bottomButton.backgroundColor = backgroundColor
            bottomButton.layer.borderWidth = CGFloat(borderWidth)
            bottomButton.layer.borderColor = borderColor.cgColor
        case .decode:
            progressStackView.isHidden = true
            rateLabel.isHidden = false
            rateLabel.text = BundleI18n.LarkFile.Lark_IM_SecureChat_DecryptingNow_Text
            closeButton.isHidden = true
            finishButton.isHidden = true
            leftLabel.isHidden = true
            bottomButton.isHidden = true
            decodeSpinView.isHidden = false
        case .decodeFail:
            progressStackView.isHidden = true
            rateLabel.isHidden = true
            closeButton.isHidden = true
            finishButton.isHidden = true
            decodeFailLabel.isHidden = false
            bottomButton.isHidden = false
            bottomButton.layer.borderWidth = 0
            bottomButton.backgroundColor = UIColor.ud.colorfulBlue
            bottomButton.setTitle(BundleI18n.LarkFile.Lark_IM_SecureChat_UnableToDecryptFile_TryAgain_Button, for: .normal)
            bottomButton.setTitleColor(UIColor.ud.N00, for: .normal)
        }
    }
}
