//
//  BTJiraMenuViews.swift
//  DocsSDK
//
//  Created by lizechuang on 2020/1/6.
//

import Foundation
import SKCommon
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import UIKit

public enum JiraActionId: String {
    case OpenJira
    case SyncJira
    case LockSync
    case UnLockSync
}

final class BTJiraMenuCell: UITableViewCell {
	private lazy var leftIcon = UIImageView().construct { it in
		it.contentMode = .scaleAspectFill
	}

	private lazy var nameLabel = UILabel().construct { it in
		it.textColor = UDColor.textTitle
		it.textAlignment = .left
		it.font = UIFont.systemFont(ofSize: 16)
	}

	private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupLayout()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupLayout() {
		contentView.addSubview(leftIcon)
		leftIcon.snp.makeConstraints { it in
			it.left.equalToSuperview().offset(14.5)
			it.centerY.equalToSuperview()
			it.height.width.equalTo(20)
		}

		contentView.addSubview(nameLabel)
		nameLabel.snp.makeConstraints { it in
			it.left.equalTo(leftIcon.snp.right).offset(13.5)
			it.centerY.equalToSuperview()
		}

		contentView.addSubview(bottomLine)
		bottomLine.snp.makeConstraints { it in
			it.left.equalTo(nameLabel)
			it.right.bottom.equalToSuperview()
			it.height.equalTo(1)
		}
	}

	func setActionData(action: BTJiraMenuAction, indexPath: IndexPath) {
        let type = JiraActionId(rawValue: action.id)
        let imageMapping: [JiraActionId?: UIImage] = [
            .OpenJira: UDIcon.switchItemOutlined,
            .SyncJira: UDIcon.refreshOutlined,
            .LockSync: UDIcon.lockOutlined,
            .UnLockSync: UDIcon.unlockOutlined
        ]
        leftIcon.image = action.enable ? imageMapping[type] : imageMapping[type]?.ud.withTintColor(UIColor.ud.iconDisabled)
		nameLabel.text = action.text
        if !action.enable {
            self.isUserInteractionEnabled = false
            nameLabel.textColor = UIColor.ud.iconDisabled
        }
	}
}

final class BTJiraDragTitleView: UIView {
	private lazy var dragLine = UIView().construct { it in
		it.backgroundColor = UDColor.lineBorderCard
		it.layer.cornerRadius = 2.0
	}

	lazy var titleLabel = UILabel().construct { it in
		it.textColor = UDColor.textTitle
		it.textAlignment = .left
		it.font = UIFont.systemFont(ofSize: 16)
	}

	lazy var detailLabel = UILabel().construct { it in
		it.textColor = UDColor.textCaption
		it.textAlignment = .left
		it.font = UIFont.systemFont(ofSize: 12)
	}

	private lazy var leftIcon = UIImageView().construct { it in
		it.contentMode = .scaleAspectFill
        it.image = UDIcon.getIconByKey(.jiraOutlined, size: CGSize(width: 36, height: 36))
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
        backgroundColor = UDColor.bgBody
		layer.cornerRadius = 6.0
        layer.maskedCorners = .top
		layer.masksToBounds = true
		setupLayout()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupLayout() {
		addSubview(dragLine)
		dragLine.snp.makeConstraints { it in
			it.top.equalToSuperview().offset(8.0)
			it.centerX.equalToSuperview()
			it.width.equalTo(40.0)
			it.height.equalTo(4.0)
		}

		addSubview(leftIcon)
		leftIcon.snp.makeConstraints { it in
			it.top.equalToSuperview().offset(26.0)
			it.left.equalToSuperview().offset(12.0)
			it.width.height.equalTo(36.0)
		}

		addSubview(titleLabel)
		titleLabel.snp.makeConstraints { it in
			it.top.equalTo(dragLine.snp.bottom).offset(9.0)
			it.left.equalTo(leftIcon.snp.right).offset(12.0)
		}

		addSubview(detailLabel)
		detailLabel.snp.makeConstraints { it in
			it.top.equalTo(titleLabel.snp.bottom).offset(2.0)
			it.left.equalTo(titleLabel)
			it.bottom.equalToSuperview().offset(-8.5)
		}
	}
}
