//
//  FilterDrawerSectionFooter.swift
//  Todo
//
//  Created by baiyantao on 2023/2/22.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

struct FilterDrawerSectionFooterData {
    var isExpanded: Bool
}

final class FilterDrawerSectionFooter: UITableViewHeaderFooterView {

    var viewData: FilterDrawerSectionFooterData? {
        didSet {
            guard let data = viewData else { return }
            if data.isExpanded {
                titleLabel.text = I18N.Todo_TaskList_HideArchivedList_Button
                iconView.image = UDIcon.upOutlined
                    .ud.withTintColor(UIColor.ud.iconN2)
            } else {
                titleLabel.text = I18N.Todo_TaskList_ShowArchivedList_Button
                iconView.image = UDIcon.downOutlined
                    .ud.withTintColor(UIColor.ud.iconN2)
            }
        }
    }

    var clickHandler: (() -> Void)?

    private lazy var iconView = UIImageView()
    private lazy var titleLabel = initTitleLabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let containerView = UIView()
        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-8)
        }

        containerView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(48)
            $0.width.height.equalTo(16)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(iconView.snp.right).offset(4)
            $0.right.equalToSuperview().offset(-16)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onClick))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }

    @objc
    private func onClick() {
        clickHandler?()
    }
}
