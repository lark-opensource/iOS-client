//
//  WikiHomePageTableViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/22.
//

import UIKit
import SKCommon
import SKSpace
import UniverseDesignColor
import SKWorkspace

class WikiHomePageTableViewCell: UITableViewCell {
    let statusImageViewHeight: CGFloat = 12

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.ct.systemRegular(ofSize: 17)
        label.textColor = UDColor.textTitle
        return label
    }()

    // 同步状态View
    private lazy var statusView: SyncStatusView = {
        let view = SyncStatusView()
        return view
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.ct.systemRegular(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        self.docs.addStandardHover()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgBody
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-24)
            make.height.equalTo(24)
        }
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(statusView)
        statusView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: statusImageViewHeight, height: statusImageViewHeight))
            make.centerY.equalTo(subtitleLabel)
            make.left.equalTo(nameLabel)
        }
        configSynStatusUI(statusIsHidden: true)
    }

    private func configSynStatusUI(statusIsHidden: Bool) {
        statusView.isHidden = statusIsHidden
        if statusIsHidden {
            subtitleLabel.snp.remakeConstraints { (make) in
                make.height.equalTo(20)
                make.top.equalTo(nameLabel.snp.bottom)
                make.left.equalTo(nameLabel.snp.left)
                make.bottom.equalToSuperview().offset(-12)
                make.right.equalToSuperview().offset(-24)
            }
        } else {
            subtitleLabel.snp.remakeConstraints { (make) in
                make.height.equalTo(20)
                make.top.equalTo(nameLabel.snp.bottom)
                make.left.equalTo(statusView.snp.right).offset(2)
                make.bottom.equalToSuperview().offset(-12)
                make.right.equalToSuperview().offset(-24)
            }
        }
    }
    func updateUI(item: WikiHomePageListProtocol) {
        nameLabel.text = item.displayName
        subtitleLabel.text = item.subtitleContent
        if let image = item.displayIcon {
            iconImageView.image = image
        } else if let url = item.displayIconURL {
            iconImageView.kf.setImage(with: url)
        }
        statusView.image = item.syncStatusImage
        updateSynStatus(item.upSyncStatus)
        set(enable: item.enable)
    }

    func updateSynStatus(_ status: UpSyncStatus) {
        switch status {
        case .none, .finishOver1s:
            configSynStatusUI(statusIsHidden: true)
        default:
            configSynStatusUI(statusIsHidden: false)
        }
        if status == .uploading {
            statusView.startRotation()
        } else {
            statusView.stopRotation()
        }
    }

    func set(enable: Bool) {
        if enable {
            contentView.alpha = 1
        } else {
            contentView.alpha = 0.3
        }
    }
}
