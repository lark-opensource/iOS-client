//
//  SendAttachedFileContentView.swift
//  LarkFile
//
//  Created by ChalrieSu on 2018/9/20.
//

import UIKit
import Foundation

final class SendAttachedFileContentView: UIView {
    private let iconButton = UIButton()
    private let titleLabel = UILabel()
    private let sizeLabel = UILabel()
    private let durationLabel = UILabel()

    var iconButtonClickedBlock: ((SendAttachedFileContentView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconButton)
        iconButton.imageView?.contentMode = .scaleAspectFill
        iconButton.clipsToBounds = true
        iconButton.snp.makeConstraints { (make) in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        iconButton.addTarget(self, action: #selector(iconButtonClicked), for: .touchUpInside)

        addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textAlignment = .left
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconButton.snp.right).offset(12)
            make.top.equalToSuperview().offset(14.5)
            make.right.equalToSuperview()
        }

        addSubview(sizeLabel)
        sizeLabel.font = UIFont.systemFont(ofSize: 12)
        sizeLabel.textAlignment = .left
        sizeLabel.textColor = UIColor.ud.N500
        sizeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconButton.snp.right).offset(12)
            make.bottom.equalToSuperview().offset(-14)
        }

        addSubview(durationLabel)
        durationLabel.font = UIFont.systemFont(ofSize: 12)
        durationLabel.textAlignment = .left
        durationLabel.textColor = UIColor.ud.N500
        durationLabel.snp.makeConstraints { (make) in
            make.left.equalTo(sizeLabel.snp.right).offset(10)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    @objc
    func iconButtonClicked() {
        iconButtonClickedBlock?(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(name: String, size: Int64, duration: TimeInterval?, isVideo: Bool) {
        if isVideo {
            iconButton.imageView?.contentMode = .scaleAspectFill
        } else {
            iconButton.imageView?.contentMode = .scaleAspectFit
        }
        titleLabel.text = name
        sizeLabel.text = sizeStringFromSize(size)
        if let duration = duration {
            durationLabel.text = durationStringFromDuration(duration)
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }
    }

    func setImage(_ image: UIImage?) {
        iconButton.setImage(image, for: .normal)
    }

    /// 把TimeInterval转成 "时长： 28：56：39" 这种格式
    private func durationStringFromDuration(_ timeInterval: TimeInterval) -> String {
        let hourString = String(format: "%02d", Int(timeInterval / 3600))
        let minString = String(format: "%02d", Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60))
        let secondString = String(format: "%02d", Int(timeInterval.truncatingRemainder(dividingBy: 60)))
        return BundleI18n.LarkFile.Lark_File_FileAttachVideoDuration + ":" + "\(hourString)" + ":" + "\(minString)" + ":" + "\(secondString)"
    }

    static let tokens = ["Bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
    /// 把size转成 "296.5MB" 这种格式
    private func sizeStringFromSize(_ size: Int64) -> String {
        var size: Float = Float(size)
        var mulitiplyFactor = 0
        while size > 1024 {
            size /= 1024
            mulitiplyFactor += 1
        }
        if mulitiplyFactor < SendAttachedFileContentView.tokens.count {
            return String(format: "%.2f\(SendAttachedFileContentView.tokens[mulitiplyFactor])", size)
        }
        return ""
    }
}
