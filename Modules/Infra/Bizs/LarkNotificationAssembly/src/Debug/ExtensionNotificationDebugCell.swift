//
//  ExtensionNotificationDebugCell.swift
//  LarkExtensionAssembly
//
//  Created by yaoqihao on 2022/6/30.
//

import Foundation
import LarkNotificationServiceExtension
import LarkUIKit
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import NotificationUserInfo

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

final class NotificationLabelTableViewCell: UITableViewCell {
    lazy var titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.boldSystemFont(ofSize: 15)
        titleView.textColor = UIColor.ud.textTitle
        titleView.numberOfLines = 1
        return titleView
    }()

    lazy var bodyLabel: UILabel = {
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 13)
        bodyLabel.textColor = UIColor.ud.textTitle
        bodyLabel.numberOfLines = 1
        return bodyLabel
    }()

    lazy var wrapperView: UIStackView = {
        let wrapperView = UIStackView()
        wrapperView.axis = .vertical
        wrapperView.alignment = .fill
        return wrapperView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(wrapperView)

        self.wrapperView.addArrangedSubview(titleView)
        self.wrapperView.addArrangedSubview(bodyLabel)

        wrapperView.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(10)
            make.bottom.right.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(title: String, detail: String) {
        self.titleView.text = title
        self.bodyLabel.text = detail
    }
}

class NotificationDebugTableViewCell: UITableViewCell {
    var title: String = ""
    var body: String = ""
    var extra: LarkNSEExtra?

    lazy var avatarView: UIImageView = {
        let avatarView = UIImageView()
        avatarView.layer.cornerRadius = 10
        avatarView.contentMode = .scaleAspectFit
        return avatarView
    }()

    lazy var titleView: UILabel = {
        let titleView = UILabel()
        titleView.font = UIFont.boldSystemFont(ofSize: 15)
        titleView.textColor = UIColor.ud.textTitle
        titleView.numberOfLines = 1
        return titleView
    }()

    lazy var subTitleView: UILabel = {
        let subTitleView = UILabel()
        subTitleView.font = UIFont.boldSystemFont(ofSize: 15)
        subTitleView.textColor = UIColor.ud.textTitle
        subTitleView.numberOfLines = 1
        return subTitleView
    }()

    lazy var bodyLabel: UILabel = {
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 13)
        bodyLabel.textColor = UIColor.ud.textTitle
        bodyLabel.numberOfLines = 1
        return bodyLabel
    }()

    lazy var timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.font = UIFont.systemFont(ofSize: 13)
        timeLabel.textColor = UIColor.ud.textPlaceholder
        timeLabel.numberOfLines = 1
        return timeLabel
    }()

    lazy var wrapperView: UIStackView = {
        let wrapperView = UIStackView()
        wrapperView.axis = .vertical
        wrapperView.alignment = .fill
        return wrapperView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        let cellWrapper = UIView()
        cellWrapper.backgroundColor = UIColor.ud.bgFloat
        cellWrapper.layer.cornerRadius = 10
        cellWrapper.clipsToBounds = true
        cellWrapper.layer.masksToBounds = true
        cellWrapper.addSubview(avatarView)
        cellWrapper.addSubview(wrapperView)

        self.backgroundColor = .clear

        self.contentView.addSubview(cellWrapper)

        cellWrapper.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.left.right.equalToSuperview()
        }

        let titleWrapper = UIView()
        titleWrapper.addSubview(titleView)
        titleWrapper.addSubview(timeLabel)

        self.wrapperView.addArrangedSubview(titleWrapper)
        self.wrapperView.addArrangedSubview(subTitleView)
        self.wrapperView.addArrangedSubview(bodyLabel)

        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(38)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
        }

        wrapperView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.right.equalToSuperview().offset(-10)
            make.left.equalTo(avatarView.snp.right).offset(10)
        }

        titleView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
        }

        timeLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(titleView.snp.right)
            make.top.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(title: String, body: String, extra: LarkNSEExtra) {
        self.title = title
        self.body = body
        self.extra = extra
    }

    func getTime(time: UInt64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let formatString = "MM-dd HH:mm"
        let format = DateFormatter()
        format.dateFormat = formatString
        let logTime = format.string(from: date)
        return logTime
    }
}

final class NotificationDebugTableViewNormalCell: NotificationDebugTableViewCell {
    override func updateUI(title: String, body: String, extra: LarkNSEExtra) {
        super.updateUI(title: title, body: body, extra: extra)

        self.titleView.text = title
        self.bodyLabel.text = body
        self.timeLabel.text = self.getTime(time: extra.time)

        self.subTitleView.isHidden = true

        self.avatarView.image = UDIcon.docColorful
    }
}

final class NotificationDebugTableViewIntentCell: NotificationDebugTableViewCell {
    var currentDownloadTask: URLSessionDownloadTask?

    var iconImageView = UIImageView()

    override func updateUI(title: String, body: String, extra: LarkNSEExtra) {
        super.updateUI(title: title, body: body, extra: extra)

        getAvatar()

        self.titleView.text = extra.senderName
        self.bodyLabel.text = body
        self.subTitleView.text = extra.groupName
        self.timeLabel.text = self.getTime(time: extra.time)
        self.subTitleView.isHidden = false
    }

    private func getAvatar() {
        guard let imageUrl = extra?.imageUrl, let url = URL(string: imageUrl) else {
            updateAvatar()
            return
        }

        currentDownloadTask = URLSession.shared.downloadTask(with: url,
                                                             completionHandler: { [weak self] fileURL, _, error in
            if error != nil {
                self?.updateAvatar()
                return
            }

            if let fileURL = fileURL {
                let image = UIImage(contentsOfFile: fileURL.path)
                if image != nil {
                    self?.updateAvatar(image)
                } else {
                    self?.updateAvatar()
                }
            } else {
                self?.updateAvatar()
            }
        })

        // Begin download task.
        currentDownloadTask?.resume()
    }

    private func updateAvatar(_ avatar: UIImage? = nil) {
        DispatchQueue.main.async {
            self.iconImageView.removeFromSuperview()

            guard let avatar = avatar else {
                self.avatarView.image = UDIcon.docColorful
                self.avatarView.layer.cornerRadius = 10
                return
            }

            self.iconImageView = UIImageView()
            self.avatarView.addSubview(self.iconImageView)
            self.iconImageView.image = UDIcon.docColorful
            self.avatarView.image = avatar

            self.iconImageView.snp.makeConstraints { make in
                make.centerX.equalTo(self.avatarView.snp.right)
                make.centerY.equalTo(self.avatarView.snp.bottom)
                make.width.height.equalTo(16)
            }
            self.iconImageView.layer.cornerRadius = 4
            self.avatarView.layer.cornerRadius = 19
        }
    }
}
