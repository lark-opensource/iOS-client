//
//  EMManagerEntryModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/29.
//

import Foundation
import UIKit
import LarkUrgent
import UniverseDesignBadge
import LarkOpenSetting
import EENavigator
import LarkSettingUI
import LarkContainer

final class EMManagerEntryModule: BaseModule {
    private var emBadge: Bool = false

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.onRegisterDequeueViews = { tableView in
            tableView.register(EMManagerCell.self, forCellReuseIdentifier: "EMManagerCell")
        }
        NotificationCenter.default.rx
            .notification(Notification.EM.existActive.name)
            .subscribe(onNext: { [weak self] notification in
                guard let self = self, let show = notification.userInfo?[Notification.EM.exist] as? Bool else { return }
                if self.emBadge != show {
                    self.emBadge = show
                    self.context?.reload()
                }
            })
            .disposed(by: disposeBag)
        EMManager.shared.fetchExistActive()
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let item = EMManagerCellProp(
            title: EMManager.Cons.settingTitle,
            badgeConfig: emBadge ? .dot : nil,
            onClick: { [weak self] _ in
                guard let from = self?.context?.vc else { return }
                self?.userResolver.navigator.push(EMSettingViewController(), from: from)
            })
        return SectionProp(items: [item])
    }
}

final class EMManagerCellProp: CellProp, CellClickable {
    var title: String
    var badgeConfig: UDBadgeConfig?
    var onClick: ClickHandler?

    init(title: String,
         badgeConfig: UDBadgeConfig? = nil,
         onClick: ClickHandler? = nil) {
        self.title = title
        self.badgeConfig = badgeConfig
        self.onClick = onClick
        super.init(cellIdentifier: "EMManagerCell", selectionStyle: .normal)
    }
}

final class EMManagerCell: BaseCell {
    /// 中间标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.mine_right_arrow
        return imageView
    }()

    private lazy var badgeView: UDBadge = {
        let badgeView = UDBadge(config: .dot)
        badgeView.isHidden = true
        return badgeView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        /// 中间标题
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.top.equalTo(13)
        }

        /// badge
        contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }

        /// 箭头
        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? EMManagerCellProp else { return }

        titleLabel.setFigmaText(info.title)
        if let config = info.badgeConfig {
            self.badgeView.config = config
            self.badgeView.isHidden = false
        } else {
            self.badgeView.isHidden = true
        }
    }
}
