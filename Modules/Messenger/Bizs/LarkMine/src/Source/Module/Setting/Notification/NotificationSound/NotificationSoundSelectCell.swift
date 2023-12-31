//
//  NotificationSoundSelectCell.swift
//  LarkMine
//
//  Created by Yaoguoguo on 2022/10/18.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignLoading

//push点击事件
typealias NotificationSoundSettingSelectHandler = () -> Void

enum NotificationSoundSettingStatus {
    case normal
    case selected
    case loading
}

struct NotificationSoundSettingSelectModel {
    var cellIdentifier: String
    var title: String
    var subTitle: String
    var status: NotificationSoundSettingStatus
    var selectedHandler: NotificationSoundSettingSelectHandler
}

final class NotificationSoundSettingSelectCell: UITableViewCell {
    var status: NotificationSoundSettingStatus = .normal {
        didSet {
            updateStatus()
        }
    }

    var item: NotificationSoundSettingSelectModel? {
        didSet {
            setCellInfo()
        }
    }

    /// 标题
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .left
        return titleLabel
    }()

    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = UIColor.ud.textPlaceholder
        subtitleLabel.textAlignment = .left
        return subtitleLabel
    }()

    /// 内容
    private lazy var selectIcon: UIImageView = {
        let contentIcon = UIImageView(image: Resources.select_icon)
        return contentIcon
    }()

    /// 内容
    private lazy var loadingView: UDSpin = {
        return UDLoading.presetSpin(
            color: .primary,
            loadingText: "",
            textDistribution: .horizonal
        )
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgFloat
        /// 设置水平方向抗压性
        self.contentView.addSubview(self.selectIcon)
        self.selectIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.selectIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        self.selectIcon.isHidden = true

        self.contentView.addSubview(self.loadingView)
        self.loadingView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.loadingView.snp.makeConstraints { (make) in
            make.center.equalTo(self.selectIcon.snp.center)
        }
        self.loadingView.isHidden = true

        /// 标题，距离头部底部为16，居中 距离开关16
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(14)
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(self.selectIcon.snp.left).offset(-16)
        }
        self.contentView.addSubview(self.subtitleLabel)
        self.subtitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(4)
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(self.selectIcon.snp.left).offset(-16)
            make.bottom.equalToSuperview().offset(-14)
        }
        self.lu.addTapGestureRecognizer(action: #selector(selectAction), target: self, touchNumber: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func selectAction() {
        guard let currItem = item as? NotificationSoundSettingSelectModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        currItem.selectedHandler()
    }

    func setCellInfo() {
        guard let currItem = item as? NotificationSoundSettingSelectModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        self.titleLabel.text = currItem.title
        self.subtitleLabel.text = currItem.subTitle

        var offset: CGFloat = 0
        if currItem.subTitle.isEmpty {
            self.subtitleLabel.isHidden = true
        } else {
            self.subtitleLabel.isHidden = false
            offset = 2
        }
        self.subtitleLabel.snp.updateConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(offset)
        }
        self.status = currItem.status
    }

    private func updateStatus() {
        self.selectIcon.isHidden = status != .selected
        self.loadingView.isHidden = status != .loading
    }
}
